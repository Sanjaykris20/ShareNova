import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sharenova.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. File Expiry Schema
    await db.execute('''
      CREATE TABLE file_expiry (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        expiry_deadline INTEGER NOT NULL, -- Unix timestamp in ms
        max_views INTEGER,
        view_count INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0 -- Boolean: 0 = false, 1 = true
      )
    ''');

    // 2. Local Transfer Log Schema
    await db.execute('''
      CREATE TABLE transfer_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        direction TEXT NOT NULL, -- 'sent' or 'received'
        channel TEXT NOT NULL,    -- 'wifiDirect' or 'bluetooth'
        speed REAL NOT NULL,      -- Mbps
        timestamp INTEGER NOT NULL, -- Unix timestamp in ms
        encrypted INTEGER DEFAULT 1,
        passcode INTEGER DEFAULT 0
      )
    ''');

    // 3. Trusted Devices Schema (for auto-sync & pairings)
    await db.execute('''
      CREATE TABLE trusted_devices (
        id TEXT PRIMARY KEY, -- Device ID or MAC Address
        display_name TEXT NOT NULL,
        service_uuid TEXT,
        public_key TEXT NOT NULL
      )
    ''');

    // 4. Auto-Sync Rules Schema
    await db.execute('''
      CREATE TABLE sync_rules (
        id TEXT PRIMARY KEY,
        folder_path TEXT NOT NULL,
        trigger_type TEXT NOT NULL, -- 'time', 'wifi', 'battery', 'proximity'
        trigger_value TEXT,         -- e.g. SSID, hour, threshold
        target_device_id TEXT NOT NULL,
        FOREIGN KEY (target_device_id) REFERENCES trusted_devices (id)
      )
    ''');

    // 5. Offline Pending Revokes Schema
    await db.execute('''
      CREATE TABLE pending_revokes (
        file_id TEXT PRIMARY KEY,
        target_device_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        delivered INTEGER DEFAULT 0
      )
    ''');

    // 6. Local Room Audit Log Schema
    await db.execute('''
      CREATE TABLE audit_log (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        actor_device_id TEXT NOT NULL,
        action TEXT NOT NULL, -- 'UPLOAD', 'DELETE', 'REVOKE', 'ROLE_CHANGE', 'VIEW'
        file_id TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // --- CRUD helpers for File Expiry ---

  Future<int> insertFileExpiry(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('file_expiry', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getFileExpiry(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'file_expiry',
      columns: ['id', 'file_path', 'expiry_deadline', 'max_views', 'view_count', 'deleted'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateFileExpiry(String id, Map<String, dynamic> values) async {
    final db = await instance.database;
    return await db.update(
      'file_expiry',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getActiveFileExpiries() async {
    final db = await instance.database;
    return await db.query(
      'file_expiry',
      where: 'deleted = 0',
    );
  }

  // --- CRUD helpers for Transfer Log ---

  Future<int> insertTransferLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transfer_log', row);
  }

  Future<List<Map<String, dynamic>>> getTransferLogs() async {
    final db = await instance.database;
    return await db.query('transfer_log', orderBy: 'timestamp DESC');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

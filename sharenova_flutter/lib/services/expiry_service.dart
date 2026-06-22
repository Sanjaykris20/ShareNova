// ignore_for_file: avoid_print
import 'dart:io';
import 'db_helper.dart';

class ExpiryService {
  static final ExpiryService instance = ExpiryService._init();
  ExpiryService._init();

  /// Registers a file for expiry tracking in SQLite.
  /// [expiryDuration] is duration after which it expires.
  /// [maxViews] is the maximum times a file can be opened.
  Future<void> registerFile({
    required String fileId,
    required String filePath,
    Duration? expiryDuration,
    int? maxViews,
  }) async {
    final int deadline = expiryDuration != null
        ? DateTime.now().add(expiryDuration).millisecondsSinceEpoch
        : DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch; // default 1 year

    await DbHelper.instance.insertFileExpiry({
      'id': fileId,
      'file_path': filePath,
      'expiry_deadline': deadline,
      'max_views': maxViews,
      'view_count': 0,
      'deleted': 0,
    });
  }

  /// Verification check that runs "on access" before rendering the file.
  /// Increments view count and checks if the file has expired.
  /// If expired or views exceeded, deletes the file from disk and marks as deleted in DB.
  /// Returns `true` if valid, `false` if expired and deleted.
  Future<bool> verifyAndAccess(String fileId) async {
    final expiry = await DbHelper.instance.getFileExpiry(fileId);
    if (expiry == null) return true; // not tracked under expiry rules

    if (expiry['deleted'] == 1) {
      return false; // already deleted
    }

    final int deadline = expiry['expiry_deadline'];
    final int? maxViews = expiry['max_views'];
    final int viewCount = expiry['view_count'];
    final String filePath = expiry['file_path'];

    final now = DateTime.now().millisecondsSinceEpoch;

    // Check time deadline
    if (now > deadline) {
      await _deleteFile(fileId, filePath);
      return false;
    }

    // Check view count limit
    if (maxViews != null && viewCount >= maxViews) {
      await _deleteFile(fileId, filePath);
      return false;
    }

    // Increment view count since we are accessing it now
    final newViewCount = viewCount + 1;
    await DbHelper.instance.updateFileExpiry(fileId, {
      'view_count': newViewCount,
    });

    // Check if this access hit the limit
    if (maxViews != null && newViewCount >= maxViews) {
      // Wiped immediately after this final view
      await _deleteFile(fileId, filePath);
    }

    return true;
  }

  /// Periodic background cleaner running while the app is active
  Future<void> runCleanup() async {
    final activeExpiries = await DbHelper.instance.getActiveFileExpiries();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var expiry in activeExpiries) {
      final String fileId = expiry['id'];
      final String filePath = expiry['file_path'];
      final int deadline = expiry['expiry_deadline'];
      final int? maxViews = expiry['max_views'];
      final int viewCount = expiry['view_count'];

      if (now > deadline || (maxViews != null && viewCount >= maxViews)) {
        await _deleteFile(fileId, filePath);
      }
    }
  }

  Future<void> _deleteFile(String fileId, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting expired file $filePath: $e');
    } finally {
      await DbHelper.instance.updateFileExpiry(fileId, {
        'deleted': 1,
      });
    }
  }
}

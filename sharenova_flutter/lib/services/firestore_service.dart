// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sharenova_flutter/models/file_metadata.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  Future<void> saveUser({
    required String deviceId,
    required String displayName,
    required String publicKeyBase64,
    String? fcmToken,
  }) async {
    await _db.collection(_usersCollection).doc(deviceId).set({
      'displayName': displayName,
      'publicKey': publicKeyBase64,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String deviceId) async {
    final doc = await _db.collection(_usersCollection).doc(deviceId).get();
    return doc.data();
  }

  // Existing share collection methods (kept for compatibility)
  static const String _sharesCollection = 'shares';

  Future<void> createShare({
    required String senderId,
    required String receiverId,
    required String type,
    required String url,
    required Map<String, dynamic> extra,
  }) async {
    await _db.collection(_sharesCollection).add({
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type,
      'url': url,
      'extra': extra,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ShareItem>> getReceivedShares(String userId) {
    return _db
        .collection(_sharesCollection)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShareItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------- File metadata methods ----------
  static const String _filesCollection = 'files';

  /// Creates a file metadata document. Returns the generated document ID.
  Future<String> createFileEntry(FileMetadata meta) async {
    final docRef = await _db.collection(_filesCollection).add(meta.toMap());
    return docRef.id;
  }

  /// Retrieves a [FileMetadata] for the given document ID.
  Future<FileMetadata?> getFileMetadata(String fileId) async {
    final doc = await _db.collection(_filesCollection).doc(fileId).get();
    if (!doc.exists) return null;
    return FileMetadata.fromDoc(doc);
  }
}

class ShareItem {
  final String id;
  final String senderId;
  final String receiverId;
  final String type;
  final String url;
  final Map<String, dynamic> extra;
  final Timestamp timestamp;

  ShareItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.url,
    required this.extra,
    required this.timestamp,
  });

  factory ShareItem.fromMap(String id, Map<String, dynamic> map) {
    return ShareItem(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      type: map['type'] ?? '',
      url: map['url'] ?? '',
      extra: Map<String, dynamic>.from(map['extra'] ?? {}),
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}

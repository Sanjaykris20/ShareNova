// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing metadata for a file stored in Firebase Storage.
class FileMetadata {
  final String fileId;
  final String ownerId;
  final String? roomId; // null for direct transfers
  final String? recipientDeviceId; // null for room files
  final String fileName;
  final int sizeBytes;
  final String mimeType;
  final String storagePath; // Firebase Storage path
  final String? encryptedKeyBlob; // AES key or ECDH public key
  final Timestamp? expiryTimestamp;
  final int? maxViews;
  final int viewCount;
  final bool deleted;
  final bool passcodeProtected;
  final String? saltHex; // for PBKDF2 if passcode protected
  final Timestamp? createdAt;
  final bool synced;

  FileMetadata({
    required this.fileId,
    required this.ownerId,
    this.roomId,
    this.recipientDeviceId,
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
    required this.storagePath,
    this.encryptedKeyBlob,
    this.expiryTimestamp,
    this.maxViews,
    this.viewCount = 0,
    this.deleted = false,
    this.passcodeProtected = false,
    this.saltHex,
    this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'roomId': roomId,
        'recipientDeviceId': recipientDeviceId,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
        'storagePath': storagePath,
        'encryptedKeyBlob': encryptedKeyBlob,
        'expiryTimestamp': expiryTimestamp,
        'maxViews': maxViews,
        'viewCount': viewCount,
        'deleted': deleted,
        'passcodeProtected': passcodeProtected,
        'saltHex': saltHex,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'synced': synced,
      };

  factory FileMetadata.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FileMetadata(
      fileId: doc.id,
      ownerId: data['ownerId'] ?? '',
      roomId: data['roomId'],
      recipientDeviceId: data['recipientDeviceId'],
      fileName: data['fileName'] ?? '',
      sizeBytes: data['sizeBytes'] ?? 0,
      mimeType: data['mimeType'] ?? '',
      storagePath: data['storagePath'] ?? '',
      encryptedKeyBlob: data['encryptedKeyBlob'],
      expiryTimestamp: data['expiryTimestamp'],
      maxViews: data['maxViews'],
      viewCount: data['viewCount'] ?? 0,
      deleted: data['deleted'] ?? false,
      passcodeProtected: data['passcodeProtected'] ?? false,
      saltHex: data['saltHex'],
      createdAt: data['createdAt'],
      synced: data['synced'] ?? false,
    );
  }
}

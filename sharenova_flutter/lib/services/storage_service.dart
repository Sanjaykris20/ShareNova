// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sharenova_flutter/models/file_metadata.dart';
import 'package:sharenova_flutter/services/cloud/chunked_uploader.dart';
import 'package:sharenova_flutter/services/cloud/chunked_downloader.dart';
import 'package:sharenova_flutter/services/firestore_service.dart';
import 'package:sharenova_flutter/core/crypto/ecdh_key_pair.dart';
import 'package:sharenova_flutter/core/crypto/aes_gcm_cipher.dart';

class StorageService {
  final FirestoreService _firestore = FirestoreService();

  /// Uploads a [file] securely using ECDH and AES-GCM, storing metadata in Firestore.
  /// If [recipientPublicKeyBase64] is supplied, encrypts the file prior to chunked upload.
  /// Returns the generated fileId.
  Future<String> uploadFile(
    File file,
    FileMetadata meta, {
    String? recipientPublicKeyBase64,
  }) async {
    final storagePath = 'uploads/${meta.ownerId}/${DateTime.now().millisecondsSinceEpoch}_${meta.fileName}';

    File fileToUpload = file;
    String? encryptedKeyBlob;

    if (recipientPublicKeyBase64 != null) {
      // 1. Generate local keypair
      final keypair = await ECDHKeyPair.generate();
      
      // 2. Decode remote recipient public key
      final remotePublicKey = SimplePublicKey(
        base64.decode(recipientPublicKeyBase64),
        type: KeyPairType.x25519,
      );

      // 3. Derive shared secret key
      final aesKey = await keypair.deriveSharedSecret(remotePublicKey);

      // 4. Read and encrypt file content
      final plainBytes = await file.readAsBytes();
      final cipherBytes = await AesGcmCipher.encrypt(plainBytes, aesKey);

      // 5. Write encrypted bytes to a temporary file
      final tempDir = await getTemporaryDirectory();
      final encFile = File(p.join(tempDir.path, '${meta.fileName}.enc'));
      await encFile.writeAsBytes(cipherBytes);
      fileToUpload = encFile;

      // The encryptedKeyBlob stores the sender's public key (base64) so the receiver can derive the secret
      encryptedKeyBlob = base64.encode(keypair.publicKey.bytes);
    }

    // Perform chunked upload of the encrypted (or plain) file
    await ChunkedUploader.upload(fileToUpload, storagePath);

    // Save metadata to Firestore
    final FileMetadata fullMeta = FileMetadata(
      fileId: '',
      ownerId: meta.ownerId,
      roomId: meta.roomId,
      recipientDeviceId: meta.recipientDeviceId,
      fileName: meta.fileName,
      sizeBytes: file.lengthSync(),
      mimeType: meta.mimeType,
      storagePath: storagePath,
      encryptedKeyBlob: encryptedKeyBlob,
      expiryTimestamp: meta.expiryTimestamp,
      maxViews: meta.maxViews,
      passcodeProtected: meta.passcodeProtected,
      saltHex: meta.saltHex,
    );

    final fileId = await _firestore.createFileEntry(fullMeta);
    return fileId;
  }

  /// Downloads a file, and if it was encrypted, decrypts it using the local key.
  /// Returns the local decrypted file path.
  Future<String> downloadFile(String fileId, {required ECDHKeyPair localKeyPair}) async {
    final meta = await _firestore.getFileMetadata(fileId);
    if (meta == null) throw Exception('File metadata not found');

    // Download chunks and reassemble the file (will be encrypted if uploadFile was secure)
    final localPath = await ChunkedDownloader.download(meta);
    final encryptedFile = File(localPath);

    if (meta.encryptedKeyBlob != null) {
      // 1. Decode sender's public key from metadata
      final senderPublicKey = SimplePublicKey(
        base64.decode(meta.encryptedKeyBlob!),
        type: KeyPairType.x25519,
      );

      // 2. Derive the exact same shared secret
      final aesKey = await localKeyPair.deriveSharedSecret(senderPublicKey);

      // 3. Read encrypted bytes and decrypt
      final cipherBytes = await encryptedFile.readAsBytes();
      final plainBytes = await AesGcmCipher.decrypt(cipherBytes, aesKey);

      // 4. Save decrypted bytes to a new temporary file
      final tempDir = await getTemporaryDirectory();
      final decryptedFile = File(p.join(tempDir.path, 'decrypted_${meta.fileName}'));
      await decryptedFile.writeAsBytes(plainBytes);

      // Clean up the temporary encrypted download file
      await encryptedFile.delete();

      return decryptedFile.path;
    }

    return localPath;
  }
}

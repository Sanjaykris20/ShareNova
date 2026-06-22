// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

/// Handles uploading a file to Firebase Storage in fixed‑size chunks.
///
/// The function creates an upload session document in Firestore (handled by the
/// caller) and then uploads each chunk sequentially. If any chunk fails, the
/// upload aborts and the caller can retry the whole operation.
class ChunkedUploader {
  static const int _chunkSize = 256 * 1024; // 256 KB per chunk

  /// Uploads [file] to the given [storagePath] under Firebase Storage.
  /// Returns a list of the uploaded chunk paths (useful for later cleanup).
  static Future<List<String>> upload(File file, String storagePath, {FirebaseStorage? storage}) async {
    FirebaseStorage.instance.ref().child(storagePath);
    final List<String> uploadedChunkPaths = [];
    final int fileSize = await file.length();
    final raf = file.openSync(mode: FileMode.read);
    int offset = 0;
    int index = 0;
    while (offset < fileSize) {
      final int bytesToRead = (fileSize - offset) > _chunkSize ? _chunkSize : (fileSize - offset);
      final Uint8List buffer = raf.readSync(bytesToRead);
      final String chunkPath = '$storagePath/chunk_${index.toString().padLeft(4, '0')}';
      final chunkRef = FirebaseStorage.instance.ref().child(chunkPath);
      await chunkRef.putData(buffer);
      uploadedChunkPaths.add(chunkPath);
      offset += bytesToRead;
      index++;
    }
    raf.closeSync();
    return uploadedChunkPaths;
  }
}

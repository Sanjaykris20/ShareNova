// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sharenova_flutter/models/file_metadata.dart';
import 'package:path/path.dart' as p;

/// Handles downloading a file from Firebase Storage that was uploaded in chunks.
/// The [FileMetadata] contains the base storage path where chunks were stored.

class ChunkedDownloader {
  /// Downloads all chunks for the given [meta] and reassembles them into a
  /// temporary file. Returns the absolute path to the local file.
  /// Optional [storage] can be injected for testing (defaults to FirebaseStorage.instance).
  static Future<String> download(FileMetadata meta, {FirebaseStorage? storage}) async {
    final baseRef = (storage ?? FirebaseStorage.instance).ref().child(meta.storagePath);
    // List all objects under the base path.
    final ListResult listing = await baseRef.listAll();
    final List<Reference> chunks = listing.items.where((ref) => ref.name.startsWith('chunk_')).toList();
    // Sort by chunk index to ensure correct order.
    chunks.sort((a, b) => a.name.compareTo(b.name));
    final List<int> allBytes = [];
    for (final chunkRef in chunks) {
      final Uint8List? data = await chunkRef.getData();
      if (data != null) {
        allBytes.addAll(data);
      }
    }
    // Write to a temporary file.
    final tempDir = Directory.systemTemp;
    final File outFile = File(p.join(tempDir.path, 'downloaded_${meta.fileName}_${DateTime.now().millisecondsSinceEpoch}'));
    await outFile.writeAsBytes(allBytes);
    return outFile.path;
  }
}

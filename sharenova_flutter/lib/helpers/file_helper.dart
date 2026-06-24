import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uri_to_file/uri_to_file.dart';
import '../services/compression_service.dart';

class FileHelper {
  /// Resolves a content URI to a physical directory and zips it
  static Future<File?> zipDirectory(String uriString) async {
    try {
      File resolvedFile = await toFile(uriString);
      Directory dir = Directory(resolvedFile.path);
      if (dir.existsSync()) {
        return await CompressionService.zipFolder(dir.path);
      }
    } catch (e) {
      debugPrint('Error zipping directory: $e');
    }
    return null;
  }

  /// Resolves a content URI to a physical directory and traverses it to find all files
  static Future<List<File>> traverseDirectory(String uriString) async {
    List<File> result = [];
    try {
      File resolvedFile = await toFile(uriString);
      Directory dir = Directory(resolvedFile.path);

      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (var entity in entities) {
          if (entity is File) {
            final basename = entity.uri.pathSegments.last;
            if (!basename.startsWith('.')) {
              result.add(entity);
            }
          }
        }
      } else {
        if (resolvedFile.existsSync() && !resolvedFile.path.split('/').last.startsWith('.')) {
           result.add(resolvedFile);
        }
      }
    } catch (e) {
      debugPrint('Error traversing directory: $e');
    }
    return result;
  }

  /// Calculates total size of a list of files in bytes
  static int totalSize(List<File> files) {
    return files.fold<int>(0, (sum, f) {
      try {
        return sum + f.lengthSync();
      } catch (_) {
        return sum;
      }
    });
  }
}

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class CompressionService {
  /// Zips a directory and returns the generated .zip file.
  static Future<File> zipFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      throw Exception('Directory does not exist');
    }
    
    final tempDir = await getTemporaryDirectory();
    final folderName = folderPath.split(Platform.pathSeparator).last;
    final zipFile = File('${tempDir.path}/$folderName.zip');
    
    // Create Zip encoder
    var encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    encoder.addDirectory(dir);
    encoder.close();
    
    return zipFile;
  }

  /// Unzips a .zip file to the specified destination directory.
  static Future<void> unzipFile(File zipFile, String destPath) async {
    if (!zipFile.existsSync()) {
      throw Exception('Zip file does not exist');
    }
    
    final bytes = zipFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File('$destPath/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('$destPath/$filename').createSync(recursive: true);
      }
    }
  }
}

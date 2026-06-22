import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharenova_flutter/p2p_transfer_service.dart';

void main() {
  test('P2P transfer end-to‑end', () async {
    final service = P2PTransferService();
    // Start server on any free port
    final port = await service.startFileServer(0);
    // Create temporary file with known payload
    final tempDir = Directory.systemTemp;
    final testFile = File('${tempDir.path}/p2p_test_input.txt');
    await testFile.writeAsString('Hello from P2P test!');

    String? receivedPath;
    service.onTransferComplete = (path) => receivedPath = path;

    // Send file to localhost
    await service.sendFile('127.0.0.1', port, testFile);

    // Give async callbacks a moment
    await Future.delayed(const Duration(seconds: 2));
    expect(receivedPath, isNotNull);
    final receivedContent = await File(receivedPath!).readAsString();
    expect(receivedContent, equals('Hello from P2P test!'));

    // Cleanup
    await testFile.delete();
    if (receivedPath != null) await File(receivedPath!).delete();
    service.stop();
  }, timeout: const Timeout(Duration(seconds: 10)));
}

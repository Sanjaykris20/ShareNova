// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:sharenova_flutter/core/crypto/ecdh_key_pair.dart';
import 'package:sharenova_flutter/core/crypto/aes_gcm_cipher.dart';

/// Service handling peer‑to‑peer encrypted file transfer.
class P2PTransferService {
  ServerSocket? _fileServer;
  Socket? _fileClient;

  Function(double)? onProgress;
  Function(String)? onTransferComplete;
  Function(String)? onError;

  /// Starts a TCP server that performs an ECDH handshake and receives an
  /// encrypted file. Returns the listening port.
  Future<int> startFileServer(int port) async {
    _fileServer = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _fileServer!.listen((Socket client) async {
      // Generate a fresh key pair for this connection.
      final serverKeyPair = await ECDHKeyPair.generate();
      // Send the public key to the peer.
      client.add(serverKeyPair.publicKey.bytes);

      final List<int> encrypted = [];
      SimplePublicKey? clientPublicKey;
      Uint8List? secret;
      bool handshakeDone = false;

      client.listen(
        (data) async {
          if (!handshakeDone) {
            // First chunk contains the client public key (32 bytes).
            clientPublicKey = SimplePublicKey(data, type: KeyPairType.x25519);
            secret = await serverKeyPair.deriveSharedSecret(clientPublicKey!);
            handshakeDone = true;
            if (data.length > 32) {
              encrypted.addAll(data.sublist(32));
            }
          } else {
            encrypted.addAll(data);
          }
          if (onProgress != null) onProgress!(encrypted.length.toDouble());
        },
        onDone: () async {
          try {
            if (secret == null) throw Exception('Handshake not completed');
            final decrypted = await AesGcmCipher.decrypt(Uint8List.fromList(encrypted), secret!);
            final tempDir = Directory.systemTemp;
            final file = File('${tempDir.path}/shared_file_${DateTime.now().millisecondsSinceEpoch}.bin');
            await file.writeAsBytes(decrypted);
            if (onTransferComplete != null) onTransferComplete!(file.path);
          } catch (e) {
            if (onError != null) onError!(e.toString());
          }
          client.destroy();
        },
        onError: (e) {
          if (onError != null) onError!(e.toString());
          client.destroy();
        },
      );
    });
    return _fileServer!.port;
  }

  /// Connects to a remote peer, performs handshake, encrypts the file and sends it.
  Future<void> sendFile(String ip, int port, File file) async {
    try {
      _fileClient = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      // Generate client key pair.
      final clientKeyPair = await ECDHKeyPair.generate();
      // Receive server public key.
      final serverPubBytes = await _fileClient!.first;
      final serverPublicKey = SimplePublicKey(serverPubBytes, type: KeyPairType.x25519);
      // Send client public key.
      _fileClient!.add(clientKeyPair.publicKey.bytes);
      // Derive shared secret.
      final secret = await clientKeyPair.deriveSharedSecret(serverPublicKey);
      // Read file, encrypt, then send encrypted payload.
      final fileBytes = await file.readAsBytes();
      final encrypted = await AesGcmCipher.encrypt(Uint8List.fromList(fileBytes), secret);
      final length = encrypted.length;
      int sent = 0;
      const chunkSize = 64 * 1024; // 64KB
      for (int offset = 0; offset < length; offset += chunkSize) {
        final end = (offset + chunkSize > length) ? length : offset + chunkSize;
        final chunk = encrypted.sublist(offset, end);
        _fileClient!.add(chunk);
        sent += chunk.length;
        if (onProgress != null) onProgress!(sent / length);
      }
      await _fileClient!.flush();
      _fileClient!.destroy();
      // Server will invoke onTransferComplete with the received file path.
    } catch (e) {
      if (onError != null) onError!(e.toString());
    }
  }

  /// Stops any running server or client connections.
  void stop() {
    _fileServer?.close();
    _fileServer = null;
    _fileClient?.destroy();
    _fileClient = null;
  }
}

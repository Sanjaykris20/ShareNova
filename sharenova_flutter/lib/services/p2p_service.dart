// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import '../core/crypto/ecdh_key_pair.dart';
import '../core/crypto/aes_gcm_cipher.dart';
import 'compression_service.dart';

/// Represents a discovered peer device
class P2pDevice {
  final String id; // IP address
  final String displayName;
  final ConnectionType connectionType;
  final int rssi;
  final int port;

  const P2pDevice({
    required this.id,
    required this.displayName,
    required this.connectionType,
    required this.rssi,
    required this.port,
  });
}

enum ConnectionType { wifiDirect, bluetooth }

/// Holds an active secured session after handshake
class P2pSession {
  final ConnectionType type;
  final String ip;
  final int port;
  final Uint8List aesKey;

  const P2pSession({
    required this.type,
    required this.ip,
    required this.port,
    required this.aesKey,
  });
}

/// Service for discovery, connection, handshake, and encrypted transfer
class P2pService {
  final StreamController<P2pDevice> _discovered = StreamController<P2pDevice>.broadcast();
  Stream<P2pDevice> get discovered => _discovered.stream;

  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServer;
  Timer? _broadcastTimer;
  bool _isScanning = false;

  void Function(double)? onProgress;
  void Function(String)? onTransferComplete;
  void Function(String)? onError;

  // ---------- Discovery (UDP Broadcast) ----------

  Future<String> _getLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return '127.0.0.1';
  }

  Future<void> startWifiDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      // Bind UDP socket to receive discovery broadcasts
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final data = json.decode(message);
              if (data['type'] == 'discover') {
                final device = P2pDevice(
                  id: datagram.address.address,
                  displayName: data['name'] ?? 'Unknown Device',
                  connectionType: ConnectionType.wifiDirect,
                  rssi: -50,
                  port: data['port'] ?? 9999,
                );
                _discovered.add(device);
              }
            } catch (e) {
              print('Error parsing discovery packet: $e');
            }
          }
        }
      });

      // Start broadcasting our presence
      final localIp = await _getLocalIp();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final data = json.encode({
            'type': 'discover',
            'name': 'Device_${localIp.split('.').last}',
            'port': 9999,
          });
          _udpSocket?.send(
            utf8.encode(data),
            InternetAddress('255.255.255.255'),
            8888,
          );
        } catch (e) {
          print('Error sending broadcast: $e');
        }
      });
    } catch (e) {
      print('UDP discovery setup error: $e');
    }
  }

  Future<void> startBleDiscovery() async {
    // Bluetooth discovery stub
    return;
  }

  // ---------- TCP File Server (Receiver) ----------

  Future<int> startFileServer() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 9999);
      _tcpServer!.listen((Socket client) async {
        try {
          // Perform secure handshake
          final serverKeyPair = await ECDHKeyPair.generate();
          
          // Send server public key first
          client.add(serverKeyPair.publicKey.bytes);
          await client.flush();

          final List<int> buffer = [];
          Uint8List? aesKey;
          int? metadataSize;
          Map<String, dynamic>? metadata;
          int? expectedSize;
          final List<int> encryptedPayload = [];

          client.listen(
            (data) async {
              buffer.addAll(data);

              // 1. First 32 bytes is the client's public key
              if (aesKey == null && buffer.length >= 32) {
                final clientPubBytes = Uint8List.fromList(buffer.sublist(0, 32));
                buffer.removeRange(0, 32);

                final clientPublicKey = SimplePublicKey(clientPubBytes, type: KeyPairType.x25519);
                aesKey = await serverKeyPair.deriveSharedSecret(clientPublicKey);
              }

              // 2. Next 4 bytes is the metadata size
              if (aesKey != null && metadataSize == null && buffer.length >= 4) {
                final mSizeBytes = Uint8List.fromList(buffer.sublist(0, 4));
                buffer.removeRange(0, 4);
                metadataSize = ByteData.sublistView(mSizeBytes).getUint32(0, Endian.big);
              }

              // 3. Read metadata JSON
              if (metadataSize != null && metadata == null && buffer.length >= metadataSize!) {
                final jsonBytes = buffer.sublist(0, metadataSize!);
                buffer.removeRange(0, metadataSize!);
                final jsonString = utf8.decode(jsonBytes);
                metadata = jsonDecode(jsonString);
              }

              // 4. Next 8 bytes is the big-endian file size
              if (metadata != null && expectedSize == null && buffer.length >= 8) {
                final sizeBytes = Uint8List.fromList(buffer.sublist(0, 8));
                buffer.removeRange(0, 8);
                expectedSize = ByteData.sublistView(sizeBytes).getUint64(0, Endian.big);
              }

              // 5. The rest is the AES encrypted payload
              if (expectedSize != null) {
                encryptedPayload.addAll(buffer);
                buffer.clear();

                if (onProgress != null) {
                  onProgress!(encryptedPayload.length / expectedSize!);
                }

                // If we received all expected encrypted bytes
                if (encryptedPayload.length >= expectedSize!) {
                  try {
                    final decrypted = await AesGcmCipher.decrypt(
                      Uint8List.fromList(encryptedPayload),
                      aesKey!,
                    );
                    
                    final filename = metadata?['filename'] ?? 'shared_file_${DateTime.now().millisecondsSinceEpoch}.bin';
                    
                    // Attempt to save to Downloads
                    Directory? saveDir;
                    if (Platform.isAndroid) {
                      saveDir = Directory('/storage/emulated/0/Download');
                      if (!saveDir.existsSync()) {
                        saveDir = await getExternalStorageDirectory();
                      }
                    } else {
                      saveDir = await getApplicationDocumentsDirectory();
                    }
                    
                    final file = File('${saveDir!.path}/$filename');
                    await file.writeAsBytes(decrypted);

                    // If it's a zip file, unzip it and clean up the original zip
                    if (filename.endsWith('.zip')) {
                      final extractFolder = filename.replaceAll('.zip', '');
                      final extractPath = '${saveDir.path}/$extractFolder';
                      await CompressionService.unzipFile(file, extractPath);
                      try {
                        await file.delete();
                      } catch (_) {}
                    }

                    if (onTransferComplete != null) {
                      onTransferComplete!(file.path);
                    }
                  } catch (e) {
                    if (onError != null) onError!('Decryption error: $e');
                  }
                  client.destroy();
                }
              }
            },
            onError: (e) {
              if (onError != null) onError!('Socket error: $e');
              client.destroy();
            },
            onDone: () {
              client.destroy();
            },
          );
        } catch (e) {
          if (onError != null) onError!('Handshake error: $e');
          client.destroy();
        }
      });
      return _tcpServer!.port;
    } catch (e) {
      if (onError != null) onError!('Server bind error: $e');
      rethrow;
    }
  }

  // ---------- Secure Handshake & Connect (Sender) ----------

  Future<P2pSession> connectAndHandshake(P2pDevice device) async {
    final clientKeyPair = await ECDHKeyPair.generate();
    final Socket socket = await Socket.connect(device.id, device.port, timeout: const Duration(seconds: 10));

    final Completer<P2pSession> completer = Completer();
    final List<int> buffer = [];

    socket.listen((data) async {
      buffer.addAll(data);
      if (buffer.length >= 32 && !completer.isCompleted) {
        final serverPubBytes = Uint8List.fromList(buffer.sublist(0, 32));
        final serverPublicKey = SimplePublicKey(serverPubBytes, type: KeyPairType.x25519);

        // Send client public key back
        socket.add(clientKeyPair.publicKey.bytes);
        await socket.flush();

        final aesKey = await clientKeyPair.deriveSharedSecret(serverPublicKey);
        completer.complete(P2pSession(
          type: ConnectionType.wifiDirect,
          ip: device.id,
          port: device.port,
          aesKey: aesKey,
        ));
      }
    }, onError: (e) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    final session = await completer.future;
    socket.destroy(); // Handshake connection closed; real transfer will open fresh socket or use standard stream
    return session;
  }

  // ---------- File Transfer ----------

  Future<void> sendFiles(List<File> files, P2pSession session, {bool compress = false}) async {
    int totalBytes = 0;
    for (final file in files) {
      try { totalBytes += file.lengthSync(); } catch (_) {}
    }
    
    int sentBytes = 0;
    for (final file in files) {
      await sendFile(file, session, isBatch: true, batchSentBytes: sentBytes, batchTotalBytes: totalBytes);
      try { sentBytes += file.lengthSync(); } catch (_) {}
    }
    
    if (onTransferComplete != null) {
      onTransferComplete!("All files sent successfully");
    }
  }

  Future<void> sendFile(File file, P2pSession session, {bool isBatch = false, int batchSentBytes = 0, int batchTotalBytes = 0}) async {
    Socket? socket;
    try {
      socket = await Socket.connect(session.ip, session.port, timeout: const Duration(seconds: 10));

      // 1. Send public key again to identify ourselves
      final clientKeyPair = await ECDHKeyPair.generate(); // Temporary identifier keypair
      socket.add(clientKeyPair.publicKey.bytes);
      await socket.flush();

      // 2. Prepare and send metadata
      final filename = file.uri.pathSegments.last;
      final metadata = jsonEncode({'filename': filename});
      final metadataBytes = utf8.encode(metadata);
      
      final mSizeHeader = ByteData(4)..setUint32(0, metadataBytes.length, Endian.big);
      socket.add(mSizeHeader.buffer.asUint8List());
      socket.add(metadataBytes);
      await socket.flush();

      // 3. Read, encrypt file bytes
      final fileBytes = await file.readAsBytes();
      final encrypted = await AesGcmCipher.encrypt(Uint8List.fromList(fileBytes), session.aesKey);
      final length = encrypted.length;

      // 4. Send file size header (8 bytes)
      final sizeHeader = ByteData(8)..setUint64(0, length, Endian.big);
      socket.add(sizeHeader.buffer.asUint8List());
      await socket.flush();

      // 5. Send encrypted payload in chunks
      int sent = 0;
      const chunkSize = 64 * 1024; // 64KB
      for (int offset = 0; offset < length; offset += chunkSize) {
        final end = (offset + chunkSize > length) ? length : offset + chunkSize;
        final chunk = encrypted.sublist(offset, end);
        socket.add(chunk);
        sent += chunk.length;
        if (onProgress != null) {
          if (isBatch && batchTotalBytes > 0) {
            onProgress!((batchSentBytes + sent) / batchTotalBytes);
          } else {
            onProgress!(sent / length);
          }
        }
        await socket.flush();
      }

      socket.destroy();
      if (!isBatch && onTransferComplete != null) {
        onTransferComplete!("Sent successfully");
      }
    } catch (e) {
      socket?.destroy();
      if (onError != null) onError!('Send error: $e');
    }
  }

  Future<File> receiveFile(P2pSession session, String filename) async {
    return File('');
  }

  void dispose() {
    _broadcastTimer?.cancel();
    _udpSocket?.close();
    _tcpServer?.close();
    _discovered.close();
  }
}
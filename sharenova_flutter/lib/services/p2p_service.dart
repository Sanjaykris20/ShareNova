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
import 'package:wifi_direct_plugin/wifi_direct_plugin.dart';

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
  void Function(String, int, int, String)? onFileProgress;
  void Function(String)? onTransferComplete;
  void Function(String)? onError;

  // ---------- Discovery (Wi-Fi Direct) ----------

  Future<void> startAdvertising(String deviceName, int port) async {
    try {
      await WifiDirectPlugin.initialize();
      await WifiDirectPlugin.startAsServer(deviceName);
    } catch (e) {
      print('Wi-Fi Direct advertising setup error: $e');
    }
  }

  void stopAdvertising() {
    WifiDirectPlugin.disconnect();
    WifiDirectPlugin.stopDiscovery();
  }

  StreamSubscription? _wifiDirectSubscription;

  Future<void> startDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      await WifiDirectPlugin.initialize();
      await WifiDirectPlugin.startDiscovery();
      
      _wifiDirectSubscription?.cancel();
      _wifiDirectSubscription = WifiDirectPlugin.peersStream.listen((peers) {
        for (var peer in peers) {
          final device = P2pDevice(
            id: peer.deviceAddress, // Use MAC address temporarily as ID
            displayName: peer.deviceName,
            connectionType: ConnectionType.wifiDirect,
            rssi: -50,
            port: 9999, // Our TCP server port
          );
          _discovered.add(device);
        }
      });
    } catch (e) {
      print('Wi-Fi Direct discovery setup error: $e');
    }
  }

  void stopDiscovery() {
    _isScanning = false;
    _wifiDirectSubscription?.cancel();
    WifiDirectPlugin.stopDiscovery();
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
                
                final filename = metadata?['filename'] ?? 'shared_file_${DateTime.now().millisecondsSinceEpoch}.bin';
                
                // Dispatch individual file progress
                if (onFileProgress != null) {
                  onFileProgress!(filename, expectedSize!, encryptedPayload.length, 'transferring');
                }

                // If we received all expected encrypted bytes
                if (encryptedPayload.length >= expectedSize!) {
                  try {
                    final decrypted = await AesGcmCipher.decrypt(
                      Uint8List.fromList(encryptedPayload),
                      aesKey!,
                    );
                    
                    final filename = metadata?['filename'] ?? 'shared_file_${DateTime.now().millisecondsSinceEpoch}.bin';
                    
                    // Attempt to save to Downloads/ShareNova
                    Directory? saveDir;
                    if (Platform.isAndroid) {
                      saveDir = Directory('/storage/emulated/0/Download/ShareNova');
                      if (!saveDir.existsSync()) {
                        try {
                          saveDir.createSync(recursive: true);
                        } catch (e) {
                          saveDir = await getExternalStorageDirectory();
                        }
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

                    if (onFileProgress != null) {
                      onFileProgress!(filename, expectedSize!, expectedSize!, 'completed');
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
    String peerIp = device.id;
    
    // Check if device.id is a MAC address (contains ':'). If so, connect via Wi-Fi direct.
    if (device.id.contains(':')) {
      bool connected = await WifiDirectPlugin.connect(device.id);
      if (!connected) {
        print("WifiDirectPlugin.connect returned false, but we might already be connected. Proceeding...");
      }
      
      await Future.delayed(const Duration(seconds: 3));

      String? retrievedIp = await WifiDirectPlugin.getPeerIpAddress();
      if (retrievedIp != null && retrievedIp.isNotEmpty) {
        peerIp = retrievedIp;
      } else {
        peerIp = "192.168.49.1";
      }
    }

    print("Attempting to connect to peer IP: $peerIp on port: ${device.port}");
    final clientKeyPair = await ECDHKeyPair.generate();
    final Socket socket = await Socket.connect(peerIp, device.port, timeout: const Duration(seconds: 15));
    print("Socket connected successfully to $peerIp");

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
          ip: peerIp,
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

      final Completer<Uint8List> keyCompleter = Completer();
      final List<int> buffer = [];

      socket.listen((data) {
        if (!keyCompleter.isCompleted) {
          buffer.addAll(data);
          if (buffer.length >= 32) {
            keyCompleter.complete(Uint8List.fromList(buffer.sublist(0, 32)));
          }
        }
      });

      // 1. Read Server's public key
      final serverPubBytes = await keyCompleter.future;
      final serverPublicKey = SimplePublicKey(serverPubBytes, type: KeyPairType.x25519);

      // 2. Send our new public key
      final clientKeyPair = await ECDHKeyPair.generate();
      socket.add(clientKeyPair.publicKey.bytes);
      await socket.flush();

      // 3. Derive the correct AES key for this connection
      final fileAesKey = await clientKeyPair.deriveSharedSecret(serverPublicKey);

      // 4. Prepare and send metadata
      final filename = file.uri.pathSegments.last;
      final metadata = jsonEncode({'filename': filename});
      final metadataBytes = utf8.encode(metadata);
      
      if (onFileProgress != null) {
        onFileProgress!(filename, await file.length(), 0, 'transferring');
      }
      
      final mSizeHeader = ByteData(4)..setUint32(0, metadataBytes.length, Endian.big);
      socket.add(mSizeHeader.buffer.asUint8List());
      socket.add(metadataBytes);
      await socket.flush();

      // 5. Read, encrypt file bytes using the newly derived fileAesKey
      final fileBytes = await file.readAsBytes();
      final encrypted = await AesGcmCipher.encrypt(Uint8List.fromList(fileBytes), fileAesKey);
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
        if (onFileProgress != null) {
          onFileProgress!(filename, length, sent, 'transferring');
        }
        await socket.flush();
      }
      await socket.close();
      
      if (onFileProgress != null) {
        onFileProgress!(filename, length, length, 'completed');
      }

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
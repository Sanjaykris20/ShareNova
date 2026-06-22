// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Simple singleton service to handle Bluetooth connections and file transfer.
class BluetoothService {
  BluetoothService._privateConstructor();
  static final BluetoothService instance = BluetoothService._privateConstructor();

  /// Connect to a remote device and send the given file.
  /// Returns a Future that completes when the transfer finishes.
  Future<void> sendFile(BluetoothDevice device, File file) async {
    try {
      // Establish connection
      final BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');

      // Read file bytes
      final List<int> bytes = await file.readAsBytes();
      // Send file size first (4 bytes, big endian)
      final int length = bytes.length;
      final ByteData sizeData = ByteData(4)..setUint32(0, length, Endian.big);
      connection.output.add(sizeData.buffer.asUint8List());
      await connection.output.allSent;

      // Send the actual file data in chunks
      const int chunkSize = 1024;
      for (int offset = 0; offset < length; offset += chunkSize) {
        final int end = (offset + chunkSize > length) ? length : offset + chunkSize;
        connection.output.add(Uint8List.fromList(bytes.sublist(offset, end)));
        await connection.output.allSent;
      }
      print('File transfer completed');
      await connection.finish();
    } catch (e) {
      print('Bluetooth send error: $e');
      rethrow;
    }
  }

  /// Start listening for incoming files.
  /// Returns a stream of received files saved to the temporary directory.
  Stream<File> receiveFiles() async* {
    // Enable discovery mode so other devices can find us
    await FlutterBluetoothSerial.instance.requestDiscoverable(60);
    // Create a server socket
    final server = await BluetoothServerSocket.listenOnBluetooth();
    await for (final BluetoothConnection connection in server) {
      try {
        // First read 4‑byte length header
        final Uint8List sizeBytes = await _readExact(connection, 4);
        final int fileSize = ByteData.sublistView(sizeBytes).getUint32(0, Endian.big);
        // Read file data
        final Uint8List fileBytes = await _readExact(connection, fileSize);
        // Save to temp file
        final String tempPath = '${Directory.systemTemp.path}/bluetooth_recv_${DateTime.now().millisecondsSinceEpoch}';
        final File outFile = File(tempPath);
        await outFile.writeAsBytes(fileBytes);
        yield outFile;
        await connection.finish();
      } catch (e) {
        print('Bluetooth receive error: $e');
        // ignore and continue listening
      }
    }
  }

  // Helper to read exactly `count` bytes from a connection.
  Future<Uint8List> _readExact(BluetoothConnection conn, int count) async {
    final Completer<Uint8List> completer = Completer();
    final List<int> buffer = [];
    StreamSubscription<Uint8List>? sub;
    sub = conn.input!.listen((data) {
      buffer.addAll(data);
      if (buffer.length >= count && !completer.isCompleted) {
        completer.complete(Uint8List.fromList(buffer.sublist(0, count)));
        sub?.cancel();
      }
    });
    return completer.future;
  }
}

class BluetoothServerSocket extends Stream<BluetoothConnection> {
  static Future<BluetoothServerSocket> listenOnBluetooth() async => throw UnimplementedError();
  @override StreamSubscription<BluetoothConnection> listen(void Function(BluetoothConnection event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) => throw UnimplementedError();
}

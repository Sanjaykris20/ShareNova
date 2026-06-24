// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';
import 'services/p2p_service.dart';

class RoomScannerScreen extends StatefulWidget {
  const RoomScannerScreen({super.key});

  @override
  State<RoomScannerScreen> createState() => _RoomScannerScreenState();
}

class _RoomScannerScreenState extends State<RoomScannerScreen> {
  bool _isConnecting = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isConnecting) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        try {
          final data = jsonDecode(barcode.rawValue!);
          if (data['ip'] != null && data['port'] != null) {
            setState(() {
              _isConnecting = true;
            });
            
            final state = Provider.of<ShareState>(context, listen: false);
            
            if (data['type'] == 'room') {
              // Connect to Chat Room
              await state.joinRoom(data['ip'], data['port'], "Participant");
              if (mounted) {
                state.navigateTo('chat_room');
              }
            } else {
              // Connect to P2P File Transfer
              final p2p = Provider.of<P2pService>(context, listen: false);
              final device = P2pDevice(
                id: data['ip'],
                port: data['port'],
                displayName: "QR Scanned Device",
                connectionType: ConnectionType.wifiDirect,
                rssi: 0,
              );
              
              try {
                final session = await p2p.connectAndHandshake(device);
                if (mounted) {
                  state.setCurrentSession(session);
                  state.navigateTo('transfer');
                }
              } catch (e) {
                if (mounted) {
                  setState(() { _isConnecting = false; });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to connect: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
            break;
          }
        } catch (e) {
          // Not a valid QR
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () => state.goBack(),
        ),
        title: const Text(
          "Scan Room QR",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          if (_isConnecting)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    SizedBox(height: 16),
                    Text("Connecting...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

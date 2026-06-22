// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';

class RoomHostScreen extends StatefulWidget {
  const RoomHostScreen({super.key});

  @override
  State<RoomHostScreen> createState() => _RoomHostScreenState();
}

class _RoomHostScreenState extends State<RoomHostScreen> {
  String? _qrData;
  bool _isStarting = true;

  @override
  void initState() {
    super.initState();
    _startHosting();
  }

  Future<void> _startHosting() async {
    final state = Provider.of<ShareState>(context, listen: false);
    
    // Find local IP
    String ipAddress = "127.0.0.1";
    if (!kIsWeb) {
      try {
        for (var interface in await NetworkInterface.list()) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              ipAddress = addr.address;
              break;
            }
          }
        }
      } catch (e) {
        print("Could not find IP: $e");
      }
    }

    final port = await state.startRoom("Host");
    
    final payload = {
      'ip': ipAddress,
      'port': port,
      'name': 'Local Room'
    };
    
    if (mounted) {
      setState(() {
        _qrData = jsonEncode(payload);
        _isStarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF111827)),
          onPressed: () {
            state.leaveRoom();
            state.navigateTo('room_gateway');
          },
        ),
        title: const Text(
          "Host Room",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: Center(
        child: _isStarting
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: QrImageView(
                      data: _qrData!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Scan to Join",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Have your friends scan this QR code.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => state.navigateTo('chat_room'),
                    child: const Text("Enter Chat Room", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }
}

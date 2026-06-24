// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/p2p_service.dart';
import '../share_state.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  late P2pService _p2pService;
  late AnimationController _radarController;
  String _localIp = 'Loading...';
  int _port = 9999;
  double _progress = 0.0;
  bool _isTransferring = false;
  String? _receivedFilePath;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _p2pService = Provider.of<P2pService>(context, listen: false);
    _setupServer();
  }

  Future<void> _setupServer() async {
    try {
      _port = await _p2pService.startFileServer();
      
      // Get local IP
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _localIp = addr.address;
            });
            break;
          }
        }
      }

      // Listen to progress and completion
      _p2pService.onProgress = (progress) {
        setState(() {
          _isTransferring = true;
          _progress = progress;
        });
      };

      _p2pService.onTransferComplete = (filePath) {
        setState(() {
          _isTransferring = false;
          _progress = 1.0;
          _receivedFilePath = filePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File received successfully! Saved to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      };

      _p2pService.onError = (err) {
        setState(() {
          _isTransferring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer Error: $err'), backgroundColor: Colors.red),
        );
      };
    } catch (e) {
      print('Failed to start server: $e');
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _p2pService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context, listen: false);
    final qrData = json.encode({'ip': _localIp, 'port': _port});

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Receive Files', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () {
            state.navigateTo('home');
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_receivedFilePath != null) ...[
                    // Success View
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(LucideIcons.circle_check, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text(
                            "Transfer Complete!",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "File path:\n$_receivedFilePath",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: () {
                                  // Accept – keep the file
                                  setState(() {
                                    _receivedFilePath = null;
                                    _progress = 0.0;
                                  });
                                },
                                child: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: () {
                                  // Reject – delete the file if it exists
                                  if (_receivedFilePath != null) {
                                    try { File(_receivedFilePath!).deleteSync(); } catch (_) {}
                                  }
                                  setState(() {
                                    _receivedFilePath = null;
                                    _progress = 0.0;
                                  });
                                },
                                child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ] else if (_isTransferring) ...[
                    // Transfer Progress View
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFF1F2937)),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF2563EB)),
                          const SizedBox(height: 24),
                          const Text(
                            "Receiving encrypted stream...",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: const Color(0xFF1F2937),
                            color: const Color(0xFF2563EB),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${(_progress * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Waiting View with Radar & QR
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1 * (1 - _radarController.value)),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.5 * (1 - _radarController.value)),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.download, size: 48, color: Color(0xFF2563EB)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Waiting for connection...",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Connect to the same Wi-Fi network and scan the QR code from the sending device.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "IP Address: $_localIp",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';
import 'services/p2p_service.dart';
import 'package:file_picker/file_picker.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  Timer? _timer;
  bool _showToast = false;

  final List<String> _phaseMessages = [
    "Generating local keypair...",
    "Exchanging public keys (Wi-Fi Direct)...",
    "Computing ECDH shared secret...",
    "Transferring encrypted chunks...",
    "Transfer Complete"
  ];

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ShareState>(context, listen: false);
    final p2p = Provider.of<P2pService>(context, listen: false);
    if (state.currentSession != null) {
      state.setTransferPhase(3);
      state.setTransferProgress(0.0);
      p2p.onProgress = (progress) {
        state.setTransferProgress(progress * 100);
      };
      p2p.onTransferComplete = (msg) {
        state.setTransferProgress(100.0);
        state.setTransferPhase(4);
      };
      p2p.onError = (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
        );
      };
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    final state = Provider.of<ShareState>(context, listen: false);
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (state.transferPhase < 3) {
        state.setTransferPhase(state.transferPhase + 1);
      } else if (state.transferPhase == 3 && !state.isTransferPaused) {
        if (state.transferProgress < 100) {
          state.setTransferProgress(state.transferProgress + 8.5);
          if (state.transferProgress >= 100) {
            state.setTransferProgress(100.0);
            state.setTransferPhase(4);
            _timer?.cancel();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndSend() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null) return;
    final file = File(filePath);
    final state = Provider.of<ShareState>(context, listen: false);
    final p2p = Provider.of<P2pService>(context, listen: false);
    final session = state.currentSession;
    if (session == null) return;
    state.setTransferPhase(3);
    state.setTransferProgress(0.0);
    await p2p.sendFile(file, session);
  }

  void _handleDisconnect() {
    final state = Provider.of<ShareState>(context, listen: false);
    setState(() {
      _showToast = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        state.clearSelection();
        state.navigateTo('home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.transferPhase < 3
                            ? "Securing Channel"
                            : state.transferPhase == 4
                                ? "Complete"
                                : state.isTransferPaused
                                    ? "Paused"
                                    : "Transferring",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (state.transferPhase == 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.isTransferPaused
                                ? const Color(0xFF78350F)
                                : const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            state.isTransferPaused ? "0 MB/s" : "120 MB/s",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: state.isTransferPaused ? const Color(0xFFFBBF24) : const Color(0xFF93C5FD),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Device Nodes Box
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xFF1F2937)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Color(0xFF1F2937),
                                    backgroundImage: NetworkImage(
                                      "https://api.dicebear.com/7.x/avataaars/png?seed=Felix",
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Me", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      if (state.transferPhase < 3) ...[
                                        Icon(
                                          state.transferPhase == 2 ? LucideIcons.key : LucideIcons.shield_alert,
                                          color: state.transferPhase == 2 ? Colors.green : Colors.blue,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _phaseMessages[state.transferPhase],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: state.isTransferPaused
                                                ? const Color(0xFFFFECEF)
                                                : const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            state.isTransferPaused ? "PAUSED" : "ENCRYPTED STREAM",
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: state.isTransferPaused ? Colors.red : const Color(0xFF065F46),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: state.transferProgress / 100,
                                            backgroundColor: const Color(0xFF1F2937),
                                            color: state.isTransferPaused ? Colors.yellow : const Color(0xFF3B82F6),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Color(0xFF1F2937),
                                    backgroundImage: NetworkImage(
                                      "https://api.dicebear.com/7.x/avataaars/png?seed=Mac",
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Sarah", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Total Progress Circle
                        if (state.transferPhase >= 3) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Total Progress",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                "${state.transferProgress.toInt()}%",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: state.transferPhase == 4
                                      ? Colors.green
                                      : state.isTransferPaused
                                          ? Colors.yellow
                                          : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: state.transferProgress / 100,
                              minHeight: 16,
                              backgroundColor: const Color(0xFF111827),
                              color: state.transferPhase == 4 ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF030712),
                    border: Border(top: BorderSide(color: Color(0xFF111827))),
                  ),
                  child: state.transferPhase == 4
                      ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: () {
                                  state.clearSelection();
                                  state.navigateTo('file_manager');
                                },
                                child: const Text("Send More", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F2937),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: () {
                                  state.navigateTo('history');
                                },
                                child: const Text("History", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (state.transferPhase == 3) ...[
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: state.isTransferPaused ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: () => state.toggleTransferPause(),
                                  child: Text(
                                    state.isTransferPaused ? "Resume" : "Pause",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: _handleDisconnect,
                                child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            if (state.currentSession != null) ...[ // Show send button when session ready
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: _pickAndSend,
                                  child: const Text("Pick & Send", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ],
                        ),
                )
              ],
            ),

            // Disconnect Toast Overlay
            if (_showToast)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.shield_alert, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Connection Closed",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

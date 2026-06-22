// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';
import 'mock_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<dynamic> _history = List.from(MockData.recentTransfers);

  void _showKillDialog(dynamic file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildKillDialog(file),
    );
  }

  Widget _buildKillDialog(dynamic file) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFEF2F2), width: 4),
            ),
            child: const Icon(LucideIcons.triangle_alert, size: 32, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Execute Remote Kill?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            "This queues an encrypted kill signal. If the receiver is offline, the signal waits and destroys the file data the instant their app next opens.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      file.status = 'revoked';
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.2), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.octagon_x, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Send Kill Signal",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF111827)),
          onPressed: () => state.navigateTo('home'),
        ),
        title: const Text(
          "Transfer History",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Logged locally on this device.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ..._history.map((file) {
              final isRevoked = file.status == 'revoked';
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRevoked ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isRevoked ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isRevoked ? const Color(0xFFFEE2E2) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRevoked ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB)),
                              ),
                              child: Icon(
                                isRevoked ? LucideIcons.octagon_x : LucideIcons.file_text,
                                size: 18,
                                color: isRevoked ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isRevoked ? const Color(0xFF7F1D1D) : const Color(0xFF111827),
                                    decoration: isRevoked ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${file.size} • ${file.time}",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (file.status == 'active')
                          GestureDetector(
                            onTap: () => _showKillDialog(file),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(LucideIcons.eye_off, size: 12, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text(
                                    "Revoke Now",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isRevoked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle, size: 10, color: Color(0xFFEF4444)),
                                SizedBox(width: 4),
                                Text(
                                  "Killed",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Text(
                              "View",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                            ),
                          ),
                      ],
                    ),
                    if (file.status == 'active') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(LucideIcons.lock, size: 10, color: Color(0xFF6B7280)),
                                SizedBox(width: 4),
                                Text(
                                  "Sent to Sarah's Mac",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(LucideIcons.timer, size: 10, color: Color(0xFFF97316)),
                                SizedBox(width: 4),
                                Text(
                                  "Expires in 21h 14m",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

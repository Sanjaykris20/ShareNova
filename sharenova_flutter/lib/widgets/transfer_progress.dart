import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../share_state.dart';

class TransferProgressWidget extends StatelessWidget {
  const TransferProgressWidget({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    final files = state.transferFiles;
    
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalSize = 0;
    for (var f in files) {
      totalSize += f.sizeBytes;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Detailed File List",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 16),
              ),
              Text(
                _formatBytes(totalSize),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final progress = file.sizeBytes > 0 
                  ? (file.transferredBytes / file.sizeBytes).clamp(0.0, 1.0) 
                  : 0.0;
                  
              final isComplete = file.status == 'completed';
              final isFailed = file.status == 'failed';
              final isPaused = file.status == 'paused' || state.isTransferPaused;

              Color progressColor = const Color(0xFF3B82F6); // Blue
              if (isComplete) progressColor = const Color(0xFF10B981); // Green
              if (isFailed) progressColor = const Color(0xFFEF4444); // Red
              if (isPaused) progressColor = const Color(0xFFFBBF24); // Yellow

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.insert_drive_file,
                      color: isComplete ? const Color(0xFF10B981) : const Color(0xFF93C5FD), 
                      size: 24
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatBytes(file.sizeBytes),
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: progressColor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

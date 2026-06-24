import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../share_state.dart';
import '../helpers/file_helper.dart';

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
    final files = state.pickedFiles;
    
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSize = FileHelper.totalSize(files);
    final isComplete = state.transferPhase == 4;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Transfer Details",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
              Text(
                _formatBytes(totalSize),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
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
              final basename = file.uri.pathSegments.last;
              final sizeStr = _formatBytes(file.lengthSync());
              
              // We'll roughly estimate individual progress.
              // In a real app, P2pService could publish a Map<String, double> per file.
              // For now, we show a filled bar if complete, or a general indicator.
              final progress = isComplete ? 1.0 : (state.transferProgress / 100.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.blue[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            basename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFF111827),
                            color: isComplete ? Colors.green : Colors.blue,
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sizeStr,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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

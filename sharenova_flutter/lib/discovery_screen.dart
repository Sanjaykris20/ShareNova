// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  final List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Simulate finding devices
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _devices.add({"id": 1, "name": "Sarah's Mac", "type": "laptop"});
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _devices.add({"id": 2, "name": "David's Pixel 8", "type": "phone"});
        });
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Stack(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
                    onPressed: () => state.navigateTo('file_manager'),
                  ),
                  Column(
                    children: const [
                      Text(
                        "Nearby Radar",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "DIRECT ACTIVE",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399), letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Radar Animation & Central Node
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sonar Rings
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        double progress = (_radarController.value + (index / 3)) % 1.0;
                        double scale = 1.0 + (progress * 4.0);
                        double opacity = 0.8 * (1.0 - progress);

                        return Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Central Avatar Node
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F2937),
                      border: Border.all(color: const Color(0xFF374151), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          blurRadius: 40,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Image.network("https://api.dicebear.com/7.x/avataaars/png?seed=Felix"),
                    ),
                  ),

                  // Orbiting Found Devices
                  ...List.generate(_devices.length, (index) {
                    final dev = _devices[index];
                    // Position devices at different offsets
                    double dx = index == 0 ? -110.0 : 115.0;
                    double dy = index == 0 ? -120.0 : 100.0;

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: GestureDetector(
                        onTap: () {
                          state.resetTransfer();
                          state.navigateTo('transfer');
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    dev['type'] == 'laptop' ? LucideIcons.monitor : LucideIcons.smartphone,
                                    size: 30,
                                    color: const Color(0xFF111827),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF374151)),
                              ),
                              child: Text(
                                dev['name'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),

            // Scanning Prompt
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E40AF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF60A5FA), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Scanning for active P2P nodes...",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "TAP A DEVICE TO INITIATE HANDSHAKE",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
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

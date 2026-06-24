// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/p2p_service.dart';
import '../share_state.dart';
import '../services/location_permission_service.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> with TickerProviderStateMixin {
  late P2pService _p2pService;
  final List<P2pDevice> _devices = [];
  late List<AnimationController> _radarControllers;

  @override
  void initState() {
    super.initState();
    _p2pService = Provider.of<P2pService>(context, listen: false);
    _initializeDiscovery();

    _radarControllers = List.generate(3, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      );
      Future.delayed(Duration(milliseconds: index * 1300), () {
        if (mounted) {
          controller.repeat();
        }
      });
      return controller;
    });
  }

  Future<void> _initializeDiscovery() async {
    await LocationPermissionService.requestLocationPermission();
    _p2pService.startWifiDiscovery();
    _p2pService.startBleDiscovery();
    _p2pService.discovered.listen((device) {
      setState(() {
        if (!_devices.any((d) => d.id == device.id && d.connectionType == device.connectionType)) {
          _devices.add(device);
        }
      });
    });
  }

  @override
  void dispose() {
    _p2pService.dispose();
    for (var controller in _radarControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _connect(P2pDevice device) async {
    final state = Provider.of<ShareState>(context, listen: false);
    final session = await _p2pService.connectAndHandshake(device);
    state.setCurrentSession(session);
    state.navigateTo('transfer');
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // gray-950
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 16,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => state.navigateTo('home'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: const Icon(LucideIcons.arrow_left, color: Colors.white, size: 24),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        "Nearby Radar",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      Row(
                        children: const [
                          Icon(LucideIcons.wifi, color: Color(0xFF34D399), size: 10),
                          SizedBox(width: 4),
                          Text(
                            "DIRECT ACTIVE",
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 40), // Spacer
                ],
              ),
            ),

            // Radar Animation & Devices
            Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Radar Rings
                    ..._radarControllers.map((controller) {
                      return AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + (controller.value * 4), // Scale from 1 to 5
                            child: Opacity(
                              opacity: (1 - controller.value) * 0.8, // Fade out
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    // Central User Node
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1F2937), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              backgroundImage: const NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Felix"),
                            ),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF030712), width: 2),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.radar, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Orbiting Devices
                    ...List.generate(_devices.length, (index) {
                      final device = _devices[index];
                      // Calculate position on a circle
                      final angle = (index * (360 / max(1, _devices.length))) * (pi / 180);
                      final radius = 120.0;
                      final dx = radius * cos(angle);
                      final dy = radius * sin(angle);

                      return Positioned(
                        left: 150 + dx - 32, // center + offset - half width
                        top: 200 + dy - 32,
                        child: GestureDetector(
                          onTap: () => _connect(device),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      device.connectionType == ConnectionType.wifiDirect ? LucideIcons.smartphone : LucideIcons.bluetooth,
                                      size: 30,
                                      color: const Color(0xFF111827),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2937).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF374151)),
                                ),
                                child: Text(
                                  device.displayName.isNotEmpty ? device.displayName : device.id,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Scanning Status
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), // blue-900/30
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF1E40AF)), // blue-800
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF60A5FA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Scanning for active P2P nodes...",
                          style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      state.navigateTo('room_scanner');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.scan_line, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Scan QR to Connect",
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

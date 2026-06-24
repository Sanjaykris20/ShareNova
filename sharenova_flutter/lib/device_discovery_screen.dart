import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'share_state.dart';
import 'services/p2p_service.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final List<P2pDevice> _discoveredDevices = [];
  StreamSubscription? _discoverySub;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _startDiscovery();
  }

  void _startDiscovery() {
    final p2p = Provider.of<P2pService>(context, listen: false);
    p2p.startWifiDiscovery();

    _discoverySub = p2p.discovered.listen((device) {
      if (!mounted) return;
      setState(() {
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          _discoveredDevices.add(device);
        }
      });
    });
  }

  Future<void> _connectToDevice(P2pDevice device) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
    });

    try {
      final p2p = Provider.of<P2pService>(context, listen: false);
      final session = await p2p.connectAndHandshake(device);
      
      if (!mounted) return;
      
      final state = Provider.of<ShareState>(context, listen: false);
      state.setCurrentSession(session);
      state.navigateTo('transfer');
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to connect: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _discoverySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ShareState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030712), // Deep dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
          onPressed: () => state.navigateTo('file_manager'),
        ),
        title: const Text(
          "Searching nearby...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Radar Animation Background
          Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRadarCircle(300, 0.05),
                    _buildRadarCircle(200, 0.1),
                    _buildRadarCircle(100, 0.2),
                    Transform.rotate(
                      angle: _radarController.value * 2 * 3.14159,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            center: FractionalOffset.center,
                            colors: <Color>[
                              Colors.transparent,
                              const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              const Color(0xFF3B82F6).withValues(alpha: 0.5),
                            ],
                            stops: const <double>[0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Center "Me" Avatar
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F2937),
                border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.user, color: Colors.white, size: 32),
              ),
            ),
          ),

          // Discovered Devices
          ..._discoveredDevices.asMap().entries.map((entry) {
            final index = entry.key;
            final device = entry.value;
            // Position devices in a circle around the center
            final angle = (index * (3.14159 * 2) / (_discoveredDevices.isEmpty ? 1 : _discoveredDevices.length));
            final radius = 120.0;
            
            return Align(
              alignment: Alignment(
                (radius * 0.01 * (angle > 1.57 && angle < 4.71 ? -1 : 1)), // Rough approximation
                (radius * 0.01 * (angle > 3.14 ? -1 : 1)),
              ),
              child: GestureDetector(
                onTap: () => _connectToDevice(device),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF374151),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.smartphone, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        device.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Connecting Overlay
          if (_isConnecting)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    SizedBox(height: 24),
                    Text(
                      "Establishing Secure ECDH Channel...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }
}

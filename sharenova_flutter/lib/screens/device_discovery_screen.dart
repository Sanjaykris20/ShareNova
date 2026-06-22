// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/p2p_service.dart';
import '../share_state.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  State<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  late P2pService _p2pService;
  final List<P2pDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _p2pService = Provider.of<P2pService>(context, listen: false);
    // Start both discovery mechanisms
    _p2pService.startWifiDiscovery();
    _p2pService.startBleDiscovery();
    _p2pService.discovered.listen((device) {
      setState(() {
        // Avoid duplicates
        if (!_devices.any((d) => d.id == device.id && d.connectionType == device.connectionType)) {
          _devices.add(device);
        }
      });
    });
  }

  @override
  void dispose() {
    _p2pService.dispose();
    super.dispose();
  }

  Future<void> _connect(P2pDevice device) async {
    final state = Provider.of<ShareState>(context, listen: false);
    final session = await _p2pService.connectAndHandshake(device);
    state.setCurrentSession(session);
    // Move to the transfer screen
    state.navigateTo('transfer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Discovery'),
        backgroundColor: const Color(0xFF030712),
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final d = _devices[index];
          return ListTile(
            leading: Icon(d.connectionType == ConnectionType.wifiDirect ? LucideIcons.wifi : LucideIcons.bluetooth),
            title: Text(d.displayName.isNotEmpty ? d.displayName : d.id),
            subtitle: Text(d.connectionType == ConnectionType.wifiDirect ? 'Wi‑Fi Direct' : 'Bluetooth'),
            trailing: Text('RSSI ${d.rssi}'),
            onTap: () => _connect(d),
          );
        },
      ),
    );
  }
}

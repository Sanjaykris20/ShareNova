import 'dart:async';
import 'dart:io';
import 'package:wifi_direct_plugin/wifi_direct_plugin.dart';
import '../models/peer_device.dart';

/// Service handling Wi‑Fi Direct discovery and connections.
class WifiDirectService {
  /// Starts discovery and returns a stream of discovered peers.
  Stream<List<PeerDevice>> discoverPeers() async* {
    // Ensure permissions are already granted (location) before calling.
    await WifiDirectPlugin.initialize();
    await WifiDirectPlugin.startDiscovery();
    
    yield* WifiDirectPlugin.peersStream.map((peers) {
      return peers.map((p) => PeerDevice(
            id: p.deviceAddress,
            name: p.deviceName,
            transport: Transport.wifiDirect,
          )).toList();
    });
  }

  /// Connects to the given peer and returns the socket connected to the group owner.
  /// The caller can then use the socket to exchange data.
  Future<Socket> connect(PeerDevice device) async {
    // Initiate connection – the plugin returns true if connection starts
    final success = await WifiDirectPlugin.connect(device.id);
    if (!success) {
      throw Exception("Failed to initiate connection to ${device.name}");
    }
    
    // Wait a moment for the group to form and connection to establish
    await Future.delayed(const Duration(seconds: 2));
    
    // Obtain connection info
    final info = await WifiDirectPlugin.getCurrentConnectionInfo();
    if (info == null || !info.isConnected) {
      throw Exception("Failed to connect or connection info is not available");
    }
    
    final address = info.groupOwnerAddress;
    if (address == null) {
      throw Exception("Failed to get group owner address");
    }
    
    // Use the group owner address to connect socket
    final socket = await Socket.connect(address, 8888);
    return socket;
  }
}

import 'package:sharenova_flutter/services/p2p_service.dart';

/// Represents a user discovered via P2P discovery
class NearbyUser {
  final P2pDevice device;
  final String displayName;

  const NearbyUser({
    required this.device,
    required this.displayName,
  });

  factory NearbyUser.fromP2pDevice(P2pDevice device) {
    final name = device.displayName.isNotEmpty ? device.displayName : device.id;
    return NearbyUser(device: device, displayName: name);
  }

  @override
  String toString() => 'NearbyUser(displayName: $displayName, transport: ${device.connectionType})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyUser && runtimeType == other.runtimeType && device == other.device && displayName == other.displayName;

  @override
  int get hashCode => device.hashCode ^ displayName.hashCode;
}
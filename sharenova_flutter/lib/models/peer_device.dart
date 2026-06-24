enum Transport { bluetooth, wifiDirect }

class PeerDevice {
  final String id; // device address or IP
  final String name;
  final Transport transport;

  PeerDevice({required this.id, required this.name, required this.transport});
}

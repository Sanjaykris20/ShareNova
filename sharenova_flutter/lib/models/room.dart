// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a ShareNova room stored in Firestore.
class Room {
  final String roomId;
  final String adminDeviceId;
  final String? name;
  final Timestamp createdAt;

  Room({
    required this.roomId,
    required this.adminDeviceId,
    this.name,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toMap() => {
        'adminDeviceId': adminDeviceId,
        if (name != null) 'name': name,
        'createdAt': createdAt,
      };

  factory Room.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      roomId: doc.id,
      adminDeviceId: data['adminDeviceId'] ?? '',
      name: data['name'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

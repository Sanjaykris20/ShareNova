// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: use_null_aware_elements
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharenova_flutter/models/room.dart';

/// Repository handling Firestore persistence for ShareNova rooms.
class RoomRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _roomsCollection = 'rooms';
  static const String _membersSubcollection = 'members';

  /// Creates a new room document and returns the generated [Room] object.
  /// The adminDeviceId becomes the owner of the room. Optional [name] can be
  /// provided for a human‑readable name.
  Future<Room> createRoom({
    required String adminDeviceId,
    String? name,
  }) async {
    final docRef = await _db.collection(_roomsCollection).add({
      'adminDeviceId': adminDeviceId,
      if (name != null) 'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Add the admin as a member with role ADMIN.
    await _db
        .collection(_roomsCollection)
        .doc(docRef.id)
        .collection(_membersSubcollection)
        .doc(adminDeviceId)
        .set({'role': 'ADMIN'});
    return Room(
      roomId: docRef.id,
      adminDeviceId: adminDeviceId,
      name: name,
    );
  }

  /// Adds a member to the given room with the specified [role].
  Future<void> addMember({
    required String roomId,
    required String deviceId,
    required String role, // ADMIN / EDITOR / VIEWER
  }) async {
    await _db
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_membersSubcollection)
        .doc(deviceId)
        .set({'role': role});
  }

  /// Retrieves a [Room] by its document ID.
  Future<Room?> getRoom(String roomId) async {
    final doc = await _db.collection(_roomsCollection).doc(roomId).get();
    if (!doc.exists) return null;
    return Room.fromDoc(doc);
  }

  /// Lists all members (device IDs) of a room.
  Future<List<String>> listMembers(String roomId) async {
    final snapshot = await _db
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_membersSubcollection)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Removes a member from the room.
  Future<void> removeMember({
    required String roomId,
    required String deviceId,
  }) async {
    await _db
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_membersSubcollection)
        .doc(deviceId)
        .delete();
  }

  /// Deletes a room and all its sub‑collections (members, files, etc.).
  Future<void> deleteRoom(String roomId) async {
    // Delete members sub‑collection.
    final membersSnap = await _db
        .collection(_roomsCollection)
        .doc(roomId)
        .collection(_membersSubcollection)
        .get();
    for (final doc in membersSnap.docs) {
      await doc.reference.delete();
    }
    // Delete the room document itself.
    await _db.collection(_roomsCollection).doc(roomId).delete();
  }
}

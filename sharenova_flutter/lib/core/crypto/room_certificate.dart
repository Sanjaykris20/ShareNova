// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Simple representation of a signed room certificate.
///
/// In a real implementation the admin device would sign the certificate with a
/// long‑term private key. Here we just store the fields needed for verification.
class RoomCertificate {
  final String roomId;
  final String adminDeviceId;
  final Uint8List publicKey; // X25519 public key bytes
  final Uint8List signature; // Signature bytes (e.g., Ed25519 over the concatenated fields)

  RoomCertificate({
    required this.roomId,
    required this.adminDeviceId,
    required this.publicKey,
    required this.signature,
  });

  /// Verifies the certificate signature using the admin's Ed25519 public key.
  /// Returns true if the signature is valid.
  Future<bool> verify(Uint8List adminPublicKey) async {
    // For demo purposes we use Ed25519 algorithm.
    final algorithm = Ed25519();
    final key = SimplePublicKey(adminPublicKey, type: KeyPairType.ed25519);
    final data = Uint8List.fromList([
      ...roomId.codeUnits,
      ...adminDeviceId.codeUnits,
      ...publicKey,
    ]);
    try {
      return await algorithm.verify(data, signature: Signature(signature, publicKey: key));
    } catch (_) {
      return false;
    }
}

}

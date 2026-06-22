// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Simple wrapper around an ECDH key pair using the X25519 curve.
///
/// The pair is generated fresh for each session – the private key never leaves
/// the device. The public key can be exchanged over the P2P channel. The shared
/// secret is derived with [X25519().sharedSecretKey] and then converted to raw
/// bytes for use as an AES‑256‑GCM key.
class ECDHKeyPair {
  final SimpleKeyPair _privateKey;
  final SimplePublicKey publicKey;

  ECDHKeyPair._(this._privateKey, this.publicKey);

  /// Generates a new key pair.
  static Future<ECDHKeyPair> generate() async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return ECDHKeyPair._(keyPair, publicKey);
  }

  /// Derives a shared secret given the remote party's public key.
  /// Returns the raw 32‑byte secret which can be used directly as an AES‑256 key.
  Future<Uint8List> deriveSharedSecret(SimplePublicKey remotePublicKey) async {
    final algorithm = X25519();
    final secretKey = await algorithm.sharedSecretKey(
      keyPair: _privateKey,
      remotePublicKey: remotePublicKey,
    );
    final secretBytes = await secretKey.extractBytes();
    return Uint8List.fromList(secretBytes);
  }
}

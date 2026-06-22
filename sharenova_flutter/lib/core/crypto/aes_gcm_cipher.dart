// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// AES‑256‑GCM helper. Nonce is 12 bytes, tag is 16 bytes.
class AesGcmCipher {
  static final _algorithm = AesGcm.with256bits();

  /// Encrypts [plaintext] with the given 32‑byte [key] and a random nonce.
  /// Returns a tuple of (nonce, ciphertext, tag) concatenated as
  /// `nonce || ciphertext || tag`.
  static Future<Uint8List> encrypt(
    Uint8List plaintext,
    Uint8List key,
  ) async {
    final secretKey = SecretKey(key);
    final nonce = _algorithm.newNonce(); // 12‑byte nonce
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
    // secretBox.cipherText already excludes the tag; secretBox.mac holds the tag.
    final result = BytesBuilder();
    result.add(nonce);
    result.add(secretBox.cipherText);
    result.add(secretBox.mac.bytes);
    return result.toBytes();
  }

  /// Decrypts data formatted as `nonce || ciphertext || tag` using the same
  /// 32‑byte [key]. Throws if authentication fails.
  static Future<Uint8List> decrypt(
    Uint8List encrypted,
    Uint8List key,
  ) async {
    // nonce (12) + tag (16) = 28 bytes overhead
    if (encrypted.length < 28) {
      throw ArgumentError('Encrypted payload too short');
    }
    final nonce = encrypted.sublist(0, 12);
    final tag = encrypted.sublist(encrypted.length - 16);
    final cipherText = encrypted.sublist(12, encrypted.length - 16);
    final secretKey = SecretKey(key);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(tag),
    );
    final clear = await _algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(clear);
  }
}

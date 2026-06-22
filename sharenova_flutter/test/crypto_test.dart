import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharenova_flutter/core/crypto/ecdh_key_pair.dart';
import 'package:sharenova_flutter/core/crypto/aes_gcm_cipher.dart';

void main() {
  test('ECDH shared secret is symmetric', () async {
    final alice = await ECDHKeyPair.generate();
    final bob = await ECDHKeyPair.generate();

    final secret1 = await alice.deriveSharedSecret(bob.publicKey);
    final secret2 = await bob.deriveSharedSecret(alice.publicKey);

    expect(secret1, equals(secret2));
    expect(secret1.length, equals(32)); // X25519 produces 32‑byte secret
  });

  test('AES‑256‑GCM encrypt/decrypt round‑trip', () async {
    // Use a deterministic key for testing
    final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final plaintext = Uint8List.fromList('Hello ShareNova'.codeUnits);

    final encrypted = await AesGcmCipher.encrypt(plaintext, key);
    // Ensure encrypted payload is longer than plaintext (nonce+tag added)
    expect(encrypted.length, greaterThan(plaintext.length));

    final decrypted = await AesGcmCipher.decrypt(encrypted, key);
    expect(decrypted, equals(plaintext));
  });
}

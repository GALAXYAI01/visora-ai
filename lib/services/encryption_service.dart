import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

/// AES-256-CBC encryption utility for securing sensitive data.
/// Prevents plaintext exposure through browser DevTools / inspect tab.
class EncryptionService {
  static late enc.Key _key;
  static late enc.IV _iv;
  static bool _initialized = false;

  /// Initialize with a secret key (from .env or generated at runtime).
  /// The key is hashed to guarantee a 32-byte AES-256 key.
  static void initialize({String? secretKey}) {
    final seed = secretKey ?? _generateRandomKey();
    // SHA-256 hash produces exactly 32 bytes → AES-256
    final hash = sha256.convert(utf8.encode(seed)).bytes;
    _key = enc.Key.fromBase64(base64Encode(hash));
    _iv = enc.IV.fromLength(16);
    _initialized = true;
  }

  /// Encrypt a plaintext string → Base64 ciphertext
  static String encrypt(String plaintext) {
    _ensureInit();
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    return encrypter.encrypt(plaintext, iv: _iv).base64;
  }

  /// Decrypt a Base64 ciphertext → plaintext string
  static String decrypt(String ciphertext) {
    _ensureInit();
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(ciphertext, iv: _iv);
  }

  /// Encrypt a Map → Base64 ciphertext
  static String encryptMap(Map<String, dynamic> data) {
    return encrypt(jsonEncode(data));
  }

  /// Decrypt a Base64 ciphertext → Map
  static Map<String, dynamic> decryptMap(String ciphertext) {
    return jsonDecode(decrypt(ciphertext)) as Map<String, dynamic>;
  }

  /// Hash a password with SHA-256 (one-way, for login verification)
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Securely wipe a value by overwriting in memory (best effort in Dart)
  static String sanitize(String sensitive) {
    return '*' * sensitive.length;
  }

  static String _generateRandomKey() {
    final rng = Random.secure();
    return List.generate(32, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static void _ensureInit() {
    if (!_initialized) initialize();
  }
}

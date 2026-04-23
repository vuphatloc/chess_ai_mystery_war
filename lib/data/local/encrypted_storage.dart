import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// AES-256 encrypted SharedPreferences wrapper.
/// All data is encrypted before saving and decrypted on read.
/// When migrating to server: replace read/write with API calls.
class EncryptedStorage {
  static const _salt = 'ChessAIMysteryWar_v1_2025';
  static enc.Encrypter? _encrypter;

  static enc.Encrypter _getEncrypter() {
    if (_encrypter != null) return _encrypter!;
    final keyBytes = sha256.convert(utf8.encode(_salt)).bytes;
    final key = enc.Key(Uint8ListHelper.fromList(keyBytes));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return _encrypter!;
  }

  static String _encrypt(String plainText) {
    final iv = enc.IV.fromLength(16);
    final encrypted = _getEncrypter().encrypt(plainText, iv: iv);
    // Store iv + encrypted data together as base64
    final combined = iv.base64 + ':' + encrypted.base64;
    return combined;
  }

  static String? _decrypt(String cipherText) {
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _getEncrypter().decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('enc_$key', _encrypt(value));
  }

  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('enc_$key');
    if (raw == null) return null;
    return _decrypt(raw);
  }

  static Future<void> saveMap(String key, Map<String, dynamic> map) async {
    await saveString(key, jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> loadMap(String key) async {
    final str = await loadString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_$key');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('enc_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

/// Helper to convert List<int> to Uint8List
class Uint8ListHelper {
  static Uint8List fromList(List<int> list) {
    return Uint8List.fromList(list);
  }
}

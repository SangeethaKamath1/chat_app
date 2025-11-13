import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // ⚠️ This should be stored securely (e.g., in Firebase Remote Config or backend-managed)
  static final _key = encrypt.Key.fromUtf8('16charSecretKey!'); // must be 16, 24, or 32 chars
  static final _iv = encrypt.IV.fromUtf8('8bytesInitVect'); // must be 8 or 16 bytes

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print("Decryption error: $e");
      return encryptedText; // fallback if already plain
    }
  }

static  bool looksEncrypted(String text) {
  // Example 1️⃣: You can detect AES encrypted strings (Base64-like)
  final base64Regex = RegExp(r'^[A-Za-z0-9+/=]+$');

  // Example 2️⃣: Or if you prefix encrypted messages (recommended)
  // e.g., message = "ENC:<base64string>"
  if (text.startsWith("ENC:")) return true;

  // Heuristic check for Base64 + reasonable length
  return base64Regex.hasMatch(text) && text.length > 16;
}
}

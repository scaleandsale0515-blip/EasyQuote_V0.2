import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../storage/local_db.dart';

/// Admin activation lock.
///
/// How it works:
/// - The real ID and Password are never stored as plain text anywhere in
///   the compiled app. Only a salted SHA-256 hash of each is hardcoded here.
/// - On first launch, the user must enter the correct ID + Password. Once
///   verified, an "activated" flag is written to the local Hive 'app' box.
/// - Every subsequent launch checks that flag first — if present, the lock
///   screen is skipped.
/// - Uninstalling the app wipes its local storage on Android, so the flag
///   is gone and the lock screen will ask again after a reinstall, exactly
///   as required.
/// - A wrong ID or Password never unlocks the app, no matter how many
///   attempts (no bypass, no "forgot password" flow, by design).
///
/// Note on security: hashing + a hardcoded salt keeps the literal
/// credentials out of plain sight inside the compiled APK. It is not
/// literally unbreakable — someone with APK reverse-engineering skill could
/// eventually recover the hash and attempt to brute-force it — but with a
/// strong password like this one, that is impractical for typical use.
class AdminAuth {
  AdminAuth._();

  // Hardcoded salt — combined with the ID/Password before hashing.
  static const String _salt = 'EQ26_xR9!kLp_saltv1';

  // SHA-256("FactoryFlowRP2026" + salt)
  static const String _idHash =
      'd9ec5d7ca931104ea9edc8e3b7f047aea8e49109225e6544e778e7451dcefaff';

  // SHA-256("AdxyRBP@7989Qwop" + salt)
  static const String _pwHash =
      'a75b127746015ef768f7ded6eff7b8ce36f555679d87f27ea84ebce61d243ad7';

  static String _hash(String input) =>
      sha256.convert(utf8.encode(input + _salt)).toString();

  /// True if this device has already been unlocked once before.
  static bool isActivated() {
    final box = LocalDB.instance.appBox;
    return box.get('adminActivated', defaultValue: false) == true;
  }

  /// Verifies the entered ID + Password against the hardcoded hashes.
  /// On success, marks this device as activated so the lock screen is
  /// skipped on future launches (until uninstall/reinstall).
  static bool verifyAndActivate(String enteredId, String enteredPassword) {
    final idOk = _hash(enteredId) == _idHash;
    final pwOk = _hash(enteredPassword) == _pwHash;
    if (idOk && pwOk) {
      LocalDB.instance.appBox.put('adminActivated', true);
      return true;
    }
    return false;
  }
}

import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:local_auth/local_auth.dart';

/// Background lock + biometric — mirrors `ThemedActivity.isOpenValidate`.
class SecurityService {
  SecurityService(this._prefs);

  static const int backgroundLockMinutes = 5;

  final AppPreferences _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get isSecurityEnabled => _prefs.securityValidationEnabled;

  Future<void> setSecurityEnabled(bool value) =>
      _prefs.setSecurityValidationEnabled(value);

  String? get gesturePattern => _prefs.gesturePassword;

  Future<void> setGesturePattern(String pattern) =>
      _prefs.setGesturePassword(pattern);

  Future<void> clearGesturePattern() => _prefs.setGesturePassword(null);

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = '請驗證身分'}) async {
    if (!isSecurityEnabled) return true;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  bool needsUnlock({required bool isAppTerminate}) {
    if (!isSecurityEnabled) return false;
    if (isAppTerminate) return true;
    final bg = _prefs.backgroundTimestamp;
    if (bg <= 0) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - bg;
    return elapsed >= backgroundLockMinutes * 60 * 1000;
  }

  Future<void> onEnterBackground() async {
    await _prefs.setIsEnterBackground(true);
    await _prefs.setBackgroundTimestamp(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> onUnlockSuccess() async {
    await _prefs.setBackgroundTimestamp(0);
    await _prefs.setIsEnterBackground(false);
    await _prefs.setIsAppTerminate(false);
  }

  Future<void> onAppTerminate() async {
    await _prefs.setIsAppTerminate(true);
  }

  bool verifyGesture(String input) {
    final stored = _prefs.gesturePassword;
    if (stored == null || stored.isEmpty) return true;
    return stored == input;
  }
}

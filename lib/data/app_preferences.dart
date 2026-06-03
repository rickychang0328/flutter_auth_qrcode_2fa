import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors Android `ds-preferences` + lazy-write keys.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String grouplistJson = 'grouplistjson';
  static const String shareAccountListJson = 'shareaccountlistjson';
  static const String isSecurityValidation = 'isSecurityValidation';
  static const String isFirstSetFingerprint = 'isFirstSetFingerprint';
  static const String gesturePwdKey = 'gesture_pwd_key';
  static const String enterBackgroundTime = 'enterBackgroundTime';
  static const String isEnterBackground = 'isEnterBackground';
  static const String isAppTerminate = 'isAppTerminate';

  static Future<AppPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  bool get securityValidationEnabled =>
      _prefs.getBool(isSecurityValidation) ?? false;

  Future<void> setSecurityValidationEnabled(bool value) =>
      _prefs.setBool(isSecurityValidation, value);

  String? get grouplistJsonRaw => _prefs.getString(grouplistJson);

  Future<void> setGrouplistJson(String value) =>
      _prefs.setString(grouplistJson, value);

  String? get shareAccountListJsonRaw =>
      _prefs.getString(shareAccountListJson);

  Future<void> setShareAccountListJson(String value) =>
      _prefs.setString(shareAccountListJson, value);

  String? get gesturePassword => _prefs.getString(gesturePwdKey);

  Future<void> setGesturePassword(String? value) {
    if (value == null) return _prefs.remove(gesturePwdKey);
    return _prefs.setString(gesturePwdKey, value);
  }

  int get backgroundTimestamp => _prefs.getInt(enterBackgroundTime) ?? 0;

  Future<void> setBackgroundTimestamp(int value) =>
      _prefs.setInt(enterBackgroundTime, value);

  bool get isEnterBackgroundFlag =>
      _prefs.getBool(isEnterBackground) ?? false;

  Future<void> setIsEnterBackground(bool value) =>
      _prefs.setBool(isEnterBackground, value);

  bool get isAppTerminateFlag => _prefs.getBool(isAppTerminate) ?? false;

  Future<void> setIsAppTerminate(bool value) =>
      _prefs.setBool(isAppTerminate, value);
}


import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUser {

  static final PreferencesUser _instancia = PreferencesUser._internal();

  factory PreferencesUser() {
    return _instancia;
  }
  PreferencesUser._internal();

  late SharedPreferences _prefs;

  initiPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void savePrefs(
      {required dynamic type, required String key, required dynamic value}) {
    switch (type) {
      case bool:
        _prefs.setBool(key, value);
        break;
      case int:
        _prefs.setInt(key, value);
        break;

      case String:
        _prefs.setString(key, value);
        break;
    }
  }

  Future loadPrefs({required dynamic type, required String key}) async {
    switch (type) {
      case bool:
        return _prefs.getBool(key);
      case int:
        return _prefs.getInt(key);
      case String:
        return _prefs.getString(key);
    }
  }

  Future clearOnePreference({required String key}) async {
    await _prefs.remove(key);
  }

  Future removePreferences() async {
    _prefs.clear();
  }
}
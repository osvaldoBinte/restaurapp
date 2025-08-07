import 'dart:convert';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/framework/preferences_service.dart';

class AuthService extends GetxService {
  static final AuthService _instance = AuthService._internal();
  final PreferencesUser _prefsUser = PreferencesUser();

  String? _cachedToken;

  factory AuthService() => _instance;

  AuthService._internal();

  Future<AuthService> init() async {
    await getToken();
    return this;
  }

  // Obtener token de sesión guardado
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      final sessionJson = await _prefsUser.loadPrefs(
        type: String,
        key: AppConstants.accesos,
      );

      if (sessionJson != null && sessionJson.isNotEmpty) {
        final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);
        _cachedToken = sessionMap['data']['token'];
        print('✅ Token obtenido correctamente');
        return _cachedToken;
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener token: $e');
      return null;
    }
  }

  // Guardar solo el token
  Future<bool> saveToken(String token) async {
    try {
      _cachedToken = token;

      final sessionData = {
        "message": "Accesos correctos",
        "data": {"token": token}
      };

       _prefsUser.savePrefs(
        type: String,
        key: AppConstants.accesos,
        value: jsonEncode(sessionData),
      );

      print('✅ Token guardado correctamente');
      return true;
    } catch (e) {
      print('❌ Error al guardar token: $e');
      return false;
    }
  }

  // Eliminar token
  Future<bool> logout() async {
    try {
      _cachedToken = null;
      await _prefsUser.clearOnePreference(key: AppConstants.accesos);
      print('✅ Sesión cerrada correctamente');
      return true;
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      return false;
    }
  }

  // Verificar si el token está disponible
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

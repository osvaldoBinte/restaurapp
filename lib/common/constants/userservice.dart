import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/framework/preferences_service.dart';

class UserService {
  /// Opción 1: GET personalizado con body usando Request
  static Future<Map<String, dynamic>?> obtenerUsuario() async {
    try {
      // Obtener email desde SharedPreferences
      final prefs = PreferencesUser();
      final email = await prefs.loadPrefs(type: String, key: AppConstants.userEmail);
      
      if (email == null || email.isEmpty) {
        print('No se encontró email en SharedPreferences');
        return null;
      }

      final url = Uri.parse('${AppConstants.serverBase}/usuarios/obtenerUsuario/');
      
      // Crear request personalizada con GET pero con body
      final request = http.Request('GET', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'email': email});
      
      final streamedResponse = await request.send()
          .timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));
      
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardar isAdmin en SharedPreferences
        if (data['isAdmin'] != null) {
          final prefs = PreferencesUser();
           prefs.savePrefs(
            type: bool, 
            key: AppConstants.userIsAdmin, 
            value: data['isAdmin']
          );
        }
        
        return data;
      } else {
        print('Error al obtener usuario: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error en obtenerUsuario: $e');
      return null;
    }
  }

  /// Opción 2: Usando el método _makeRequest actualizado
  static Future<Map<String, dynamic>?> obtenerUsuarioConMakeRequest() async {
    try {
      // Obtener email desde SharedPreferences
      final prefs = PreferencesUser();
      final email = await prefs.loadPrefs(type: String, key: AppConstants.userEmail);
      
      if (email == null || email.isEmpty) {
        print('No se encontró email en SharedPreferences');
        return null;
      }

      final url = '${AppConstants.serverBase}/usuarios/obtenerUsuario/';
      
      // Llamar usando GET con body
      final data = await _makeRequest(
        url: url,
        method: 'GET',
        body: {'email': email},
      );
      
      // Guardar isAdmin en SharedPreferences
      if (data != null && data['isAdmin'] != null) {
        final prefs = PreferencesUser();
         prefs.savePrefs(
          type: bool, 
          key: AppConstants.userIsAdmin, 
          value: data['isAdmin']
        );
      }
      
      return data;
    } catch (e) {
      print('Error en obtenerUsuario: $e');
      return null;
    }
  }

  /// Método _makeRequest actualizado para soportar GET con body
  static Future<dynamic> _makeRequest({
    required String url,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    try {
      http.Response response;
      final headers = {
        'Content-Type': 'application/json',
      };

      switch (method) {
        case 'GET':
          if (body != null) {
            // GET con body usando Request personalizada
            final request = http.Request('GET', Uri.parse(url));
            request.headers.addAll(headers);
            request.body = jsonEncode(body);
            
            final streamedResponse = await request.send();
            response = await http.Response.fromStream(streamedResponse);
          } else {
            // GET normal sin body
            response = await http.get(
              Uri.parse(url),
              headers: headers,
            );
          }
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      print('⭐ $method request a: $url');
      if (body != null) {
        print('⭐ Body enviado: ${jsonEncode(body)}');
      }
      print('⭐ Respuesta código: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('⭐ Respuesta exitosa');
        final jsonData = jsonDecode(response.body);
        return jsonData;
      } else {
        print('❌ Error en la respuesta: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      return null;
    }
  }

  /// Opción 3: Cliente HTTP personalizado usando dio (alternativa)
  /// Necesitarías agregar dio: ^5.3.2 en pubspec.yaml
  /*
  static Future<Map<String, dynamic>?> obtenerUsuarioConDio() async {
    try {
      final prefs = PreferencesUser();
      final email = await prefs.loadPrefs(type: String, key: AppConstants.userEmail);
      
      if (email == null || email.isEmpty) {
        print('No se encontró email en SharedPreferences');
        return null;
      }

      final dio = Dio();
      final response = await dio.request(
        '${AppConstants.serverBase}/usuarios/obtenerUsuario/',
        options: Options(
          method: 'GET',
          headers: {'Content-Type': 'application/json'},
        ),
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['isAdmin'] != null) {
          final prefs = PreferencesUser();
          await prefs.savePrefs(
            type: bool, 
            key: AppConstants.userIsAdmin, 
            value: data['isAdmin']
          );
        }
        
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Error en obtenerUsuario: $e');
      return null;
    }
  }
  */

  static Future<bool> isUserAdmin() async {
    try {
      final prefs = PreferencesUser();
      final isAdmin = await prefs.loadPrefs(type: bool, key: AppConstants.userIsAdmin);
      return isAdmin ?? false;
    } catch (e) {
      print('Error al verificar si es admin: $e');
      return false;
    }
  }

  /// Cerrar sesión y limpiar todas las preferencias
  static Future<void> cerrarSesion() async {
    try {
      final prefs = PreferencesUser();
      
      // Limpiar todas las preferencias
      await prefs.removePreferences();
      
      print('Sesión cerrada exitosamente');
      
      // Navegar a la pantalla de login
      Get.offAllNamed('/login'); // Cambia '/login' por tu ruta de login
      
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // En caso de error, intentar limpiar preferencias específicas
      try {
        final prefs = PreferencesUser();
        await prefs.clearOnePreference(key: AppConstants.userEmail);
        await prefs.clearOnePreference(key: AppConstants.userIsAdmin);
        await prefs.clearOnePreference(key: AppConstants.isLoggedIn);
        await prefs.clearOnePreference(key: AppConstants.loginTimestamp);
        
        Get.offAllNamed('/login');
      } catch (e2) {
        print('Error crítico al cerrar sesión: $e2');
      }
    }
  }

  /// Confirmar cierre de sesión con diálogo
  static void confirmarCerrarSesion() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?\n\nSe eliminarán todos los datos guardados.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              cerrarSesion(); // Ejecutar cierre de sesión
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
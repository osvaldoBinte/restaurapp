import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/settings/routes_names.dart';
import 'package:restaurapp/framework/preferences_service.dart';

class LoginController extends GetxController {
  // Observables
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;
  
  // Controllers para los campos
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // URL base de tu API usando AppConstants
  String get apiBaseUrl => AppConstants.serverBase;
  
  // Instancia de preferencias
  final PreferencesUser _prefs = PreferencesUser();

  @override
  void onInit() {
    super.onInit();
    // Inicializar preferencias si es necesario
    _initPreferences();
  }

  @override
  void onClose() {
    // Limpiar controllers
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Inicializar preferencias
  Future<void> _initPreferences() async {
    await _prefs.initiPrefs();
  }

  /// Toggle para mostrar/ocultar contraseña
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Validar email usando constantes
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo';
    }
    if (!RegExp(AppConstants.emailRegex).hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  /// Validar contraseña usando constantes
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }
    return null;
  }

  /// Función principal de login
  Future<void> login() async {
    // Validar formulario
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      // Mostrar loading
      isLoading.value = true;
      errorMessage.value = '';

      print('🚀 Iniciando login con API base: $apiBaseUrl');

      // Preparar datos para envío
      final Map<String, dynamic> loginData = {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      };

      // Realizar petición HTTP
      final response = await _makeLoginRequest(loginData);

      // Procesar respuesta
      await _handleLoginResponse(response);

    } catch (e) {
      // Manejar errores
      _handleError(e);
    } finally {
      // Ocultar loading
      isLoading.value = false;
    }
  }

  /// Realizar petición HTTP de login usando AppConstants
  Future<http.Response> _makeLoginRequest(Map<String, dynamic> loginData) async {
    final Uri url = Uri.parse('$apiBaseUrl${AppConstants.loginEndpoint}');
    
    print('📡 Realizando petición a: $url');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(loginData),
    ).timeout(
      Duration(seconds: AppConstants.requestTimeoutSeconds),
      onTimeout: () {
        throw Exception('Tiempo de espera agotado');
      },
    );

    print('📨 Respuesta recibida - Status: ${response.statusCode}');
    return response;
  }

  /// Procesar respuesta del login
  Future<void> _handleLoginResponse(http.Response response) async {
    print('🔍 Procesando respuesta del login...');
    
    if (response.statusCode == 200) {
      // Login exitoso
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('✅ Login exitoso: $responseData');
      
      // Validar que la respuesta tenga los campos esperados
      if (responseData.containsKey('email') && responseData.containsKey('isAdmin')) {
        await _saveUserData(responseData);
        await _navigateToHome();
      } else {
        print('❌ Respuesta incompleta del servidor');
        throw Exception('Respuesta del servidor incompleta');
      }
      
    } else if (response.statusCode == 401) {
      // Credenciales incorrectas
      print('🔐 Credenciales incorrectas');
      errorMessage.value = 'Correo o contraseña incorrectos';
      
    } else if (response.statusCode == 404) {
      // Usuario no encontrado
      print('👤 Usuario no encontrado');
      errorMessage.value = 'Usuario no encontrado';
      
    } else if (response.statusCode >= 500) {
      // Error del servidor
      print('🚨 Error del servidor: ${response.statusCode}');
      errorMessage.value = 'Error del servidor. Intenta más tarde';
      
    } else {
      // Otros errores
      print('⚠️ Error desconocido: ${response.statusCode}');
      try {
        final errorData = json.decode(response.body);
        errorMessage.value = errorData['message'] ?? 'Error desconocido';
      } catch (e) {
        errorMessage.value = 'Error de conexión';
      }
    }
  }

  /// Guardar datos del usuario en preferencias usando AppConstants
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      print('💾 Guardando datos del usuario...');
      
      // Guardar email usando AppConstants
      _prefs.savePrefs(
        type: String,
        key: AppConstants.userEmail,
        value: userData['email'],
      );
      
      // Guardar estado de admin usando AppConstants
      _prefs.savePrefs(
        type: bool,
        key: AppConstants.userIsAdmin,
        value: userData['isAdmin'],
      );
      
      // Guardar flag de sesión activa usando AppConstants
      _prefs.savePrefs(
        type: bool,
        key: AppConstants.isLoggedIn,
        value: true,
      );
      
      // Guardar timestamp del login usando AppConstants
      _prefs.savePrefs(
        type: String,
        key: AppConstants.loginTimestamp,
        value: DateTime.now().toIso8601String(),
      );
      
      print('✅ Datos de usuario guardados correctamente');
      print('📧 Email: ${userData['email']}');
      print('🔑 Es Admin: ${userData['isAdmin']}');
      
    } catch (e) {
      print('❌ Error guardando datos de usuario: $e');
      throw Exception('Error guardando datos de usuario');
    }
  }

  /// Navegar a la pantalla principal
  Future<void> _navigateToHome() async {
    // Limpiar formulario
    _clearForm();
    
   
    
    // Navegar a home
    print('🏠 Navegando a la pantalla principal...');
     Get.offAllNamed(RoutesNames.homePage);
  }

  /// Manejar errores
  void _handleError(dynamic error) {
    print('❌ Error en login: $error');
    
    String errorMsg;
    
    if (error.toString().contains('SocketException')) {
      errorMsg = 'Sin conexión a internet';
    } else if (error.toString().contains('TimeoutException') || 
               error.toString().contains('Tiempo de espera agotado')) {
      errorMsg = 'Tiempo de espera agotado';
    } else if (error.toString().contains('FormatException')) {
      errorMsg = 'Error en el formato de respuesta';
    } else if (error.toString().contains('HandshakeException')) {
      errorMsg = 'Error de conexión SSL';
    } else {
      errorMsg = 'Error inesperado. Intenta nuevamente';
    }
    
    errorMessage.value = errorMsg;
    
    // Mostrar snackbar de error
    Get.snackbar(
      'Error',
      errorMsg,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Limpiar formulario
  void _clearForm() {
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
    print('🧹 Formulario limpiado');
  }

  /// Cerrar sesión usando AppConstants
  Future<void> logout() async {
    try {
      print('🚪 Cerrando sesión...');
      
      // Limpiar todas las preferencias
      await _prefs.removePreferences();
      
      // Limpiar formulario
      _clearForm();
      
      // Mostrar mensaje
      Get.snackbar(
        'Sesión cerrada',
        'Has cerrado sesión correctamente',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
      
      // Navegar al login
       Get.offAllNamed(RoutesNames.loginPage);
      
      print('✅ Sesión cerrada correctamente');
      
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
    }
  }

  /// Verificar si hay sesión activa usando AppConstants
  Future<bool> isLoggedIn() async {
    try {
      final isLogged = await _prefs.loadPrefs(
        type: bool, 
        key: AppConstants.isLoggedIn
      );
      return isLogged ?? false;
    } catch (e) {
      print('⚠️ Error verificando sesión: $e');
      return false;
    }
  }

  /// Obtener datos del usuario guardados usando AppConstants
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final email = await _prefs.loadPrefs(
        type: String, 
        key: AppConstants.userEmail
      );
      final isAdmin = await _prefs.loadPrefs(
        type: bool, 
        key: AppConstants.userIsAdmin
      );
      
      if (email != null && isAdmin != null) {
        return {
          'email': email,
          'isAdmin': isAdmin,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo datos de usuario: $e');
      return null;
    }
  }

  /// Obtener información adicional del usuario
  Future<Map<String, dynamic>?> getFullUserInfo() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        final loginTime = await _prefs.loadPrefs(
          type: String,
          key: AppConstants.loginTimestamp
        );
        
        return {
          ...userData,
          'loginTimestamp': loginTime,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo información completa del usuario: $e');
      return null;
    }
  }

  /// Verificar si el usuario es administrador
  Future<bool> isUserAdmin() async {
    try {
      final isAdmin = await _prefs.loadPrefs(
        type: bool,
        key: AppConstants.userIsAdmin
      );
      return isAdmin ?? false;
    } catch (e) {
      print('⚠️ Error verificando permisos de admin: $e');
      return false;
    }
  }

  /// Obtener email del usuario actual
  Future<String?> getCurrentUserEmail() async {
    try {
      return await _prefs.loadPrefs(
        type: String,
        key: AppConstants.userEmail
      );
    } catch (e) {
      print('⚠️ Error obteniendo email del usuario: $e');
      return null;
    }
  }
}
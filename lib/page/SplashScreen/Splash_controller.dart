import 'package:get/get.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/common/settings/routes_names.dart';
import 'package:restaurapp/framework/preferences_service.dart';


class SplashController extends GetxController {
  // Observables
  final RxBool isLoading = true.obs;
  final RxString loadingMessage = 'Iniciando aplicación...'.obs;
  
  // Duración mínima del splash (para que no se vea muy rápido)
  static const int minSplashDuration = 2000; // 2 segundos

  @override
  void onInit() {
    super.onInit();
    _initializeSplash();
  }

  /// Inicializar splash y verificar estado de la app
  Future<void> _initializeSplash() async {
    try {
      final startTime = DateTime.now();
      
      print('🚀 Iniciando SplashScreen...');
      
      
      // Verificar usuario con UserService
      await _checkUserWithService();
      
      // Asegurar duración mínima del splash
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsedTime < minSplashDuration) {
        final remainingTime = minSplashDuration - elapsedTime;
        await Future.delayed(Duration(milliseconds: remainingTime));
      }
      
    } catch (e) {
      print('❌ Error en SplashScreen: $e');
      // En caso de error, ir al login por seguridad
      _navigateToLogin();
    }
  }


  /// Verificar usuario usando UserService
  Future<void> _checkUserWithService() async {
    try {
      loadingMessage.value = 'Verificando sesión...';
      
      // Verificar si hay email guardado primero
    
      
      
      // Llamar al servicio para obtener datos del usuario
      final userData = await UserService.obtenerUsuario();
      
      if (userData != null) {
        // Si obtenerUsuario funciona correctamente, ir al home
        print('✅ Usuario validado correctamente');
        print('👤 Datos del usuario: ${userData.toString()}');
        
        loadingMessage.value = 'Cargando aplicación...';
        await Future.delayed(Duration(milliseconds: 500));
        
        _navigateToHome();
      } else {
        // Si obtenerUsuario falla, ir al login
        print('❌ Error al obtener datos del usuario');
        _navigateToLogin();
      }
      
    } catch (e) {
      print('❌ Error en _checkUserWithService: $e');
      _navigateToLogin();
    }
  }

  /// Navegar al login
  void _navigateToLogin() {
    isLoading.value = false;
    print('➡️ Redirigiendo a LoginPage');
    Get.offAllNamed(RoutesNames.loginPage);
  }

  /// Navegar al home
  void _navigateToHome() {
    isLoading.value = false;
    print('➡️ Redirigiendo a HomePage');
    Get.offAllNamed(RoutesNames.homePage);
  }

  /// Método público para refrescar el splash (útil para testing)
  Future<void> refreshSplash() async {
    isLoading.value = true;
    loadingMessage.value = 'Iniciando aplicación...';
    await _initializeSplash();
  }


  /// Obtener información de debug del estado actual
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final prefs = PreferencesUser();
      final email = await prefs.loadPrefs(type: String, key: AppConstants.userEmail);
      final isAdmin = await prefs.loadPrefs(type: bool, key: AppConstants.userIsAdmin);
      final isLoggedIn = await prefs.loadPrefs(type: bool, key: AppConstants.isLoggedIn);
      
      return {
        'userEmail': email,
        'isAdmin': isAdmin,
        'isLoggedIn': isLoggedIn,
        'timestamp': DateTime.now().toIso8601String(),
        'loadingMessage': loadingMessage.value,
        'isLoading': isLoading.value,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
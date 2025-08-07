import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Base URL
  static String serverBase = dotenv.env['API_BASE'].toString();
  
  // User preferences keys
  static const String userEmail = "user_email";
  static const String userIsAdmin = 'user_isAdmin';
  static const String isLoggedIn = 'is_logged_in';
  static const String loginTimestamp = 'login_timestamp';
  
  // Existing keys
  static const String accesos = "accesos";
  static const String modeStorageKey = 'productos_mode_key';
  static const String productosEscaneados = 'productos_escaneados_por_orden';
  
  // API Endpoints
  static const String loginEndpoint = '/usuarios/LoginUsuario/';
  
  // App Settings
  static const int requestTimeoutSeconds = 30;
  
  // Validation
  static const int minPasswordLength = 1;
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
}
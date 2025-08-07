// user_profile_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/framework/preferences_service.dart';
class UserProfileController extends GetxController {
  // Observables para estado
  final RxBool isLoading = true.obs;
  final RxBool isEditing = false.obs;
  final RxBool isUpdating = false.obs;
  
  // Observables para datos del usuario
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userUsername = ''.obs;
  final RxString userRole = ''.obs;
  final RxBool isAdmin = false.obs;
  final RxString joinDate = ''.obs;
  
  // Controllers para edición
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController usernameController;
  
  // Datos adicionales (simulados por ahora)
  final RxInt ordersProcessed = 0.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt activeDays = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    loadUserProfile();
  }

  void _initializeControllers() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    usernameController = TextEditingController();
  }

  /// Cargar perfil del usuario
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      
      // Obtener datos del usuario desde el servicio
      final userData = await UserService.obtenerUsuario();
      
      if (userData != null) {
        // Mapear datos del servidor
        _mapUserData(userData);
        
        // Actualizar controllers
        _updateControllers();
      } else {
        // Si no se pueden obtener datos del servidor, usar datos locales
        await _loadLocalUserData();
      }
      
    } catch (e) {
      print('Error cargando perfil: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar el perfil del usuario',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _mapUserData(Map<String, dynamic> userData) {
    userName.value = userData['nombre'] ?? userData['name'] ?? 'Usuario';
    userEmail.value = userData['email'] ?? '';
    userPhone.value = userData['telefono'] ?? userData['phone'] ?? '';
    userUsername.value = userData['username'] ?? userData['usuario'] ?? '';
    isAdmin.value = userData['isAdmin'] ?? false;
    
    // Configurar rol basado en isAdmin
    userRole.value = isAdmin.value ? 'Administrador' : 'Usuario';
    
    // Formatear fecha de registro si existe
    if (userData['fechaRegistro'] != null) {
      joinDate.value = _formatDate(userData['fechaRegistro']);
    } else {
      joinDate.value = 'No disponible';
    }
    
    // Datos adicionales si están disponibles
    ordersProcessed.value = userData['ordenesProcesadas'] ?? 0;
    averageRating.value = (userData['calificacionPromedio'] ?? 0.0).toDouble();
    activeDays.value = userData['diasActivo'] ?? 0;
  }

  Future<void> _loadLocalUserData() async {
    try {
      final prefs = PreferencesUser();
      
      final email = await prefs.loadPrefs(type: String, key: AppConstants.userEmail);
      final isAdminLocal = await prefs.loadPrefs(type: bool, key: AppConstants.userIsAdmin);
      
      userEmail.value = email ?? '';
      isAdmin.value = isAdminLocal ?? false;
      userRole.value = isAdmin.value ? 'Administrador' : 'Usuario';
      userName.value = 'Usuario'; // Valor por defecto
      
      _updateControllers();
    } catch (e) {
      print('Error cargando datos locales: $e');
    }
  }

  void _updateControllers() {
    nameController.text = userName.value;
    emailController.text = userEmail.value;
    phoneController.text = userPhone.value;
    usernameController.text = userUsername.value;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${date.day} de ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  /// Alternar modo edición
  void toggleEditing() {
    if (isEditing.value) {
      // Guardar cambios
      saveProfile();
    } else {
      // Entrar en modo edición
      isEditing.value = true;
    }
  }

  /// Guardar perfil
  Future<void> saveProfile() async {
    try {
      isUpdating.value = true;
      
      // Validar datos antes de guardar
      if (!_validateProfileData()) {
        return;
      }
      
      // Aquí podrías llamar a un endpoint para actualizar el perfil
      // Por ahora solo actualizamos localmente
      userName.value = nameController.text.trim();
      userEmail.value = emailController.text.trim();
      userPhone.value = phoneController.text.trim();
      userUsername.value = usernameController.text.trim();
      
      // Simular delay de red
      await Future.delayed(Duration(seconds: 1));
      
      isEditing.value = false;
      
      Get.snackbar(
        'Éxito',
        'Perfil actualizado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF8B4513).withOpacity(0.7),
        colorText: Colors.white,
      );
      
    } catch (e) {
      print('Error guardando perfil: $e');
      Get.snackbar(
        'Error',
        'No se pudo actualizar el perfil',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  bool _validateProfileData() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'El nombre no puede estar vacío');
      return false;
    }
    
    if (emailController.text.trim().isEmpty) {
      Get.snackbar('Error', 'El email no puede estar vacío');
      return false;
    }
    
    // Validar formato de email
    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar('Error', 'El formato del email no es válido');
      return false;
    }
    
    return true;
  }

  /// Cancelar edición
  void cancelEditing() {
    isEditing.value = false;
    _updateControllers(); // Restaurar valores originales
  }

  /// Refrescar datos del perfil
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  /// Cerrar sesión usando UserService
  void logout() {
    UserService.confirmarCerrarSesion();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    super.onClose();
  }
}

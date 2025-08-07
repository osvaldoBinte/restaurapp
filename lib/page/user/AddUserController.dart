import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';

// Controller GetX para agregar usuarios
class AddUserController extends GetxController {
  // Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Form Key
  final formKey = GlobalKey<FormState>();
  
  // Observables
  var selectedRole = UserRole.secondary.obs;
  var selectedShift = Rxn<String>();
  var isActive = true.obs;
  var showPassword = false.obs;
  var showConfirmPassword = false.obs;
  var isLoading = false.obs;
  
  // API Server
  String defaultApiServer = AppConstants.serverBase;
  
  // Lista de turnos
  final List<String> shifts = [
    'Matutino (6:00 AM - 2:00 PM)',
    'Vespertino (2:00 PM - 10:00 PM)',
    'Nocturno (10:00 PM - 6:00 AM)',
    'Tiempo Completo (6:00 AM - 10:00 PM)',
  ];

  @override
  void onInit() {
    super.onInit();
    // Inicializar cualquier dato necesario
  }

  @override
  void onClose() {
    // Limpiar controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Cambiar rol del usuario
  void changeUserRole(UserRole role) {
    selectedRole.value = role;
  }

  /// Cambiar turno del usuario
  void changeShift(String? shift) {
    selectedShift.value = shift;
  }

  /// Cambiar estado activo
  void toggleActive(bool value) {
    isActive.value = value;
  }

  /// Mostrar/ocultar contraseña
  void toggleShowPassword() {
    showPassword.value = !showPassword.value;
  }

  /// Mostrar/ocultar confirmar contraseña
  void toggleShowConfirmPassword() {
    showConfirmPassword.value = !showConfirmPassword.value;
  }

  /// Limpiar formulario
  void clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    usernameController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    selectedRole.value = UserRole.secondary;
    selectedShift.value = null;
    isActive.value = true;
    showPassword.value = false;
    showConfirmPassword.value = false;
  }

  /// Validar formulario
  bool validateForm() {
    if (!formKey.currentState!.validate()) {
      _showError('Por favor completa todos los campos correctamente');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return false;
    }

    return true;
  }

  /// Crear usuario - consumir endpoint
  Future<void> createUser() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;

      // Mostrar loading
      Get.dialog(
        Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text(
                  'Creando usuario...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Por favor espera',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Preparar datos del usuario
      final userData = {
        "nombre": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
        "isAdmin": selectedRole.value == UserRole.principal,
      };

      print('📤 Enviando datos del usuario: $userData');

      // Hacer petición al endpoint
      Uri uri = Uri.parse('$defaultApiServer/usuarios/CrearUsuario/');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );

      print('📡 Respuesta del servidor - Código: ${response.statusCode}');
      print('📄 Cuerpo de respuesta: ${response.body}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true || response.statusCode == 201) {
          await _showSuccessDialog();
        } else {
          _showError(responseData['message'] ?? 'Error al crear el usuario');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? 'Datos inválidos');
      } else if (response.statusCode == 409) {
        _showError('El email o nombre de usuario ya existe');
      } else {
        _showError('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al crear usuario: $e');
      _showError('Error de conexión. Verifica tu conexión a internet.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mostrar diálogo de éxito
  Future<void> _showSuccessDialog() async {
    await QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.success,
      title: '¡Usuario Creado!',
      text: 'El usuario ${nameController.text} ha sido creado exitosamente.',
      confirmBtnText: 'Continuar',
      confirmBtnColor: Color(0xFF27AE60),
      onConfirmBtnTap: () {
        Get.back(); // Cerrar el QuickAlert
        _showOptionsDialog();
      },
    );
  }

  /// Mostrar opciones después de crear usuario
  void _showOptionsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Usuario Creado!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E1F08),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El usuario ${nameController.text} ha sido creado exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF5F2F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Nombre:', nameController.text),
                  _buildInfoRow('Email:', emailController.text),
                  _buildInfoRow('Usuario:', usernameController.text),
                  _buildInfoRow('Tipo:', selectedRole.value == UserRole.principal ? "Administrador" : "Empleado"),
                  _buildInfoRow('Estado:', isActive.value ? "Activo" : "Inactivo"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              clearForm(); // Limpiar formulario para crear otro
            },
            child: Text(
              'Crear Otro',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              Get.back(); // Volver a la pantalla anterior
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Terminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E1F08),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar error
  void _showError(String message) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: message,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }

  /// Validar email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Validar nombre
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el nombre completo';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Validar teléfono
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el teléfono';
    }
    if (value.length != 10) {
      return 'Debe tener 10 dígitos';
    }
    return null;
  }

  /// Validar nombre de usuario
  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el nombre de usuario';
    }
    if (value.length < 4) {
      return 'Debe tener al menos 4 caracteres';
    }
    return null;
  }

  /// Validar contraseña
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa la contraseña';
    }
    if (value.length < 6) {
      return 'Debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Validar confirmación de contraseña
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma la contraseña';
    }
    if (value != passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Obtener preview del usuario
  Map<String, String> get userPreview {
    return {
      'name': nameController.text.isNotEmpty ? nameController.text : 'Nombre del Usuario',
      'username': usernameController.text.isNotEmpty ? usernameController.text : 'usuario',
      'email': emailController.text.isNotEmpty ? emailController.text : 'email@ejemplo.com',
      'role': selectedRole.value == UserRole.principal ? 'Principal' : 'Secundario',
      'status': isActive.value ? 'Activo' : 'Inactivo',
    };
  }
}

// Enum para roles de usuario
enum UserRole {
  principal,
  secondary,
}

// Extensión para obtener el texto del rol
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.principal:
        return 'Usuario Principal';
      case UserRole.secondary:
        return 'Usuario Secundario';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.principal:
        return 'Administrador\nAcceso completo';
      case UserRole.secondary:
        return 'Empleado\nAcceso limitado';
    }
  }
  
  IconData get icon {
    switch (this) {
      case UserRole.principal:
        return Icons.admin_panel_settings;
      case UserRole.secondary:
        return Icons.person;
    }
  }
}
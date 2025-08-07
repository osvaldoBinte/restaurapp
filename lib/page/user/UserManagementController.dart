import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
class Usuario {
  final int? id;
  final String nombre;
  final String email;
  final bool isAdmin;
  final DateTime? fechaCreacion;

  Usuario({
     this.id,
    required this.nombre,
    required this.email,
    required this.isAdmin,
    this.fechaCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      fechaCreacion: json['fechaCreacion'] != null 
        ? DateTime.tryParse(json['fechaCreacion']) 
        : null,
    );
  }

  String get roleText => isAdmin ? 'Administrador' : 'Empleado';
  IconData get roleIcon => isAdmin ? Icons.admin_panel_settings : Icons.person;
  Color get roleColor => isAdmin ? Color(0xFF8B4513) : Colors.grey[600]!;
}

// Controller GetX para gestión de usuarios
class UserManagementController extends GetxController {
  // Observables
  var usuarios = <Usuario>[].obs;
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var searchQuery = ''.obs;
  var selectedFilter = UserFilter.todos.obs;
  
  // Controllers para edición
  final editNameController = TextEditingController();
  final editEmailController = TextEditingController();
  final editPasswordController = TextEditingController();
  final searchController = TextEditingController();
  
  // Controllers para creación
  final createNameController = TextEditingController();
  final createEmailController = TextEditingController();
  final createPasswordController = TextEditingController();
  // Form key para edición
  final editFormKey = GlobalKey<FormState>();
    final createFormKey = GlobalKey<FormState>();

  // Variables para edición
  var editingUser = Rxn<Usuario>();
  var editIsAdmin = false.obs;
  var showEditPassword = false.obs;
  
  var createIsAdmin = false.obs;
    // Variables para creación
  var showCreatePassword = false.obs;
  
  // API Server
  String defaultApiServer = AppConstants.serverBase;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    
    // Escuchar cambios en la búsqueda
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    editNameController.dispose();
    editEmailController.dispose();
    editPasswordController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Obtener usuarios filtrados
  List<Usuario> get filteredUsers {
    var filtered = usuarios.where((user) {
      // Filtro por búsqueda
      final matchesSearch = searchQuery.value.isEmpty ||
          user.nombre.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.value.toLowerCase());
      
      // Filtro por tipo
      final matchesFilter = selectedFilter.value == UserFilter.todos ||
          (selectedFilter.value == UserFilter.administradores && user.isAdmin) ||
          (selectedFilter.value == UserFilter.empleados && !user.isAdmin);
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Ordenar por nombre
    filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
    return filtered;
  }

Future<void> loadUsers() async {
  try {
    isLoading.value = true;

    Uri uri = Uri.parse('$defaultApiServer/usuarios/ListarUsuarios/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('📡 Listar usuarios - Código: ${response.statusCode}');
    print('📄 Respuesta: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // ✅ CORRECCIÓN: Tu JSON es directamente un array
      if (data is List) {
        // La respuesta es directamente una lista de usuarios
        usuarios.value = data.map((json) => Usuario.fromJson(json)).toList();
        print('✅ Usuarios cargados: ${usuarios.length}');
      } else if (data is Map && data['usuarios'] != null) {
        // Por si acaso cambia el formato en el futuro
        final usuariosList = data['usuarios'] as List;
        usuarios.value = usuariosList.map((json) => Usuario.fromJson(json)).toList();
        print('✅ Usuarios cargados: ${usuarios.length}');
      } else {
        print('❌ Formato de respuesta inesperado: ${data.runtimeType}');
        _showError('Formato de respuesta inválido');
      }
    } else {
      print('❌ Error HTTP: ${response.statusCode}');
      _showError('Error al cargar usuarios (${response.statusCode})');
    }

  } catch (e) {
    print('❌ Error al cargar usuarios: $e');
    _showError('Error de conexión al cargar usuarios');
  } finally {
    isLoading.value = false;
  }
}

  /// Refrescar lista de usuarios
  Future<void> refreshUsers() async {
    isRefreshing.value = true;
    await loadUsers();
    isRefreshing.value = false;
  }

  /// Eliminar usuario
 Future<void> deleteUser(Usuario user) async {
    try {
      // Mostrar confirmación
      final confirmed = await _showDeleteConfirmation(user);
      if (!confirmed) return;

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
                Text('Eliminando usuario...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Preparar datos para eliminación
      final deleteData = {
        "email": user.email,
      };

      print('📤 Eliminando usuario: $deleteData');

      Uri uri = Uri.parse('$defaultApiServer/usuarios/EliminarUsuario/');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(deleteData),
      );

      print('📡 Eliminar usuario - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminar de la lista local usando email como identificador
        usuarios.removeWhere((u) => u.email == user.email);
        
        _showSuccess('Usuario eliminado correctamente');
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Error al eliminar usuario');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al eliminar usuario: $e');
      _showError('Error de conexión al eliminar usuario');
    }
  }

  /// Preparar edición de usuario
  void startEditUser(Usuario user) {
    editingUser.value = user;
    editNameController.text = user.nombre;
    editEmailController.text = user.email;
    editPasswordController.clear(); // Contraseña vacía por defecto
    editIsAdmin.value = user.isAdmin;
    showEditPassword.value = false;
    
    _showEditDialog();
  }
  void showCreateUserDialog() {
    // Limpiar campos
    createNameController.clear();
    createEmailController.clear();
    createPasswordController.clear();
    createIsAdmin.value = false;
    showCreatePassword.value = false;
    
    _showCreateDialog();
  }
void _showCreateDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Crear Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: createFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          'Nombre Completo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: createNameController,
                          decoration: InputDecoration(
                            hintText: 'Nombre del usuario',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF8B4513)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre es requerido';
                            }
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Email
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: createEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'email@ejemplo.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.email, color: Color(0xFF8B4513)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El email es requerido';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Contraseña
                        Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        Obx(() => TextFormField(
                          controller: createPasswordController,
                          obscureText: !showCreatePassword.value,
                          decoration: InputDecoration(
                            hintText: 'Mínimo 6 caracteres',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF8B4513)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showCreatePassword.value ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF8B4513),
                              ),
                              onPressed: () {
                                showCreatePassword.value = !showCreatePassword.value;
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contraseña es requerida';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        )),
                        
                        SizedBox(height: 20),
                        
                        // Tipo de usuario
                        Text(
                          'Tipo de Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 12),
                        Obx(() => Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => createIsAdmin.value = true,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: createIsAdmin.value ? Color(0xFF8B4513) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: createIsAdmin.value ? Color(0xFF8B4513) : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: createIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Administrador',
                                        style: TextStyle(
                                          color: createIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => createIsAdmin.value = false,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: !createIsAdmin.value ? Color(0xFF8B4513) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !createIsAdmin.value ? Color(0xFF8B4513) : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: !createIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Empleado',
                                        style: TextStyle(
                                          color: !createIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Crear Usuario',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 Future<void> createUser() async {
    if (!createFormKey.currentState!.validate()) return;

    try {
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
                Text('Creando usuario...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Preparar datos
      final createData = {
        "nombre": createNameController.text.trim(),
        "email": createEmailController.text.trim(),
        "password": createPasswordController.text,
        "isAdmin": createIsAdmin.value,
      };

      print('📤 Creando usuario: $createData');

      Uri uri = Uri.parse('$defaultApiServer/usuarios/CrearUsuario/');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(createData),
      );

      print('📡 Crear usuario - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cerrar diálogo de creación
        Get.back();
        
        _showSuccess('Usuario creado correctamente');
        
        // Recargar lista de usuarios
        await loadUsers();
        
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Error al crear usuario');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al crear usuario: $e');
      _showError('Error de conexión al crear usuario');
    }
  }
  /// Modificar usuario
  Future<void> updateUser() async {
    if (!editFormKey.currentState!.validate()) return;

    try {
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
                Text('Actualizando usuario...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Preparar datos
      final updateData = {
        "email": editEmailController.text.trim(),
        "nombre": editNameController.text.trim(),
        "isAdmin": editIsAdmin.value,
      };

      // Agregar contraseña solo si se proporcionó
      if (editPasswordController.text.isNotEmpty) {
        updateData["password"] = editPasswordController.text;
      }

      print('📤 Actualizando usuario: $updateData');

      Uri uri = Uri.parse('$defaultApiServer/usuarios/ModificarUsuario/');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      print('📡 Modificar usuario - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200) {
        // Cerrar diálogo de edición
        Get.back();
        
        // Actualizar usuario en la lista local
        final index = usuarios.indexWhere((u) => u.id == editingUser.value!.id);
        if (index != -1) {
          usuarios[index] = Usuario(
            nombre: editNameController.text.trim(),
            email: editEmailController.text.trim(),
            isAdmin: editIsAdmin.value,
            fechaCreacion: editingUser.value!.fechaCreacion,
          );
        }
        
        _showSuccess('Usuario actualizado correctamente');
        
        // Limpiar datos de edición
        editingUser.value = null;
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Error al actualizar usuario');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al actualizar usuario: $e');
      _showError('Error de conexión al actualizar usuario');
    }
  }

  /// Cambiar filtro
  void changeFilter(UserFilter filter) {
    selectedFilter.value = filter;
  }

  /// Limpiar búsqueda
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Mostrar diálogo de confirmación para eliminar
  Future<bool> _showDeleteConfirmation(Usuario user) async {
    bool confirmed = false;
    
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmar Eliminación',
                style: TextStyle(
                  fontSize: 18,
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
              '¿Estás seguro de que deseas eliminar este usuario?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    user.roleText,
                    style: TextStyle(
                      color: user.roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              Get.back();
            },
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              confirmed = true;
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    return confirmed;
  }

  /// Mostrar diálogo de edición
  void _showEditDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editar Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        editingUser.value = null;
                        Get.back();
                      },
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: editFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          'Nombre Completo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: editNameController,
                          decoration: InputDecoration(
                            hintText: 'Nombre del usuario',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF8B4513)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre es requerido';
                            }
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Email
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: editEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'email@ejemplo.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.email, color: Color(0xFF8B4513)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El email es requerido';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Contraseña (opcional)
                        Text(
                          'Nueva Contraseña (opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 8),
                        Obx(() => TextFormField(
                          controller: editPasswordController,
                          obscureText: !showEditPassword.value,
                          decoration: InputDecoration(
                            hintText: 'Dejar vacío para mantener actual',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF8B4513)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showEditPassword.value ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF8B4513),
                              ),
                              onPressed: () {
                                showEditPassword.value = !showEditPassword.value;
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty && value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        )),
                        
                        SizedBox(height: 20),
                        
                        // Tipo de usuario
                        Text(
                          'Tipo de Usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        SizedBox(height: 12),
                        Obx(() => Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => editIsAdmin.value = true,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: editIsAdmin.value ? Color(0xFF8B4513) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: editIsAdmin.value ? Color(0xFF8B4513) : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: editIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Administrador',
                                        style: TextStyle(
                                          color: editIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => editIsAdmin.value = false,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: !editIsAdmin.value ? Color(0xFF8B4513) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !editIsAdmin.value ? Color(0xFF8B4513) : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: !editIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Empleado',
                                        style: TextStyle(
                                          color: !editIsAdmin.value ? Colors.white : Color(0xFF8B4513),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          editingUser.value = null;
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: updateUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Guardar Cambios',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostrar mensaje de éxito
  void _showSuccess(String message) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.success,
      title: 'Éxito',
      text: message,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFF27AE60),
    );
  }

  /// Mostrar mensaje de error
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
}

// Enum para filtros
enum UserFilter {
  todos,
  administradores,
  empleados,
  activos,
  inactivos,
}

extension UserFilterExtension on UserFilter {
  String get displayName {
    switch (this) {
      case UserFilter.todos:
        return 'Todos';
      case UserFilter.administradores:
        return 'Administradores';
      case UserFilter.empleados:
        return 'Empleados';
      case UserFilter.activos:
        return 'Activos';
      case UserFilter.inactivos:
        return 'Inactivos';
    }
  }
  
  IconData get icon {
    switch (this) {
      case UserFilter.todos:
        return Icons.group;
      case UserFilter.administradores:
        return Icons.admin_panel_settings;
      case UserFilter.empleados:
        return Icons.person;
      case UserFilter.activos:
        return Icons.check_circle;
      case UserFilter.inactivos:
        return Icons.cancel;
    }
  }
}
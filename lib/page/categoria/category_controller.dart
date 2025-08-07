import 'dart:convert';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:restaurapp/common/constants/constants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';



class CategoryController extends GetxController {
  // Estado de carga
  var isLoading = false.obs;
  
  // Lista de categorías (opcional para mostrar las categorías existentes)
  var categories = <Map<String, dynamic>>[].obs;
  
  // Mensaje de respuesta
  var message = ''.obs;
  
  String defaultApiServer = AppConstants.serverBase;

  /// Método para crear una nueva categoría
  Future<bool> crearCategoriaMenu({
    required String nombre,
    required String descripcion,
  }) async {
    try {
      // Cambiar estado de carga
      isLoading.value = true;
      message.value = '';

      // Preparar los datos
      Map<String, dynamic> data = {
        "nombre": nombre,
        "descripcion": descripcion,
      };

      // Crear la URI
      Uri uri = Uri.parse('$defaultApiServer/menu/crearCategoriaMenu/');

      print('🌐 Enviando POST a: $uri');
      print('📝 Datos a enviar: ${jsonEncode(data)}');

      // Realizar la petición POST
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Agregar headers adicionales si es necesario (como Authorization)
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      // Verificar el código de respuesta
      if (response.statusCode == 201) {
        // Éxito
        final responseData = jsonDecode(response.body);
        
        message.value = 'Categoría creada exitosamente';
        
        // Opcional: Agregar la nueva categoría a la lista local
        categories.add({
          'nombre': nombre,
          'descripcion': descripcion,
          'id': responseData['id'] ?? DateTime.now().millisecondsSinceEpoch,
        });

        // Mostrar alerta de éxito con QuickAlert
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Éxito!',
          text: 'Categoría "$nombre" creada correctamente',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF8B4513),
          autoCloseDuration: Duration(seconds: 3),
        );

        return true;

      } else {
        // Error del servidor
        String errorMessage = 'Error del servidor (${response.statusCode})';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // Si no se puede parsear la respuesta de error
          errorMessage = 'Error: ${response.reasonPhrase}';
        }

        message.value = errorMessage;
        
        // Mostrar alerta de error con QuickAlert
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error del Servidor',
          text: errorMessage,
          confirmBtnText: 'Entendido',
          confirmBtnColor: Color(0xFFE74C3C),
        );

        return false;
      }

    } catch (e) {
      // Error de conexión o excepción
      String errorMessage = 'Error de conexión: ${e.toString()}';
      message.value = errorMessage;

      print('🚨 Error en crearCategoriaMenu: $e');

      // Mostrar alerta de error de conexión con QuickAlert
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar al servidor.\nVerifica tu conexión a internet.',
        confirmBtnText: 'Reintentar',
        confirmBtnColor: Color(0xFFE74C3C),
        showCancelBtn: true,
        cancelBtnText: 'Cancelar',
      );

      return false;

    } finally {
      // Siempre cambiar el estado de carga al final
      isLoading.value = false;
    }
  }

  /// Método para obtener todas las categorías (opcional)
  Future<void> obtenerCategorias() async {
    try {
      isLoading.value = true;

      Uri uri = Uri.parse('$defaultApiServer/menu/categorias/');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        categories.value = data.cast<Map<String, dynamic>>();
      } else {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.warning,
          title: 'Error al Cargar',
          text: 'No se pudieron obtener las categorías',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFF39C12),
        );
      }

    } catch (e) {
      print('Error al obtener categorías: $e');
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Error al obtener las categorías',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Método para limpiar mensajes
  void clearMessage() {
    message.value = '';
  }

  /// Método para validar datos antes de enviar
  bool validarDatos({required String nombre, required String descripcion}) {
    if (nombre.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Campo Requerido',
        text: 'El nombre es requerido',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }

    if (descripcion.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Campo Requerido',
        text: 'La descripción es requerida',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }

    if (nombre.length < 2) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Validación',
        text: 'El nombre debe tener al menos 2 caracteres',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }

    return true;
  }

  /// Método conveniente que combina validación y creación
  Future<bool> crearCategoriaConValidacion({
    required String nombre,
    required String descripcion,
  }) async {
    // Primero validar
    if (!validarDatos(nombre: nombre, descripcion: descripcion)) {
      return false;
    }

    // Luego crear
    return await crearCategoriaMenu(nombre: nombre, descripcion: descripcion);
  }

  /// Método para mostrar confirmación antes de crear
  Future<void> mostrarConfirmacionCrear({
    required String nombre,
    required String descripcion,
  }) async {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Creación',
      text: '¿Estás seguro de crear la categoría "$nombre"?',
      confirmBtnText: 'Crear',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF8B4513),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el diálogo de confirmación
        await crearCategoriaConValidacion(nombre: nombre, descripcion: descripcion);
      },
    );
  }

  /// Método para mostrar información de la categoría
  void mostrarInfoCategoria(Map<String, dynamic> categoria) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.info,
      title: categoria['nombre'] ?? 'Categoría',
      text: categoria['descripcion'] ?? 'Sin descripción',
      confirmBtnText: 'Cerrar',
      confirmBtnColor: Color(0xFF3498DB),
    );
  }

  /// Método para mostrar carga con QuickAlert
  void mostrarCargando() {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.loading,
      title: 'Guardando...',
      text: 'Creando la categoría',
    );
  }
}

// Ejemplo de uso en un Widget
/*
class CreateCategoryScreen extends StatelessWidget {
  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Categoría')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: categoryController.isLoading.value 
                ? null 
                : () async {
                    final success = await categoryController.crearCategoriaConValidacion(
                      nombre: nameController.text.trim(),
                      descripcion: descriptionController.text.trim(),
                    );
                    
                    if (success) {
                      // Limpiar campos
                      nameController.clear();
                      descriptionController.clear();
                      
                      // Opcional: Navegar de vuelta
                      // Get.back();
                    }
                  },
              child: categoryController.isLoading.value 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Guardando...'),
                    ],
                  )
                : Text('Guardar Categoría'),
            )),
          ],
        ),
      ),
    );
  }
}
*/
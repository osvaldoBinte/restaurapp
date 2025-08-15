import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/categoria/listarcategoria/EditCategoryModalContent.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Controller GetX para listar categorías
class CategoryListController extends GetxController {
  var isLoading = false.obs;
  var categories = <Map<String, dynamic>>[].obs;
  var filteredCategories = <Map<String, dynamic>>[].obs; // Nueva variable observable
  var message = ''.obs;
  var isDeleting = false.obs;
  var isUpdating = false.obs;
  String defaultApiServer = AppConstants.serverBase;

  @override
  void onInit() {
    super.onInit();
    listarCategorias(); // Cargar categorías al iniciar
    
    // Escuchar cambios en categories para actualizar filteredCategories
    ever(categories, (List<Map<String, dynamic>> categoriesList) {
      filteredCategories.value = List.from(categoriesList);
    });
  }
  Future<bool> modificarCategoria({
    required int id,
    required String nombre,
    required String descripcion,
  }) async {
    try {
      isUpdating.value = true;
      message.value = '';

      // Validaciones
      if (nombre.trim().isEmpty) {
        _mostrarError('El nombre de la categoría es requerido');
        return false;
      }

      if (descripcion.trim().isEmpty) {
        _mostrarError('La descripción de la categoría es requerida');
        return false;
      }

      if (nombre.trim().length < 2) {
        _mostrarError('El nombre debe tener al menos 2 caracteres');
        return false;
      }

      // Preparar datos para enviar
      final Map<String, dynamic> categoriaData = {
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
      };

      Uri uri = Uri.parse('$defaultApiServer/menu/modificarCategoriaMenu/$id/');

      print('🔄 Modificando categoría en: $uri');
      print('📤 Datos a enviar: $categoriaData');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(categoriaData),
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        // Actualizar la categoría en la lista local
        final index = categories.indexWhere((cat) => cat['id'] == id);
        if (index != -1) {
          categories[index] = {
            ...categories[index],
            'nombreCategoria': nombre.trim(),
            'descripcion': descripcion.trim(),
          };
          // Esto automáticamente actualizará filteredCategories por el listener en onInit
        }

        message.value = 'Categoría modificada exitosamente';
        
        // Mostrar mensaje de éxito
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Actualizada!',
          text: 'La categoría ha sido modificada correctamente',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF27AE60),
          autoCloseDuration: Duration(seconds: 2),
        );

        // Recargar datos del menú
        await _recargarDatosMenu();

        return true;

      } else {
        String errorMessage = 'Error al modificar categoría (${response.statusCode})';
        
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error: ${response.reasonPhrase}';
        }

        message.value = errorMessage;
        _mostrarError(errorMessage);
        return false;
      }

    } catch (e) {
      String errorMessage = 'Error de conexión: ${e.toString()}';
      message.value = errorMessage;

      print('🚨 Error en modificarCategoria: $e');
      _mostrarError('No se pudo conectar al servidor para modificar la categoría.');
      return false;

    } finally {
      isUpdating.value = false;
    }
  }
   void mostrarModalEdicion(Map<String, dynamic> categoria) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle del modal
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header del modal
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Editar Categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // Contenido del modal
              Expanded(
                child: EditCategoryModalContent(categoria: categoria),
              ),
            ],
          ),
        ),
      ),
    );
  }
    Future<void> _recargarDatosMenu() async {
    try {
      // Recargar la lista de categorías
      await listarCategorias();
      
      // Buscar si existe CreateOrderController y recargar
      if (Get.isRegistered<CreateOrderController>()) {
        final CreateOrderController controller = Get.find<CreateOrderController>();
        await controller.cargarDatosIniciales();
        print('✅ Datos del menú recargados');
      }
    } catch (e) {
      print('⚠️ Error al recargar datos del menú: $e');
    }
  }

  /// ✅ NUEVO: Método auxiliar para mostrar errores
void _mostrarError(String mensaje) {
  // ✅ CORRECCIÓN: Verificar contexto antes de mostrar alert
  final context = Get.context;
  if (context != null) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  } else {
    // Fallback: imprimir en consola si no hay contexto
    print('❌ ERROR: $mensaje');
  }
}
  /// Método para obtener todas las categorías
  Future<void> listarCategorias() async {
    try {
      isLoading.value = true;
      message.value = '';

      Uri uri = Uri.parse('$defaultApiServer/menu/listarCategorias/');

      print('🌐 Obteniendo categorías desde: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        categories.value = data.cast<Map<String, dynamic>>();
        
        message.value = 'Categorías cargadas exitosamente';
        
        if (categories.isEmpty) {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.info,
            title: 'Sin Categorías',
            text: 'No hay categorías registradas aún',
            confirmBtnText: 'OK',
            confirmBtnColor: Color(0xFF3498DB),
          );
        }

      } else {
        String errorMessage = 'Error al cargar categorías (${response.statusCode})';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error: ${response.reasonPhrase}';
        }

        message.value = errorMessage;
        
      }

    } catch (e) {
      String errorMessage = 'Error de conexión: ${e.toString()}';
      message.value = errorMessage;

      print('🚨 Error en listarCategorias: $e');

      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar al servidor.\nVerifica tu conexión a internet.',
        confirmBtnText: 'Reintentar',
        confirmBtnColor: Color(0xFFE74C3C),
        showCancelBtn: true,
        cancelBtnText: 'Cancelar',
        onConfirmBtnTap: () {
          Get.back();
          listarCategorias();
        },
      );

    } finally {
      isLoading.value = false;
    }
  }

  /// Método para eliminar una categoría
  Future<bool> eliminarCategoria(int id) async {
    try {
      isDeleting.value = true;

      Uri uri = Uri.parse('$defaultApiServer/menu/eliminarCategoriaMenu/$id/');

      print('🌐 Eliminando categoría desde: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminar de la lista local
        categories.removeWhere((categoria) => categoria['id'] == id);
        
        message.value = 'Categoría eliminada exitosamente';
        final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Eliminada!',
          text: 'La categoría ha sido eliminada correctamente',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF27AE60),
          autoCloseDuration: Duration(seconds: 2),
        );

        return true;

      } else {
        String errorMessage = 'Error al eliminar categoría (${response.statusCode})';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error: ${response.reasonPhrase}';
        }

        message.value = errorMessage;
        
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error al Eliminar',
          text: errorMessage,
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );

        return false;
      }

    } catch (e) {
      String errorMessage = 'Error de conexión: ${e.toString()}';
      message.value = errorMessage;

      print('🚨 Error en eliminarCategoria: $e');

      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar al servidor para eliminar la categoría.',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );

      return false;

    } finally {
      isDeleting.value = false;
    }
  }

  /// Método para confirmar eliminación
  void confirmarEliminacion(Map<String, dynamic> categoria) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Eliminación',
      text: '¿Estás seguro de eliminar la categoría "${categoria['nombreCategoria']}"?\n\nEsta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el diálogo de confirmación
        await eliminarCategoria(categoria['id']);
      },
    );
  }

  /// Método para refrescar la lista
  Future<void> refrescarLista() async {
    await listarCategorias();
  }

  /// Método para filtrar categorías (nuevo método)
  void filtrarCategorias(String query) {
    if (query.isEmpty) {
      filteredCategories.value = List.from(categories);
    } else {
      filteredCategories.value = categories.where((categoria) {
        final nombre = categoria['nombreCategoria']?.toLowerCase() ?? '';
        final descripcion = categoria['descripcion']?.toLowerCase() ?? '';
        return nombre.contains(query.toLowerCase()) || 
               descripcion.contains(query.toLowerCase());
      }).toList();
    }
  }

  /// Método para buscar categorías (mantenido para compatibilidad)
  List<Map<String, dynamic>> buscarCategorias(String query) {
    if (query.isEmpty) return categories;
    
    return categories.where((categoria) {
      final nombre = categoria['nombreCategoria']?.toLowerCase() ?? '';
      final descripcion = categoria['descripcion']?.toLowerCase() ?? '';
      return nombre.contains(query.toLowerCase()) || 
             descripcion.contains(query.toLowerCase());
    }).toList();
  }


  Future<bool> actualizarOrdenCategoria(int categoriaId, int nuevoOrden) async {
  try {
    print('🔄 desde Actualizando orden de categoría $categoriaId a posición $nuevoOrden');

    Uri uri = Uri.parse('$defaultApiServer/menu/actualizarOrdenCategoriaMenu/$categoriaId/');
    
    final Map<String, dynamic> body = {
      'ordenMenu': nuevoOrden,
    };

    print('📡 URL: $uri');
    print('📤 Body: $body');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('📡 Código de respuesta: ${response.statusCode}');
    print('📄 Respuesta del servidor: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ desde Orden actualizado correctamente');
      print('📄 desde Respuesta: ${response.body}');
      
      // ✅ CORRECCIÓN: Verificar si el controller existe antes de usarlo
      try {
        if (Get.isRegistered<CreateOrderController>()) {
          final CreateOrderController controller = Get.find<CreateOrderController>();
          await controller.obtenerCategorias();
          print('✅ Datos del menú recargados');
        }
      } catch (e) {
        print('⚠️ Error al recargar CreateOrderController: $e');
        // No detener el flujo si falla esto
      }
      
      return true;
    } else {
      String errorMessage = 'Error al actualizar orden (${response.statusCode})';
      
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'Error: ${response.reasonPhrase ?? 'Desconocido'}';
      }

      print('❌ Error: $errorMessage');
      _mostrarError(errorMessage);
      return false;
    }

  } catch (e) {
    print('❌ Error de conexión: $e');
    _mostrarError('Error de conexión al actualizar el orden');
    return false;
  }
}
Future<void> actualizarOrdenCategorias(List<Map<String, dynamic>> categoriasOrdenadas) async {
  try {
   // isLoading.value = true;
    
    // Actualizar orden en lote
    for (int i = 0; i < categoriasOrdenadas.length; i++) {
      final categoria = categoriasOrdenadas[i];
      final nuevoOrden = i + 1; // Orden basado en 1
       print('desde  actualizarOrdenCategorias');
      await actualizarOrdenCategoria(categoria['id'], nuevoOrden);
      
    }
    
    // Recargar la lista para reflejar los cambios
   
    
    
  } catch (e) {
    print('❌ Error al actualizar orden múltiple: $e');
    _mostrarError('Error al guardar el nuevo orden');
  } finally {
    isLoading.value = false;
  }
}
}
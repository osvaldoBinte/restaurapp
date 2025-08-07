import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Controller GetX para listar categorías
class CategoryListController extends GetxController {
  var isLoading = false.obs;
  var categories = <Map<String, dynamic>>[].obs;
  var filteredCategories = <Map<String, dynamic>>[].obs; // Nueva variable observable
  var message = ''.obs;
  var isDeleting = false.obs;
  
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
        
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error al Cargar',
          text: errorMessage,
          confirmBtnText: 'Reintentar',
          confirmBtnColor: Color(0xFFE74C3C),
          onConfirmBtnTap: () {
            Get.back();
            listarCategorias();
          },
        );
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
        
          final OrdersController controller3 = Get.put(OrdersController());
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
}
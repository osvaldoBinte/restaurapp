import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class MesaService extends GetxService {
  // 🌐 URL base de la API

  String defaultApiServer = AppConstants.serverBase;
  
  // 🔄 Estado de carga
  final RxBool isLoading = false.obs;
  
  /// 🍽️ Atender toda la mesa
  /// 
  /// Consume el endpoint para marcar todos los pedidos de una mesa como atendidos
  /// @param mesaId - ID de la mesa a atender
  /// @return Future<bool> - true si fue exitoso, false si hubo error
  Future<bool> atenderTodaMesa(int mesaId) async {
    try {
      isLoading.value = true;
      
      // 📡 Construir URL con el ID de la mesa
      final url = Uri.parse('$defaultApiServer/mesas/$mesaId/atender-todo/');
      
      print('🔄 Atendiendo mesa $mesaId en: $url');
      
      // 🚀 Realizar petición POST/PUT (ajusta según tu API)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Si necesitas enviar datos adicionales, agrégalos aquí
        body: json.encode({
          'mesa_id': mesaId,
          'accion': 'atender_todo',
        }),
      );
      
      print('📡 Respuesta: ${response.statusCode}');
      print('📄 Body: ${response.body}');
      
      // ✅ Verificar si la petición fue exitosa
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 🎉 Éxito - Parsear respuesta si es necesario
        final responseData = json.decode(response.body);
        
        // Mostrar mensaje de éxito
        Get.snackbar(
          '✅ Éxito',
          'Mesa $mesaId atendida completamente',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green[700],
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 2),
          icon: Icon(Icons.check_circle, color: Colors.green[700]),
        );
        
        return true;
      } else {
        // ❌ Error del servidor
        _handleError(response.statusCode, response.body, mesaId);
        return false;
      }
      
    } catch (e) {
      // 🚨 Error de conexión o excepción
      print('❌ Error al atender mesa $mesaId: $e');
      
      Get.snackbar(
        '❌ Error de Conexión',
        'No se pudo conectar con el servidor',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[700],
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.red[700]),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> atenderMesaConConfirmacion(int mesaId) async {
    bool success = await atenderTodaMesa(mesaId);
        
        if (success) {
          // 🔄 Refrescar datos si es exitoso
          final ordersController = Get.find<OrdersController>();
          await ordersController.refrescarDatos();
        }
  }
  
  /// 🎯 Método alternativo con diferentes HTTP methods
  /// 
  /// Si tu API usa PUT en lugar de POST
  Future<bool> atenderTodaMesaPUT(int mesaId) async {
    try {
      isLoading.value = true;
      
      final url = Uri.parse('$defaultApiServer/mesas/$mesaId/atender-todo/');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'mesa_id': mesaId}),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
      
    } catch (e) {
      print('Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 🎯 Método para GET si no requiere body
  Future<bool> atenderTodaMesaGET(int mesaId) async {
    try {
      isLoading.value = true;
      
      final url = Uri.parse('$defaultApiServer/mesas/$mesaId/atender-todo/');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
      
    } catch (e) {
      print('Error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// ⚠️ Manejo de errores
  void _handleError(int statusCode, String responseBody, int mesaId) {
    String errorMessage;
    
    switch (statusCode) {
      case 400:
        errorMessage = 'Datos inválidos para la mesa $mesaId';
        break;
      case 404:
        errorMessage = 'Mesa $mesaId no encontrada';
        break;
      case 500:
        errorMessage = 'Error interno del servidor';
        break;
      default:
        errorMessage = 'Error desconocido (Código: $statusCode)';
    }
    
    Get.snackbar(
      '❌ Error',
      errorMessage,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red[700],
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 3),
      icon: Icon(Icons.error_outline, color: Colors.red[700]),
    );
  }
}
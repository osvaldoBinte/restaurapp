import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:restaurapp/common/constants/constants.dart';

// ============================================================================
// ORDEN SERVICE - Servicio para manejo de órdenes y pedidos
// ============================================================================

class OrdenService {
  final String _baseUrl = AppConstants.serverBase;

  // ==========================================================================
  // PEDIDOS PENDIENTES
  // ==========================================================================

  /// Obtener lista de pedidos pendientes (para carousel)
  Future<Map<String, dynamic>> obtenerPedidosPendientes() async {
    try {
      Uri uri = Uri.parse('$_baseUrl/ordenes/obtenerListaPedidosPendientes/');

      print('\n' + '=' * 80);
      print('🎠 CAROUSEL - obtenerListaPedidosPendientes');
      print('=' * 80);
      print('URL: $uri');
      print('Timestamp: ${DateTime.now().toIso8601String()}');
      print('=' * 80 + '\n');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body:');
      print(response.body);
      print('=' * 80 + '\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // CASO 1: Sin pedidos
        if (data.containsKey('message') && 
            data['message'].toString().contains('No hay pedidos')) {
          print('ℹ️ Backend reporta: ${data['message']}');
          return {
            'success': true,
            'pedidosPorMesa': [],
            'message': data['message'],
          };
        }

        // CASO 2: Con pedidos
        if (data['success'] == true && data.containsKey('pedidosPorMesa')) {
          print('✅ Pedidos pendientes obtenidos correctamente');
          return {
            'success': true,
            'pedidosPorMesa': data['pedidosPorMesa'],
          };
        }

        // CASO 3: Estructura alternativa
        if (data.containsKey('pedidosPorMesa')) {
          return {
            'success': true,
            'pedidosPorMesa': data['pedidosPorMesa'],
          };
        }

        // CASO 4: Estructura desconocida
        print('⚠️ Estructura de respuesta inesperada');
        return {
          'success': false,
          'error': 'Estructura de respuesta inesperada',
        };
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('🚨 Error en obtenerPedidosPendientes: $e');
      print('Stack trace: $stackTrace\n');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==========================================================================
  // MESAS CON PEDIDOS ABIERTOS
  // ==========================================================================

  /// Obtener mesas con pedidos abiertos (para lista de mesas)
  Future<Map<String, dynamic>> obtenerMesasConPedidosAbiertos() async {
    try {
      print('\n' + '=' * 80);
      print('📋 LISTA DE MESAS - obtenerMesasConPedidosAbiertos');
      print('=' * 80);

      final response = await http.get(
        Uri.parse('$_baseUrl/ordenes/obtenerMesasConPedidosAbiertos/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // CASO 1: Sin mesas
        if (data.containsKey('message') && 
            data['message'].toString().contains('No hay mesas')) {
          print('ℹ️ Backend reporta: ${data['message']}');
          return {
            'success': true,
            'mesasOcupadas': [],
            'message': data['message'],
          };
        }

        // CASO 2: Con mesas
        if (data.containsKey('success') && data['success'] == true) {
          if (!data.containsKey('mesasOcupadas')) {
            return {
              'success': false,
              'error': 'Respuesta sin campo "mesasOcupadas"',
            };
          }

          print('✅ Mesas con pedidos obtenidas correctamente');
          return {
            'success': true,
            'mesasOcupadas': data['mesasOcupadas'],
          };
        }

        return {
          'success': false,
          'error': data.containsKey('message') 
              ? data['message'] 
              : 'Respuesta inesperada',
        };
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en obtenerMesasConPedidosAbiertos: $e\n');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==========================================================================
  // ACTUALIZAR ESTADO DE ORDEN
  // ==========================================================================

  /// Actualizar estado de un detalle de orden
  Future<Map<String, dynamic>> actualizarEstadoOrden(
    int detalleId, 
    String nuevoEstado,
  ) async {
    try {
      Uri uri = Uri.parse('$_baseUrl/ordenes/actualizarStatusorden/$detalleId/');

      print('\n' + '=' * 80);
      print('🔄 ACTUALIZAR ESTADO ORDEN');
      print('=' * 80);
      print('URL: $uri');
      print('Detalle ID: $detalleId');
      print('Nuevo Estado: $nuevoEstado');
      print('=' * 80 + '\n');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'status': nuevoEstado,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || response.statusCode == 200) {
          print('✅ Estado actualizado correctamente');
          return {
            'success': true,
            'data': data,
          };
        } else {
          return {
            'success': false,
            'error': 'Error en la respuesta del servidor',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==========================================================================
  // ELIMINAR DETALLE DE PEDIDO
  // ==========================================================================

  /// Eliminar un detalle de pedido específico
  Future<Map<String, dynamic>> eliminarDetallePedido(int detalleId) async {
    try {
      Uri uri = Uri.parse('$_baseUrl/ordenes/pedido/$detalleId/detalles/eliminar/');

      print('\n' + '=' * 80);
      print('🗑️ ELIMINAR DETALLE DE PEDIDO');
      print('=' * 80);
      print('URL: $uri');
      print('Detalle ID: $detalleId');
      print('Timestamp: ${DateTime.now().toIso8601String()}');
      print('=' * 80 + '\n');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('=' * 80 + '\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Detalle $detalleId eliminado correctamente');
          return {
            'success': true,
            'message': data['message'] ?? 'Detalle eliminado correctamente',
          };
        } else {
          final mensaje = data['message'] ?? 'Error desconocido';
          print('❌ Error en respuesta: $mensaje');
          return {
            'success': false,
            'error': mensaje,
          };
        }
      } else if (response.statusCode == 404) {
        print('❌ Detalle no encontrado (404)');
        return {
          'success': false,
          'error': 'El detalle no existe o ya fue eliminado',
        };
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        return {
          'success': false,
          'error': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e, stackTrace) {
      print('🚨 Error en eliminarDetallePedido: $e');
      print('Stack trace: $stackTrace\n');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==========================================================================
  // COMPLETAR Y OBTENER TOTAL DE PEDIDO
  // ==========================================================================

  /// Completar detalle y obtener total del pedido
  Future<Map<String, dynamic>> completarYTotalPedido(int detalleId) async {
    try {
      Uri uri = Uri.parse('$_baseUrl/ordenes/CompletarYTotalPedido/$detalleId/');

      print('\n' + '=' * 80);
      print('💰 COMPLETAR Y TOTAL PEDIDO');
      print('=' * 80);
      print('URL: $uri');
      print('Detalle ID: $detalleId');
      print('=' * 80 + '\n');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Pedido completado - Total: ${data['total']}');
          return {
            'success': true,
            'detalleId': detalleId,
            'pedidoId': data['pedidoId'],
            'total': data['total'],
          };
        } else {
          return {
            'success': false,
            'detalleId': detalleId,
            'error': 'Respuesta no exitosa del servidor',
          };
        }
      } else {
        return {
          'success': false,
          'detalleId': detalleId,
          'error': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error al completar pedido: $e');
      return {
        'success': false,
        'detalleId': detalleId,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==========================================================================
  // ATENDER TODOS LOS PEDIDOS DE UNA MESA
  // ==========================================================================

  /// Atender todos los pedidos pendientes de una mesa
  Future<Map<String, dynamic>> atenderTodosMesa(int numeroMesa) async {
    try {
      Uri uri = Uri.parse('$_baseUrl/mesas/$numeroMesa/atender-todo/');

      print('\n' + '=' * 80);
      print('✅ ATENDER TODOS LOS PEDIDOS - MESA $numeroMesa');
      print('=' * 80);
      print('URL: $uri');
      print('=' * 80 + '\n');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'numeroMesa': numeroMesa,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      print('=' * 80 + '\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || response.statusCode == 200) {
          print('✅ Mesa $numeroMesa atendida correctamente');
          return {
            'success': true,
            'message': data['message'] ?? 'Mesa atendida correctamente',
            'data': data,
          };
        } else {
          final mensaje = data['message'] ?? data['error'] ?? 'Error desconocido';
          return {
            'success': false,
            'error': mensaje,
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Mesa no encontrada en el servidor',
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final mensaje = data['message'] ?? data['error'] ?? 'Solicitud inválida';
        return {
          'success': false,
          'error': mensaje,
        };
      } else {
        return {
          'success': false,
          'error': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error en atenderTodosMesa: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==========================================================================
  // LIBERAR MESA
  // ==========================================================================

  /// Liberar una mesa específica
  Future<Map<String, dynamic>> liberarMesa(int mesaId) async {
    try {
      Uri uri = Uri.parse('$_baseUrl/mesas/liberarMesa/$mesaId/');

      print('\n' + '=' * 80);
      print('🔓 LIBERAR MESA');
      print('=' * 80);
      print('URL: $uri');
      print('Mesa ID: $mesaId');
      print('=' * 80 + '\n');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': true}),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Mesa $mesaId liberada correctamente');
          return {
            'success': true,
            'message': data['message'] ?? 'Mesa liberada correctamente',
          };
        } else {
          return {
            'success': false,
            'error': data['message'] ?? 'Error desconocido',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Error del servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error al liberar mesa: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==========================================================================
  // ALERTAS Y UI HELPERS
  // ==========================================================================

  /// Mostrar alerta de error
  void mostrarError(String titulo, String mensaje) {
    if (Get.context == null) return;

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: titulo,
      text: mensaje,
      confirmBtnText: 'Entendido',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }

  /// Mostrar alerta de éxito
  void mostrarExito(String titulo, String mensaje, {int duracion = 2}) {
    if (Get.context == null) return;

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.success,
      title: titulo,
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFF27AE60),
      autoCloseDuration: Duration(seconds: duracion),
    );
  }

  /// Mostrar loading dialog
  void mostrarLoading(String mensaje) {
    if (Get.context == null) return;

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
              Text(mensaje),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Cerrar loading dialog
  void cerrarLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'dart:async';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/OrderStatusModal.dart';
import 'package:restaurapp/page/orders/historial/HistorialDetailsModal.dart';
import 'package:restaurapp/page/orders/modaltable/TableDetailsModal.dart';
import 'package:restaurapp/page/orders/orders_page.dart';

// Controller GetX para historial de ventas - SIN PEDIDOS PENDIENTES
class HistorialController extends GetxController {
  var isLoading = false.obs;
  var isLoadingModal = false.obs;
  var historialVentas = <Map<String, dynamic>>[].obs; // 🆕 Reemplaza pedidosPendientes
  var selectedTableData = <Map<String, dynamic>>[].obs;
  var maxPaginasEstimadas = 10.obs; // Puedes ajustar este valor

  // Variables para paginación del historial
  var currentPage = 1.obs;
  var hasMoreData = true.obs;
  var fechaConsulta = DateTime.now().toString().split(' ')[0].obs; // 🆕 Fecha actual
  var pageSize = 3.obs; // Tamaño de página personalizable
  var totalPages = 1.obs; // Total de páginas
  var showPaginationControls = true.obs; // Mostrar/ocultar controles
  final List<int> pageSizeOptions = [1, 2, 3, 4, 5, 10, 15];

  String defaultApiServer = AppConstants.serverBase;

  // Variables para el timer
  Timer? _autoRefreshTimer;
  var isAutoRefreshEnabled = true.obs;
  final int autoRefreshInterval = 30; // 🆕 Reducido a 30 segundos para historial

  @override
  void onInit() {
    super.onInit();
    cargarDatos();
    _iniciarAutoRefresh();
  }

  @override
  void onClose() {
    _detenerAutoRefresh();
    super.onClose();
  }

  // Iniciar auto-refresh
  void _iniciarAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: autoRefreshInterval),
      (timer) {
        if (isAutoRefreshEnabled.value && !isLoading.value) {
          print('🔄 Auto-refresh historial ejecutándose...');
          cargarDatos();
        }
      },
    );
    print('✅ Auto-refresh historial iniciado: cada $autoRefreshInterval segundos');
  }

  // Detener auto-refresh
  void _detenerAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    print('🛑 Auto-refresh historial detenido');
  }

  // Alternar auto-refresh
  void toggleAutoRefresh() {
    isAutoRefreshEnabled.value = !isAutoRefreshEnabled.value;
    
    if (isAutoRefreshEnabled.value) {
      if (_autoRefreshTimer == null || !_autoRefreshTimer!.isActive) {
        _iniciarAutoRefresh();
      }
      print('▶️ Auto-refresh historial habilitado');
    } else {
      _detenerAutoRefresh();
      print('⏸️ Auto-refresh historial pausado');
    }
  }

  // Reiniciar timer
  void _reiniciarTimer() {
    if (isAutoRefreshEnabled.value) {
      _detenerAutoRefresh();
      _iniciarAutoRefresh();
    }
  }
/// Ir a una página específica
Future<void> irAPagina(int numeroPagina) async {
  if (numeroPagina < 1) {
    print('⚠️ Número de página debe ser mayor a 0');
    return;
  }
  
  if (numeroPagina == currentPage.value) {
    print('ℹ️ Ya estás en la página $numeroPagina');
    return;
  }
  
  print('📄 Navegando de página ${currentPage.value} a $numeroPagina');
  currentPage.value = numeroPagina;
  
  // ✅ La API nos dirá si la página existe o no
  await obtenerHistorialVentas(resetear: true);
}

/// Página anterior - ✅ Usa información real de la API
Future<void> paginaAnterior() async {
  if (currentPage.value > 1) {
    await irAPagina(currentPage.value - 1);
  } else {
    print('⚠️ Ya estás en la primera página');
  }
}
Future<void> eliminarPedido(int pedidoId) async {
  try {
    // ✅ Guardar context antes del async
    final ctx = Get.context!;
    
    QuickAlert.show(
      context: ctx,
      type: QuickAlertType.confirm,
      title: '¿Eliminar pedido?',
      text: 'Esta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      barrierDismissible: true, // ✅ Permite cerrar tocando fuera
      onConfirmBtnTap: () {
        // ✅ Cerrar con Navigator en lugar de Get.back()
        Navigator.of(ctx, rootNavigator: true).pop();
        
        // ✅ Delay mínimo para que el dialog cierre antes de continuar
        Future.delayed(Duration(milliseconds: 150), () {
          _ejecutarEliminarPedido(pedidoId);
        });
      },
    );
  } catch (e) {
    print('❌ Error: $e');
  }
}

Future<void> _ejecutarEliminarPedido(int pedidoId) async {
  isLoading.value = true;
  
  try {
    final uri = Uri.parse('$defaultApiServer/ordenes/$pedidoId/eliminarPedido/');
    
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 15));

    print('📡 Eliminar pedido $pedidoId - Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      historialVentas.removeWhere(
        (v) => v['pedidoId'] == pedidoId || v['id'] == pedidoId,
      );

      Get.snackbar(
        '✅ Pedido eliminado',
        'El pedido #$pedidoId fue eliminado correctamente',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error del servidor');
    }

  } catch (e) {
    print('❌ Error eliminando pedido: $e');
    Get.snackbar(
      'Error',
      'No se pudo eliminar el pedido: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
    );
  } finally {
    isLoading.value = false;
  }
}
/// Página siguiente - ✅ Usa información real de la API
Future<void> paginaSiguiente() async {
  // ✅ No necesitamos verificar hasMoreData aquí, 
  // la API nos responderá con la información correcta
  await irAPagina(currentPage.value + 1);
}

/// Primera página
Future<void> primeraPagina() async {
  if (currentPage.value != 1) {
    await irAPagina(1);
  } else {
    print('ℹ️ Ya estás en la primera página');
  }
}

/// Última página - ✅ Usa totalPages real de la API
Future<void> ultimaPagina() async {
  if (currentPage.value != totalPages.value && totalPages.value > 0) {
    await irAPagina(totalPages.value);
  } else {
    print('ℹ️ Ya estás en la última página');
  }
}

/// 🔧 MÉTODO cambiarPageSize MEJORADO
Future<void> cambiarPageSize(int nuevoPageSize) async {
  if (isLoading.value) {
    print('⏳ Operación en progreso, espera...');
    return;
  }

  print('🔄 Cambiando page_size de ${pageSize.value} a $nuevoPageSize');
  pageSize.value = nuevoPageSize;
  
  // ✅ Al cambiar el tamaño, ir a página 1 para evitar problemas
  currentPage.value = 1;
  
  await obtenerHistorialVentas(resetear: true);
}

// ✅ NUEVO: Método para saltar a una página específica (opcional)
Future<void> saltarAPagina(int numeroPagina) async {
  if (numeroPagina < 1 || numeroPagina > totalPages.value) {
    print('⚠️ Página $numeroPagina fuera de rango (1-${totalPages.value})');
    
    // Mostrar mensaje al usuario
    if (Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Página no válida. Rango: 1-${totalPages.value}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }
  
  await irAPagina(numeroPagina);
}

  /// 🆕 MÉTODO PRINCIPAL: Cargar historial de ventas
  Future<void> cargarDatos() async {
    final esAutoRefresh = _autoRefreshTimer?.isActive == true;
    
    if (!esAutoRefresh) {
      isLoading.value = true;
    }

    try {
      await obtenerHistorialVentas();
      
      if (esAutoRefresh) {
        print('✅ Auto-refresh historial completado');
      }
    } catch (e) {
      print('❌ Error en cargarDatos historial: $e');
    } finally {
      if (!esAutoRefresh) {
        isLoading.value = false;
      }
    }
  }
// 🔧 MÉTODO obtenerHistorialVentas ACTUALIZADO PARA USAR PAGINACIÓN DE LA API

Future<void> obtenerHistorialVentas({bool resetear = false}) async {
  try {
    // ✅ Prevenir múltiples cargas simultáneas
    if (isLoading.value && !resetear) {
      print('⏳ Ya hay una carga en progreso...');
      return;
    }

    // ✅ Establecer loading al inicio
    isLoading.value = true;

    if (resetear) {
      historialVentas.clear();
      hasMoreData.value = true;
    }

    // URL con pageSize dinámico
    Uri uri = Uri.parse('$defaultApiServer/ordenes/ObtenerHistorialVentasPorDia/?fecha=${fechaConsulta.value}&page=${currentPage.value}&page_size=${pageSize.value}');

    print('📡 Cargando historial: $uri');
    print('📊 Parámetros: fecha=${fechaConsulta.value}, página=${currentPage.value}, tamaño=${pageSize.value}');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 15));

    print('📡 Historial ventas - Código: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // ✅ NUEVO: Extraer información de paginación de la API
        if (data.containsKey('pagination')) {
          final paginationInfo = data['pagination'];
          
          // ✅ Actualizar variables de paginación con datos reales de la API
          currentPage.value = paginationInfo['current_page'] ?? currentPage.value;
          totalPages.value = paginationInfo['total_pages'] ?? 1;
          hasMoreData.value = paginationInfo['has_next'] ?? false;
          
          // ✅ Información adicional útil
          final totalMesas = paginationInfo['total_mesas'] ?? 0;
          final hasPrevious = paginationInfo['has_previous'] ?? false;
          
          print('✅ Información de paginación de la API:');
          print('   📍 Página actual: ${currentPage.value}');
          print('   📄 Total páginas: ${totalPages.value}');
          print('   📊 Total mesas: $totalMesas');
          print('   ⬅️ Tiene anterior: $hasPrevious');
          print('   ➡️ Tiene siguiente: ${hasMoreData.value}');
        }
        
        // ✅ Procesar mesasOcupadas (puede estar vacío)
        if (data.containsKey('mesasOcupadas')) {
          List<dynamic> mesasOcupadas = data['mesasOcupadas'];
          List<Map<String, dynamic>> ventasConvertidas = [];
          
          // Procesar solo si hay datos
          if (mesasOcupadas.isNotEmpty) {
            for (var mesa in mesasOcupadas) {
              final numeroMesa = mesa['numeroMesa'];
              final pedidosMesa = mesa['pedidos'] as List;
              
              for (var pedido in pedidosMesa) {
                final pedidoId = pedido['pedidoId'];
                final nombreOrden = pedido['nombreOrden'];
                final fechaPedido = pedido['fechaPedido'];
                final statusPedido = pedido['statusPedido'];
                final detalles = pedido['detalles'] as List;
                
                double totalPedido = 0.0;
                int totalItems = 0;
                List<Map<String, dynamic>> detallesFormateados = [];
                
                for (var detalle in detalles) {
                  String statusDetalle = detalle['statusDetalle'] ?? 'completado';
                  
                  if (statusDetalle != 'cancelado') {
                    double precio = (detalle['precioUnitario'] ?? 0.0).toDouble();
                    int cantidad = (detalle['cantidad'] ?? 1);
                    totalPedido += precio * cantidad;
                    totalItems += cantidad;
                    
                    detallesFormateados.add({
                      'detalleId': detalle['detalleId'],
                      'nombreProducto': detalle['nombreProducto'],
                      'cantidad': cantidad,
                      'precioUnitario': precio,
                      'observaciones': detalle['observaciones'] ?? '',
                      'statusDetalle': statusDetalle,
                    });
                  }
                }
                
                if (totalPedido > 0) {
                  ventasConvertidas.add({
                    'pedidoId': pedidoId,
                    'id': pedidoId,
                    'numeroMesa': numeroMesa,
                    'nombreOrden': nombreOrden,
                    'cliente': nombreOrden,
                    'fecha': fechaPedido,
                    'fechaVenta': fechaPedido,
                    'total': totalPedido,
                    'totalVenta': totalPedido,
                    'status': statusPedido,
                    'estado': statusPedido,
                    'detalles': detallesFormateados,
                    'items': detallesFormateados,
                    'totalItems': totalItems,
                  });
                }
              }
            }
            
            // Ordenar por fecha
            ventasConvertidas.sort((a, b) {
              try {
                final fechaA = DateTime.parse(a['fecha']);
                final fechaB = DateTime.parse(b['fecha']);
                return fechaB.compareTo(fechaA);
              } catch (e) {
                return 0;
              }
            });
            
            print('✅ Datos procesados: ${ventasConvertidas.length} ventas encontradas');
          } else {
            print('📋 No hay datos en mesasOcupadas para página ${currentPage.value}');
          }
          
          // ✅ Actualizar la lista (puede estar vacía y está bien)
          historialVentas.value = ventasConvertidas;
          
        } else {
          print('⚠️ Respuesta sin mesasOcupadas');
          historialVentas.clear();
        }
      } else {
        print('⚠️ success=false en respuesta');
        historialVentas.clear();
        // Mantener totalPages si no hay información de paginación
        if (!data.containsKey('pagination')) {
          totalPages.value = 1;
        }
      }
    } else if (response.statusCode == 404) {
      print('📋 No hay datos (404) para página ${currentPage.value}');
      historialVentas.clear();
      // En 404, probablemente no hay paginación, usar valores por defecto
      totalPages.value = 1;
      hasMoreData.value = false;
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }

  } catch (e) {
    print('❌ Error al obtener historial de ventas: $e');
    
    // Solo mostrar alert si no es auto-refresh
    if (_autoRefreshTimer?.isActive != true) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo cargar el historial de ventas.\n\nVerifica tu conexión a internet.',
        confirmBtnText: 'Aceptar',
        confirmBtnColor: Color(0xFF8B4513),
      );
    }
    
    // En caso de error, limpiar datos pero mantener estructura
    historialVentas.clear();
    if (totalPages.value == 0) totalPages.value = 1;
  } finally {
    // ✅ IMPORTANTE: Siempre quitar el loading al final
    isLoading.value = false;
  }
}

  /// 🆕 MÉTODO: Cambiar fecha de consulta
  Future<void> cambiarFechaConsulta(DateTime nuevaFecha) async {
    fechaConsulta.value = nuevaFecha.toString().split(' ')[0];
    print('📅 Nueva fecha de consulta: ${fechaConsulta.value}');
    await obtenerHistorialVentas(resetear: true);
  }

  /// 🆕 MÉTODO: Cargar más datos (para paginación infinita)
  Future<void> cargarMasDatos() async {
    if (!hasMoreData.value || isLoading.value) return;
    
    print('📄 Cargando página ${currentPage.value}...');
    await obtenerHistorialVentas();
  }

  /// 🆕 MÉTODO: Mostrar detalles de una venta
  void mostrarDetallesVenta(Map<String, dynamic> venta) {
    Get.bottomSheet(
    HistorialDetailsModal(venta: venta),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
   
  );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Refrescar datos y reiniciar timer
  Future<void> refrescarDatos() async {
    await obtenerHistorialVentas(resetear: true);
    _reiniciarTimer();
  }

  /// Obtener fecha formateada para mostrar
  String get fechaFormateada {
    try {
      final fecha = DateTime.parse(fechaConsulta.value);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    } catch (e) {
      return fechaConsulta.value;
    }
  }

  /// Obtener total de ventas del día
  double get totalVentasDelDia {
    return historialVentas.fold(0.0, (total, venta) {
      final montoVenta = double.tryParse(venta['total']?.toString() ?? venta['totalVenta']?.toString() ?? '0') ?? 0.0;
      return total + montoVenta;
    });
  }

  /// Obtener cantidad total de órdenes
  int get totalOrdenesDelDia => historialVentas.length;
}
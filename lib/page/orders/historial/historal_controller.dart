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
  
  // Variables para paginación del historial
  var currentPage = 1.obs;
  var hasMoreData = true.obs;
  var fechaConsulta = DateTime.now().toString().split(' ')[0].obs; // 🆕 Fecha actual

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

  Future<void> obtenerHistorialVentas({bool resetear = false}) async {
  try {
    if (resetear) {
      currentPage.value = 1;
      historialVentas.clear();
      hasMoreData.value = true;
    }

    if (!hasMoreData.value && !resetear) {
      print('📋 No hay más datos para cargar');
      return;
    }

    // URL del endpoint actual
    Uri uri = Uri.parse('$defaultApiServer/ordenes/ObtenerHistorialVentasPorDia/?fecha=${fechaConsulta.value}&page=${currentPage.value}&page_size=5');

    print('📡 Cargando historial: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('📡 Historial ventas - Código: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data.containsKey('mesasOcupadas')) {
        List<dynamic> mesasOcupadas = data['mesasOcupadas'];
        
        // 🆕 CONVERTIR MESAS A HISTORIAL DE VENTAS
        List<Map<String, dynamic>> ventasConvertidas = [];
        
        for (var mesa in mesasOcupadas) {
          final numeroMesa = mesa['numeroMesa'];
          final pedidosMesa = mesa['pedidos'] as List;
          
          for (var pedido in pedidosMesa) {
            final pedidoId = pedido['pedidoId'];
            final nombreOrden = pedido['nombreOrden'];
            final fechaPedido = pedido['fechaPedido'];
            final statusPedido = pedido['statusPedido'];
            final detalles = pedido['detalles'] as List;
            
            // Calcular total del pedido
            double totalPedido = 0.0;
            int totalItems = 0;
            List<Map<String, dynamic>> detallesFormateados = [];
            
            for (var detalle in detalles) {
              // Solo incluir items pagados o completados
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
            
            // Solo agregar pedidos con total > 0
            if (totalPedido > 0) {
              ventasConvertidas.add({
                'pedidoId': pedidoId,
                'id': pedidoId, // ID alternativo
                'numeroMesa': numeroMesa,
                'nombreOrden': nombreOrden,
                'cliente': nombreOrden, // Campo alternativo
                'fecha': fechaPedido,
                'fechaVenta': fechaPedido, // Campo alternativo
                'total': totalPedido,
                'totalVenta': totalPedido, // Campo alternativo
                'status': statusPedido,
                'estado': statusPedido, // Campo alternativo
                'detalles': detallesFormateados,
                'items': detallesFormateados, // Campo alternativo
                'totalItems': totalItems,
              });
            }
          }
        }
        
        print('📊 Ventas convertidas: ${ventasConvertidas.length}');
        
        // Ordenar por fecha (más recientes primero)
        ventasConvertidas.sort((a, b) {
          try {
            final fechaA = DateTime.parse(a['fecha']);
            final fechaB = DateTime.parse(b['fecha']);
            return fechaB.compareTo(fechaA);
          } catch (e) {
            return 0;
          }
        });
        
        if (resetear) {
          historialVentas.value = ventasConvertidas;
        } else {
          // Agregar nuevas ventas evitando duplicados
          for (var venta in ventasConvertidas) {
            final existeId = historialVentas.any((v) => 
              v['pedidoId'] == venta['pedidoId']
            );
            
            if (!existeId) {
              historialVentas.add(venta);
            }
          }
        }

        // Para este endpoint, no hay paginación real, así que marcar como sin más datos
        hasMoreData.value = false;
        currentPage.value++;

        print('✅ Historial procesado: ${historialVentas.length} ventas total');
        
      } else {
        print('⚠️ Respuesta sin mesasOcupadas o success=false');
        if (resetear) {
          historialVentas.clear();
        }
        hasMoreData.value = false;
      }
    } else if (response.statusCode == 404) {
      print('📋 No hay datos de historial para la fecha ${fechaConsulta.value}');
      if (resetear) {
        historialVentas.clear();
      }
      hasMoreData.value = false;
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }

  } catch (e) {
    print('❌ Error al obtener historial de ventas: $e');
    
    // Solo mostrar error si NO es auto-refresh
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
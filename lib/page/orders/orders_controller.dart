import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'dart:async'; // ✅ AGREGADO: Import para Timer

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/OrderStatusModal.dart';
import 'package:restaurapp/page/orders/TableDetailsModal.dart';
import 'package:restaurapp/page/orders/orders_page.dart';

// Controller GetX para órdenes - ACTUALIZADO CON AUTO-REFRESH
class OrdersController extends GetxController {
  var isLoading = false.obs;
  var isLoadingModal = false.obs;
  var pedidosPendientes = <Map<String, dynamic>>[].obs;
  var pedidosIndividuales = <Map<String, dynamic>>[].obs;
  var mesasConPedidos = <Map<String, dynamic>>[].obs;
  var selectedTableData = <Map<String, dynamic>>[].obs;
  
  String defaultApiServer = AppConstants.serverBase;

  // ✅ NUEVO: Variables para el timer
  Timer? _autoRefreshTimer;
  var isAutoRefreshEnabled = true.obs;
  final int autoRefreshInterval = 20; // segundos

  @override
  void onInit() {
    super.onInit();
    cargarDatos();
    _iniciarAutoRefresh(); // ✅ NUEVO: Iniciar auto-refresh
  }

  @override
  void onClose() {
    _detenerAutoRefresh(); // ✅ NUEVO: Limpiar timer al cerrar
    super.onClose();
  }

  // ✅ NUEVO: Iniciar auto-refresh
  void _iniciarAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: autoRefreshInterval),
      (timer) {
        if (isAutoRefreshEnabled.value && !isLoading.value) {
          print('🔄 Auto-refresh ejecutándose...');
          cargarDatos();
        }
      },
    );
    print('✅ Auto-refresh iniciado: cada $autoRefreshInterval segundos');
  }

  // ✅ NUEVO: Detener auto-refresh
  void _detenerAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    print('🛑 Auto-refresh detenido');
  }

  // ✅ NUEVO: Alternar auto-refresh (para controlar desde UI)
  void toggleAutoRefresh() {
    isAutoRefreshEnabled.value = !isAutoRefreshEnabled.value;
    
    if (isAutoRefreshEnabled.value) {
      if (_autoRefreshTimer == null || !_autoRefreshTimer!.isActive) {
        _iniciarAutoRefresh();
      }
      print('▶️ Auto-refresh habilitado');
    } else {
      _detenerAutoRefresh();
      print('⏸️ Auto-refresh pausado');
    }
  }

  // ✅ NUEVO: Reiniciar timer (útil cuando se hace refresh manual)
  void _reiniciarTimer() {
    if (isAutoRefreshEnabled.value) {
      _detenerAutoRefresh();
      _iniciarAutoRefresh();
    }
  }

  /// Cargar ambos endpoints
  Future<void> cargarDatos() async {
    // ✅ MODIFICADO: Solo mostrar loading si no es auto-refresh
    final esAutoRefresh = _autoRefreshTimer?.isActive == true;
    
    if (!esAutoRefresh) {
      isLoading.value = true;
    }

    try {
      await Future.wait([
        obtenerPedidosPendientes(),
        obtenerMesasConPedidosAbiertos(),
      ]);
      
      if (esAutoRefresh) {
        print('✅ Auto-refresh completado');
      }
    } catch (e) {
      print('❌ Error en cargarDatos: $e');
    } finally {
      if (!esAutoRefresh) {
        isLoading.value = false;
      }
    }
  }

  /// Obtener pedidos pendientes para el carousel
  Future<void> obtenerPedidosPendientes() async {
    try {
      Uri uri = Uri.parse('$defaultApiServer/ordenes/obtenerListaPedidosPendientes/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Pedidos pendientes - Código: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          pedidosPendientes.value = List<Map<String, dynamic>>.from(data['pedidosPorMesa']);
          
          // NUEVA LÓGICA: Extraer todos los pedidos individuales
          _extraerPedidosIndividuales();
        }
      } else {
        // ✅ MODIFICADO: Solo mostrar error si NO es auto-refresh
        if (_autoRefreshTimer?.isActive != true) {
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'No se pudieron cargar los pedidos pendientes',
            confirmBtnText: 'OK',
            confirmBtnColor: Color(0xFFE74C3C),
          );
        }
      }

    } catch (e) {
      print('Error al obtener pedidos pendientes: $e');
      
      // ✅ MODIFICADO: Solo mostrar error si NO es auto-refresh
      if (_autoRefreshTimer?.isActive != true) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error de Conexión',
          text: 'No se pudo conectar al servidor $e',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );
      }
    }
  }

  /// NUEVA FUNCIÓN: Extraer pedidos individuales para el carrusel
  void _extraerPedidosIndividuales() {
    List<Map<String, dynamic>> detallesFlat = [];
    
    for (var mesaPedidos in pedidosPendientes) {
      final numeroMesa = mesaPedidos['numeroMesa'];
      final pedidos = mesaPedidos['pedidos'] as List;
      
      for (var pedido in pedidos) {
        final detalles = pedido['detalles'] as List;
        final pedidoInfo = {
          'pedidoId': pedido['pedidoId'],
          'nombreOrden': pedido['nombreOrden'],
          'fecha': pedido['fecha'],
          'status': pedido['status'],
          'total': pedido['total'],
        };
        
        // Extraer cada detalle individual
        for (var detalle in detalles) {
          Map<String, dynamic> detalleConInfo = Map.from(detalle);
          // Agregar información de mesa y pedido al detalle
          detalleConInfo['numeroMesa'] = numeroMesa;
          detalleConInfo['pedidoId'] = pedidoInfo['pedidoId'];
          detalleConInfo['nombreOrden'] = pedidoInfo['nombreOrden'];
          detalleConInfo['fecha'] = pedidoInfo['fecha'];
          detalleConInfo['status'] = pedidoInfo['status'];
          detalleConInfo['totalPedido'] = pedidoInfo['total'];
          
          detallesFlat.add(detalleConInfo);
        }
      }
    }
    
    pedidosIndividuales.value = detallesFlat;
  }

  void mostrarModalEstadoOrden(int detalleId) {
    print(detalleId);
    Get.dialog(
      OrderStatusModal(pedidoId: detalleId),
    );
  }

  Future<void> actualizarEstadoOrden(int detalleId, String nuevoEstado) async {
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
                Text('Actualizando estado...'),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      Uri uri = Uri.parse('$defaultApiServer/ordenes/actualizarStatusorden/$detalleId/');

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

      print('📡 Actualizar estado - Código: ${response.statusCode}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true || response.statusCode == 200) {
          // Cerrar modal de estado
          Get.back();
          
          // Mostrar mensaje de éxito
          QuickAlert.show(
            context: Get.context!,
            type: QuickAlertType.success,
            title: 'Éxito',
            text: 'Estado actualizado correctamente',
            confirmBtnText: 'OK',
            confirmBtnColor: Color(0xFF27AE60),
          );
          
          // Recargar datos y reiniciar timer
          await refrescarDatos();
        } else {
          _mostrarErrorActualizacion('Error en la respuesta del servidor');
        }
      } else {
        _mostrarErrorActualizacion('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error al actualizar estado: $e');
      _mostrarErrorActualizacion('Error de conexión');
    }
  }

  void _mostrarErrorActualizacion(String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'No se pudo actualizar el estado: $mensaje',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }
Future<void> obtenerMesasConPedidosAbiertos() async {
  try {
    final response = await http.get(
      Uri.parse('$defaultApiServer/ordenes/obtenerMesasConPedidosAbiertos/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('message') && data['message'].toString().contains('No hay mesas')) {
        print('ℹ️ Servidor responde: ${data['message']}');
        mesasConPedidos.clear();
        pedidosIndividuales.clear();
        print('✅ Estado limpio: Sin mesas con pedidos activos');
        return;
      }
      
      if (data.containsKey('success') && data['success'] == true) {
        mesasConPedidos.clear();
        pedidosIndividuales.clear();
        
        if (!data.containsKey('mesasOcupadas')) {
          print('⚠️ Respuesta sin campo "mesasOcupadas"');
          return;
        }
        
        final mesas = data['mesasOcupadas'] as List;
        
        if (mesas.isEmpty) {
          print('ℹ️ Lista de mesasOcupadas vacía');
          return;
        }
        
        for (var mesa in mesas) {
          final numeroMesa = mesa['numeroMesa'];
          final statusMesa = mesa['status'] ?? true;
          
          // ✅ AGREGAR: Capturar el ID de la mesa del response
          final idMesa = mesa['id'] as int? ?? 
                       mesa['idMesa'] as int? ?? 
                       mesa['mesa_id'] as int? ?? 
                       mesa['mesaId'] as int? ?? 
                       numeroMesa; // Usar numeroMesa como fallback

          // 🔍 DEBUG: Ver qué ID está llegando del servidor
          print('📋 Mesa $numeroMesa - ID capturado: $idMesa');
          print('📋 Estructura mesa completa: ${mesa.keys.toList()}');
          
          final pedidosMesa = mesa['pedidos'] as List;
          
          List<Map<String, dynamic>> pedidosFormateados = [];
          
          for (var pedido in pedidosMesa) {
            final pedidoId = pedido['pedidoId'];
            final nombreOrden = pedido['nombreOrden'];
            final fechaPedido = pedido['fechaPedido'];
            final detalles = pedido['detalles'] as List;
            
            List<Map<String, dynamic>> detallesFormateados = [];
            
            for (var detalle in detalles) {
              String statusDetalle = detalle['statusDetalle'] ?? 'proceso';
              
              if (statusDetalle == 'True') {
                statusDetalle = 'proceso';
              } else if (statusDetalle == 'False') {
                statusDetalle = 'proceso';
              }
              
              detallesFormateados.add({
                'detalleId': detalle['detalleId'],
                'nombreProducto': detalle['nombreProducto'],
                'cantidad': detalle['cantidad'],
                'precioUnitario': detalle['precioUnitario'],
                'observaciones': detalle['observaciones'] ?? '',
                'statusDetalle': statusDetalle,
              });
              
              if (statusDetalle == 'proceso') {
                pedidosIndividuales.add({
                  'detalleId': detalle['detalleId'],
                  'pedidoId': pedidoId,
                  'numeroMesa': numeroMesa,
                  'nombreOrden': nombreOrden,
                  'fecha': fechaPedido,
                  'nombreProducto': detalle['nombreProducto'],
                  'cantidad': detalle['cantidad'],
                  'precio': detalle['precioUnitario'],
                  'observaciones': detalle['observaciones'] ?? '',
                  'status': statusDetalle,
                });
              }
            }
            
            double totalPedido = 0.0;
            for (var detalle in detallesFormateados) {
              totalPedido += (detalle['precioUnitario'] * detalle['cantidad']);
            }
            
            final statusPedido = detallesFormateados.every((d) => d['statusDetalle'] == 'cancelado') 
              ? 'cancelado' 
              : detallesFormateados.any((d) => d['statusDetalle'] == 'proceso') 
                ? 'proceso' 
                : 'completado';
            
            pedidosFormateados.add({
              'pedidoId': pedidoId,
              'nombreOrden': nombreOrden,
              'fecha': fechaPedido,
              'detalles': detallesFormateados,
              'total': totalPedido,
              'status': statusPedido,
            });
          }
          
          final tienePersonasActivos = pedidosFormateados.any((p) => p['status'] != 'cancelado');
          
          if (tienePersonasActivos) {
            // ✅ SOLUCIÓN: Agregar el ID a la estructura de mesa
            mesasConPedidos.add({
              'numeroMesa': numeroMesa,
              'id': idMesa,                    // ✅ AGREGAR campo id
              'idnumeroMesa': idMesa,          // ✅ AGREGAR también con este nombre
              'mesaId': idMesa,                // ✅ AGREGAR variación adicional
              'statusMesa': statusMesa,
              'pedidos': pedidosFormateados,
            });
            
            // 🔍 DEBUG: Confirmar que se agregó correctamente
            print('✅ Mesa agregada - Número: $numeroMesa, ID: $idMesa');
          }
        }
        
        if (pedidosIndividuales.isNotEmpty) {
          pedidosIndividuales.sort((a, b) {
            final fechaA = DateTime.parse(a['fecha']);
            final fechaB = DateTime.parse(b['fecha']);
            return fechaB.compareTo(fechaA);
          });
        }
        
        print('✅ Mesas cargadas: ${mesasConPedidos.length}');
        print('✅ Pedidos individuales: ${pedidosIndividuales.length}');
        
        // 🔍 DEBUG: Ver estructura final de una mesa
        if (mesasConPedidos.isNotEmpty) {
          print('📋 Estructura mesa ejemplo: ${mesasConPedidos.first.keys.toList()}');
          print('📋 ID de primera mesa: ${mesasConPedidos.first['id']}');
        }
        
      } else {
        final message = data.containsKey('message') ? data['message'] : 'Respuesta inesperada del servidor';
        print('⚠️ Respuesta del servidor: $message');
        mesasConPedidos.clear();
        pedidosIndividuales.clear();
      }
      
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Error en obtenerMesasConPedidosAbiertos: $e');
    
    if (!e.toString().contains('No hay mesas') && _autoRefreshTimer?.isActive != true) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar con el servidor.\n\nPor favor verifica tu conexión a internet.',
        confirmBtnText: 'Aceptar',
        confirmBtnColor: Color(0xFF8B4513),
      );
    }
  }
}

  /// Mostrar detalles de mesa en modal
  void mostrarDetallesMesa(int numeroMesa) {
    final mesa = mesasConPedidos.firstWhereOrNull(
      (mesa) => mesa['numeroMesa'] == numeroMesa
    );
    
    if (mesa != null) {
      selectedTableData.value = [mesa];
      _showTableDetailsModal(mesa);
    }
  }

  void _showTableDetailsModal(Map<String, dynamic> mesa) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          child: TableDetailsModal(mesa: mesa),
        ),
      ),
    );
  }

  /// ✅ MODIFICADO: Refrescar datos y reiniciar timer
  Future<void> refrescarDatos() async {
    await cargarDatos();
    _reiniciarTimer(); // Reiniciar el timer después del refresh manual
  }

  /// Calcular total de una mesa considerando solo productos no cancelados
  double calcularTotalMesa(Map<String, dynamic> mesa) {
    double total = 0.0;
    final pedidos = mesa['pedidos'] as List;
    
    for (var pedido in pedidos) {
      final detalles = pedido['detalles'] as List;
      for (var detalle in detalles) {
        // Solo sumar productos que no estén cancelados
        if ((detalle['statusDetalle'] ?? 'proceso') != 'cancelado') {
          total += (detalle['precioUnitario'] ?? 0.0) * (detalle['cantidad'] ?? 1);
        }
      }
    }
    
    return total;
  }

  /// Contar items de una mesa considerando solo productos no cancelados
  int contarItemsMesa(Map<String, dynamic> mesa) {
    int total = 0;
    final pedidos = mesa['pedidos'] as List;
    
    for (var pedido in pedidos) {
      final detalles = pedido['detalles'] as List;
      for (var detalle in detalles) {
        // Solo contar detalles que no estén cancelados
        if ((detalle['statusDetalle'] ?? 'proceso') != 'cancelado') {
          total += (detalle['cantidad'] as int? ?? 1);
        }
      }
    }
    
    return total;
  }

  // Método para obtener todos los detalleId de una mesa
  List<int> obtenerDetalleIdsDeMesa(int numeroMesa) {
    List<int> detalleIds = [];
    
    final mesa = mesasConPedidos.firstWhereOrNull(
      (mesa) => mesa['numeroMesa'] == numeroMesa
    );
    
    if (mesa != null) {
      final pedidos = mesa['pedidos'] as List;
      
      for (var pedido in pedidos) {
        final detalles = pedido['detalles'] as List;
        for (var detalle in detalles) {
          // Solo agregar detalles que no estén cancelados
          if ((detalle['statusDetalle'] ?? 'proceso') != 'cancelado') {
            detalleIds.add(detalle['detalleId']);
          }
        }
      }
    }
    
    print('📋 DetalleIds encontrados para mesa $numeroMesa: $detalleIds');
    return detalleIds;
  }

  // Obtener pedidoIds pagables de una mesa
  List<int> obtenerPedidoIdsPagablesDeMesa(int numeroMesa) {
    List<int> pedidoIds = [];
    
    final mesa = mesasConPedidos.firstWhereOrNull(
      (mesa) => mesa['numeroMesa'] == numeroMesa
    );
    
    if (mesa != null) {
      final pedidos = mesa['pedidos'] as List;
      
      for (var pedido in pedidos) {
        final detalles = pedido['detalles'] as List;
        
        // Verificar si el pedido tiene al menos un detalle completado
        bool tieneDetallesCompletados = detalles.any(
          (detalle) => (detalle['statusDetalle'] ?? 'proceso') == 'completado'
        );
        
        if (tieneDetallesCompletados) {
          pedidoIds.add(pedido['pedidoId']);
        }
      }
    }
    
    print('📋 PedidoIds pagables para mesa $numeroMesa: $pedidoIds');
    return pedidoIds;
  }

  Future<Map<String, dynamic>?> procesarDetalleId(int detalleId) async {
    try {
      Uri uri = Uri.parse('$defaultApiServer/ordenes/CompletarYTotalPedido/$detalleId/');
      
      print('📡 Procesando detalleId $detalleId: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Respuesta para detalleId $detalleId - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
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
      print('❌ Error al procesar detalleId $detalleId: $e');
      return {
        'success': false,
        'detalleId': detalleId,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Nuevo método de pago que procesa todos los detalleIds
  Future<void> pagarMesa(int numeroMesa) async {
    try {
      // Obtener todos los detalleIds de la mesa
      final detalleIds = obtenerDetalleIdsDeMesa(numeroMesa);
      
      if (detalleIds.isEmpty) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.warning,
          title: 'Sin Items',
          text: 'No hay items válidos para procesar en la mesa $numeroMesa',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFF39C12),
        );
        return;
      }

      // Mostrar loading con progreso
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
                Text('Procesando pago...'),
                SizedBox(height: 8),
                Text(
                  'Procesando ${detalleIds.length} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Procesar todos los detalleIds
      List<Map<String, dynamic>> resultados = [];
      double totalGeneral = 0.0;
      int exitosos = 0;
      int fallidos = 0;

      for (int detalleId in detalleIds) {
        final resultado = await procesarDetalleId(detalleId);
        if (resultado != null) {
          resultados.add(resultado);
          
          if (resultado['success'] == true) {
            exitosos++;
            totalGeneral += (resultado['total'] ?? 0.0).toDouble();
          } else {
            fallidos++;
          }
        } else {
          fallidos++;
        }
      }

      // Cerrar loading
      Get.back();

      // Mostrar resultado
      if (fallidos == 0) {
        // Todos exitosos
        Get.back(); // Cerrar modal de detalles
        
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: 'Pago Exitoso',
          text: 'Mesa $numeroMesa pagada correctamente\n'
                '$exitosos items procesados\n'
                'Total: \$${totalGeneral.toStringAsFixed(2)}',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF27AE60),
        );
        
        // Recargar datos y reiniciar timer
        await refrescarDatos();
        
      } else if (exitosos > 0) {
        // Parcialmente exitoso
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.warning,
          title: 'Pago Parcial',
          text: 'Mesa $numeroMesa procesada parcialmente\n'
                'Exitosos: $exitosos items\n'
                'Fallidos: $fallidos items\n'
                'Total procesado: \$${totalGeneral.toStringAsFixed(2)}',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFF39C12),
        );
        
        // Recargar datos para reflejar cambios
        await refrescarDatos();
        
      } else {
        // Todos fallaron
        _mostrarErrorPago('No se pudo procesar ningún item de la mesa');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al procesar pago de mesa: $e');
      _mostrarErrorPago('Error de conexión');
    }
  }

  void _mostrarErrorPago(String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error en el Pago',
      text: 'No se pudo procesar el pago: $mensaje',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }

  // Función para confirmar pago con nueva información
  void confirmarPago(int numeroMesa, double total) {
    final detalleIds = obtenerDetalleIdsDeMesa(numeroMesa);
    final cantidadItems = detalleIds.length;
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Pago',
      text: '¿Confirmar el pago de la Mesa $numeroMesa?\n\n'
            'Total estimado: \$${total.toStringAsFixed(2)}\n'
            'Items a procesar: $cantidadItems\n\n'
            'Se procesarán todos los items válidos individualmente.',
      confirmBtnText: 'Confirmar Pago',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF27AE60),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar diálogo de confirmación
        await pagarMesa(numeroMesa);
      },
    );
  }
}
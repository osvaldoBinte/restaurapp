import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';
import 'dart:async'; // ✅ AGREGADO: Import para Timer

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/OrderStatusModal.dart';
import 'package:restaurapp/page/orders/modaltable/TableDetailsModal.dart';
import 'package:restaurapp/page/orders/orders_page.dart';
import 'package:restaurapp/page/orders/serivios/orden_service.dart';

// Controller GetX para órdenes - ACTUALIZADO CON AUTO-REFRESH
class OrdersController extends GetxController {
  var isLoading = false.obs;
  var isLoadingModal = false.obs;
  var pedidosPendientes = <Map<String, dynamic>>[].obs;
  var pedidosIndividuales = <Map<String, dynamic>>[].obs;
  var mesasConPedidos = <Map<String, dynamic>>[].obs;
  var selectedTableData = <Map<String, dynamic>>[].obs;
  var isLiberandoTodasLasMesas = false.obs;
  final OrdenService ordenService = OrdenService();

  String defaultApiServer = AppConstants.serverBase;

  // ✅ NUEVO: Variables para el timer
  Timer? _autoRefreshTimer;
  var isAutoRefreshEnabled = true.obs;
  final int autoRefreshInterval = 5; // segundos

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

Future<void> cargarDatos() async {
  final esAutoRefresh = _autoRefreshTimer?.isActive == true;
  
  if (!esAutoRefresh) {
    isLoading.value = true;
  }

  try {
    await Future.wait([
      obtenerPedidosPendientes(), // Para el carousel
      obtenerMesasConPedidosAbiertos(), // Para la lista de mesas
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
Future<void> refrescarSoloMesas() async {
  try {
    await obtenerMesasConPedidosAbiertos();
    print('✅ Mesas refrescadas');
  } catch (e) {
    print('❌ Error refrescando mesas: $e');
  }
}

 Future<void> obtenerPedidosPendientes() async {
  try {
    Uri uri = Uri.parse('$defaultApiServer/ordenes/obtenerListaPedidosPendientes/');

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
      
      // ✅ CASO 1: Respuesta vacía/sin pedidos
      if (data.containsKey('message') && data['message'].toString().contains('No hay pedidos')) {
        print('ℹ️ Backend reporta: ${data['message']}');
        print('✅ Carousel estará vacío (sin pedidos pendientes)\n');
        
        pedidosPendientes.clear();
        pedidosIndividuales.clear();
        return;
      }
      
      // ✅ CASO 2: Respuesta con estructura success y pedidosPorMesa
      if (data['success'] == true && data.containsKey('pedidosPorMesa')) {
        print('\n📦 ESTRUCTURA COMPLETA:');
        print(JsonEncoder.withIndent('  ').convert(data));
        print('=' * 80 + '\n');
        
        pedidosPendientes.value = List<Map<String, dynamic>>.from(data['pedidosPorMesa']);
        
        print('🔍 DETALLES DE PEDIDOS PENDIENTES:');
        print('=' * 80);
        
        for (var i = 0; i < pedidosPendientes.length; i++) {
          final mesaPedido = pedidosPendientes[i];
          print('\n📋 Mesa/Grupo ${i + 1}:');
          print('  Mesa: ${mesaPedido['mesa'] ?? mesaPedido['numeroMesa']}');
          print('  Orden ID: ${mesaPedido['ordenId']}');
          print('  Tiempo: ${mesaPedido['tiempoTranscurrido']}');
          print('  Total: \$${mesaPedido['total']}');
          
          if (mesaPedido['items'] != null) {
            final items = mesaPedido['items'] as List;
            print('  Items: ${items.length}');
            
            for (var j = 0; j < items.length; j++) {
              final item = items[j];
              print('    ${j + 1}. ${item['nombre']} x${item['cantidad']} - Estado: ${item['estado']}');
            }
          }
        }
        print('=' * 80 + '\n');
        
        // Extraer pedidos individuales para el carousel
        _extraerPedidosIndividuales();
        
        print('📊 RESUMEN CAROUSEL:');
        print('  Mesas con pedidos pendientes: ${pedidosPendientes.length}');
        print('  Items individuales en carousel: ${pedidosIndividuales.length}\n');
      } 
      // ✅ CASO 3: Estructura alternativa sin campo "success"
      else if (data.containsKey('pedidosPorMesa')) {
        print('ℹ️ Respuesta sin campo "success", procesando de todas formas...\n');
        
        pedidosPendientes.value = List<Map<String, dynamic>>.from(data['pedidosPorMesa']);
        _extraerPedidosIndividuales();
        
        print('📊 RESUMEN CAROUSEL:');
        print('  Items en carousel: ${pedidosIndividuales.length}\n');
      }
      // ✅ CASO 4: Estructura desconocida
      else {
        print('⚠️ Estructura de respuesta inesperada');
        print('Keys disponibles: ${data.keys.toList()}');
        print('Contenido: $data\n');
        
        pedidosPendientes.clear();
        pedidosIndividuales.clear();
      }
      
    } else {
      print('❌ Error HTTP ${response.statusCode}\n');
      
      if (_autoRefreshTimer?.isActive != true) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'No se pudieron cargar los pedidos pendientes (${response.statusCode})',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );
      }
    }

  } catch (e, stackTrace) {
    print('🚨 Error en obtenerPedidosPendientes: $e');
    print('Stack trace: $stackTrace\n');
    
    if (_autoRefreshTimer?.isActive != true) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar al servidor\n\n$e',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    }
  }
}/// Extraer pedidos individuales del endpoint de pedidos pendientes
void _extraerPedidosIndividuales() {
  List<Map<String, dynamic>> detallesFlat = [];
  
  print('\n🔄 Extrayendo pedidos individuales para carousel...');
  print('Pedidos pendientes a procesar: ${pedidosPendientes.length}');
  
  for (var mesaPedidos in pedidosPendientes) {
    final numeroMesa = mesaPedidos['numeroMesa'];
    
    print('  Procesando Mesa $numeroMesa...');
    
    // ✅ CORRECCIÓN: La estructura tiene "pedidos" no "items"
    if (mesaPedidos['pedidos'] != null) {
      final pedidos = mesaPedidos['pedidos'] as List;
      
      print('    Total pedidos en esta mesa: ${pedidos.length}');
      
      for (var pedido in pedidos) {
        final pedidoId = pedido['pedidoId'];
        final nombreOrden = pedido['nombreOrden'] ?? 'Orden $pedidoId';
        final fechaPedido = pedido['fecha'] ?? DateTime.now().toIso8601String();
        
        // ✅ CORRECCIÓN: Los items están en "detalles"
        if (pedido['detalles'] != null) {
          final detalles = pedido['detalles'] as List;
          
          print('      Pedido $pedidoId tiene ${detalles.length} detalles');
          
          for (var detalle in detalles) {
            // ✅ VERIFICAR si debe mostrarse en el listado
            final mostrarEnListado = detalle['mostrarEnListado'] ?? true;
            
            if (!mostrarEnListado) {
              print('        ⊗ Detalle ${detalle['detalleId']} oculto (mostrarEnListado: false)');
              continue; // Saltar este detalle
            }
            
            // Crear estructura para el carousel
            Map<String, dynamic> itemFormateado = {
              'detalleId': detalle['detalleId'],
              'menuId': detalle['productoId'] ?? 0, // ✅ productoId en vez de menuId
              'numeroMesa': numeroMesa,
              'pedidoId': pedidoId, // ✅ Cambiado de ordenId a pedidoId
              'nombreOrden': nombreOrden,
              'nombreProducto': detalle['nombreProducto'], // ✅ nombreProducto (no "nombre")
              'cantidad': detalle['cantidad'],
              'precio': double.tryParse(detalle['precio']?.toString() ?? '0') ?? 0.0,
              'subtotal': double.tryParse(detalle['subtotal']?.toString() ?? '0') ?? 0.0,
              'estado': detalle['status'] ?? 'proceso', // ✅ status (no "estado")
              'observaciones': detalle['observaciones'] ?? '',
              'fecha': fechaPedido,
              'mostrarEnListado': mostrarEnListado, // ✅ Guardar el flag
            };
            
            detallesFlat.add(itemFormateado);
            print('        ✓ Detalle ${detalle['detalleId']}: ${detalle['nombreProducto']}');
          }
        } else {
          print('      ⚠️ Pedido $pedidoId sin campo "detalles"');
        }
      }
    } else {
      print('    ⚠️ Mesa $numeroMesa sin campo "pedidos"');
    }
  }
  
  // Ordenar por fecha (más reciente primero)
detallesFlat.sort((a, b) {
  try {
    final fechaA = DateTime.parse(a['fecha']);
    final fechaB = DateTime.parse(b['fecha']);
    return fechaA.compareTo(fechaB); // ✅ CAMBIADO: fechaA con fechaB (era fechaB con fechaA)
  } catch (e) {
    return 0;
  }
});
  
  pedidosIndividuales.assignAll(detallesFlat);
  
  print('\n✅ EXTRACCIÓN COMPLETADA:');
  print('  Total items extraídos: ${detallesFlat.length}');
  
  if (detallesFlat.isNotEmpty) {
    print('  Primer item: ${detallesFlat.first['nombreProducto']} (Mesa ${detallesFlat.first['numeroMesa']})');
    print('  Fecha más reciente: ${detallesFlat.first['fecha']}');
    
    // Mostrar resumen de mesas
    Set<int> mesasUnicas = detallesFlat.map((item) => item['numeroMesa'] as int).toSet();
    print('  Mesas con pedidos: ${mesasUnicas.join(', ')}');
  }
  print('');
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

    

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true || response.statusCode == 200) {
          
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
    print('\n' + '=' * 80);
    print('📋 LISTA DE MESAS - obtenerMesasConPedidosAbiertos');
    print('=' * 80);
    
    final response = await http.get(
      Uri.parse('$defaultApiServer/ordenes/obtenerMesasConPedidosAbiertos/'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // ✅ CASO 1: Sin mesas
      if (data.containsKey('message') && data['message'].toString().contains('No hay mesas')) {
        print('ℹ️ Backend reporta: ${data['message']}');
        print('✅ Lista de mesas estará vacía\n');
        
        mesasConPedidos.clear();
        return;
      }
      
      // ✅ CASO 2: Con mesas
      if (data.containsKey('success') && data['success'] == true) {
        mesasConPedidos.clear();
        
        if (!data.containsKey('mesasOcupadas')) {
          print('⚠️ Respuesta sin campo "mesasOcupadas"\n');
          return;
        }
        
        final mesas = data['mesasOcupadas'] as List;
        
        if (mesas.isEmpty) {
          print('ℹ️ Lista de mesasOcupadas vacía\n');
          return;
        }
        
        print('\n🔍 Procesando ${mesas.length} mesas...');
        
        for (var mesa in mesas) {
          final numeroMesa = mesa['numeroMesa'];
          final statusMesa = mesa['status'] ?? true;
          final idMesa = mesa['id'] ?? mesa['idMesa'] ?? mesa['mesaId'] ?? numeroMesa;
          
          print('  Mesa $numeroMesa (ID: $idMesa)');
          
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
              
              if (statusDetalle == 'True') statusDetalle = 'proceso';
              else if (statusDetalle == 'False') statusDetalle = 'proceso';
              
              detallesFormateados.add({
                'detalleId': detalle['detalleId'],
                'nombreProducto': detalle['nombreProducto'],
                'cantidad': detalle['cantidad'],
                'precioUnitario': detalle['precioUnitario'],
                'observaciones': detalle['observaciones'] ?? '',
                'statusDetalle': statusDetalle,
              });
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
          
          final tieneProductosActivos = pedidosFormateados.any((p) => p['status'] != 'cancelado');
          
          if (tieneProductosActivos) {
            mesasConPedidos.add({
              'numeroMesa': numeroMesa,
              'id': idMesa,
              'idnumeroMesa': idMesa,
              'mesaId': idMesa,
              'statusMesa': statusMesa,
              'pedidos': pedidosFormateados,
            });
          }
        }
        
        print('\n📊 RESUMEN LISTA DE MESAS:');
        print('  Mesas con pedidos activos: ${mesasConPedidos.length}\n');
        
      } else {
        final message = data.containsKey('message') ? data['message'] : 'Respuesta inesperada';
        print('⚠️ ${message}\n');
        mesasConPedidos.clear();
      }
      
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Error en obtenerMesasConPedidosAbiertos: $e\n');
    
    if (!e.toString().contains('No hay mesas') && _autoRefreshTimer?.isActive != true) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar con el servidor para la lista de mesas.',
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
  showModalBottomSheet(
    context: Get.context!,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.95, // 95% de la pantalla
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: TableDetailsModal(mesa: mesa),
    ),
  );
}

  /// ✅ MODIFICADO: Refrescar datos y reiniciar timer
/// ✅ MODIFICADO: refrescarDatos ahora solo refresca mesas
Future<void> refrescarDatos() async {
  await refrescarSoloMesas();
  _reiniciarTimer();
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
  // ✅ NUEVO MÉTODO: Atender todos los pedidos de una mesa
Future<void> atenderTodosLosPedidosMesa(int numeroMesa) async {
  try {
    // 🔍 PASO 1: Obtener el ID de la mesa desde la estructura
    final mesa = mesasConPedidos.firstWhereOrNull(
      (mesa) => mesa['numeroMesa'] == numeroMesa
    );
    
    if (mesa == null) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'No se encontró la mesa $numeroMesa',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
      return;
    }

    // 🔍 PASO 2: Extraer el ID de la mesa
    final mesaId = mesa['id'] ?? 
                  mesa['idnumeroMesa'] ?? 
                  mesa['mesaId'] ?? 
                  numeroMesa; // Fallback al número de mesa

    print('🏪 Mesa $numeroMesa - ID para API: $mesaId');

    // 🔍 PASO 3: Verificar que hay pedidos pendientes
    final pedidos = mesa['pedidos'] as List;
    final pedidosPendientes = pedidos.where((pedido) {
      final detalles = pedido['detalles'] as List;
      return detalles.any((detalle) => 
        (detalle['statusDetalle'] ?? 'proceso') == 'proceso'
      );
    }).toList();

    if (pedidosPendientes.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.info,
        title: 'Sin Pedidos Pendientes',
        text: 'La mesa $numeroMesa no tiene pedidos pendientes para atender',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFF3498DB),
      );
      return;
    }

    // 🔍 PASO 4: Mostrar confirmación
    final cantidadPedidosPendientes = pedidosPendientes.length;
    final totalItems = pedidosPendientes.fold<int>(0, (sum, pedido) {
      final detalles = pedido['detalles'] as List;
      return sum + detalles.where((detalle) => 
        (detalle['statusDetalle'] ?? 'proceso') == 'proceso'
      ).length;
    });

    await ejecutarAtenderMesa( numeroMesa);

  } catch (e) {
    print('❌ Error en atenderTodosLosPedidosMesa: $e');
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'Error al procesar la solicitud: $e',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }
}

// 🔧 MÉTODO PRIVADO: Ejecutar la llamada a la API
Future<void> ejecutarAtenderMesa(int numeroMesa) async {
  try {
    // 🔍 PASO 1: Mostrar loading
   
    // 🔍 PASO 2: Construir URL y realizar llamada POST
    Uri uri = Uri.parse('$defaultApiServer/mesas/$numeroMesa/atender-todo/');
    
    print('📡 Llamando API: $uri');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // El body puede estar vacío o contener información adicional si es necesario
      body: jsonEncode({
        'numeroMesa': numeroMesa,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    print('📡 Respuesta API - Código: ${response.statusCode}');
    print('📡 Respuesta API - Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true || response.statusCode == 200) {
     
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        
       
        // 🔄 PASO 5: Recargar datos para reflejar cambios
        await refrescarDatos();
        
      } else {
        // ❌ ERROR EN RESPUESTA
        final mensaje = data['message'] ?? data['error'] ?? 'Respuesta inesperada del servidor';
        _mostrarErrorAtenderMesa('Error del servidor: $mensaje');
      }
      
    } else if (response.statusCode == 404) {
      _mostrarErrorAtenderMesa('Mesa no encontrada en el servidor');
      
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      final mensaje = data['message'] ?? data['error'] ?? 'Solicitud inválida';
      _mostrarErrorAtenderMesa('Error en la solicitud: $mensaje');
      
    } else {
      _mostrarErrorAtenderMesa('Error del servidor (${response.statusCode})');
    }

  } catch (e) {
    // 🔍 PASO 6: Manejo de errores de conexión
    
    // Cerrar loading si está abierto
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    
    print('❌ Error de conexión en _ejecutarAtenderMesa: $e');
    _mostrarErrorAtenderMesa('Error de conexión: $e');
  }
}
void _mostrarErrorAtenderMesa(String mensaje) {
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.error,
    title: 'Error al Atender Mesa',
    text: 'No se pudieron atender los pedidos:\n\n$mensaje',
    confirmBtnText: 'Entendido',
    confirmBtnColor: Color(0xFFE74C3C),
  );
}
Future<void> liberarTodasLasMesas() async {
  // Evitar múltiples ejecuciones
  if (isLiberandoTodasLasMesas.value) return;
  
  try {
    // Obtener todas las mesas con pedidos pendientes
    List<Map<String, dynamic>> mesasConPendientes = [];
    
    for (var mesa in mesasConPedidos) {
      final numeroMesa = mesa['numeroMesa'];
      final pedidos = mesa['pedidos'] as List;
      
      // Verificar si la mesa tiene pedidos pendientes
      bool tienePendientes = pedidos.any((pedido) {
        final detalles = pedido['detalles'] as List;
        return detalles.any((detalle) => 
          (detalle['statusDetalle'] ?? 'proceso') == 'proceso'
        );
      });
      
      if (tienePendientes) {
        // Contar items pendientes
        int itemsPendientes = 0;
        for (var pedido in pedidos) {
          final detalles = pedido['detalles'] as List;
          itemsPendientes += detalles.where((detalle) => 
            (detalle['statusDetalle'] ?? 'proceso') == 'proceso'
          ).length;
        }
        
        mesasConPendientes.add({
          'numeroMesa': numeroMesa,
          'itemsPendientes': itemsPendientes,
          'mesa': mesa,
        });
        
        print('✅ Mesa $numeroMesa agregada para liberación');
      }
    }
    
    // Validar que hay mesas para liberar
    if (mesasConPendientes.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.info,
        title: 'Sin Pedidos Pendientes',
        text: 'No hay mesas con pedidos pendientes para liberar.',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFF3498DB),
      );
      return;
    }
    
    // Calcular totales para confirmación
    final totalMesas = mesasConPendientes.length;
    final totalItems = mesasConPendientes.fold<int>(0, 
      (sum, mesa) => sum + (mesa['itemsPendientes'] as int)
    );
    
    // Mostrar diálogo de confirmación
    String detallesMesas = mesasConPendientes.map((mesa) => 
      'Mesa ${mesa['numeroMesa']}: ${mesa['itemsPendientes']} items'
    ).join('\n');
     await _ejecutarLiberacionMasiva(mesasConPendientes);
    
  } catch (e) {
    print('❌ Error en liberarTodasLasMesas: $e');
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'Error al procesar la solicitud: $e',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }
}

dynamic _extraerIdMesa(Map<String, dynamic> mesa, int numeroMesa) {
  // Lista de posibles campos que contienen el ID de la mesa
  List<String> posiblesCamposId = [
    'id',           // Campo más común
    'idMesa',       // Alternativa 1
    'mesaId',       // Alternativa 2
    'mesa_id',      // Snake case
    'idnumeroMesa', // Campo específico que vimos antes
    'pk',           // Primary key
    'Mesa_id',      // Capitalizado
    'ID',           // Mayúsculas
  ];
  
  // 🔍 BUSCAR el ID en los campos posibles
  for (String campo in posiblesCamposId) {
    if (mesa.containsKey(campo) && mesa[campo] != null) {
      dynamic valor = mesa[campo];
      
      // Verificar que sea un número válido
      if (valor is int && valor > 0) {
        print('✅ ID encontrado en campo "$campo": $valor');
        return valor;
      } else if (valor is String) {
        try {
          int idParsed = int.parse(valor);
          if (idParsed > 0) {
            print('✅ ID encontrado en campo "$campo" (string): $idParsed');
            return idParsed;
          }
        } catch (e) {
          // Continuar buscando
        }
      }
    }
  }
  
  // 🔍 BUSCAR en pedidos individuales por si el ID está ahí
  try {
    final pedidos = mesa['pedidos'] as List;
    if (pedidos.isNotEmpty) {
      final primerPedido = pedidos.first;
      
      // Buscar en el primer pedido
      for (String campo in ['mesaId', 'mesa_id', 'idMesa']) {
        if (primerPedido.containsKey(campo)) {
          dynamic valor = primerPedido[campo];
          if (valor is int && valor > 0) {
            print('✅ ID encontrado en pedido, campo "$campo": $valor');
            return valor;
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Error buscando ID en pedidos: $e');
  }
  
  // 🔍 ÚLTIMO RECURSO: Buscar mesa por número en todas las mesas
  for (var mesaCompleta in mesasConPedidos) {
    if (mesaCompleta['numeroMesa'] == numeroMesa) {
      // Hacer una búsqueda más profunda
      print('🔍 Estructura completa de mesa $numeroMesa:');
      mesaCompleta.forEach((key, value) {
        print('  "$key": $value (${value.runtimeType})');
      });
      break;
    }
  }
  
  // ⚠️ FALLBACK: Usar numeroMesa como ID (puede causar 404 si no coincide)
  print('⚠️ No se encontró ID específico para mesa $numeroMesa, usando numeroMesa como fallback');
  return numeroMesa;
}Future<void> _ejecutarLiberacionMasiva(List<Map<String, dynamic>> mesasConPendientes) async {
  try {
    // ✅ ACTIVAR estado de carga
    isLiberandoTodasLasMesas.value = true;
    
    List<Map<String, dynamic>> resultados = [];
    int exitosas = 0;
    int fallidas = 0;
    
    for (var mesaInfo in mesasConPendientes) {
      final numeroMesa = mesaInfo['numeroMesa'];
      
      try {
        print('🔄 Procesando Mesa $numeroMesa...');
        
        Uri uri = Uri.parse('$defaultApiServer/mesas/$numeroMesa/atender-todo/');
        
        print('📡 URL llamada: $uri');
        
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );
        
        print('📡 Mesa $numeroMesa - Respuesta: ${response.statusCode}');
        print('📡 Mesa $numeroMesa - Body: ${response.body}');
        
        if (response.statusCode == 200) {
          exitosas++;
          resultados.add({
            'numeroMesa': numeroMesa,
            'success': true,
            'itemsProcesados': mesaInfo['itemsPendientes'],
          });
          print('✅ Mesa $numeroMesa liberada exitosamente');
          
        } else if (response.statusCode == 404) {
          fallidas++;
          resultados.add({
            'numeroMesa': numeroMesa,
            'success': false,
            'error': 'Mesa $numeroMesa no encontrada en el servidor',
          });
          print('❌ Mesa $numeroMesa - Error 404: Mesa no encontrada');
          
        } else {
          fallidas++;
          final responseBody = response.body.isNotEmpty ? response.body : 'Sin mensaje';
          resultados.add({
            'numeroMesa': numeroMesa,
            'success': false,
            'error': 'Error HTTP ${response.statusCode}: $responseBody',
          });
          print('❌ Mesa $numeroMesa - Error HTTP ${response.statusCode}');
        }
        
        // Pausa entre requests
        await Future.delayed(Duration(milliseconds: 300));
        
      } catch (e) {
        fallidas++;
        resultados.add({
          'numeroMesa': numeroMesa,
          'success': false,
          'error': 'Error de conexión: $e',
        });
        print('❌ Mesa $numeroMesa - Error de conexión: $e');
      }
    }
    
    // Mostrar resultados
    if (fallidas == 0) {
      final totalItemsProcesados = resultados.fold<int>(0, 
        (sum, resultado) => sum + (resultado['itemsProcesados'] as int? ?? 0)
      );
      
    
      
    } else if (exitosas > 0) {
      final mesasExitosas = resultados.where((r) => r['success'] == true)
        .map((r) => 'Mesa ${r['numeroMesa']}').join(', ');
      
      final erroresDetallados = resultados.where((r) => r['success'] == false)
        .map((r) => '• Mesa ${r['numeroMesa']}: ${r['error']}').join('\n');
      
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Liberación Parcial',
        text: '⚠️ Procesamiento parcial:\n\n'
              '✅ Exitosas ($exitosas): $mesasExitosas\n\n'
              '❌ Errores ($fallidas):\n$erroresDetallados',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFFF39C12),
      );
      
    } else {
      final erroresDetallados = resultados.map((r) => 
        '• Mesa ${r['numeroMesa']}: ${r['error']}'
      ).join('\n');
      
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error en Liberación',
        text: '❌ No se pudo liberar ninguna mesa:\n\n$erroresDetallados\n\n'
              '💡 Verifica que las mesas existan en el servidor.',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    }
    
    // Recargar datos
    await refrescarDatos();
    
  } catch (e) {
    print('❌ Error general en _ejecutarLiberacionMasiva: $e');
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error de Sistema',
      text: 'Error inesperado: $e',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  } finally {
    // ✅ DESACTIVAR estado de carga
    isLiberandoTodasLasMesas.value = false;
  }
}

void debugEstructuraMesa(int numeroMesa) {
  final mesa = mesasConPedidos.firstWhereOrNull(
    (mesa) => mesa['numeroMesa'] == numeroMesa
  );
  
  if (mesa != null) {
    print('🔍 === DEBUG ESTRUCTURA MESA $numeroMesa ===');
    mesa.forEach((key, value) {
      print('$key: $value (${value.runtimeType})');
    });
    print('🔍 === FIN DEBUG ===');
  } else {
    print('❌ Mesa $numeroMesa no encontrada en mesasConPedidos');
  }
}
// 🔧 MÉTODO AUXILIAR: Obtener conteo de mesas con pendientes (para UI)
int obtenerConteoMesasConPendientes() {
  int conteo = 0;
  
  for (var mesa in mesasConPedidos) {
    final pedidos = mesa['pedidos'] as List;
    
    bool tienePendientes = pedidos.any((pedido) {
      final detalles = pedido['detalles'] as List;
      return detalles.any((detalle) => 
        (detalle['statusDetalle'] ?? 'proceso') == 'proceso'
      );
    });
    
    if (tienePendientes) {
      conteo++;
    }
  }
  
  return conteo;
}
// 🔧 MÉTODO AUXILIAR: Obtener conteo de mesas con pedidos completados (listos para liberar)
int obtenerConteoMesasCompletadas() {
  int conteo = 0;
  
  for (var mesa in mesasConPedidos) {
    final pedidos = mesa['pedidos'] as List;
    
    bool todosCompletados = pedidos.every((pedido) {
      final detalles = pedido['detalles'] as List;
      // Verificar que TODOS los detalles estén completados (no en proceso, no cancelados)
      return detalles.every((detalle) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        return status == 'completado' || status == 'pagado' || status == 'cancelado';
      });
    });
    
    // Solo contar la mesa si tiene al menos un producto completado (no solo cancelados)
    bool tieneProductosCompletados = pedidos.any((pedido) {
      final detalles = pedido['detalles'] as List;
      return detalles.any((detalle) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        return status == 'completado';
      });
    });
    
    if (todosCompletados && tieneProductosCompletados) {
      conteo++;
    }
  }
  
  return conteo;
}

// 🔧 MÉTODO ALTERNATIVO: Si quieres solo mesas con productos completados (más simple)
int obtenerConteoMesasListasParaLiberar() {
  int conteo = 0;
  
  for (var mesa in mesasConPedidos) {
    final pedidos = mesa['pedidos'] as List;
    
    // Verificar si la mesa tiene productos completados y ninguno en proceso
    bool sinProceso = true;
    bool tieneCompletados = false;
    
    for (var pedido in pedidos) {
      final detalles = pedido['detalles'] as List;
      
      for (var detalle in detalles) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        
        if (status == 'proceso') {
          sinProceso = false;
        }
        
        if (status == 'completado') {
          tieneCompletados = true;
        }
      }
    }
    
    // Contar la mesa si no tiene productos en proceso Y tiene productos completados
    if (sinProceso && tieneCompletados) {
      conteo++;
    }
  }
  
  return conteo;
}

Future<void> liberarMesasCompletadas() async {
  // Evitar múltiples ejecuciones
  if (isLiberandoTodasLasMesas.value) return;
  
  try {
    // Obtener mesas con pedidos completados (sin productos en proceso)
    List<Map<String, dynamic>> mesasCompletadas = [];
    
    for (var mesa in mesasConPedidos) {
      final numeroMesa = mesa['numeroMesa'];
      final pedidos = mesa['pedidos'] as List;
      
      // Verificar si la mesa tiene productos completados y ninguno en proceso
      bool sinProceso = true;
      bool tieneCompletados = false;
      
      for (var pedido in pedidos) {
        final detalles = pedido['detalles'] as List;
        
        for (var detalle in detalles) {
          final status = detalle['statusDetalle'] ?? 'proceso';
          
          if (status == 'proceso') {
            sinProceso = false;
          }
          
          if (status == 'completado') {
            tieneCompletados = true;
          }
        }
      }
      
      // Agregar mesa si cumple los criterios
      if (sinProceso && tieneCompletados) {
        mesasCompletadas.add({
          'numeroMesa': numeroMesa,
          'mesa': mesa,
        });
        print('✅ Mesa $numeroMesa agregada para liberación (completada)');
      }
    }
    
    // Validar que hay mesas para liberar
    if (mesasCompletadas.isEmpty) {
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.info,
        title: 'Sin Mesas Listas',
        text: 'No hay mesas con pedidos completados listas para liberar.',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFF3498DB),
      );
      return;
    }
    
    // Mostrar confirmación
    final totalMesas = mesasCompletadas.length;
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Liberar Mesas Completadas',
      text: '¿Está seguro de que quiere liberar todas las mesas con pedidos completados?\n\n'
            'Total de mesas: $totalMesas\n\n'
            'Esta acción liberará las mesas que tienen todos sus pedidos completados.',
      confirmBtnText: 'Liberar Todas ($totalMesas)',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF27AE60),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el diálogo de confirmación
        await _ejecutarLiberacionMesasCompletadas(mesasCompletadas);
      },
    );
    
  } catch (e) {
    print('❌ Error en liberarMesasCompletadas: $e');
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: 'Error al procesar la solicitud: $e',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }
}
Future<void> _ejecutarLiberacionMesasCompletadas(List<Map<String, dynamic>> mesasCompletadas) async {
  try {
    // Activar estado de carga
    isLiberandoTodasLasMesas.value = true;
    
    
    int exitosas = 0;
    int fallidas = 0;
    List<String> mesasFallidas = [];
    
    // Procesar cada mesa
    for (var mesaInfo in mesasCompletadas) {
      final numeroMesa = mesaInfo['numeroMesa'];
      final mesa = mesaInfo['mesa'];
      
      try {
        // Extraer el ID de la mesa
        final mesaId = mesa['id'] ?? 
                      mesa['idnumeroMesa'] ?? 
                      mesa['mesaId'] ?? 
                      numeroMesa; // Fallback
        
        print('🏪 Liberando Mesa $numeroMesa (ID: $mesaId)...');
        
        Uri uri = Uri.parse('$defaultApiServer/mesas/liberarMesa/$mesaId/');
        final statusData = {'status': true};
        
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(statusData),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['success'] == true) {
            exitosas++;
            print('✅ Mesa $numeroMesa liberada correctamente');
          } else {
            fallidas++;
            mesasFallidas.add('Mesa $numeroMesa');
            print('❌ Error liberando Mesa $numeroMesa: ${data['message'] ?? 'Error desconocido'}');
          }
        } else {
          fallidas++;
          mesasFallidas.add('Mesa $numeroMesa');
          print('❌ Error HTTP liberando Mesa $numeroMesa: ${response.statusCode}');
        }
        
        // Pausa entre requests
        await Future.delayed(Duration(milliseconds: 200));
        
      } catch (e) {
        fallidas++;
        mesasFallidas.add('Mesa $numeroMesa');
        print('❌ Excepción liberando Mesa $numeroMesa: $e');
      }
    }
    
    // Cerrar diálogo de progreso
    Get.back();
    
    // Mostrar resultado
    if (fallidas == 0) {
      // Todas las mesas fueron liberadas exitosamente
     
    } else if (exitosas > 0) {
      // Algunas mesas fueron liberadas
      String mensajeFallidas = mesasFallidas.length <= 3 
          ? mesasFallidas.join(', ')
          : '${mesasFallidas.take(3).join(', ')} y ${mesasFallidas.length - 3} más';
      
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.warning,
        title: 'Liberación Parcial',
        text: '⚠️ Liberación completada parcialmente\n'
              'Exitosas: $exitosas\n'
              'Fallidas: $fallidas\n'
              'Mesas con error: $mensajeFallidas',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFFF39C12),
      );
    } else {
      // Ninguna mesa pudo ser liberada
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error en Liberación',
        text: '❌ No se pudo liberar ninguna mesa completada\n'
              'Total intentadas: ${mesasCompletadas.length}\n'
              'Verifica la conexión con el servidor.',
        confirmBtnText: 'Entendido',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    }
    
    // Refrescar datos
    await refrescarDatos();
    
  } catch (e) {
    // Cerrar diálogo de progreso si está abierto
    if (Get.isDialogOpen ?? false) Get.back();
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error Crítico',
      text: 'Error inesperado al liberar las mesas: $e',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
    
    print('❌ Error crítico en _ejecutarLiberacionMesasCompletadas: $e');
  } finally {
    // Desactivar estado de carga
    isLiberandoTodasLasMesas.value = false;
  }
}

}
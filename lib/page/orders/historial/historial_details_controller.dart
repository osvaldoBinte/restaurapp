import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';

import 'package:restaurapp/common/services/BluetoothPrinterService.dart';
import 'package:restaurapp/page/orders/historial/historal_controller.dart';

class HistorialDetailsController extends GetxController {
  // Observables
  final selectedOrderIndex = (0).obs; // Por defecto seleccionar el primer (y único) pedido
  final productosSeleccionados = <int>{}.obs;
  final isUpdating = false.obs;
  final isBluetoothConnected = false.obs;
  
  // Services
  final UniversalPrinterService printerService = UniversalPrinterService();
  
  // Datos actuales
  Map<String, dynamic> _ventaActual = {};

  void inicializarConVenta(Map<String, dynamic> venta) {
    _ventaActual = venta;
    
    // Para historial, siempre seleccionar la venta completa (índice 0)
    selectedOrderIndex.value = 0;
    
    // Limpiar productos seleccionados
    productosSeleccionados.clear();
    
    print('🎯 HistorialDetailsController inicializado con venta #${venta['pedidoId'] ?? venta['id']}');
  }

  // Getters adaptados para historial
  Map<String, dynamic> get ventaActual => _ventaActual;
  
  int get pedidoId => _ventaActual['pedidoId'] ?? _ventaActual['id'] ?? 0;
  int get numeroMesa => _ventaActual['numeroMesa'] ?? 0;
  String get nombreOrden => _ventaActual['nombreOrden'] ?? _ventaActual['cliente'] ?? 'Sin nombre';
  String get fechaVenta => _ventaActual['fecha'] ?? _ventaActual['fechaVenta'] ?? '';
  String get statusVenta => _ventaActual['status'] ?? _ventaActual['estado'] ?? 'completado';
  
  List<Map<String, dynamic>> get productos {
    final items = (_ventaActual['detalles'] ?? _ventaActual['items']) as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  double get totalVenta {
    final total = (_ventaActual['total'] ?? _ventaActual['totalVenta']) as num? ?? 0;
    return total.toDouble();
  }
// En tu HistorialDetailsController, actualiza estos métodos:

void toggleProductoSeleccionado(int detalleId) {
  print('🔄 toggleProductoSeleccionado called with detalleId: $detalleId');
  print('   Current selected products: ${productosSeleccionados.toList()}');
  
  if (productosSeleccionados.contains(detalleId)) {
    productosSeleccionados.remove(detalleId);
    print('   ➖ Removed $detalleId from selection');
  } else {
    productosSeleccionados.add(detalleId);
    print('   ➕ Added $detalleId to selection');
  }
  
  print('   New selected products: ${productosSeleccionados.toList()}');
  print('   Products count: ${productosSeleccionados.length}');
  
  update(); // ← ¡AGREGAR ESTA LÍNEA!
}

void toggleSeleccionarTodos() {
  if (productosSeleccionados.length == productos.length) {
    // Si todos están seleccionados, deseleccionar todos
    productosSeleccionados.clear();
    print('❌ Deseleccionados todos los productos');
  } else {
    // Seleccionar todos los productos válidos
    productosSeleccionados.clear();
    for (int i = 0; i < productos.length; i++) {
      var producto = productos[i];
      final detalleId = (producto['detalleId'] as int?) ?? 
                        (producto['id'] as int?) ?? 
                        (producto['itemId'] as int?) ??
                        (producto['nombreProducto'] ?? producto['producto'] ?? 'Producto$i').hashCode;
      productosSeleccionados.add(detalleId);
    }
    print('✅ Seleccionados todos los productos: ${productosSeleccionados.length}');
  }
  
  update(); // ← ¡AGREGAR ESTA LÍNEA!
}

double calcularTotalProductosSeleccionados() {
  if (productosSeleccionados.isEmpty) return 0.0;
  
  double totalSeleccionados = 0.0;
  
  for (int i = 0; i < productos.length; i++) {
    var producto = productos[i];
    try {
      final detalleId = (producto['detalleId'] as int?) ?? 
                        (producto['id'] as int?) ?? 
                        (producto['itemId'] as int?) ??
                        (producto['nombreProducto'] ?? producto['producto'] ?? 'Producto$i').hashCode;
      
      if (productosSeleccionados.contains(detalleId)) {
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 
                              (producto['precio'] as num?)?.toDouble() ?? 0.0;
        totalSeleccionados += precioUnitario * cantidad;
      }
    } catch (e) {
      print('❌ Error procesando producto: $e');
      continue;
    }
  }
  
  return totalSeleccionados;
}

List<Map<String, dynamic>> _obtenerProductosSeleccionados() {
  List<Map<String, dynamic>> productosSeleccionadosList = [];
  
  for (int i = 0; i < productos.length; i++) {
    var producto = productos[i];
    final detalleId = (producto['detalleId'] as int?) ?? 
                      (producto['id'] as int?) ?? 
                      (producto['itemId'] as int?) ??
                      (producto['nombreProducto'] ?? producto['producto'] ?? 'Producto$i').hashCode;
                      
    if (productosSeleccionados.contains(detalleId)) {
      productosSeleccionadosList.add(producto);
    }
  }
  
  return productosSeleccionadosList;
}
  double get totalParaFooter {
    final totalSeleccionados = calcularTotalProductosSeleccionados();
    return productosSeleccionados.isNotEmpty ? totalSeleccionados : totalVenta;
  }

  String get labelTotalFooter {
    if (productosSeleccionados.isNotEmpty) {
      return 'Total Seleccionados (${productosSeleccionados.length}):';
    }
    return 'Total de la Venta:';
  }

  // Método para actualizar datos del historial
  Future<void> actualizarDatosManualmente() async {
    if (isUpdating.value) return;
    
    isUpdating.value = true;
    
    try {
      final historialController = Get.find<HistorialController>();
      await historialController.refrescarDatos();
      await Future.delayed(Duration(milliseconds: 300));
      
      Get.snackbar(
        'Actualizado',
        'Historial actualizado correctamente',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error en actualización: $e');
      Get.snackbar(
        'Error',
        'No se pudieron actualizar los datos del historial',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  // ✅ MÉTODO PRINCIPAL: Imprimir ticket completo
  void confirmarImprimirTicketCompleto() {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Imprimir Ticket Completo',
      text: '¿Imprimir el ticket completo de la venta?\n\n'
            'Venta: #$pedidoId\n'
            'Cliente: $nombreOrden\n'
            'Mesa: $numeroMesa\n'
            'Total: \$${totalVenta.toStringAsFixed(2)}\n'
            'Productos: ${productos.length}',
      confirmBtnText: 'Imprimir Ticket',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF8B4513),
      onConfirmBtnTap: () async {
        Get.back();
        await _imprimirTicketCompleto();
      },
    );
  }

  // ✅ MÉTODO: Imprimir solo productos seleccionados
  void confirmarImprimirProductosSeleccionados() {
    final totalSeleccionados = calcularTotalProductosSeleccionados();
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Imprimir Productos Seleccionados',
      text: '¿Imprimir ticket con los productos seleccionados?\n\n'
            'Venta: #$pedidoId\n'
            'Cliente: $nombreOrden\n'
            'Mesa: $numeroMesa\n'
            'Productos seleccionados: ${productosSeleccionados.length}\n'
            'Total seleccionados: \$${totalSeleccionados.toStringAsFixed(2)}',
      confirmBtnText: 'Imprimir Seleccionados',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF2196F3),
      onConfirmBtnTap: () async {
        Get.back();
        await _imprimirProductosSeleccionados();
      },
    );
  }

  Future<void> _imprimirTicketCompleto() async {
    try {
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Conectando impresora y generando ticket...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Conectar impresora
      final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
      
      Get.back(); // Cerrar diálogo de progreso

      if (!impresoraConectada) {
        Get.snackbar(
          'Impresora No Disponible',
          'No se pudo conectar con la impresora.\n\nVerifica que esté encendida y conectada.',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        return;
      }

      // Crear estructura de pedido para el ticket
      final pedidoParaTicket = _crearEstructuraPedidoCompleto();
      
      // Imprimir ticket
      await printerService.imprimirTicket(pedidoParaTicket, totalVenta);

      Get.snackbar(
        'Ticket Impreso',
        'Ticket completo impreso correctamente\n\n'
        'Venta: #$pedidoId\n'
        'Total: \$${totalVenta.toStringAsFixed(2)}\n'
        'Productos: ${productos.length}',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );

    } catch (e) {
      Get.back(); // Cerrar diálogo si está abierto
      
      print('❌ Error imprimiendo ticket: $e');
      Get.snackbar(
        'Error de Impresión',
        'No se pudo imprimir el ticket: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } finally {
      await printerService.desconectar();
    }
  }

  Future<void> _imprimirProductosSeleccionados() async {
    try {
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Conectando impresora y generando ticket...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Conectar impresora
      final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
      
      Get.back(); // Cerrar diálogo de progreso

      if (!impresoraConectada) {
        Get.snackbar(
          'Impresora No Disponible',
          'No se pudo conectar con la impresora.\n\nVerifica que esté encendida y conectada.',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        return;
      }

      // Obtener productos seleccionados
      final productosSeleccionadosList = _obtenerProductosSeleccionados();
      final totalSeleccionados = calcularTotalProductosSeleccionados();
      
      if (productosSeleccionadosList.isEmpty) {
        Get.snackbar(
          'Sin Productos',
          'No hay productos seleccionados para imprimir',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return;
      }

      // Crear estructura de pedido para el ticket con productos seleccionados
      final pedidoParaTicket = _crearEstructuraPedidoSeleccionados(productosSeleccionadosList);
      
      // Imprimir ticket
      await printerService.imprimirTicket(pedidoParaTicket, totalSeleccionados);

      Get.snackbar(
        'Ticket Impreso',
        'Ticket de productos seleccionados impreso correctamente\n\n'
        'Venta: #$pedidoId\n'
        'Productos: ${productosSeleccionadosList.length}\n'
        'Total: \$${totalSeleccionados.toStringAsFixed(2)}',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );

      // Limpiar selección después de imprimir
      productosSeleccionados.clear();

    } catch (e) {
      Get.back(); // Cerrar diálogo si está abierto
      
      print('❌ Error imprimiendo productos seleccionados: $e');
      Get.snackbar(
        'Error de Impresión',
        'No se pudo imprimir el ticket: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } finally {
      await printerService.desconectar();
    }
  }


  Map<String, dynamic> _crearEstructuraPedidoCompleto() {
    return {
      'pedidoId': pedidoId,
      'nombreOrden': nombreOrden,
      'detalles': productos,
      'totalCalculado': totalVenta,
      'tipoTicket': 'historial_completo',
      'fechaCompra': fechaVenta,
      'mesa': numeroMesa,
      'esReimpresion': true,
      'fechaReimpresion': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _crearEstructuraPedidoSeleccionados(List<Map<String, dynamic>> productosSeleccionadosList) {
    final totalSeleccionados = calcularTotalProductosSeleccionados();
    
    return {
      'pedidoId': pedidoId,
      'nombreOrden': '$nombreOrden (Seleccionados)',
      'detalles': productosSeleccionadosList,
      'totalCalculado': totalSeleccionados,
      'tipoTicket': 'historial_seleccionados',
      'fechaCompra': fechaVenta,
      'mesa': numeroMesa,
      'esReimpresion': true,
      'fechaReimpresion': DateTime.now().toIso8601String(),
      'productosSeleccionados': productosSeleccionadosList.length,
      'totalProductosVenta': productos.length,
    };
  }

  // Métodos de utilidad visual
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado': return Colors.green;
      case 'proceso': return Colors.orange;
      case 'cancelado': return Colors.red;
      case 'pagado': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String getProductEmoji(String nombreProducto) {
    final nombre = nombreProducto.toLowerCase();
    
    if (nombre.contains('café') || nombre.contains('coffee')) return '☕';
    if (nombre.contains('hamburguesa') || nombre.contains('burger')) return '🍔';
    if (nombre.contains('pizza')) return '🍕';
    if (nombre.contains('pollo') || nombre.contains('chicken')) return '🍗';
    if (nombre.contains('pescado') || nombre.contains('fish')) return '🐟';
    if (nombre.contains('ensalada') || nombre.contains('salad')) return '🥗';
    if (nombre.contains('pasta') || nombre.contains('spaghetti')) return '🍝';
    if (nombre.contains('bebida') || nombre.contains('drink') || nombre.contains('jugo')) return '🥤';
    if (nombre.contains('cerveza') || nombre.contains('beer')) return '🍺';
    if (nombre.contains('vino') || nombre.contains('wine')) return '🍷';
    if (nombre.contains('postre') || nombre.contains('dessert') || nombre.contains('helado')) return '🍰';
    if (nombre.contains('taco')) return '🌮';
    if (nombre.contains('sandwich') || nombre.contains('torta')) return '🥪';
    if (nombre.contains('sopa') || nombre.contains('soup')) return '🍲';
    
    return '🍽️';
  }

  String formatearFecha(String fecha) {
    try {
      final DateTime fechaParsed = DateTime.parse(fecha);
      return '${fechaParsed.day.toString().padLeft(2, '0')}/${fechaParsed.month.toString().padLeft(2, '0')}/${fechaParsed.year} ${fechaParsed.hour.toString().padLeft(2, '0')}:${fechaParsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  // Getter para determinar si se puede imprimir
  bool get puedeImprimir => productos.isNotEmpty;
  bool get tieneProductosSeleccionados => productosSeleccionados.isNotEmpty;
  
  // Getter para el tipo de botón de impresión
  String get tipoBotonImpresion {
    if (productosSeleccionados.isEmpty) {
      return 'completo'; // Imprimir todo
    } else if (productosSeleccionados.length == productos.length) {
      return 'todos_seleccionados'; // Todos seleccionados
    } else {
      return 'seleccionados'; // Solo algunos seleccionados
    }
  }
}
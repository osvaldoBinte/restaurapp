import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

import 'package:restaurapp/common/services/BluetoothPrinterService.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderController.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderScreen.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class TableDetailsController extends GetxController {
  // Observables
  final selectedOrderIndex = (-1).obs; // -1 significa "todos los pedidos"
  final productosSeleccionados = <int>{}.obs;
  final isUpdating = false.obs;
  final isBluetoothConnected = false.obs;
  
  // Services
  final UniversalPrinterService printerService = UniversalPrinterService();
  
  // Datos actuales
  Map<String, dynamic> _mesaActual = {};
  
  @override
  void onInit() {
    super.onInit();
    _setupOrdersListener();
  }

  void inicializarConMesa(Map<String, dynamic> mesa) {
    _mesaActual = mesa;
  }

  void _setupOrdersListener() {
    try {
      final ordersController = Get.find<OrdersController>();
      
      ever(ordersController.mesasConPedidos, (List<dynamic> mesas) {
        if (!isUpdating.value) {
          print('🔄 Órdenes actualizadas, refrescando modal...');
          update(); // Actualizar GetBuilder
        }
      });
      
    } catch (e) {
      print('❌ Error configurando listener: $e');
    }
  }

  // Getters
  Map<String, dynamic> get mesaActualizada {
    final ordersController = Get.find<OrdersController>();
    return ordersController.mesasConPedidos.firstWhere(
      (mesa) => mesa['numeroMesa'] == _mesaActual['numeroMesa'],
      orElse: () => _mesaActual,
    );
  }

  int get numeroMesa => mesaActualizada['numeroMesa'];
  int get idnumeromesa => mesaActualizada['id'] as int? ?? 0;
  List get pedidos => mesaActualizada['pedidos'] as List;
  
  double get totalMesa {
    final ordersController = Get.find<OrdersController>();
    return ordersController.calcularTotalMesa(mesaActualizada);
  }

  // Métodos de UI
  void seleccionarPedido(int index) {
    selectedOrderIndex.value = index;
    productosSeleccionados.clear(); // Limpiar selección al cambiar de vista
  }

  void toggleProductoSeleccionado(int detalleId) {
    if (productosSeleccionados.contains(detalleId)) {
      productosSeleccionados.remove(detalleId);
    } else {
      productosSeleccionados.add(detalleId);
    }
    
    print('Producto ${detalleId} ${productosSeleccionados.contains(detalleId) ? 'seleccionado' : 'deseleccionado'}');
    print('Productos seleccionados: $productosSeleccionados');
  }

  // Métodos para obtener datos de vista
  List<Map<String, dynamic>> get todosLosProductos {
    List<Map<String, dynamic>> productos = [];
    
    for (int i = 0; i < pedidos.length; i++) {
      final pedido = Map<String, dynamic>.from(pedidos[i]);
      final detalles = pedido['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        productos.add(<String, dynamic>{
          ...detalleMap,
          'pedidoId': pedido['pedidoId'],
          'nombreOrden': pedido['nombreOrden'],
          'colorPedido': getOrderColor(i),
        });
      }
    }
    
    return productos;
  }

  List<Map<String, dynamic>> getProductosDePedido(int index) {
    if (index >= pedidos.length) return [];
    
    final pedido = Map<String, dynamic>.from(pedidos[index]);
    final detalles = pedido['detalles'] as List? ?? [];
    
    return detalles.map((detalle) {
      final detalleMap = Map<String, dynamic>.from(detalle);
      return <String, dynamic>{
        ...detalleMap,
        'pedidoId': pedido['pedidoId'],
        'nombreOrden': pedido['nombreOrden'],
        'colorPedido': Color(0xFF2196F3),
      };
    }).toList();
  }

  // Métodos para cálculos
  double calcularTotalProductosSeleccionados() {
    if (productosSeleccionados.isEmpty) return 0.0;
    
    double totalSeleccionados = 0.0;
    List<Map<String, dynamic>> productos = selectedOrderIndex.value == -1 
        ? todosLosProductos 
        : getProductosDePedido(selectedOrderIndex.value);
    
    for (var producto in productos) {
      try {
        final detalleId = producto['detalleId'] as int?;
        final statusDetalle = producto['statusDetalle'] as String? ?? 'proceso';
        
        if (detalleId != null && productosSeleccionados.contains(detalleId) && statusDetalle != 'cancelado') {
          final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalSeleccionados += precioUnitario * cantidad;
        }
      } catch (e) {
        print('❌ Error procesando producto: $e');
        continue;
      }
    }
    
    return totalSeleccionados;
  }

  double get totalParaFooter {
    final totalSeleccionados = calcularTotalProductosSeleccionados();
    
    if (productosSeleccionados.isNotEmpty) {
      return totalSeleccionados;
    }
    
    return selectedOrderIndex.value == -1 
        ? totalMesa 
        : calcularTotalPedido(pedidos[selectedOrderIndex.value]);
  }

  String get labelTotalFooter {
    if (productosSeleccionados.isNotEmpty) {
      return 'Total Mesa(${productosSeleccionados.length}):';
    }
    
    return selectedOrderIndex.value == -1 ? 'Total Mesa:' : 'Total Pedido:';
  }

  double calcularTotalPedido(Map<String, dynamic> pedido) {
    double total = 0.0;
    final detalles = pedido['detalles'] as List? ?? [];
    
    for (var detalle in detalles) {
      try {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        
        if (status != 'cancelado') {
          final precioUnitario = (detalleMap['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          final cantidad = (detalleMap['cantidad'] as num?)?.toInt() ?? 1;
          total += precioUnitario * cantidad;
        }
      } catch (e) {
        print('❌ Error calculando total del detalle: $e');
        continue;
      }
    }
    return total;
  }

  // Métodos de validación
  bool mesaTieneProductosEnProceso() {
    for (var pedido in pedidos) {
      try {
        final pedidoMap = Map<String, dynamic>.from(pedido);
        final detalles = pedidoMap['detalles'] as List? ?? [];
        
        for (var detalle in detalles) {
          final detalleMap = Map<String, dynamic>.from(detalle);
          final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
          if (status == 'proceso') return true;
        }
      } catch (e) {
        print('❌ Error verificando productos en proceso: $e');
        continue;
      }
    }
    return false;
  }

  bool puedeSerPagado(Map<String, dynamic> pedido) {
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        if (status != 'proceso' && status != 'cancelado') return true;
      }
    } catch (e) {
      print('❌ Error verificando si puede ser pagado: $e');
    }
    return false;
  }

  // Métodos de navegación y modales
  void mostrarSelectorPedidoParaAgregar() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Seleccionar Pedido',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿A qué pedido desea agregar productos?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              width: double.maxFinite,
              child: Column(
                children: pedidos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pedido = entry.value;
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getOrderColor(index),
                        child: Text(
                          '#${pedido['pedidoId']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        pedido['nombreOrden'] ?? 'Sin nombre',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Pedido #${pedido['pedidoId']}'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Get.back();
                        abrirModalAgregarProductos(pedido);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void manejarBotonAgregarProductos() {
    if (selectedOrderIndex.value == -1) {
      if (pedidos.length == 1) {
        abrirModalAgregarProductos(pedidos[0]);
      } else if (pedidos.length > 1) {
        mostrarSelectorPedidoParaAgregar();
      } else {
        Get.snackbar(
          'Error',
          'No hay pedidos disponibles',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } else {
      abrirModalAgregarProductos(pedidos[selectedOrderIndex.value]);
    }
  }

  void abrirModalAgregarProductos(Map<String, dynamic> pedido) {
    final pedidoId = pedido['pedidoId'] as int;
    final numeroMesa = _mesaActual['numeroMesa'] as int;
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: AddProductsToOrderScreen(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      final controller = Get.find<OrdersController>();
      controller.refrescarDatos();
    });
    
    Future.delayed(Duration(milliseconds: 100), () {
      try {
        Get.find<AddProductsToOrderController>().inicializarConPedido(
          pedidoId,
          numeroMesa,
          nombreOrden,
        );
      } catch (e) {
        Get.put(AddProductsToOrderController()).inicializarConPedido(
          pedidoId,
          numeroMesa,
          nombreOrden,
        );
      }
    });
  }

  // Métodos de actualización de datos
  Future<void> actualizarDatosManualmente() async {
    if (isUpdating.value) return;
    
    isUpdating.value = true;
    
    try {
      final ordersController = Get.find<OrdersController>();
      await ordersController.refrescarDatos();
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('❌ Error en actualización: $e');
      Get.snackbar(
        'Error',
        'No se pudieron actualizar los datos',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  // Métodos de cambio de estado
  void cambiarEstadoProducto(Map<String, dynamic> producto, String nuevoEstado) {
    final detalleId = producto['detalleId'] as int;
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    final pedidoId = producto['pedidoId'];
    
    String titulo = nuevoEstado == 'completado' ? 'Completar Producto' : 'Cancelar Producto';
    String mensaje = nuevoEstado == 'completado' 
        ? '¿Marcar "$nombreProducto" como completado?'
        : '¿Está seguro de que quiere cancelar "$nombreProducto"?\n\nEsta acción no se puede deshacer.';
    
    String textoBoton = nuevoEstado == 'completado' ? 'Completar' : 'Cancelar';
    Color colorBoton = nuevoEstado == 'completado' ? Colors.green : Colors.red;
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: titulo,
      text: '$mensaje\n\nPedido #$pedidoId',
      confirmBtnText: textoBoton,
      cancelBtnText: 'Volver',
      confirmBtnColor: colorBoton,
      onConfirmBtnTap: () async {
        Get.back();
        
        final controller = Get.find<OrdersController>();
        await controller.actualizarEstadoOrden(detalleId, nuevoEstado);
      },
    );
  }

  // Métodos de cantidad
  void aumentarCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];
    final cantidadActual = producto['cantidad'] ?? 1;
    final nuevaCantidad = cantidadActual + 1;
    
    await _actualizarCantidadProducto(detalleId, nuevaCantidad);
  }

  void disminuirCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];
    final cantidadActual = producto['cantidad'] ?? 1;
    
    if (cantidadActual <= 1) {
      _confirmarEliminarProducto(producto);
      return;
    }
    
    final nuevaCantidad = cantidadActual - 1;
    await _actualizarCantidadProducto(detalleId, nuevaCantidad);
  }

  Future<void> _actualizarCantidadProducto(int detalleId, int nuevaCantidad) async {
    final controller = Get.find<OrdersController>();
    
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      Uri uri = Uri.parse('${controller.defaultApiServer}/pedidos/actualizar-cantidad/$detalleId/');
      
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'cantidad': nuevaCantidad}),
      );

      Get.back();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          Get.snackbar(
            'Cantidad Actualizada',
            'La cantidad se actualizó correctamente',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
          
          await controller.refrescarDatos();
        } else {
          _mostrarErrorCantidad('Error del servidor: ${data['message'] ?? 'Error desconocido'}');
        }
      } else {
        _mostrarErrorCantidad('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      
      print('❌ Error al actualizar cantidad: $e');
      _mostrarErrorCantidad('Error de conexión: $e');
    }
  }

  void _confirmarEliminarProducto(Map<String, dynamic> producto) {
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Eliminar Producto',
      text: '¿Está seguro de que quiere eliminar "$nombreProducto" del pedido?\n\n'
            'Esta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Get.back();
        await _eliminarProducto(producto['detalleId']);
      },
    );
  }

  Future<void> _eliminarProducto(int detalleId) async {
    final controller = Get.find<OrdersController>();
    
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      Uri uri = Uri.parse('${controller.defaultApiServer}/pedidos/eliminar-detalle/$detalleId/');
      
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      Get.back();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          Get.snackbar(
            'Producto Eliminado',
            'El producto se eliminó correctamente del pedido',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 2),
          );
          
          await controller.refrescarDatos();
        } else {
          _mostrarErrorCantidad('Error al eliminar: ${data['message'] ?? 'Error desconocido'}');
        }
      } else {
        _mostrarErrorCantidad('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      
      print('❌ Error al eliminar producto: $e');
      _mostrarErrorCantidad('Error de conexión: $e');
    }
  }

  void _mostrarErrorCantidad(String mensaje) {
    Get.snackbar(
      'Error',
      mensaje,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  // Métodos de pago y liberación
  void confirmarLiberarMesa() {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Liberar Mesa',
      text: '¿Está seguro de que quiere liberar la Mesa $numeroMesa?\n\n'
            'Esta acción marcará la mesa como disponible.',
      confirmBtnText: 'Liberar Mesa',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back();
        await _liberarMesa();
      },
    );
  }

  Future<void> _liberarMesa() async {
    final controller = Get.find<OrdersController>();
    
    try {
      Uri uri = Uri.parse('${controller.defaultApiServer}/mesas/liberarMesa/$idnumeromesa/');
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
          Get.back();
          
          Get.snackbar(
            'Mesa Liberada',
            'La Mesa $numeroMesa ha sido liberada correctamente',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          
          await controller.refrescarDatos();
        } else {
          _mostrarErrorLiberacion('Error en la respuesta del servidor');
        }
      } else {
        _mostrarErrorLiberacion('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      _mostrarErrorLiberacion('Error de conexión: $e');
    }
  }

  void _mostrarErrorLiberacion(String mensaje) {
    Get.snackbar(
      'Error al Liberar Mesa',
      'No se pudo liberar la mesa: $mensaje',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
  }

  void confirmarPagoPedido(Map<String, dynamic> pedido) {
    final pedidoId = pedido['pedidoId'];
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final total = calcularTotalPedido(pedido);
    final detalleIds = _obtenerDetalleIdsDePedido(pedido);
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Pago',
      text: '¿Confirmar el pago del pedido?\n\n'
            'Pedido: $nombreOrden\n'
            'ID: #$pedidoId\n'
            'Total: \$${total.toStringAsFixed(2)}',
      confirmBtnText: 'Confirmar Pago',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF27AE60),
      onConfirmBtnTap: () async {
        Get.back();
        await _pagarPedidoEspecifico(pedido, detalleIds, total);
      },
    );
  }

  List<int> _obtenerDetalleIdsDePedido(Map<String, dynamic> pedido) {
    List<int> detalleIds = [];
    
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        
        if (status == 'completado') {
          final detalleId = detalleMap['detalleId'] as int?;
          if (detalleId != null) {
            detalleIds.add(detalleId);
          }
        }
      }
    } catch (e) {
      print('❌ Error obteniendo detalle IDs: $e');
    }
    
    return detalleIds;
  }

  Future<void> _pagarPedidoEspecifico(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];
    
    try {
      final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
      if (!impresoraConectada) {
        Get.snackbar(
          'Impresora no disponible',
          'Se procesará el pago sin imprimir ticket',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }

      double totalReal = 0.0;
      int exitosos = 0;
      int fallidos = 0;

      for (int detalleId in detalleIds) {
        final resultado = await controller.procesarDetalleId(pedidoId);
        if (resultado != null && resultado['success'] == true) {
          exitosos++;
          totalReal += (resultado['total'] ?? 0.0).toDouble();
        } else {
          fallidos++;
        }
      }

      if (fallidos == 0 && impresoraConectada) {
        try {
          await printerService.imprimirTicket(pedido, totalReal);
        } catch (e) {
          print('❌ Error en impresión: $e');
        }
      }

      if (fallidos == 0) {
        String mensaje = 'Pedido #$pedidoId pagado correctamente\nTotal: \${totalReal.toStringAsFixed(2)}';
        
        if (impresoraConectada) {
          mensaje += '\n✅ Ticket impreso';
        }
        
        Get.snackbar(
          'Pago Exitoso',
          mensaje,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        
        await controller.refrescarDatos();
        
      } else if (exitosos > 0) {
        Get.snackbar(
          'Pago Parcial',
          'Pedido #$pedidoId procesado parcialmente\nExitosos: $exitosos items\nFallidos: $fallidos items',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        
        await controller.refrescarDatos();
        
      } else {
        Get.snackbar(
          'Error en Pago',
          'No se pudo procesar ningún item del pedido #$pedidoId',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al procesar pago del pedido: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      await printerService.desconectar();
    }
  }

  // Métodos de utilidad
  Color getOrderColor(int index) {
    List<Color> colors = [
      Color(0xFF8B4513), Color(0xFF2196F3), Color(0xFF4CAF50),
      Color(0xFFFF9800), Color(0xFF9C27B0), Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado': return Colors.green;
      case 'proceso': return Colors.orange;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String getProductEmoji(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower.contains('bebida')) return '🥤';
    if (categoriaLower.contains('postre')) return '🍰';
    if (categoriaLower.contains('extra')) return '🥄';
    return '🌮';
  }
}
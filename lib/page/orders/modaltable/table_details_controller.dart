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
  
  // Determinar el índice inicial basado en la cantidad de pedidos
  final pedidos = mesa['pedidos'] as List? ?? [];
  
  if (pedidos.length > 1) {
    // Si hay más de un pedido, seleccionar el primer pedido (índice 0)
    selectedOrderIndex.value = 0;
  } else if (pedidos.length == 1) {
    // Si hay exactamente un pedido, seleccionarlo automáticamente (índice 0)
    selectedOrderIndex.value = 0;
  } else {
    // Si no hay pedidos, mantener "Todos" (índice -1)
    selectedOrderIndex.value = -1;
  }
  
  print('🎯 inicializarConMesa: ${pedidos.length} pedidos, selectedOrderIndex=${selectedOrderIndex.value}');
  
  // Limpiar productos seleccionados
  productosSeleccionados.clear();
}


  void _setupOrdersListener() {
  try {
    final ordersController = Get.find<OrdersController>();
    
    ever(ordersController.mesasConPedidos, (List<dynamic> mesas) {
      if (!isUpdating.value) {
        print('🔄 Órdenes actualizadas, refrescando modal...');
        
        // Verificar si la mesa actual cambió en número de pedidos
        final mesaActualizada = mesas.firstWhere(
          (mesa) => mesa['numeroMesa'] == _mesaActual['numeroMesa'],
          orElse: () => _mesaActual,
        );
        
        final pedidos = mesaActualizada['pedidos'] as List? ?? [];
        
        print('🎯 Listener: ${pedidos.length} pedidos, selectedOrderIndex actual=${selectedOrderIndex.value}');
        
        // Si hay más de un pedido y está seleccionado "Todos", cambiar al primer pedido
        if (pedidos.length > 1 && selectedOrderIndex.value == -1) {
          selectedOrderIndex.value = 0;
          productosSeleccionados.clear();
          print('🎯 Cambiando a primer pedido (múltiples pedidos)');
        }
        // Si hay un solo pedido y no está seleccionado, seleccionarlo
        else if (pedidos.length == 1 && selectedOrderIndex.value != 0) {
          selectedOrderIndex.value = 0;
          productosSeleccionados.clear();
          print('🎯 Seleccionando único pedido');
        }
        // Si no hay pedidos, ir a vista "Todos"
        else if (pedidos.length == 0 && selectedOrderIndex.value != -1) {
          selectedOrderIndex.value = -1;
          productosSeleccionados.clear();
          print('🎯 Sin pedidos, vista Todos');
        }
        // Si el índice seleccionado es mayor al número de pedidos disponibles, ajustar
        else if (selectedOrderIndex.value >= pedidos.length) {
          selectedOrderIndex.value = pedidos.length > 0 ? 0 : -1;
          productosSeleccionados.clear();
          print('🎯 Ajustando índice fuera de rango');
        }
        
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
      
      // Excluir productos cancelados y pagados del cálculo
      if (detalleId != null && 
          productosSeleccionados.contains(detalleId) && 
          statusDetalle != 'cancelado' && 
          statusDetalle != 'pagado') {
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
      
      // Excluir productos cancelados y pagados del total
      if (status != 'cancelado' && status != 'pagado') {
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

  bool mesaTieneProductosEnProceso() {
  for (var pedido in pedidos) {
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        // Solo considerar como "en proceso" los que realmente están en proceso
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
      // Puede ser pagado si tiene productos completados (no cancelados ni ya pagados)
      if (status == 'completado') return true;
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
  void cambiarEstadoProducto(Map<String, dynamic> producto, String nuevoEstado) async {
    final detalleId = producto['detalleId'] as int;
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    final pedidoId = producto['pedidoId'];
    
    String titulo = nuevoEstado == 'completado' ? 'Completar Producto' : 'Cancelar Producto';
    String mensaje = nuevoEstado == 'completado' 
        ? '¿Marcar "$nombreProducto" como completado?'
        : '¿Está seguro de que quiere cancelar "$nombreProducto"?\n\nEsta acción no se puede deshacer.';
    
    String textoBoton = nuevoEstado == 'completado' ? 'Completar' : 'Cancelar';
    Color colorBoton = nuevoEstado == 'completado' ? Colors.green : Colors.red;
    
     final controller = Get.find<OrdersController>();
        await controller.actualizarEstadoOrden(detalleId, nuevoEstado);
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
    

      Uri uri = Uri.parse('${controller.defaultApiServer}/ordenes/detalle/$detalleId/actualizarCantidad/');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'cantidad': nuevaCantidad}),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
         
          
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
        await pagarPedidoEspecifico(pedido, detalleIds, total);
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

  Future<void> pagarPedidoEspecifico(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
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

    // En lugar de usar procesarDetalleId, marcar cada detalle como "pagado"
    for (int detalleId in detalleIds) {
      try {
        // Marcar el producto como pagado
        await controller.actualizarEstadoOrden(detalleId, 'pagado');
        
        // Buscar el detalle para obtener su precio y calcular el total
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario = (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;
          exitosos++;
        }
      } catch (e) {
        print('❌ Error marcando detalle $detalleId como pagado: $e');
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

Map<String, dynamic>? _buscarDetallePorId(int detalleId) {
  for (var pedido in pedidos) {
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        if (detalleMap['detalleId'] == detalleId) {
          return detalleMap;
        }
      }
    } catch (e) {
      print('❌ Error buscando detalle: $e');
      continue;
    }
  }
  return null;
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
    case 'pagado': return Colors.blue; // Color azul para productos pagados
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
  void confirmarPagoYLiberacion(Map<String, dynamic> pedido) {
  final pedidoId = pedido['pedidoId'];
  final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
  final total = calcularTotalPedido(pedido);
  final detalleIds = _obtenerDetalleIdsDePedido(pedido);
  final esUnico = pedidos.length == 1;
  
  String titulo = esUnico ? 'Pagar y Liberar Mesa' : 'Último Pedido - Pagar y Liberar';
  String mensaje = esUnico 
      ? '¿Confirmar el pago y liberar la Mesa $numeroMesa?\n\n'
      : '🎉 ¡Este es el último pedido pendiente!\n\n¿Confirmar el pago y liberar la Mesa $numeroMesa?\n\n';
  
  mensaje += 'Pedido: $nombreOrden\n'
             'ID: #$pedidoId\n'
             'Total: \${total.toStringAsFixed(2)}\n\n'
             'Esta acción procesará el pago e inmediatamente liberará la mesa.';
  
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.confirm,
    title: titulo,
    text: mensaje,
    confirmBtnText: 'Pagar y Liberar',
    cancelBtnText: 'Cancelar',
    confirmBtnColor: Color(0xFF27AE60),
    onConfirmBtnTap: () async {
      Get.back();
      Get.back();
      await _pagarYLiberarMesa(pedido, detalleIds, total);
    },
  );
}
Future<void> _pagarYLiberarMesa(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    // Mostrar diálogo de progreso
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando pago y liberando mesa...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Paso 1: Conectar impresora
    final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
    if (!impresoraConectada) {
      print('⚠️ Impresora no disponible, continuando sin imprimir...');
    }

    // Paso 2: Procesar el pago
    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;

    for (int detalleId in detalleIds) {
      try {
        // Marcar el producto como pagado
        await controller.actualizarEstadoOrden(detalleId, 'pagado');
        
        // Buscar el detalle para obtener su precio y calcular el total
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario = (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;
          exitosos++;
        }
      } catch (e) {
        print('❌ Error marcando detalle $detalleId como pagado: $e');
        fallidos++;
      }
    }

    // Paso 3: Liberar mesa (solo si el pago fue exitoso)
    bool mesaLiberada = false;
    if (fallidos == 0) {
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
          mesaLiberada = data['success'] == true;
        }
      } catch (e) {
        print('❌ Error liberando mesa: $e');
      }
    }

    // Paso 4: Imprimir ticket (si hay impresora y el pago fue exitoso)
    if (fallidos == 0 && impresoraConectada) {
      try {
        await printerService.imprimirTicket(pedido, totalReal);
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    // Cerrar diálogo de progreso
    Get.back();

    // Paso 5: Mostrar resultado
    if (fallidos == 0 && mesaLiberada) {
      // Éxito completo
      String mensaje = 'Mesa $numeroMesa liberada exitosamente\n'
                      'Pedido #$pedidoId pagado\n'
                      'Total: \${totalReal.toStringAsFixed(2)}';
      
      if (impresoraConectada) {
        mensaje += '\n✅ Ticket impreso';
      }
      
      Get.snackbar(
        'Operación Exitosa',
        mensaje,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      // Cerrar el modal y refrescar datos
      Get.back();
      await controller.refrescarDatos();
      
    } else if (fallidos == 0 && !mesaLiberada) {
      // Pago exitoso pero error liberando mesa
      Get.snackbar(
        'Pago Exitoso - Error al Liberar',
        'Pedido #$pedidoId pagado correctamente\nTotal: \${totalReal.toStringAsFixed(2)}\n\n❌ No se pudo liberar la mesa automáticamente',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      await controller.refrescarDatos();
      
    } else {
      // Error en el pago
      Get.snackbar(
        'Error en la Operación',
        'No se pudo completar el pago del pedido #$pedidoId\nExitosos: $exitosos items\nFallidos: $fallidos items',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }

  } catch (e) {
    // Cerrar diálogo de progreso si está abierto
    if (Get.isDialogOpen ?? false) Get.back();
    
    Get.snackbar(
      'Error',
      'Error al procesar pago y liberación: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } finally {
    await printerService.desconectar();
  }
}
bool esUltimoPedidoPendiente(Map<String, dynamic> pedidoActual) {
  int pedidosConProductosPendientes = 0;
  
  for (var pedido in pedidos) {
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      bool tienePendientes = false;
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        
        // Si tiene productos en proceso o completados (no pagados ni cancelados)
        if (status == 'proceso' || status == 'completado') {
          tienePendientes = true;
          break;
        }
      }
      
      if (tienePendientes) {
        pedidosConProductosPendientes++;
      }
    } catch (e) {
      print('❌ Error verificando pedido pendiente: $e');
      continue;
    }
  }
  
  // Es el último pendiente si solo hay 1 pedido con productos pendientes
  // y el pedido actual puede ser pagado
  return pedidosConProductosPendientes == 1 && puedeSerPagado(pedidoActual);
}

// Método para verificar si todos los demás pedidos están completamente pagados
bool todosLosDemasPedidosEstanPagados(int pedidoActualIndex) {
  for (int i = 0; i < pedidos.length; i++) {
    if (i == pedidoActualIndex) continue; // Saltar el pedido actual
    
    try {
      final pedidoMap = Map<String, dynamic>.from(pedidos[i]);
      final detalles = pedidoMap['detalles'] as List? ?? [];
      
      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
        
        // Si encuentra cualquier producto que no esté pagado ni cancelado
        if (status != 'pagado' && status != 'cancelado') {
          return false;
        }
      }
    } catch (e) {
      print('❌ Error verificando pedido pagado: $e');
      continue;
    }
  }
  
  return true;
}

List<Map<String, dynamic>> getProductosSeleccionadosDelPedidoActual() {
  if (selectedOrderIndex.value == -1 || productosSeleccionados.isEmpty) {
    return [];
  }
  
  List<Map<String, dynamic>> productosSeleccionadosDelPedido = [];
  final productos = getProductosDePedido(selectedOrderIndex.value);
  
  for (var producto in productos) {
    final detalleId = producto['detalleId'] as int?;
    final status = producto['statusDetalle'] as String? ?? 'proceso';
    
    if (detalleId != null && 
        productosSeleccionados.contains(detalleId) && 
        status == 'completado') {
      productosSeleccionadosDelPedido.add(producto);
    }
  }
  
  return productosSeleccionadosDelPedido;
}
bool pagandoSeleccionadosCompletariaElPedido() {
  if (selectedOrderIndex.value == -1) return false;
  
  final pedido = pedidos[selectedOrderIndex.value];
  final pedidoMap = Map<String, dynamic>.from(pedido);
  final detalles = pedidoMap['detalles'] as List? ?? [];
  
  for (var detalle in detalles) {
    try {
      final detalleMap = Map<String, dynamic>.from(detalle);
      final detalleId = detalleMap['detalleId'] as int?;
      final status = detalleMap['statusDetalle'] as String? ?? 'proceso';
      
      // Si hay algún producto que no esté seleccionado, cancelado o ya pagado
      if (detalleId != null && 
          status != 'cancelado' && 
          status != 'pagado' && 
          !productosSeleccionados.contains(detalleId)) {
        return false; // Quedarían productos pendientes
      }
    } catch (e) {
      print('❌ Error verificando detalle: $e');
      continue;
    }
  }
  
  return true; // Todos los productos estarían pagados, cancelados o seleccionados
}
bool completandoEstePedidoSeriaElUltimo() {
  if (selectedOrderIndex.value == -1) return false;
  
  // Verificar que todos los demás pedidos estén completamente pagados
  return todosLosDemasPedidosEstanPagados(selectedOrderIndex.value);
}
String getTipoBotonPago() {
  final productosSeleccionados = getProductosSeleccionadosDelPedidoActual();
  
  if (productosSeleccionados.isEmpty) {
    return 'ninguno'; // No mostrar botón
  }
  
  final completariaElPedido = pagandoSeleccionadosCompletariaElPedido();
  final seriaElUltimo = completandoEstePedidoSeriaElUltimo();
  
  if (completariaElPedido && seriaElUltimo) {
    return 'pagar_y_liberar'; // PAGAR Y LIBERAR MESA
  } else {
    return 'pagar_seleccionados'; // PAGAR SELECCIONADOS
  }
}

double calcularTotalProductosSeleccionadosDelPedido() {
  final productosSeleccionados = getProductosSeleccionadosDelPedidoActual();
  double total = 0.0;
  
  for (var producto in productosSeleccionados) {
    try {
      final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
      final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
      total += precioUnitario * cantidad;
    } catch (e) {
      print('❌ Error calculando producto seleccionado: $e');
      continue;
    }
  }
  
  return total;
}
void confirmarPagoProductosSeleccionados() {
  final productosSeleccionados = getProductosSeleccionadosDelPedidoActual();
  final pedido = pedidos[selectedOrderIndex.value];
  final pedidoId = pedido['pedidoId'];
  final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
  final total = calcularTotalProductosSeleccionadosDelPedido();
  final tipoBoton = getTipoBotonPago();
  
  String titulo = tipoBoton == 'pagar_y_liberar' 
      ? 'Pagar Seleccionados y Liberar Mesa'
      : 'Pagar Productos Seleccionados';
  
  String mensaje = tipoBoton == 'pagar_y_liberar'
      ? '🎉 Al pagar estos productos se completará el último pedido pendiente.\n\n'
      : '';
  
  mensaje += '¿Confirmar el pago de los productos seleccionados?\n\n'
             'Pedido: $nombreOrden\n'
             'ID: #$pedidoId\n'
             'Productos: ${productosSeleccionados.length}\n'
             'Total: \$${total.toStringAsFixed(2)}';
  
  if (tipoBoton == 'pagar_y_liberar') {
    mensaje += '\n\n🏠 La mesa será liberada automáticamente.';
  }
  
  String textoBoton = tipoBoton == 'pagar_y_liberar' 
      ? 'Pagar y Liberar'
      : 'Pagar Seleccionados';
  
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.confirm,
    title: titulo,
    text: mensaje,
    confirmBtnText: textoBoton,
    cancelBtnText: 'Cancelar',
    confirmBtnColor: Color(0xFF27AE60),
    onConfirmBtnTap: () async {
      Get.back();
      
      if (tipoBoton == 'pagar_y_liberar') {
        await _pagarSeleccionadosYLiberarMesa(productosSeleccionados, pedido, total);
      } else {
        await _pagarProductosSeleccionados(productosSeleccionados, pedido, total);
      }
    },
  );
}

Future<void> _pagarProductosSeleccionados(List<Map<String, dynamic>> productos, Map<String, dynamic> pedido, double totalEstimado) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando pago de productos seleccionados...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;

    for (var producto in productos) {
      try {
        final detalleId = producto['detalleId'] as int;
        await controller.actualizarEstadoOrden(detalleId, 'pagado');
        
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        totalReal += precioUnitario * cantidad;
        exitosos++;
      } catch (e) {
        print('❌ Error pagando producto: $e');
        fallidos++;
      }
    }

    Get.back(); // Cerrar diálogo de progreso

    if (fallidos == 0) {
      Get.snackbar(
        'Pago Exitoso',
        'Productos pagados correctamente\nPedido #$pedidoId\n$exitosos productos pagados\nTotal: \$${totalReal.toStringAsFixed(2)}',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
      // Limpiar selección
      productosSeleccionados.clear();
      await controller.refrescarDatos();
      
    } else {
      Get.snackbar(
        'Pago Parcial',
        'Algunos productos no se pudieron procesar\nExitosos: $exitosos\nFallidos: $fallidos',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }

  } catch (e) {
    if (Get.isDialogOpen ?? false) Get.back();
    
    Get.snackbar(
      'Error',
      'Error al procesar pago: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }
}

// Método para pagar seleccionados y liberar mesa
Future<void> _pagarSeleccionadosYLiberarMesa(List<Map<String, dynamic>> productos, Map<String, dynamic> pedido, double totalEstimado) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando pago y liberando mesa...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Conectar impresora
    final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();

    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;

    // Pagar productos seleccionados
    for (var producto in productos) {
      try {
        final detalleId = producto['detalleId'] as int;
        await controller.actualizarEstadoOrden(detalleId, 'pagado');
        
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        totalReal += precioUnitario * cantidad;
        exitosos++;
      } catch (e) {
        print('❌ Error pagando producto: $e');
        fallidos++;
      }
    }

    // Liberar mesa si el pago fue exitoso
    bool mesaLiberada = false;
    if (fallidos == 0) {
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
          mesaLiberada = data['success'] == true;
        }
      } catch (e) {
        print('❌ Error liberando mesa: $e');
      }
    }

    // Imprimir ticket
    if (fallidos == 0 && impresoraConectada) {
      try {
        await printerService.imprimirTicket(pedido, totalReal);
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    Get.back(); // Cerrar diálogo de progreso

    if (fallidos == 0 && mesaLiberada) {
      String mensaje = '🎉 Mesa $numeroMesa liberada exitosamente!\n'
                      'Productos seleccionados pagados\n'
                      'Pedido #$pedidoId completado\n'
                      'Total: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraConectada) {
        mensaje += '\n✅ Ticket impreso';
      }
      
      Get.snackbar(
        'Operación Exitosa',
        mensaje,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      // Limpiar selección y cerrar modal
      productosSeleccionados.clear();
      Get.back();
      await controller.refrescarDatos();
      
    } else {
      String mensaje = fallidos == 0 
          ? 'Productos pagados correctamente pero no se pudo liberar la mesa'
          : 'Error en el proceso de pago y liberación';
      
      Get.snackbar(
        'Error Parcial',
        mensaje,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      // Limpiar selección aunque haya errores
      productosSeleccionados.clear();
      await controller.refrescarDatos();
    }

  } catch (e) {
    if (Get.isDialogOpen ?? false) Get.back();
    
    Get.snackbar(
      'Error',
      'Error al procesar pago y liberación: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } finally {
    await printerService.desconectar();
  }
}
}
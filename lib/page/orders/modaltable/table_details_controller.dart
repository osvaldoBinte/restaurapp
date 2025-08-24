import 'dart:convert';
import 'dart:io';
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

  // ✅ REEMPLAZA tu función confirmarPagoPedido con esta versión mejorada

void confirmarPagoPedido(Map<String, dynamic> pedido) async {
  final pedidoId = pedido['pedidoId'];
  final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
  final total = calcularTotalPedido(pedido);
  final detalleIds = _obtenerDetalleIdsDePedido(pedido);
  
  try {
    // ✅ PASO 1: Mostrar diálogo de "Verificando impresora..."
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🔍 Verificando impresora disponible...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // ✅ PASO 2: Realizar diagnóstico de impresora
    bool impresoraConectada = await printerService.conectarImpresoraConDiagnostico();
    
    // Cerrar el diálogo de "verificando"
    Get.back();

    // ✅ PASO 3: Mostrar resultado del diagnóstico Y confirmación de pago juntos
    String tituloDialog;
    String mensajeDialog;
    QuickAlertType tipoDialog;
    IconData icono;

    if (impresoraConectada) {
      tituloDialog = '✅ Confirmar Pago con Impresión';
      mensajeDialog = '🖨️ IMPRESORA DETECTADA Y LISTA:\n\n'
          '📍 Sistema: ${Platform.operatingSystem}\n'
          '🔗 Impresora: ${printerService.selectedPrinterName}\n'
          '📊 Total encontradas: ${printerService.impresorasDetectadas.length}\n'
          '\n'
          '💰 DETALLES DEL PAGO:\n'
          'Pedido: $nombreOrden\n'
          'ID: #$pedidoId\n'
          'Total: \$${total.toStringAsFixed(2)}\n'
          '\n'
          '¿Confirmar el pago e imprimir ticket?';
      tipoDialog = QuickAlertType.success;
    } else {
      tituloDialog = '⚠️ Confirmar Pago sin Impresión';
      mensajeDialog = '🔍 ESTADO DE IMPRESORAS:\n\n'
          '📍 Sistema: ${Platform.operatingSystem}\n'
          '📊 Impresoras encontradas: ${printerService.impresorasDetectadas.length}\n';
      
      if (printerService.impresorasDetectadas.isNotEmpty) {
        mensajeDialog += '\n🖨️ Lista detectada:\n';
        for (int i = 0; i < printerService.impresorasDetectadas.length && i < 3; i++) {
          mensajeDialog += '  ${i+1}. ${printerService.impresorasDetectadas[i]}\n';
        }
      } else {
        mensajeDialog += '❌ No se detectaron impresoras\n';
      }
      
      mensajeDialog += '\n💰 DETALLES DEL PAGO:\n'
                      'Pedido: $nombreOrden\n'
                      'ID: #$pedidoId\n'
                      'Total: \$${total.toStringAsFixed(2)}\n'
                      '\n'
                      '⚠️ El pago se procesará SIN imprimir ticket.\n'
                      '¿Desea continuar?';
      tipoDialog = QuickAlertType.warning;
    }

    // ✅ PASO 4: Mostrar diálogo de confirmación con información de impresora
    QuickAlert.show(
      context: Get.context!,
      type: tipoDialog,
      title: tituloDialog,
      text: mensajeDialog,
      confirmBtnText: impresoraConectada ? 'Pagar e Imprimir' : 'Pagar sin Ticket',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: impresoraConectada ? Color(0xFF27AE60) : Color(0xFFFF9800),
      onConfirmBtnTap: () async {
        Get.back();
        // ✅ PASO 5: Proceder con el pago (la impresora ya está conectada si es posible)
        await pagarPedidoEspecificoConImpresoraYaVerificada(pedido, detalleIds, total, impresoraConectada);
      },
      onCancelBtnTap: () {
        Get.back();
        // Desconectar impresora si se cancela
        printerService.desconectar();
      },
    );

  } catch (e) {
    // Cerrar diálogo si hay error
    if (Get.isDialogOpen ?? false) Get.back();
    
    print('❌ Error en diagnóstico de impresora: $e');
    
    // Mostrar error y opción de continuar sin diagnóstico
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: '❌ Error de Diagnóstico',
      text: '🔍 No se pudo verificar el estado de la impresora:\n\n'
          'Error: $e\n\n'
          '💰 DETALLES DEL PAGO:\n'
          'Pedido: $nombreOrden\n'
          'ID: #$pedidoId\n'
          'Total: \$${total.toStringAsFixed(2)}\n\n'
          '¿Procesar pago sin verificar impresora?',
      confirmBtnText: 'Pagar sin Verificar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back();
        // Proceder con el método original como fallback
        await pagarPedidoEspecificoConImpresoraYaVerificada(pedido, detalleIds, total, false);
      },
    );
  }
}

// ✅ NUEVA FUNCIÓN: Versión optimizada que NO vuelve a verificar la impresora
Future<void> pagarPedidoEspecificoConImpresoraYaVerificada(
    Map<String, dynamic> pedido, 
    List<int> detalleIds, 
    double totalEstimado,
    bool impresoraYaConectada) async {
  
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    // Mostrar progreso de pago
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('💰 Procesando pago...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;

    // Procesar pago de cada producto
    for (int detalleId in detalleIds) {
      try {
        await controller.actualizarEstadoOrden(detalleId, 'pagado');
        
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

    // Cerrar diálogo de progreso
    Get.back();

    // Intentar impresión solo si la impresora ya estaba conectada
    bool ticketImpreso = false;
    if (fallidos == 0 && impresoraYaConectada) {
      try {
        // Actualizar progreso
        Get.dialog(
          AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('🖨️ Imprimiendo ticket...'),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        await printerService.imprimirTicket(pedido, totalReal);
        ticketImpreso = true;
        
        // Cerrar diálogo de impresión
        Get.back();
        
      } catch (e) {
        // Cerrar diálogo de impresión
        if (Get.isDialogOpen ?? false) Get.back();
        
        print('❌ Error en impresión: $e');
        
        // Mostrar error de impresión pero continuar con éxito de pago
        Get.snackbar(
          '⚠️ Pago Exitoso - Error de Impresión',
          'El pago se procesó correctamente pero hubo un problema al imprimir:\n$e',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    }

    // Mostrar resultado final
    if (fallidos == 0) {
      String mensaje = 'Pedido #$pedidoId pagado correctamente\nTotal: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraYaConectada) {
        if (ticketImpreso) {
          mensaje += '\n✅ Ticket impreso correctamente';
        } else {
          mensaje += '\n⚠️ Pagado sin ticket (error de impresión)';
        }
      } else {
        mensaje += '\n📋 Procesado sin impresión (sin impresora)';
      }
      
      Get.snackbar(
        'Pago Exitoso',
        mensaje,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
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
    // Cerrar cualquier diálogo abierto
    if (Get.isDialogOpen ?? false) Get.back();
    
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

// ✅ TAMBIÉN ACTUALIZA confirmarPagoYLiberacion con el mismo patrón
void confirmarPagoYLiberacion(Map<String, dynamic> pedido) async {
  final pedidoId = pedido['pedidoId'];
  final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
  final total = calcularTotalPedido(pedido);
  final detalleIds = _obtenerDetalleIdsDePedido(pedido);
  final esUnico = pedidos.length == 1;
  
  try {
    // Verificar impresora primero
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🔍 Verificando impresora para pago final...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    bool impresoraConectada = await printerService.conectarImpresoraConDiagnostico();
    Get.back();

    // Crear mensaje según disponibilidad de impresora
    String titulo = esUnico ? '💰 Pagar y Liberar Mesa' : '🎉 Último Pedido - Pagar y Liberar';
    String mensaje;
    
    if (impresoraConectada) {
      mensaje = '✅ IMPRESORA LISTA PARA TICKET FINAL:\n\n'
          '🖨️ Impresora: ${printerService.selectedPrinterName}\n'
          '📊 Total detectadas: ${printerService.impresorasDetectadas.length}\n\n';
    } else {
      mensaje = '⚠️ SIN IMPRESORA DISPONIBLE:\n\n'
          '📊 Impresoras detectadas: ${printerService.impresorasDetectadas.length}\n'
          '❌ No se imprimirá ticket final\n\n';
    }
    
    if (!esUnico) {
      mensaje += '🎉 ¡Este es el último pedido pendiente!\n\n';
    }
    
    mensaje += '💰 DETALLES DEL PAGO FINAL:\n'
               'Pedido: $nombreOrden\n'
               'ID: #$pedidoId\n'
               'Total: \$${total.toStringAsFixed(2)}\n\n'
               '🏠 Esta acción procesará el pago y liberará la Mesa $numeroMesa.';
    
    QuickAlertType tipoDialog = impresoraConectada ? QuickAlertType.success : QuickAlertType.warning;
    String textoBoton = impresoraConectada ? 'Pagar, Imprimir y Liberar' : 'Pagar y Liberar (Sin Ticket)';
    Color colorBoton = impresoraConectada ? Color(0xFF27AE60) : Color(0xFFFF9800);
    
    QuickAlert.show(
      context: Get.context!,
      type: tipoDialog,
      title: titulo,
      text: mensaje,
      confirmBtnText: textoBoton,
      cancelBtnText: 'Cancelar',
      confirmBtnColor: colorBoton,
      onConfirmBtnTap: () async {
        Get.back();
        Get.back(); // Cerrar también el modal de detalles de mesa
        await _pagarYLiberarMesaConImpresoraVerificada(pedido, detalleIds, total, impresoraConectada);
      },
      onCancelBtnTap: () {
        Get.back();
        printerService.desconectar();
      },
    );

  } catch (e) {
    if (Get.isDialogOpen ?? false) Get.back();
    
    // Fallback a diálogo simple sin diagnóstico
    String titulo = esUnico ? 'Pagar y Liberar Mesa' : 'Último Pedido - Pagar y Liberar';
    String mensaje = '❌ Error verificando impresora: $e\n\n'
                    'Pedido: $nombreOrden\n'
                    'ID: #$pedidoId\n'
                    'Total: \$${total.toStringAsFixed(2)}\n\n'
                    '¿Continuar sin verificar impresora?';
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.warning,
      title: titulo,
      text: mensaje,
      confirmBtnText: 'Continuar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back();
        Get.back();
        await _pagarYLiberarMesaConImpresoraVerificada(pedido, detalleIds, total, false);
      },
    );
  }
}

// ✅ FUNCIÓN AUXILIAR: Pagar y liberar con impresora ya verificada
Future<void> _pagarYLiberarMesaConImpresoraVerificada(
    Map<String, dynamic> pedido, 
    List<int> detalleIds, 
    double totalEstimado,
    bool impresoraYaConectada) async {
  
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
            Text('💰 Procesando pago final y liberando mesa...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    // Procesar pago
    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;
    List<Map<String, dynamic>> productosRecienPagados = [];

    for (int detalleId in detalleIds) {
      try {
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final statusActual = detalle['statusDetalle'] as String? ?? 'proceso';
          
          if (statusActual != 'pagado') {
            await controller.actualizarEstadoOrden(detalleId, 'pagado');
            
            final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
            final precioUnitario = (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
            totalReal += precioUnitario * cantidad;
            exitosos++;
            
            productosRecienPagados.add({
              ...detalle,
              'statusDetalle': 'pagado',
            });
          }
        }
      } catch (e) {
        print('❌ Error marcando detalle $detalleId como pagado: $e');
        fallidos++;
      }
    }

    // Liberar mesa
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

    // Imprimir ticket si es posible
    bool ticketImpreso = false;
    if (fallidos == 0 && impresoraYaConectada && productosRecienPagados.isNotEmpty) {
      try {
        final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
          productosRecienPagados, 
          pedido, 
          totalReal,
          'pago_final_liberacion'
        );
        
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        ticketImpreso = true;
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    Get.back(); // Cerrar diálogo de progreso

    // Mostrar resultado
    if (fallidos == 0 && mesaLiberada) {
      String mensaje = '🎉 Mesa $numeroMesa liberada exitosamente!\n'
                      'Productos finales pagados: $exitosos\n'
                      'Total de esta transacción: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraYaConectada) {
        if (ticketImpreso && productosRecienPagados.isNotEmpty) {
          mensaje += '\n✅ Ticket final impreso';
        } else if (productosRecienPagados.isEmpty) {
          mensaje += '\n📋 No había productos pendientes por pagar';
        } else {
          mensaje += '\n⚠️ Error al imprimir ticket final';
        }
      } else {
        mensaje += '\n📋 Procesado sin impresión (sin impresora)';
      }
      
      Get.snackbar(
        'Operación Exitosa',
        mensaje,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      Get.back(); // Cerrar modal de mesa
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
      String mensaje = 'Pedido #$pedidoId pagado correctamente\nTotal: \$${totalReal.toStringAsFixed(2)}';
      
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

    // Paso 2: Procesar el pago SOLO de los productos completados (no pagados anteriormente)
    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;
    List<Map<String, dynamic>> productosRecienPagados = []; // ✅ NUEVO: Solo productos de ESTA transacción

    for (int detalleId in detalleIds) {
      try {
        // Buscar el detalle ANTES de marcarlo como pagado para obtener su estado actual
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final statusActual = detalle['statusDetalle'] as String? ?? 'proceso';
          
          // ✅ FILTRO CRÍTICO: Solo procesar si NO está ya pagado
          if (statusActual != 'pagado') {
            // Marcar el producto como pagado
            await controller.actualizarEstadoOrden(detalleId, 'pagado');
            
            final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
            final precioUnitario = (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
            totalReal += precioUnitario * cantidad;
            exitosos++;
            
            // ✅ CLAVE: Solo agregar productos que se pagaron EN ESTA transacción
            productosRecienPagados.add({
              ...detalle,
              'statusDetalle': 'pagado', // Marcar como recién pagado para el ticket
            });
            
            print('✅ Producto pagado en esta transacción: ${detalle['nombreProducto']} x$cantidad = \$${(precioUnitario * cantidad).toStringAsFixed(2)}');
          } else {
            print('⏭️ Producto ya pagado anteriormente, omitiendo: ${detalle['nombreProducto']}');
          }
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

    // Paso 4: Imprimir ticket SOLO con productos recién pagados
    if (fallidos == 0 && impresoraConectada && productosRecienPagados.isNotEmpty) {
      try {
        print('🎫 Creando ticket SOLO con ${productosRecienPagados.length} productos recién pagados (total: \$${totalReal.toStringAsFixed(2)})');
        
        // ✅ USAR SOLO productos recién pagados, NO todos los del pedido
        final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
          productosRecienPagados, 
          pedido, 
          totalReal,
          'pago_final_liberacion' // Tipo especial para diferenciarlo
        );
        
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        print('✅ Ticket impreso SOLO con productos de esta transacción');
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    // Cerrar diálogo de progreso
    Get.back();
    Get.back();

    // Paso 5: Mostrar resultado
    if (fallidos == 0 && mesaLiberada) {
      // Éxito completo
      String mensaje = 'Mesa $numeroMesa liberada exitosamente\n'
                      'Productos finales pagados: $exitosos\n'
                      'Total de esta transacción: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraConectada && productosRecienPagados.isNotEmpty) {
        mensaje += '\n✅ Ticket impreso con productos de esta transacción';
      } else if (productosRecienPagados.isEmpty) {
        mensaje += '\n📋 No había productos pendientes por pagar';
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
        'Productos pagados correctamente\nTotal: \$${totalReal.toStringAsFixed(2)}\n\n❌ No se pudo liberar la mesa automáticamente',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      await controller.refrescarDatos();
      
    } else {
      // Error en el pago
      Get.snackbar(
        'Error en la Operación',
        'No se pudo completar el pago\nExitosos: $exitosos items\nFallidos: $fallidos items',
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

// ✅ NUEVA FUNCIÓN: Crear ticket con filtro especial y tipo de transacción
Map<String, dynamic> _crearPedidoParaTicketConFiltro(
  List<Map<String, dynamic>> productosParaTicket, 
  Map<String, dynamic> pedidoOriginal, 
  double totalCalculado,
  String tipoTransaccion
) {
  print('🎫 Creando ticket filtrado con ${productosParaTicket.length} productos para $tipoTransaccion');
  
  // Crear detalles para el ticket (ya filtrados)
  List<Map<String, dynamic>> detallesParaTicket = [];
  
  for (var producto in productosParaTicket) {
    try {
      final detalleParaTicket = {
        'detalleId': producto['detalleId'],
        'nombreProducto': producto['nombreProducto'] ?? 'Producto',
        'cantidad': producto['cantidad'] ?? 1,
        'precioUnitario': (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0,
        'statusDetalle': 'pagado', // Todos están recién pagados
        'observaciones': producto['observaciones'] ?? '',
        'categoria': producto['categoria'] ?? '',
      };
      
      detallesParaTicket.add(detalleParaTicket);
      
      final subtotal = detalleParaTicket['precioUnitario'] * detalleParaTicket['cantidad'];
      print('✅ Producto en ticket: ${detalleParaTicket['nombreProducto']} x${detalleParaTicket['cantidad']} = \$${subtotal.toStringAsFixed(2)}');
    } catch (e) {
      print('❌ Error procesando producto para ticket: $e');
      continue;
    }
  }
  
  // Crear estructura de pedido para el ticket
  final pedidoParaTicket = {
    'pedidoId': pedidoOriginal['pedidoId'],
    'nombreOrden': pedidoOriginal['nombreOrden'] ?? 'Sin nombre',
    'detalles': detallesParaTicket,
    'totalCalculado': totalCalculado,
    'tipoTicket': tipoTransaccion,
    'fechaCompra': DateTime.now().toIso8601String(),
    'mesa': numeroMesa,
    // ✅ Información adicional para el ticket
    'esPagoFinal': tipoTransaccion == 'pago_final_liberacion',
    'productosEnTransaccion': productosParaTicket.length,
  };
  
  print('🎫 Ticket filtrado creado exitosamente:');
  print('   - Tipo: $tipoTransaccion');
  print('   - Pedido ID: ${pedidoParaTicket['pedidoId']}');
  print('   - Productos en ESTA transacción: ${detallesParaTicket.length}');
  print('   - Total de ESTA transacción: \$${totalCalculado.toStringAsFixed(2)}');
  
  return pedidoParaTicket;
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

    // ✅ AGREGAR: Conectar impresora para productos seleccionados también
    final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
    if (!impresoraConectada) {
      print('⚠️ Impresora no disponible para productos seleccionados');
    }

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

    // ✅ NUEVO: Imprimir ticket para productos seleccionados si todo fue exitoso
    if (fallidos == 0 && impresoraConectada) {
      try {
        // Crear estructura de pedido para ticket con solo los productos seleccionados
        final pedidoParaTicket = _crearPedidoParaTicket(productos, pedido, totalReal);
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        print('✅ Ticket impreso para productos seleccionados');
      } catch (e) {
        print('❌ Error en impresión de productos seleccionados: $e');
      }
    }

    if (fallidos == 0) {
      String mensaje = 'Productos pagados correctamente\nPedido #$pedidoId\n$exitosos productos pagados\nTotal: \$${totalReal.toStringAsFixed(2)}';
      
      // ✅ AGREGAR: Incluir información de impresión
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
  } finally {
    // ✅ AGREGAR: Desconectar impresora
    await printerService.desconectar();
  }
}
Map<String, dynamic> _crearPedidoParaTicket(List<Map<String, dynamic>> productosSeleccionados, Map<String, dynamic> pedidoOriginal, double totalCalculado) {
  print('🎫 Creando pedido para ticket con ${productosSeleccionados.length} productos seleccionados');
  
  // Filtrar solo los productos seleccionados y crear detalles para el ticket
  List<Map<String, dynamic>> detallesParaTicket = [];
  
  for (var producto in productosSeleccionados) {
    try {
      // Crear detalle para el ticket manteniendo la estructura esperada
      final detalleParaTicket = {
        'detalleId': producto['detalleId'],
        'nombreProducto': producto['nombreProducto'] ?? 'Producto',
        'cantidad': producto['cantidad'] ?? 1,
        'precioUnitario': (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0,
        'statusDetalle': 'pagado', // Marcar como pagado para el ticket
        'observaciones': producto['observaciones'] ?? '',
        'categoria': producto['categoria'] ?? '',
      };
      
      detallesParaTicket.add(detalleParaTicket);
      
      print('✅ Producto agregado al ticket: ${detalleParaTicket['nombreProducto']} x${detalleParaTicket['cantidad']}');
    } catch (e) {
      print('❌ Error procesando producto para ticket: $e');
      continue;
    }
  }
  
  // Crear estructura de pedido para el ticket
  final pedidoParaTicket = {
    'pedidoId': pedidoOriginal['pedidoId'],
    'nombreOrden': pedidoOriginal['nombreOrden'] ?? 'Sin nombre',
    'detalles': detallesParaTicket,
    'totalCalculado': totalCalculado,
    // Agregar información adicional para el ticket
    'tipoTicket': 'productos_seleccionados',
    'fechaCompra': DateTime.now().toIso8601String(),
    'mesa': numeroMesa,
  };
  
  print('🎫 Pedido para ticket creado:');
  print('   - Pedido ID: ${pedidoParaTicket['pedidoId']}');
  print('   - Nombre: ${pedidoParaTicket['nombreOrden']}');
  print('   - Productos: ${detallesParaTicket.length}');
  print('   - Total: \$${totalCalculado.toStringAsFixed(2)}');
  
  return pedidoParaTicket;
}


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
            Text('Procesando pago seleccionados y liberando mesa...'),
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
    List<Map<String, dynamic>> productosRecienPagados = []; // ✅ Solo productos de esta transacción

    // Pagar productos seleccionados
    for (var producto in productos) {
      try {
        final detalleId = producto['detalleId'] as int;
        final statusActual = producto['statusDetalle'] as String? ?? 'proceso';
        
        // ✅ FILTRO: Solo procesar si NO está ya pagado
        if (statusActual != 'pagado') {
          await controller.actualizarEstadoOrden(detalleId, 'pagado');
          
          final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;
          exitosos++;
          
          // Agregar solo productos recién pagados
          productosRecienPagados.add({
            ...producto,
            'statusDetalle': 'pagado',
          });
        } else {
          print('⏭️ Producto seleccionado ya estaba pagado: ${producto['nombreProducto']}');
        }
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

    // ✅ Imprimir ticket SOLO con productos recién pagados en esta transacción
    if (fallidos == 0 && impresoraConectada && productosRecienPagados.isNotEmpty) {
      try {
        print('🎫 Imprimiendo ticket solo con ${productosRecienPagados.length} productos recién pagados');
        final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
          productosRecienPagados, 
          pedido, 
          totalReal,
          'productos_seleccionados_liberacion'
        );
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        print('✅ Ticket impreso para pago y liberación de seleccionados');
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    Get.back(); 
    Get.back(); 
    
    if (fallidos == 0 && mesaLiberada) {
      String mensaje = '🎉 Mesa $numeroMesa liberada exitosamente!\n'
                      'Productos seleccionados pagados: $exitosos\n'
                      'Total de esta transacción: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraConectada && productosRecienPagados.isNotEmpty) {
        mensaje += '\n✅ Ticket impreso con productos de esta transacción';
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
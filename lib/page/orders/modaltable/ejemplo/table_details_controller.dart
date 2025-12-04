import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

import 'package:restaurapp/common/services/BluetoothPrinterService.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderController.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderScreen.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';
import 'package:restaurapp/page/orders/serivios/orden_service.dart';

class TableDetailsController extends GetxController {
  // Observables
  final selectedOrderIndex = (-1).obs; // -1 significa "todos los pedidos"
  final productosSeleccionados = <int>{}.obs;
  final isUpdating = false.obs;
  final isBluetoothConnected = false.obs;
  final isLiberandoTodasLasMesas = false.obs;
  final OrdenService _ordenService = OrdenService();

  // Services
  final UniversalPrinterService printerService = UniversalPrinterService();
  
  // Datos actuales
  Map<String, dynamic> _mesaActual = {};
  
  @override
  void onInit() {
    super.onInit();
    _setupOrdersListener(); 
  }
int obtenerConteoMesasConPendientes() {
      final ordersController = Get.find<OrdersController>();

  return ordersController.mesasConPedidos.length;
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

void cambiarEstadoProducto(Map<String, dynamic> producto, String nuevoEstado) async {
  final detalleId = producto['detalleId'] as int;
  final nombreProducto = producto['nombreProducto'] ?? 'Producto';
  final numeroMesaProducto = producto['numeroMesa'] ?? numeroMesa;
  
  // ✅ SI ES CANCELAR → ELIMINAR en lugar de cambiar estado
  if (nuevoEstado == 'cancelado') {
    _confirmarEliminarProducto(producto);
    return;
  }
  
  // ✅ SI ES COMPLETAR → Actualizar estado directamente SIN confirmación
  if (nuevoEstado == 'completado') {
    final controller = Get.find<OrdersController>();
    await controller.actualizarEstadoOrden(detalleId, nuevoEstado);
  }
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
    isUpdating.value = true; // Activar loading


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
    }finally {
    isUpdating.value = false; // Desactivar loading

      if (Get.isDialogOpen ?? false) Get.back();
      
    }
  }
void _confirmarEliminarProducto(Map<String, dynamic> producto) {
  final detalleId = producto['detalleId'] as int;
  final nombreProducto = producto['nombreProducto'] ?? 'Producto';
  final numeroMesaProducto = numeroMesa;
  
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.confirm,
    title: 'Eliminar Producto',
    text: '¿Está seguro de eliminar este producto?\n\n'
          'Mesa: $numeroMesaProducto\n'
          'Producto: $nombreProducto\n\n'
          '⚠️ Esta acción no se puede deshacer',
    confirmBtnText: 'Eliminar',
    cancelBtnText: 'Cancelar',
    confirmBtnColor: Color(0xFFE74C3C),
    onConfirmBtnTap: () async {
      Get.back(); // Cerrar diálogo de confirmación
      await _ejecutarEliminacionProducto(detalleId, nombreProducto);
    },
  );
}

/// ✅ NUEVO MÉTODO: Ejecutar eliminación usando el servicio
Future<void> _ejecutarEliminacionProducto(int detalleId, String nombreProducto) async {
  try {
    // Activar loading
    isUpdating.value = true;
    
    // Llamar al servicio de eliminación
    final resultado = await _ordenService.eliminarDetallePedido(detalleId);
    
    if (resultado['success'] == true) {
      // Mostrar éxito
      Get.snackbar(
        'Producto Eliminado',
        'El producto "$nombreProducto" ha sido eliminado correctamente',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      
      // Recargar datos
      final controller = Get.find<OrdersController>();
      await controller.refrescarDatos();
      
    } else {
      // Mostrar error
      final mensajeError = resultado['error'] ?? 'No se pudo eliminar el producto';
      _mostrarErrorCantidad(mensajeError);
    }
    
  } catch (e) {
    print('❌ Error al eliminar producto: $e');
    _mostrarErrorCantidad('Error de conexión: $e');
  } finally {
    isUpdating.value = false;
  }
}
  Future<void> _eliminarProducto(int detalleId) async {
    final controller = Get.find<OrdersController>();
    
    try {
       isUpdating.value = true; // Activar loading


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
    } finally{
          isUpdating.value = false; // Desactivar loading

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
void liberarTodasLasMesas() {
  final totalMesas = obtenerConteoMesasConPendientes();
  
  if (totalMesas == 0) {
    Get.snackbar(
      'Sin mesas por liberar',
      'No hay mesas con pedidos pendientes',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
    return;
  }
  
  QuickAlert.show(
    context: Get.context!,
    type: QuickAlertType.confirm,
    title: 'Liberar Todas las Mesas',
    text: '¿Está seguro de que quiere liberar TODAS las mesas con pedidos?\n\n'
          'Total de mesas: $totalMesas\n\n'
          '⚠️ Esta acción liberará todas las mesas y las marcará como disponibles.\n\n'
          'Solo se recomienda hacer esto al final del día o en casos especiales.',
    confirmBtnText: 'Liberar Todas ($totalMesas)',
    cancelBtnText: 'Cancelar',
    confirmBtnColor: Color(0xFFE74C3C),
    onConfirmBtnTap: () async {
      Get.back(); // Cerrar el diálogo de confirmación
      await _ejecutarLiberacionTodasLasMesas();
    },
  );
}

/// Método privado que ejecuta la liberación de todas las mesas
Future<void> _ejecutarLiberacionTodasLasMesas() async {
  if (isLiberandoTodasLasMesas.value) return; // Prevenir ejecuciones múltiples
  
  isLiberandoTodasLasMesas.value = true;
  
  try {
    // Obtener snapshot de las mesas actuales
    final controller = Get.find<OrdersController>();
    final mesasParaLiberar = List<Map<String, dynamic>>.from(controller.mesasConPedidos);
    final totalMesas = mesasParaLiberar.length;
    
    // Mostrar diálogo de progreso
    Get.dialog(
      AlertDialog(
        title: Text(
          'Liberando Mesas',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
            ),
            SizedBox(height: 16),
            Text('Liberando $totalMesas mesas...'),
            SizedBox(height: 8),
            Text(
              'Por favor espere...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    
    int exitosas = 0;
    int fallidas = 0;
    List<String> mesasFallidas = [];
    
    // Procesar cada mesa
    for (var mesa in mesasParaLiberar) {
      try {
        final numeroMesa = mesa['numeroMesa'];
        final idMesa = mesa['id'] as int? ?? 0;
        
        // Llamar al endpoint para liberar la mesa individual
        Uri uri = Uri.parse('${controller.defaultApiServer}/mesas/liberarMesa/$idMesa/');
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
        
        // Pequeña pausa entre requests para no saturar el servidor
        await Future.delayed(Duration(milliseconds: 200));
        
      } catch (e) {
        fallidas++;
        final numeroMesa = mesa['numeroMesa'] ?? 'N/A';
        mesasFallidas.add('Mesa $numeroMesa');
        print('❌ Excepción liberando Mesa $numeroMesa: $e');
      }
    }
    
    // Cerrar diálogo de progreso
    Get.back();
    
    // Mostrar resultado
    if (fallidas == 0) {
      // Todas las mesas fueron liberadas exitosamente
      Get.snackbar(
        'Liberación Exitosa',
        '🎉 Todas las mesas fueron liberadas correctamente\n'
        'Mesas liberadas: $exitosas',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } else if (exitosas > 0) {
      // Algunas mesas fueron liberadas
      String mensajeFallidas = mesasFallidas.length <= 3 
          ? mesasFallidas.join(', ')
          : '${mesasFallidas.take(3).join(', ')} y ${mesasFallidas.length - 3} más';
      
      Get.snackbar(
        'Liberación Parcial',
        '⚠️ Liberación completada parcialmente\n'
        'Exitosas: $exitosas\n'
        'Fallidas: $fallidas\n'
        'Mesas con error: $mensajeFallidas',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 6),
      );
    } else {
      // Ninguna mesa pudo ser liberada
      Get.snackbar(
        'Error en Liberación',
        '❌ No se pudo liberar ninguna mesa\n'
        'Total intentadas: $totalMesas\n'
        'Por favor, intente liberar las mesas individualmente.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
    
    // Refrescar datos para ver los cambios
    await controller.refrescarDatos();
    
  } catch (e) {
    // Cerrar diálogo de progreso si está abierto
    if (Get.isDialogOpen ?? false) Get.back();
    
    Get.snackbar(
      'Error Crítico',
      'Error inesperado al liberar las mesas: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
    
    print('❌ Error crítico en liberarTodasLasMesas: $e');
  } finally {
    isLiberandoTodasLasMesas.value = false;
  }
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
  

void confirmarPagoYLiberacion(Map<String, dynamic> pedido) {
  // ✅ VALIDACIÓN: Prevenir ejecuciones concurrentes
  if (isUpdating.value) {
    print('⚠️ Ya hay una operación en progreso');
    return;
  }

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
             'Total: \$${total.toStringAsFixed(2)}\n\n'
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
      // ✅ CERRAR DIÁLOGO INMEDIATAMENTE
      Navigator.of(Get.context!).pop();
      
      // ✅ ESPERAR un frame
      await Future.delayed(Duration(milliseconds: 100));
      
      // ✅ VERIFICAR NUEVAMENTE
      if (isUpdating.value) {
        print('⚠️ Operación ya en progreso');
        return;
      }
      
      // ✅ MARCAR COMO PROCESANDO
      isUpdating.value = true;
      
      try {
        await _pagarYLiberarMesa(pedido, detalleIds, total);
      } catch (e) {
        print('❌ Error: $e');
        Get.snackbar(
          'Error',
          'Error al procesar: $e',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      } finally {
        isUpdating.value = false;
      }
    },
    onCancelBtnTap: () {
      Navigator.of(Get.context!).pop();
    },
  );
}


Future<void> _pagarYLiberarMesa(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    isUpdating.value = true; // Activar loading en el botón

    // Paso 1: Conectar impresora
    final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();
    if (!impresoraConectada) {
      print('⚠️ Impresora no disponible, continuando sin imprimir...');
    }

    // Paso 2: Procesar el pago
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

    // Paso 4: Imprimir ticket
    if (fallidos == 0 && impresoraConectada && productosRecienPagados.isNotEmpty) {
      try {
        final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
          productosRecienPagados, 
          pedido, 
          totalReal,
          'pago_final_liberacion'
        );
        
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }

    // Paso 5: Mostrar resultado y cerrar modal SOLO si fue exitoso
    if (fallidos == 0 && mesaLiberada) {
      // ✅ ÉXITO COMPLETO - Cerrar modal aquí
      Get.back(); // Cerrar TableDetailsModal
      
      String mensaje = 'Mesa $numeroMesa liberada exitosamente\n'
                      'Productos finales pagados: $exitosos\n'
                      'Total: \$${totalReal.toStringAsFixed(2)}';
      
      if (impresoraConectada && productosRecienPagados.isNotEmpty) {
        mensaje += '\n✅ Ticket impreso';
      }
      
      Get.snackbar(
        'Operación Exitosa',
        mensaje,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      await controller.refrescarDatos();
      
    } else if (fallidos == 0 && !mesaLiberada) {
      // Pago exitoso pero error liberando mesa - NO cerrar modal
      Get.snackbar(
        'Pago Exitoso - Error al Liberar',
        'Productos pagados correctamente\n\n❌ No se pudo liberar la mesa automáticamente',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
      await controller.refrescarDatos();
      
    } else {
      // Error en el pago - NO cerrar modal
      Get.snackbar(
        'Error en la Operación',
        'No se pudo completar el pago',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }

  } catch (e) {
    Get.snackbar(
      'Error',
      'Error al procesar pago y liberación: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } finally {
    isUpdating.value = false; // Desactivar loading
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
  // ✅ VALIDACIÓN CRÍTICA: Prevenir ejecuciones múltiples
  if (isUpdating.value) {
    print('⚠️ Ya hay una operación en progreso, ignorando nueva solicitud');
    return; // Salir inmediatamente si ya hay algo procesando
  }

  final productosSeleccionados = getProductosSeleccionadosDelPedidoActual();
  
  if (productosSeleccionados.isEmpty) {
    Get.snackbar(
      'Sin productos',
      'No hay productos seleccionados para pagar',
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
    return;
  }

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
      // ✅ CERRAR DIÁLOGO INMEDIATAMENTE
      Navigator.of(Get.context!).pop(); // Usar Navigator.pop para asegurar cierre
      
      // ✅ ESPERAR un frame para asegurar que el diálogo se cerró
      await Future.delayed(Duration(milliseconds: 100));
      
      // ✅ VERIFICAR NUEVAMENTE antes de procesar
      if (isUpdating.value) {
        print('⚠️ Operación ya en progreso, cancelando nueva solicitud');
        return;
      }
      
      // ✅ MARCAR COMO PROCESANDO INMEDIATAMENTE
      isUpdating.value = true;
      
      try {
        if (tipoBoton == 'pagar_y_liberar') {
          await _pagarSeleccionadosYLiberarMesa(productosSeleccionados, pedido, total);
        } else {
          await _pagarProductosSeleccionados(productosSeleccionados, pedido, total);
        }
      } catch (e) {
        print('❌ Error en operación de pago: $e');
        Get.snackbar(
          'Error',
          'Error durante el proceso de pago: $e',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } finally {
        // ✅ SIEMPRE liberar el lock
        isUpdating.value = false;
      }
    },
    onCancelBtnTap: () {
      // ✅ CERRAR DIÁLOGO de forma segura
      Navigator.of(Get.context!).pop();
    },
  );
}
// Mueve la función fuera del método confirmarPagoProductosSeleccionados
Future<void> _pagarProductosSeleccionados(
  List<Map<String, dynamic>> productos, 
  Map<String, dynamic> pedido, 
  double totalEstimado
) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  try {
    isUpdating.value = true; // Activar loading
    
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

    if (fallidos == 0 && impresoraConectada) {
      try {
        final pedidoParaTicket = _crearPedidoParaTicket(productos, pedido, totalReal);
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        print('✅ Ticket impreso para productos seleccionados');
      } catch (e) {
        print('❌ Error en impresión de productos seleccionados: $e');
      }
    }

    if (fallidos == 0) {
      String mensaje = 'Productos pagados correctamente\nPedido #$pedidoId\n$exitosos productos pagados\nTotal: \$${totalReal.toStringAsFixed(2)}';
      
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
    Get.snackbar(
      'Error',
      'Error al procesar pago: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } finally {
    isUpdating.value = false; // Desactivar loading
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


Future<void> _pagarSeleccionadosYLiberarMesa(
  List<Map<String, dynamic>> productos, 
  Map<String, dynamic> pedido, 
  double totalEstimado
) async {
  final controller = Get.find<OrdersController>();
  final pedidoId = pedido['pedidoId'];
  
  bool debeRefrescarDatos = false;
  
  try {
    isUpdating.value = true; // Activar loading (en lugar de Get.dialog)

    final impresoraConectada = await printerService.conectarImpresoraAutomaticamente();

    double totalReal = 0.0;
    int exitosos = 0;
    int fallidos = 0;
    List<Map<String, dynamic>> productosRecienPagados = [];

    // Pagar productos seleccionados
    for (var producto in productos) {
      try {
        final detalleId = producto['detalleId'] as int;
        final statusActual = producto['statusDetalle'] as String? ?? 'proceso';
        
        if (statusActual != 'pagado') {
          await controller.actualizarEstadoOrden(detalleId, 'pagado');
          
          final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;
          exitosos++;
          
          productosRecienPagados.add({
            ...producto,
            'statusDetalle': 'pagado',
          });
        }
      } catch (e) {
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
    if (fallidos == 0 && impresoraConectada && productosRecienPagados.isNotEmpty) {
      try {
        final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
          productosRecienPagados, 
          pedido, 
          totalReal,
          'productos_seleccionados_liberacion'
        );
        await printerService.imprimirTicket(pedidoParaTicket, totalReal);
      } catch (e) {
        print('❌ Error en impresión: $e');
      }
    }
    
    productosSeleccionados.clear();
    debeRefrescarDatos = true;
    
    // Mostrar resultado
    if (fallidos == 0 && mesaLiberada) {
      Get.back(); // Cerrar TableDetailsModal
      
      Get.snackbar(
        'Operación Exitosa',
        '🎉 Mesa $numeroMesa liberada exitosamente!\nProductos: $exitosos\nTotal: \$${totalReal.toStringAsFixed(2)}',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
    } else if (fallidos == 0 && !mesaLiberada) {
      Get.snackbar(
        'Pago Exitoso - Error al Liberar',
        'Productos pagados pero no se pudo liberar la mesa',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      
    } else {
      Get.snackbar(
        'Error Parcial',
        'Error en el proceso',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }

  } catch (e) {
    productosSeleccionados.clear();
    debeRefrescarDatos = true;
    
    Get.snackbar(
      'Error',
      'Error al procesar: $e',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } finally {
    isUpdating.value = false; // Desactivar loading
    await printerService.desconectar();
    
    if (debeRefrescarDatos) {
      await controller.refrescarDatos();
    }
  }
}
}
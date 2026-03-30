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
  final isLiberandoTodasLasMesas = false.obs;
  final productoEnEdicion =
      Rxn<int>(); // ID del producto siendo editado (null = ninguno)
  final modoEdicion = 'aumentar'.obs; // 'aumentar' o 'disminuir'
  final cantidadEdicion = ''.obs; // Texto del input
  // Services
  bool get esGrupo => (_mesaActual['esGrupo'] ?? false) as bool;
  int? get grupoId => _mesaActual['grupoId'] as int?;

  final UniversalPrinterService printerService = UniversalPrinterService();
final mostrarVistaPedidos = true.obs; // true = tabs pedidos, false = productos agrupados

  // Datos actuales
  Map<String, dynamic> _mesaActual = {};

  @override
  void onInit() {
    super.onInit();
    _setupOrdersListener();
  }
  // ✅ Obtener productos seleccionados de TODOS los pedidos (vista agrupada)
List<Map<String, dynamic>> getProductosSeleccionadosDeTodos() {
  if (productosSeleccionados.isEmpty) return [];

  List<Map<String, dynamic>> resultado = [];
  final productos = todosLosProductos;

  for (var producto in productos) {
    final detalleId = producto['detalleId'] as int?;
    final status = producto['statusDetalle'] as String? ?? 'proceso';

    if (detalleId != null &&
        productosSeleccionados.contains(detalleId) &&
        status == 'completado') {
      resultado.add(producto);
    }
  }

  return resultado;
}

// ✅ Total de productos seleccionados en vista agrupada
double calcularTotalSeleccionadosDeTodos() {
  final productos = getProductosSeleccionadosDeTodos();
  double total = 0.0;
  for (var p in productos) {
    final cantidad = (p['cantidad'] as num?)?.toInt() ?? 1;
    final precio = (p['precioUnitario'] as num?)?.toDouble() ?? 0.0;
    total += precio * cantidad;
  }
  return total;
}

// ✅ Tipo de botón para vista agrupada
String getTipoBotonPagoAgrupado() {
  final seleccionados = getProductosSeleccionadosDeTodos();
  if (seleccionados.isEmpty) return 'ninguno';

  // Verificar si pagando estos productos se completaría TODO
  bool completariaTodo = true;

  for (var pedido in pedidos) {
    final pedidoMap = Map<String, dynamic>.from(pedido);
    final detalles = pedidoMap['detalles'] as List? ?? [];

    for (var detalle in detalles) {
      final detalleMap = Map<String, dynamic>.from(detalle);
      final detalleId = detalleMap['detalleId'] as int?;
      final status = detalleMap['statusDetalle'] as String? ?? 'proceso';

      if (status != 'cancelado' && status != 'pagado') {
        if (detalleId != null && !productosSeleccionados.contains(detalleId)) {
          completariaTodo = false;
          break;
        }
      }
    }
    if (!completariaTodo) break;
  }

  return completariaTodo ? 'pagar_y_liberar' : 'pagar_seleccionados';
}
void toggleVistaPedidos() {
  mostrarVistaPedidos.value = !mostrarVistaPedidos.value;
  productosSeleccionados.clear();
}
  // ✅ Agrupar mesa
  Future<void> agruparMesa() async {
    final controller = Get.find<OrdersController>();
    final mesaId = idnumeromesa;

    try {
      isUpdating.value = true;

      final uri = Uri.parse(
        '${controller.defaultApiServer}/mesas/agruparMesas/',
      );
      final body = {
        'mesas': [mesaId],
      };

      print('📤 Agrupando mesa $mesaId: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📡 Agrupar - Status: ${response.statusCode}');
      print('📡 Agrupar - Body: ${response.body}');

if (response.statusCode == 200 || response.statusCode == 201) {        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Mesa Agrupada',
            'La mesa $numeroMesa ha sido agrupada correctamente',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          await controller.refrescarDatos();
        } else {
          _mostrarErrorAgrupar(data['message'] ?? 'Error desconocido');
        }
      } else {
        _mostrarErrorAgrupar('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error agrupando mesa: $e');
      _mostrarErrorAgrupar('Error de conexión: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  // ✅ Desagrupar mesa (se llama al liberar si es grupo)
  Future<void> desagruparMesa(int idGrupo) async {
    final controller = Get.find<OrdersController>();

    try {
      final uri = Uri.parse(
        '${controller.defaultApiServer}/mesas/desagruparMesas/$idGrupo/',
      );

      print('📤 Desagrupando grupo $idGrupo');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Desagrupar - Status: ${response.statusCode}');
      print('📡 Desagrupar - Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Grupo $idGrupo desagrupado correctamente');
      } else {
        print('⚠️ Error desagrupando grupo $idGrupo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error desagrupando: $e');
    }
  }

  void confirmarAgruparMesa() {
    // Obtener todas las mesas disponibles (no grupos, no la mesa actual)
    final ordersController = Get.find<OrdersController>();

    // Necesitamos las mesas del listarMesas - las tenemos en CreateOrderController
    // O podemos hacer una llamada directa
    _mostrarSelectorMesas();
  }

  Future<void> _mostrarSelectorMesas() async {
    try {
      isUpdating.value = true;

      final controller = Get.find<OrdersController>();
      final uri = Uri.parse(
        '${controller.defaultApiServer}/mesas/listarMesas/',
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      isUpdating.value = false;

      if (response.statusCode != 200) {
        _mostrarErrorAgrupar('No se pudieron cargar las mesas');
        return;
      }

      final List<dynamic> data = jsonDecode(response.body);

      // Filtrar: solo mesas simples, activas, que no sean la mesa actual

      // DESPUÉS
      final mesasDisponibles = data.where((m) {
        final esGrupoM = m['esGrupo'] ?? false;
        final id = m['id'];
        return !esGrupoM &&
            id != idnumeromesa; // ✅ solo excluye grupos y la mesa actual
      }).toList();

      if (mesasDisponibles.isEmpty) {
        Get.snackbar(
          'Sin mesas disponibles',
          'No hay otras mesas disponibles para agrupar',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Mesas seleccionadas (incluye la mesa actual por defecto)
      final RxList<int> mesasSeleccionadas = <int>[idnumeromesa].obs;

      Get.dialog(
        AlertDialog(
          title: Text(
            'Seleccionar Mesas a Agrupar',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa actual: $numeroMesa (incluida)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Selecciona las mesas adicionales:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: mesasDisponibles.length,
                    itemBuilder: (context, index) {
                      final mesa = mesasDisponibles[index];
                      final mesaId = mesa['id'] as int;
                      final numeroMesaItem = mesa['numeroMesa'] as int;

                      return Obx(() {
                        final isSelected = mesasSeleccionadas.contains(mesaId);
                        return CheckboxListTile(
                          title: Text('Mesa $numeroMesaItem'),
                          subtitle: Text('ID: $mesaId'),
                          value: isSelected,
                          activeColor: Color(0xFF8B4513),
                          onChanged: (bool? value) {
                            if (value == true) {
                              mesasSeleccionadas.add(mesaId);
                            } else {
                              mesasSeleccionadas.remove(mesaId);
                            }
                          },
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: mesasSeleccionadas.length < 2
                    ? null // necesita al menos 2 mesas
                    : () {
                        Get.back();
                        agruparMesas(mesasSeleccionadas.toList());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'Agrupar (${mesasSeleccionadas.length})',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      isUpdating.value = false;
      print('❌ Error cargando mesas: $e');
      _mostrarErrorAgrupar('Error al cargar mesas: $e');
    }
  }

  // ✅ Renombrar el método para recibir la lista de IDs
  Future<void> agruparMesas(List<int> mesaIds) async {
    final controller = Get.find<OrdersController>();

    try {
      isUpdating.value = true;

      final uri = Uri.parse(
        '${controller.defaultApiServer}/mesas/agruparMesas/',
      );
      final body = {'mesas': mesaIds};

      print('📤 Agrupando mesas $mesaIds: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('📡 Agrupar - Status: ${response.statusCode}');
      print('📡 Agrupar - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Mesas Agrupadas',
            '${mesaIds.length} mesas agrupadas correctamente',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          Get.back(); // cerrar modal de detalles
          await controller.refrescarDatos();
        } else {
          _mostrarErrorAgrupar(data['message'] ?? 'Error desconocido');
        }
      } else {
        _mostrarErrorAgrupar(
          'Error del servidor (${response.statusCode})\n${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error agrupando mesas: $e');
      _mostrarErrorAgrupar('Error de conexión: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  void _mostrarErrorAgrupar(String mensaje) {
    Get.snackbar(
      'Error al Agrupar',
      mensaje,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
  }

  int obtenerConteoMesasConPendientes() {
    final ordersController = Get.find<OrdersController>();

    return ordersController.mesasConPedidos.length;
  }

void inicializarConMesa(Map<String, dynamic> mesa) {
  _mesaActual = mesa;

  final pedidos = mesa['pedidos'] as List? ?? [];
  final esGrupoMesa = mesa['esGrupo'] ?? false;

  if (esGrupoMesa) {
    // ✅ Grupos siempre muestran todos los pedidos juntos
    selectedOrderIndex.value = -1;
  } else if (pedidos.length > 1) {
    selectedOrderIndex.value = 0;
  } else if (pedidos.length == 1) {
    selectedOrderIndex.value = 0;
  } else {
    selectedOrderIndex.value = -1;
  }

  print('🎯 inicializarConMesa: esGrupo=$esGrupoMesa, ${pedidos.length} pedidos, index=${selectedOrderIndex.value}');
  productosSeleccionados.clear();
}

  void _setupOrdersListener() {
    try {
      final ordersController = Get.find<OrdersController>();

ever(ordersController.mesasConPedidos, (List<dynamic> mesas) {
  if (!isUpdating.value) {
    final mesaActualizada = mesas.firstWhere(
      (mesa) => mesa['numeroMesa'] == _mesaActual['numeroMesa'],
      orElse: () => _mesaActual,
    );

    final pedidos = mesaActualizada['pedidos'] as List? ?? [];
    final esGrupoMesa = mesaActualizada['esGrupo'] ?? false;

    // ✅ Si es grupo, siempre mantener vista "Todos"
    if (esGrupoMesa) {
      if (selectedOrderIndex.value != -1) {
        selectedOrderIndex.value = -1;
        productosSeleccionados.clear();
      }
      update();
      return;
    }

    // Resto de la lógica existente para mesas simples...
    if (pedidos.length > 1 && selectedOrderIndex.value == -1) {
      selectedOrderIndex.value = 0;
      productosSeleccionados.clear();
    } else if (pedidos.length == 1 && selectedOrderIndex.value != 0) {
      selectedOrderIndex.value = 0;
      productosSeleccionados.clear();
    } else if (pedidos.length == 0 && selectedOrderIndex.value != -1) {
      selectedOrderIndex.value = -1;
      productosSeleccionados.clear();
    } else if (selectedOrderIndex.value >= pedidos.length) {
      selectedOrderIndex.value = pedidos.length > 0 ? 0 : -1;
      productosSeleccionados.clear();
    }

    update();
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

List<Map<String, dynamic>> get todosLosProductos {
  // Para grupos: usar los pedidos reales (tienen detalleId) 
  // pero mostrar info del producto agrupado
  if (esGrupo) {
    List<Map<String, dynamic>> productos = [];

    for (int i = 0; i < pedidos.length; i++) {
      final pedido = Map<String, dynamic>.from(pedidos[i]);
      final detalles = pedido['detalles'] as List? ?? [];
      final mesaNumero = pedido['mesaNumero'] ?? '';

      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        productos.add(<String, dynamic>{
          ...detalleMap,
          'pedidoId': pedido['pedidoId'],
          // ✅ Mostrar qué mesa del grupo es este producto
          'nombreOrden': '${pedido['nombreOrden']} (Mesa $mesaNumero)',
          'colorPedido': getOrderColor(i),
        });
      }
    }

    return productos;
  }

  // Mesa simple: comportamiento original
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
          final precioUnitario =
              (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
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
          final precioUnitario =
              (detalleMap['precioUnitario'] as num?)?.toDouble() ?? 0.0;
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
  // En table_details_controller.dart

  bool puedeSerPagado(Map<String, dynamic> pedido) {
    try {
      final pedidoMap = Map<String, dynamic>.from(pedido);
      final detalles = pedidoMap['detalles'] as List? ?? [];

      // ✅ CAMBIO: Verificar que hay detalles y que TODOS estén completados
      if (detalles.isEmpty) return false;

      bool tieneAlMenosUnProducto = false;

      for (var detalle in detalles) {
        final detalleMap = Map<String, dynamic>.from(detalle);
        final status = detalleMap['statusDetalle'] as String? ?? 'proceso';

        // Ignorar productos cancelados o ya pagados
        if (status == 'cancelado' || status == 'pagado') {
          continue;
        }

        tieneAlMenosUnProducto = true;

        // Si encuentra algún producto que NO esté completado, retornar false
        if (status != 'completado') {
          return false;
        }
      }

      // Retornar true solo si hay al menos un producto válido y todos están completados
      return tieneAlMenosUnProducto;
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
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

void manejarBotonAgregarProductos() {
  // ✅ Si es grupo, ir directo sin selector de pedido
  if (esGrupo) {
    abrirModalAgregarProductos(pedidos.isNotEmpty ? pedidos[0] : {});
    return;
  }

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
  final numeroMesaLocal = _mesaActual['numeroMesa'] as int;
  final nombreOrdenLocal = pedido['nombreOrden'] ?? 'Sin nombre';

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
      final addController = Get.find<AddProductsToOrderController>();
      
      if (esGrupo && grupoId != null) {
        // ✅ Es grupo → inicializar con grupoId
        addController.inicializarConGrupo(
          grupoId!,
          _mesaActual['displayLabel'] ?? _mesaActual['nombreGrupo'] ?? 'Grupo',
        );
      } else {
        // ✅ Mesa simple → inicializar con pedidoId
        addController.inicializarConPedido(
          pedidoId,
          numeroMesaLocal,
          nombreOrdenLocal,
        );
      }
    } catch (e) {
      final addController = Get.put(AddProductsToOrderController());
      
      if (esGrupo && grupoId != null) {
        addController.inicializarConGrupo(
          grupoId!,
          _mesaActual['displayLabel'] ?? _mesaActual['nombreGrupo'] ?? 'Grupo',
        );
      } else {
        addController.inicializarConPedido(
          pedidoId,
          numeroMesaLocal,
          nombreOrdenLocal,
        );
      }
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

  // En table_details_controller.dart - método cambiarEstadoProducto
  void cambiarEstadoProducto(
    Map<String, dynamic> producto,
    String nuevoEstado,
  ) async {
    final detalleId = producto['detalleId'] as int;
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    final pedidoId = producto['pedidoId'];

    String titulo = nuevoEstado == 'completado'
        ? 'Completar Producto'
        : 'Cancelar Producto';
    String mensaje = nuevoEstado == 'completado'
        ? '¿Marcar "$nombreProducto" como completado?'
        : '¿Está seguro de que quiere cancelar "$nombreProducto"?\n\nEsta acción no se puede deshacer.';

    String textoBoton = nuevoEstado == 'completado' ? 'Completar' : 'Cancelar';
    Color colorBoton = nuevoEstado == 'completado' ? Colors.green : Colors.red;

    final controller = Get.find<OrdersController>();

    // ✅ CAMBIO: Pasar como lista con un solo elemento
    await controller.actualizarEstadoOrden(
      [detalleId],
      nuevoEstado,
      completarTodos: true,
    );

    // Verificar y cerrar modal si no hay productos activos
    await _verificarYCerrarModalSiNoHayProductosActivos();
  }

  void activarEdicionCantidad(int detalleId) {
    productoEnEdicion.value = detalleId;
    cantidadEdicion.value = '';
    modoEdicion.value = 'aumentar';
  }

  void cancelarEdicionCantidad() {
    productoEnEdicion.value = null;
    cantidadEdicion.value = '';
  }

  void toggleModoEdicion() {
    modoEdicion.value = modoEdicion.value == 'aumentar'
        ? 'disminuir'
        : 'aumentar';
  }

  void confirmarCambioManual(Map<String, dynamic> producto) async {
    final inputText = cantidadEdicion.value.trim();
    final cantidadActual = (producto['cantidad'] as num?)?.toInt() ?? 1;
    final detalleId = producto['detalleId'];

    if (inputText.isEmpty) {
      Get.snackbar(
        'Error',
        'Ingrese una cantidad válida',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      return;
    }

    final cantidad = int.tryParse(inputText);

    if (cantidad == null || cantidad <= 0) {
      Get.snackbar(
        'Error',
        'La cantidad debe ser un número mayor a 0',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      return;
    }

    // Validar si es disminuir
    if (modoEdicion.value == 'disminuir') {
      if (cantidad > cantidadActual) {
        Get.snackbar(
          'Error',
          'No puede disminuir más de la cantidad actual ($cantidadActual)',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        return;
      }
    }

    // Cancelar edición
    cancelarEdicionCantidad();

    // Ejecutar actualización
    final cantidadFinal = modoEdicion.value == 'aumentar'
        ? cantidad
        : -cantidad;
    await _actualizarCantidadProducto(detalleId, cantidadFinal);
  }

  // Métodos de cantidad
  void aumentarCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];

    await _actualizarCantidadProducto(detalleId, 1);
  }

  void disminuirCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];

    await _actualizarCantidadProducto(detalleId, -1);
  }

  Future<void> _actualizarCantidadProducto(
    int detalleId,
    int nuevaCantidad,
  ) async {
    final controller = Get.find<OrdersController>();

    try {
      isUpdating.value = true; // Activar loading

      Uri uri = Uri.parse(
        '${controller.defaultApiServer}/ordenes/detalle/$detalleId/actualizarCantidad/',
      );

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
          _mostrarErrorCantidad(
            'Error del servidor: ${data['message'] ?? 'Error desconocido'}',
          );
        }
      } else {
        _mostrarErrorCantidad('Error del servidor (${response.statusCode})');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      print('❌ Error al actualizar cantidad: $e');
      _mostrarErrorCantidad('Error de conexión: $e');
    } finally {
      isUpdating.value = false; // Desactivar loading

      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  void _confirmarEliminarProducto(Map<String, dynamic> producto) {
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Eliminar Producto',
      text:
          '¿Está seguro de que quiere eliminar "$nombreProducto" del pedido?\n\n'
          'Esta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Get.back();
        cambiarEstadoProducto(producto, 'cancelado');

        // ✅ NUEVO: Verificar después de cancelar
        await Future.delayed(
          Duration(milliseconds: 500),
        ); // Esperar a que se actualice
        await _verificarYCerrarModalSiNoHayProductosActivos();
      },
    );
  }

  /// Verifica si todos los productos están cancelados o pagados y cierra el modal si es necesario
  Future<void> _verificarYCerrarModalSiNoHayProductosActivos() async {
    try {
      // Refrescar datos primero
      final controller = Get.find<OrdersController>();
      await controller.refrescarDatos();

      // Esperar un momento para que se actualice la UI
      await Future.delayed(Duration(milliseconds: 300));

      // Obtener la mesa actualizada
      final mesaActual = mesaActualizada;
      final pedidos = mesaActual['pedidos'] as List? ?? [];

      bool hayProductosActivos = false;

      // Verificar si hay algún producto activo (no cancelado ni pagado)
      for (var pedido in pedidos) {
        try {
          final pedidoMap = Map<String, dynamic>.from(pedido);
          final detalles = pedidoMap['detalles'] as List? ?? [];

          for (var detalle in detalles) {
            final detalleMap = Map<String, dynamic>.from(detalle);
            final status = detalleMap['statusDetalle'] as String? ?? 'proceso';

            // Si encuentra algún producto activo
            if (status != 'cancelado' && status != 'pagado') {
              hayProductosActivos = true;
              break;
            }
          }

          if (hayProductosActivos) break;
        } catch (e) {
          print('❌ Error verificando pedido: $e');
          continue;
        }
      }

      // ✅ Si no hay productos activos, cerrar el modal
      if (!hayProductosActivos) {
        print('🚪 No hay productos activos, cerrando modal...');

        Get.back(); // Cerrar el modal de detalles de mesa

        Get.snackbar(
          'Mesa Actualizada',
          'Todos los productos han sido procesados',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Error verificando productos activos: $e');
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
      text:
          '¿Está seguro de que quiere liberar la Mesa $numeroMesa?\n\n'
          'Esta acción marcará la mesa como disponible.',
      confirmBtnText: 'Liberar Mesa',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back();
        await liberarMesa();
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
      text:
          '¿Está seguro de que quiere liberar TODAS las mesas con pedidos?\n\n'
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
    if (isLiberandoTodasLasMesas.value)
      return; // Prevenir ejecuciones múltiples

    isLiberandoTodasLasMesas.value = true;

    try {
      // Obtener snapshot de las mesas actuales
      final controller = Get.find<OrdersController>();
      final mesasParaLiberar = List<Map<String, dynamic>>.from(
        controller.mesasConPedidos,
      );
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          Uri uri = Uri.parse(
            '${controller.defaultApiServer}/mesas/liberarMesa/$idMesa/',
          );
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
              print(
                '❌ Error liberando Mesa $numeroMesa: ${data['message'] ?? 'Error desconocido'}',
              );
            }
          } else {
            fallidas++;
            mesasFallidas.add('Mesa $numeroMesa');
            print(
              '❌ Error HTTP liberando Mesa $numeroMesa: ${response.statusCode}',
            );
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

  Future<void> liberarMesa() async {
    final controller = Get.find<OrdersController>();
    final esGrupoActual = esGrupo;
    final idGrupoActual = grupoId;

    try {
      Uri uri = Uri.parse(
        '${controller.defaultApiServer}/mesas/liberarMesa/$idnumeromesa/',
      );

      // ✅ Si es grupo, usar /liberarMesa/0/ con grupoId en body
      if (esGrupoActual && idGrupoActual != null) {
        uri = Uri.parse('${controller.defaultApiServer}/mesas/liberarMesa/0/');
      }

      final Map<String, dynamic> statusData =
          esGrupoActual && idGrupoActual != null
          ? {'grupoId': idGrupoActual, 'status': true}
          : {'status': true};

      print(
        '📤 Liberando ${esGrupoActual ? "Grupo $idGrupoActual" : "Mesa $idnumeromesa"}',
      );
      print('📤 URL: $uri');
      print('📤 Body: ${jsonEncode(statusData)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(statusData),
      );

      print('📡 Liberar - Status: ${response.statusCode}');
      print('📡 Liberar - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // ✅ Si es grupo, desagrupar también
          if (esGrupoActual && idGrupoActual != null) {
            await desagruparMesa(idGrupoActual);
          }

          Get.back();

          Get.snackbar(
            'Mesa Liberada',
            esGrupoActual
                ? 'El grupo ha sido liberado y desagrupado correctamente'
                : 'La Mesa $numeroMesa ha sido liberada correctamente',
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
      text:
          '¿Confirmar el pago del pedido?\n\n'
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

  Future<void> pagarPedidoEspecifico(
    Map<String, dynamic> pedido,
    List<int> detalleIds,
    double totalEstimado,
  ) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];

    try {
      final impresoraConectada = await printerService
          .conectarImpresoraAutomaticamente();
      if (!impresoraConectada) {
        Get.snackbar(
          'Impresora no disponible',
          'Se procesará el pago sin imprimir ticket',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }

      // ✅ CAMBIO: Marcar todos los productos como pagados en una sola llamada
      await controller.actualizarEstadoOrden(
        detalleIds,
        'pagado',
        completarTodos: true,
      );

      // Calcular el total real
      double totalReal = 0.0;
      for (int detalleId in detalleIds) {
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario =
              (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;
        }
      }

      // Imprimir ticket
      if (impresoraConectada) {
        try {
          await printerService.imprimirTicket(pedido, totalReal);
        } catch (e) {
          print('❌ Error en impresión: $e');
        }
      }

      // Mostrar mensaje de éxito
      String mensaje =
          'Pedido #$pedidoId pagado correctamente\n'
          'Total: \$${totalReal.toStringAsFixed(2)}';

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
      Color(0xFF8B4513),
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'proceso':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      case 'pagado':
        return Colors.blue; // Color azul para productos pagados
      default:
        return Colors.grey;
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

    String titulo = esUnico
        ? 'Pagar y Liberar Mesa'
        : 'Último Pedido - Pagar y Liberar';
    String mensaje = esUnico
        ? '¿Confirmar el pago y liberar la Mesa $numeroMesa?\n\n'
        : '🎉 ¡Este es el último pedido pendiente!\n\n¿Confirmar el pago y liberar la Mesa $numeroMesa?\n\n';

    mensaje +=
        'Pedido: $nombreOrden\n'
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

  Future<void> _pagarYLiberarMesa(
    Map<String, dynamic> pedido,
    List<int> detalleIds,
    double totalEstimado,
  ) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];

    try {
      isUpdating.value = true; // Activar loading en el botón

      // Paso 1: Conectar impresora
      final impresoraConectada = await printerService
          .conectarImpresoraAutomaticamente();
      if (!impresoraConectada) {
        print('⚠️ Impresora no disponible, continuando sin imprimir...');
      }

      // Paso 2: Procesar el pago - ✅ CAMBIO: Una sola llamada con toda la lista
      await controller.actualizarEstadoOrden(
        detalleIds,
        'pagado',
        completarTodos: true,
      );

      // Calcular total real y productos pagados
      double totalReal = 0.0;
      List<Map<String, dynamic>> productosRecienPagados = [];

      for (int detalleId in detalleIds) {
        final detalle = _buscarDetallePorId(detalleId);
        if (detalle != null) {
          final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
          final precioUnitario =
              (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          totalReal += precioUnitario * cantidad;

          productosRecienPagados.add({...detalle, 'statusDetalle': 'pagado'});
        }
      }

      // Paso 3: Liberar mesa
      bool mesaLiberada = false;
      try {
        Uri uri = Uri.parse(
          '${controller.defaultApiServer}/mesas/liberarMesa/$idnumeromesa/',
        );
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

      // Paso 4: Imprimir ticket
      if (impresoraConectada && productosRecienPagados.isNotEmpty) {
        try {
          final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
            productosRecienPagados,
            pedido,
            totalReal,
            'pago_final_liberacion',
          );

          await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        } catch (e) {
          print('❌ Error en impresión: $e');
        }
      }

      // Paso 5: Mostrar resultado y cerrar modal SOLO si fue exitoso
      if (mesaLiberada) {
        // ✅ ÉXITO COMPLETO - Cerrar modal aquí
        Get.back(); // Cerrar TableDetailsModal

        String mensaje =
            'Mesa $numeroMesa liberada exitosamente\n'
            'Productos finales pagados: ${detalleIds.length}\n'
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
      } else {
        // Pago exitoso pero error liberando mesa - NO cerrar modal
        Get.snackbar(
          'Pago Exitoso - Error al Liberar',
          'Productos pagados correctamente\n\n❌ No se pudo liberar la mesa automáticamente',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );

        await controller.refrescarDatos();
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
    String tipoTransaccion,
  ) {
    print(
      '🎫 Creando ticket filtrado con ${productosParaTicket.length} productos para $tipoTransaccion',
    );

    // Crear detalles para el ticket (ya filtrados)
    List<Map<String, dynamic>> detallesParaTicket = [];

    for (var producto in productosParaTicket) {
      try {
        final detalleParaTicket = {
          'detalleId': producto['detalleId'],
          'nombreProducto': producto['nombreProducto'] ?? 'Producto',
          'cantidad': producto['cantidad'] ?? 1,
          'precioUnitario':
              (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0,
          'statusDetalle': 'pagado', // Todos están recién pagados
          'observaciones': producto['observaciones'] ?? '',
          'categoria': producto['categoria'] ?? '',
        };

        detallesParaTicket.add(detalleParaTicket);

        final subtotal =
            detalleParaTicket['precioUnitario'] * detalleParaTicket['cantidad'];
        print(
          '✅ Producto en ticket: ${detalleParaTicket['nombreProducto']} x${detalleParaTicket['cantidad']} = \$${subtotal.toStringAsFixed(2)}',
        );
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
    print(
      '   - Total de ESTA transacción: \$${totalCalculado.toStringAsFixed(2)}',
    );

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
        final precioUnitario =
            (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
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

    mensaje +=
        '¿Confirmar el pago de los productos seleccionados?\n\n'
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
        Navigator.of(
          Get.context!,
        ).pop(); // Usar Navigator.pop para asegurar cierre

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
            await _pagarSeleccionadosYLiberarMesa(
              productosSeleccionados,
              pedido,
              total,
            );
          } else {
            await _pagarProductosSeleccionados(
              productosSeleccionados,
              pedido,
              total,
            );
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

  Future<void> _pagarProductosSeleccionados(
    List<Map<String, dynamic>> productos,
    Map<String, dynamic> pedido,
    double totalEstimado,
  ) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];

    try {
      isUpdating.value = true; // Activar loading

      final impresoraConectada = await printerService
          .conectarImpresoraAutomaticamente();
      if (!impresoraConectada) {
        print('⚠️ Impresora no disponible para productos seleccionados');
      }

      // ✅ CAMBIO: Extraer todos los IDs y hacer una sola llamada
      List<int> detalleIds = productos
          .map((p) => p['detalleId'] as int)
          .toList();
      await controller.actualizarEstadoOrden(
        detalleIds,
        'pagado',
        completarTodos: true,
      );

      // Calcular total real
      double totalReal = 0.0;
      for (var producto in productos) {
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario =
            (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        totalReal += precioUnitario * cantidad;
      }

      // Imprimir ticket
      if (impresoraConectada) {
        try {
          final pedidoParaTicket = _crearPedidoParaTicket(
            productos,
            pedido,
            totalReal,
          );
          await printerService.imprimirTicket(pedidoParaTicket, totalReal);
          print('✅ Ticket impreso para productos seleccionados');
        } catch (e) {
          print('❌ Error en impresión de productos seleccionados: $e');
        }
      }

      // Mostrar mensaje de éxito
      String mensaje =
          'Productos pagados correctamente\n'
          'Pedido #$pedidoId\n'
          '${detalleIds.length} productos pagados\n'
          'Total: \$${totalReal.toStringAsFixed(2)}';

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

  Map<String, dynamic> _crearPedidoParaTicket(
    List<Map<String, dynamic>> productosSeleccionados,
    Map<String, dynamic> pedidoOriginal,
    double totalCalculado,
  ) {
    print(
      '🎫 Creando pedido para ticket con ${productosSeleccionados.length} productos seleccionados',
    );

    // Filtrar solo los productos seleccionados y crear detalles para el ticket
    List<Map<String, dynamic>> detallesParaTicket = [];

    for (var producto in productosSeleccionados) {
      try {
        // Crear detalle para el ticket manteniendo la estructura esperada
        final detalleParaTicket = {
          'detalleId': producto['detalleId'],
          'nombreProducto': producto['nombreProducto'] ?? 'Producto',
          'cantidad': producto['cantidad'] ?? 1,
          'precioUnitario':
              (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0,
          'statusDetalle': 'pagado', // Marcar como pagado para el ticket
          'observaciones': producto['observaciones'] ?? '',
          'categoria': producto['categoria'] ?? '',
        };

        detallesParaTicket.add(detalleParaTicket);

        print(
          '✅ Producto agregado al ticket: ${detalleParaTicket['nombreProducto']} x${detalleParaTicket['cantidad']}',
        );
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
    double totalEstimado,
  ) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];

    try {
      isUpdating.value = true; // Activar loading

      final impresoraConectada = await printerService
          .conectarImpresoraAutomaticamente();

      // ✅ CAMBIO: Extraer todos los IDs y hacer una sola llamada
      List<int> detalleIds = productos
          .map((p) => p['detalleId'] as int)
          .toList();
      await controller.actualizarEstadoOrden(
        detalleIds,
        'pagado',
        completarTodos: true,
      );

      // Calcular total real y productos pagados
      double totalReal = 0.0;
      List<Map<String, dynamic>> productosRecienPagados = [];

      for (var producto in productos) {
        final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario =
            (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        totalReal += precioUnitario * cantidad;

        productosRecienPagados.add({...producto, 'statusDetalle': 'pagado'});
      }

      // Liberar mesa
      bool mesaLiberada = false;
      try {
        Uri uri = Uri.parse(
          '${controller.defaultApiServer}/mesas/liberarMesa/$idnumeromesa/',
        );
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

      // Imprimir ticket
      if (impresoraConectada && productosRecienPagados.isNotEmpty) {
        try {
          final pedidoParaTicket = _crearPedidoParaTicketConFiltro(
            productosRecienPagados,
            pedido,
            totalReal,
            'productos_seleccionados_liberacion',
          );
          await printerService.imprimirTicket(pedidoParaTicket, totalReal);
        } catch (e) {
          print('❌ Error en impresión: $e');
        }
      }

      productosSeleccionados.clear();

      // Mostrar resultado
      if (mesaLiberada) {
        Get.back(); // Cerrar TableDetailsModal

        Get.snackbar(
          'Operación Exitosa',
          '🎉 Mesa $numeroMesa liberada exitosamente!\n'
              'Productos: ${detalleIds.length}\n'
              'Total: \$${totalReal.toStringAsFixed(2)}',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'Pago Exitoso - Error al Liberar',
          'Productos pagados pero no se pudo liberar la mesa',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }

      await controller.refrescarDatos();
    } catch (e) {
      productosSeleccionados.clear();

      Get.snackbar(
        'Error',
        'Error al procesar: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      await controller.refrescarDatos();
    } finally {
      isUpdating.value = false; // Desactivar loading
      await printerService.desconectar();
    }
  }

  Future<void> imprimirTicketManual(Map<String, dynamic> pedido) async {
    try {
      isUpdating.value = true;

      // Calcular total de productos no cancelados
      double totalReal = 0.0;
      List<Map<String, dynamic>> productosActivos = [];

      final detalles = pedido['detalles'] as List? ?? [];
      for (var detalle in detalles) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        if (status == 'cancelado') continue;

        final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
        final precioUnitario =
            (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        totalReal += precioUnitario * cantidad;
        productosActivos.add(detalle);
      }

      if (productosActivos.isEmpty) {
        Get.snackbar(
          'Sin productos',
          'No hay productos para imprimir',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Generar bytes
      final pedidoParaTicket = {...pedido, 'detalles': productosActivos};

      final ticketBytes = await printerService.generarBytesTicket(
        pedidoParaTicket,
        totalReal,
      );
      final impreso = await printerService.conectarYEnviarBytes(ticketBytes);

      Get.snackbar(
        impreso ? '✅ Ticket impreso' : '❌ Error al imprimir',
        impreso
            ? 'Total: \$${totalReal.toStringAsFixed(2)}'
            : 'No se pudo conectar con la impresora',
        backgroundColor: (impreso ? Colors.green : Colors.red).withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Error imprimiendo manual: $e');
      Get.snackbar(
        'Error',
        'Error al imprimir: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> renombrarOrden(int pedidoId, String nuevoNombre) async {
    if (nuevoNombre.trim().isEmpty) return;

    isUpdating.value = true;

    try {
      final controller = Get.find<OrdersController>();
      final uri = Uri.parse(
        '${controller.defaultApiServer}/ordenes/obtenerPedidosPorFecha/',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nuevoNombre': nuevoNombre.trim(),
              'pedidoId': pedidoId,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        await controller.refrescarDatos();
        update();

        Get.snackbar(
          'Nombre Actualizado',
          'El pedido ahora se llama "${nuevoNombre.trim()}"',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error renombrando orden: $e');
      Get.snackbar(
        'Error',
        'No se pudo cambiar el nombre: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  void mostrarDialogoRenombrar(Map<String, dynamic> pedido) {
    final pedidoId = pedido['pedidoId'] as int;
    final nombreActual = pedido['nombreOrden'] ?? '';
    final textController = TextEditingController(text: nombreActual);

    Get.dialog(
      AlertDialog(
        title: Text(
          'Cambiar Nombre',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nombre del pedido',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF8B4513)),
            ),
          ),
          onSubmitted: (value) {
            Get.back();
            renombrarOrden(pedidoId, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              renombrarOrden(pedidoId, textController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B4513)),
            child: Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

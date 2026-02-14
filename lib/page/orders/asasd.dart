import 'dart:typed_data';
import 'dart:ui';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/services/BluetoothPrinterService.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderController.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderScreen.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class TableDetailsModal extends StatefulWidget {
  final Map<String, dynamic> mesa;

  const TableDetailsModal({Key? key, required this.mesa}) : super(key: key);

  @override
  _TableDetailsModalState createState() => _TableDetailsModalState();
}

class _TableDetailsModalState extends State<TableDetailsModal> {
  int selectedOrderIndex = -1; // -1 significa "todos los pedidos"
  final UniversalPrinterService printerService = UniversalPrinterService();
  BluetoothConnection? bluetoothConnection;
  bool isBluetoothConnected = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _setupOrdersListener();
  }

  void _setupOrdersListener() {
    try {
      final ordersController = Get.find<OrdersController>();
      
      ever(ordersController.mesasConPedidos, (List<dynamic> mesas) {
        if (mounted && !_isUpdating) {
          print('🔄 Órdenes actualizadas, refrescando modal...');
          setState(() {});
        }
      });
      
    } catch (e) {
      print('❌ Error configurando listener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.find<OrdersController>();
    
    final mesaActualizada = ordersController.mesasConPedidos.firstWhere(
      (mesa) => mesa['numeroMesa'] == widget.mesa['numeroMesa'],
      orElse: () => widget.mesa,
    );
    
    final numeroMesa = mesaActualizada['numeroMesa'];
    final idnumeromesa = mesaActualizada['id'] as int? ?? 0;
    final pedidos = mesaActualizada['pedidos'] as List;
    final totalMesa = ordersController.calcularTotalMesa(mesaActualizada);
    
    return Column(
      children: [
        // Handle
        Container(
          margin: EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header simplificado
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa $numeroMesa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  Text(
                    '${pedidos.length} pedido${pedidos.length != 1 ? 's' : ''} activo${pedidos.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  IconButton(
                    onPressed: _actualizarDatosManualmente,
                    icon: Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Selector de pedidos (solo si hay más de uno)
        if (pedidos.length > 1)
          _buildSimpleOrderSelector(pedidos),

        // Lista de productos
        Expanded(
          child: selectedOrderIndex == -1
              ? _buildAllProductsView(pedidos)
              : _buildSingleOrderProducts(pedidos[selectedOrderIndex]),
        ),
        
        // Footer con total y acciones
        _buildSimpleFooter(pedidos, totalMesa, numeroMesa, idnumeromesa),
      ],
    );
  }

  // Selector simple como tabs
  Widget _buildSimpleOrderSelector(List pedidos) {
    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Tab "Todos"
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedOrderIndex = -1),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: selectedOrderIndex == -1 ? Color(0xFF8B4513) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Todos',
                    style: TextStyle(
                      color: selectedOrderIndex == -1 ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Tabs individuales
          ...pedidos.asMap().entries.map((entry) {
            final index = entry.key;
            final pedido = entry.value;
            final isSelected = selectedOrderIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedOrderIndex = index),
                child: Container(
                  height: 40,
                  margin: EdgeInsets.only(right: index < pedidos.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF2196F3) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '#${pedido['pedidoId']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Vista de todos los productos (estilo _showCart)
  Widget _buildAllProductsView(List pedidos) {
    List<Map<String, dynamic>> todosLosProductos = [];
    
    // Recopilar todos los productos de todos los pedidos
    for (int i = 0; i < pedidos.length; i++) {
      final pedido = pedidos[i];
      final detalles = pedido['detalles'] as List;
      
      for (var detalle in detalles) {
        todosLosProductos.add({
          ...detalle,
          'pedidoId': pedido['pedidoId'],
          'nombreOrden': pedido['nombreOrden'],
          'colorPedido': _getOrderColor(i),
        });
      }
    }

    return todosLosProductos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay productos en esta mesa',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: todosLosProductos.length,
            itemBuilder: (context, index) {
              final producto = todosLosProductos[index];
              return _buildProductCard(producto);
            },
          );
  }

  // Vista de productos de un pedido específico
  Widget _buildSingleOrderProducts(Map<String, dynamic> pedido) {
    final detalles = pedido['detalles'] as List;
    
    return Column(
      children: [
        // Info del pedido
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF8B4513).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pedido['nombreOrden'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    Text(
                      'Pedido #${pedido['pedidoId']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón agregar productos
              ElevatedButton.icon(
                onPressed: () => _abrirModalAgregarProductos(pedido),
                icon: Icon(Icons.add, size: 18),
                label: Text('AGREGAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de productos
        Expanded(
          child: detalles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Sin productos en este pedido',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    return _buildProductCard({
                      ...detalle,
                      'pedidoId': pedido['pedidoId'],
                      'nombreOrden': pedido['nombreOrden'],
                      'colorPedido': Color(0xFF2196F3),
                    });
                  },
                ),
        ),
      ],
    );
  }

  // Función para obtener emoji según categoría (igual que en tu carrito)
  String _getProductEmoji(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower.contains('bebida')) return '🥤';
    if (categoriaLower.contains('postre')) return '🍰';
    if (categoriaLower.contains('extra')) return '🥄';
    return '🌮';
  }

  // Card de producto (exactamente igual que _buildCartItem)
 Widget _buildProductCard(Map<String, dynamic> producto) {
  final statusDetalle = producto['statusDetalle'] ?? 'proceso';
  final isCancelado = statusDetalle == 'cancelado';
  final cantidad = producto['cantidad'] ?? 1;
  final precioUnitario = producto['precioUnitario'] ?? 0.0;
  final subtotal = precioUnitario * cantidad;
  final categoria = producto['categoria'] ?? '';
       
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isCancelado ? Colors.grey[200] : Color(0xFFF5F2F0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Row(
          children: [
            // Emoji del producto
            Text(
              _getProductEmoji(categoria),
              style: TextStyle(
                fontSize: 24,
                color: isCancelado ? Colors.grey : null,
              ),
            ),
            SizedBox(width: 12),
                         
            // Info del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombreProducto'] ?? 'Producto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCancelado ? Colors.grey : Color(0xFF3E1F08),
                      decoration: isCancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    '\$${precioUnitario.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      color: isCancelado ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                      decoration: isCancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                                       
                  // Observaciones
                  if (producto['observaciones']?.isNotEmpty == true)
                    Text(
                      producto['observaciones'],
                      style: TextStyle(
                        color: isCancelado ? Colors.grey : Colors.grey[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        decoration: isCancelado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                                       
                  // Info del pedido (solo en vista "Todos")
                  if (selectedOrderIndex == -1)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: producto['colorPedido'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pedido #${producto['pedidoId']} • ${producto['nombreOrden'] ?? 'Sin nombre'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: producto['colorPedido'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
                         
            // Status y controles (lado derecho)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status chip
                _buildStatusChip(statusDetalle),
                                   
                SizedBox(height: 8),
                                   
                // Botones de estado (SOLO cuando está en proceso)
                if (statusDetalle == 'proceso') ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón cancelar
                      IconButton(
                        onPressed: () => _cambiarEstadoProducto(producto, 'cancelado'),
                        icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        tooltip: 'Cancelar',
                      ),
                                               
                      // Botón completar
                      IconButton(
                        onPressed: () => _cambiarEstadoProducto(producto, 'completado'),
                        icon: Icon(Icons.check_circle, color: Colors.green, size: 18),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        tooltip: 'Completar',
                      ),
                    ],
                  ),
                                       
                  SizedBox(height: 4),
                ],
                                   
                // Controles de cantidad (solo si NO está cancelado)
                if (!isCancelado) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón disminuir
                      IconButton(
                        onPressed: () => _disminuirCantidad(producto),
                        icon: Icon(Icons.remove_circle, color: Colors.red, size: 20),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                                               
                      // Cantidad
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                      ),
                                               
                      // Botón aumentar
                      IconButton(
                        onPressed: () => _aumentarCantidad(producto),
                        icon: Icon(Icons.add_circle, color: Color(0xFF8B4513), size: 20),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ] else ...[
                  // Solo mostrar cantidad para productos cancelados
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        
        // SUBTOTAL AQUÍ ABAJO - fuera del Row, dentro del Column principal
        SizedBox(height: 8), // Espacio entre el contenido y el subtotal
        Container(
          width: double.infinity, // Para que ocupe todo el ancho
          child: Text(
            'Subtotal: \$${subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCancelado ? Colors.grey : Color(0xFF8B4513),
              decoration: isCancelado ? TextDecoration.lineThrough : null,
              fontSize: 16, // Un poco más grande para que destaque
            ),
            textAlign: TextAlign.right, // Alineado a la derecha
          ),
        ),
      ],
    ),
  );
}

  // Footer simplificado
  Widget _buildSimpleFooter(List pedidos, double totalMesa, int numeroMesa, int idnumeromesa) {
    final tieneProductosEnProceso = _mesaTieneProductosEnProceso(pedidos);
    final currentTotal = selectedOrderIndex == -1 
        ? totalMesa 
        : _calcularTotalPedido(pedidos[selectedOrderIndex]);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F2F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedOrderIndex == -1 ? 'Total Mesa:' : 'Total Pedido:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E1F08),
                ),
              ),
              Text(
                '\$${currentTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Botones de acción
          if (selectedOrderIndex == -1) ...[
            if (!tieneProductosEnProceso) ...[
              // Botón liberar mesa
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmarLiberarMesa(numeroMesa, idnumeromesa),
                  icon: Icon(Icons.cleaning_services, color: Colors.white),
                  label: Text(
                    'LIBERAR MESA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE74C3C),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Mensaje de productos en proceso
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No se puede liberar la mesa. Hay productos en proceso.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Botones para pedido específico
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirModalAgregarProductos(pedidos[selectedOrderIndex]),
                    icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: Text(
                      'AGREGAR PRODUCTOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                if (_puedeSerPagado(pedidos[selectedOrderIndex]))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarPagoPedido(
                        pedidos[selectedOrderIndex], 
                        _calcularTotalPedido(pedidos[selectedOrderIndex])
                      ),
                      icon: Icon(Icons.payment, color: Colors.white),
                      label: Text(
                        'PAGAR PEDIDO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27AE60),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          
          // Padding para navegación del sistema
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  // Widget para status chip
  Widget _buildStatusChip(String status) {
    Color statusColor = _getStatusColor(status);
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'completado':
        statusIcon = Icons.check_circle;
        break;
      case 'proceso':
        statusIcon = Icons.schedule;
        break;
      case 'cancelado':
        statusIcon = Icons.cancel;
        break;
      default:
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }void _cambiarEstadoProducto(Map<String, dynamic> producto, String nuevoEstado) {
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
      Get.back(); // Cerrar diálogo de confirmación
      
      // ✅ CAMBIO: Pasar detalleId como lista
      final controller = Get.find<OrdersController>();
      await controller.actualizarEstadoOrden([detalleId], nuevoEstado);
    },
  );
}
  void _aumentarCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];
    final cantidadActual = producto['cantidad'] ?? 1;
    final nuevaCantidad = cantidadActual + 1;
    
    await _actualizarCantidadProducto(detalleId, nuevaCantidad);
  }

  void _disminuirCantidad(Map<String, dynamic> producto) async {
    final detalleId = producto['detalleId'];
    final cantidadActual = producto['cantidad'] ?? 1;
    
    if (cantidadActual <= 1) {
      // Si la cantidad es 1, preguntar si quiere eliminar el producto
      _confirmarEliminarProducto(producto);
      return;
    }
    
    final nuevaCantidad = cantidadActual - 1;
    await _actualizarCantidadProducto(detalleId, nuevaCantidad);
  }

  // Función para actualizar cantidad en el servidor
  Future<void> _actualizarCantidadProducto(int detalleId, int nuevaCantidad) async {
    final controller = Get.find<OrdersController>();
    
    try {
      // Mostrar loading
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
        body: jsonEncode({
          'cantidad': nuevaCantidad,
        }),
      );

      // Cerrar loading
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
          
          // Refrescar datos
          await controller.refrescarDatos();
        } else {
          _mostrarErrorCantidad('Error del servidor: ${data['message'] ?? 'Error desconocido'}');
        }
      } else {
        _mostrarErrorCantidad('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al actualizar cantidad: $e');
      _mostrarErrorCantidad('Error de conexión: $e');
    }
  }

  // Confirmar eliminación de producto
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

  // Eliminar producto del pedido
  Future<void> _eliminarProducto(int detalleId) async {
    final controller = Get.find<OrdersController>();
    
    try {
      // Mostrar loading
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

      // Cerrar loading
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
          
          // Refrescar datos
          await controller.refrescarDatos();
        } else {
          _mostrarErrorCantidad('Error al eliminar: ${data['message'] ?? 'Error desconocido'}');
        }
      } else {
        _mostrarErrorCantidad('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al eliminar producto: $e');
      _mostrarErrorCantidad('Error de conexión: $e');
    }
  }

  // Mostrar error de cantidad
  void _mostrarErrorCantidad(String mensaje) {
    Get.snackbar(
      'Error',
      mensaje,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }
  Future<void> _actualizarDatosManualmente() async {
    if (_isUpdating) return;
    
    setState(() => _isUpdating = true);
    
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
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _abrirModalAgregarProductos(Map<String, dynamic> pedido) {
    final pedidoId = pedido['pedidoId'] as int;
    final numeroMesa = widget.mesa['numeroMesa'] as int;
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: AddProductsToOrderScreen(),
      ),
    ).then((_) {
      final controller = Get.find<OrdersController>();
      controller.refrescarDatos();
    });
    
    Future.delayed(Duration(milliseconds: 100), () {
      try {
        Get.find<AddProductsToOrderController>().inicializarConPedido(
          pedidoId, numeroMesa, nombreOrden,
        );
      } catch (e) {
        Get.put(AddProductsToOrderController()).inicializarConPedido(
          pedidoId, numeroMesa, nombreOrden,
        );
      }
    });
  }

  bool _puedeSerPagado(Map<String, dynamic> pedido) {
    final detalles = pedido['detalles'] as List;
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status != 'proceso' && status != 'cancelado') return true;
    }
    return false;
  }

  double _calcularTotalPedido(Map<String, dynamic> pedido) {
    double total = 0.0;
    final detalles = pedido['detalles'] as List;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status != 'cancelado') {
        total += (detalle['precioUnitario'] ?? 0.0) * (detalle['cantidad'] ?? 1);
      }
    }
    return total;
  }

  bool _mesaTieneProductosEnProceso(List pedidos) {
    for (var pedido in pedidos) {
      final detalles = pedido['detalles'] as List;
      for (var detalle in detalles) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        if (status == 'proceso') return true;
      }
    }
    return false;
  }

  void _confirmarLiberarMesa(int numeroMesa, int idnumeromesa) {
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
        await _liberarMesa(idnumeromesa);
      },
    );
  }

  Future<void> _liberarMesa(int numeroMesa) async {
    final controller = Get.find<OrdersController>();
    
    try {
      Uri uri = Uri.parse('${controller.defaultApiServer}/mesas/liberarMesa/$numeroMesa/');
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
          Get.back(); // Cerrar modal
          
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

  void _confirmarPagoPedido(Map<String, dynamic> pedido, double total) {
    final pedidoId = pedido['pedidoId'];
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    
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
        // Aquí implementarías la lógica de pago
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado': return Colors.green;
      case 'proceso': return Colors.orange;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getOrderColor(int index) {
    List<Color> colors = [
      Color(0xFF8B4513), Color(0xFF2196F3), Color(0xFF4CAF50),
      Color(0xFFFF9800), Color(0xFF9C27B0), Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  List<int> _obtenerDetalleIdsDePedido(Map<String, dynamic> pedido) {
    List<int> detalleIds = [];
    final detalles = pedido['detalles'] as List;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'completado') {
        detalleIds.add(detalle['detalleId']);
      }
    }
    return detalleIds;
  }

  Future<void> _pagarPedidoEspecifico(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    
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
}
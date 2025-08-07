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
import 'package:restaurapp/page/orders/orders_controller.dart';

class OrdersDashboardScreen extends StatelessWidget {
  final OrdersController controller = Get.put(OrdersController());

  OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EJ',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 12),
            
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Comedor "El Jobo"',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    // ✅ MODIFICADO: Agregar estado de auto-refresh
    Obx(() => Row(
      children: [
        Text(
          'Órdenes Activas',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        if (controller.isAutoRefreshEnabled.value) ...[
          SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Auto ${controller.autoRefreshInterval}s',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[200],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    )),
  ],
),
          ],
        ),
        actions: [
         
           Obx(() => IconButton(
    icon: Icon(
      controller.isAutoRefreshEnabled.value 
        ? Icons.pause_circle_filled 
        : Icons.play_circle_filled,
      color: Colors.white,
    ),
    tooltip: controller.isAutoRefreshEnabled.value 
      ? 'Pausar auto-refresh' 
      : 'Activar auto-refresh',
    onPressed: () => controller.toggleAutoRefresh(),
  )),
  
  // Botón de refresh manual existente
  IconButton(
    icon: Icon(Icons.refresh, color: Colors.white),
    onPressed: () => controller.refrescarDatos(),
  ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando órdenes...',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refrescarDatos,
          color: Color(0xFF8B4513),
          child: Column(
            children: [
              // Carousel de pedidos pendientes - 60% del espacio
              Expanded(
                flex: 3,
                child: _buildPendingOrdersCarousel(),
              ),
              
              // Lista de mesas - 40% del espacio
              Expanded(
                flex: 6,
                child: _buildTablesList(),
              ),
            ],
          ),
        );
      }),
    );
  }

Widget _buildPendingOrdersCarousel() {
  return Container(
    child: Column(
      children: [
        
Padding(
  padding: EdgeInsets.all(16),
  child: Row(
    children: [
      Icon(Icons.restaurant_menu, color: Color(0xFF8B4513)),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Pedidos Pendientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
      ),
      // ✅ NUEVO: Indicador de auto-refresh
      Obx(() {
        if (controller.isAutoRefreshEnabled.value) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      }),
    ],
  ),
),
        Expanded(
          child: Obx(() {
            if (controller.pedidosIndividuales.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'No hay pedidos pendientes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // ✅ SOLUCIÓN: ScrollConfiguration para desktop
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(Get.context!).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,    // Táctil (móvil)
                  PointerDeviceKind.mouse,    // Mouse (desktop)
                  PointerDeviceKind.trackpad, // Trackpad (laptop)
                },
                scrollbars: true, // Mostrar scrollbar en desktop
              ),
              child: Container(
                height: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.pedidosIndividuales.length,
                  itemBuilder: (context, index) {
                    final pedido = controller.pedidosIndividuales[index];
                    return _buildCarouselCardIndividual(pedido);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );
}



Widget _buildCarouselCardIndividual(Map<String, dynamic> detalle) {
  final numeroMesa = detalle['numeroMesa'];
  final nombreOrden = detalle['nombreOrden'] ?? 'Sin nombre';
  final pedidoId = detalle['detalleId'];
  final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
  final cantidad = detalle['cantidad'] ?? 1;
  // ✅ CAMBIO: Usar 'precio' en lugar de 'precioUnitario' para el carrusel
  final precio = (detalle['precio'] ?? 0.0).toDouble();
  final observaciones = detalle['observaciones'] ?? '';
  final fecha = DateTime.parse(detalle['fecha']);
  final timeString = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
       
  return Container(
    width: 180,
    margin: EdgeInsets.only(right: 12, bottom: 8),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => controller.mostrarModalEstadoOrden(pedidoId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del producto
              Text(
                nombreProducto,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
                           
              // Cantidad y precio
              Text(
                'Cantidad: $cantidad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // ✅ AGREGADO: Mostrar precio unitario
              Text(
                'Precio: \$${precio.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              SizedBox(height: 8),
                           
              // Mesa y pedido
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MESA $numeroMesa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                           
              Spacer(),
                           
              // Observaciones si existen
              if (observaciones.isNotEmpty) ...[
                Text(
                  observaciones,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
              ],
                           
              // ID del pedido y hora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#$pedidoId',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  Widget _buildCarouselCard(Map<String, dynamic> mesaPedidos) {
    final numeroMesa = mesaPedidos['numeroMesa'];
    final pedidos = mesaPedidos['pedidos'] as List;
    final primerPedido = pedidos.isNotEmpty ? pedidos.first : null;
    
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12, bottom: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primerPedido != null ? primerPedido['nombreOrden'] ?? 'Sin nombre' : 'Sin pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MESA $numeroMesa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${pedidos.length} pedido${pedidos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablesList() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Divider(color: Colors.grey[400]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Lista',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.mesasConPedidos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_restaurant, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No hay mesas con pedidos activos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.mesasConPedidos.length,
              itemBuilder: (context, index) {
                final mesa = controller.mesasConPedidos[index];
                return _buildTableCard(mesa);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> mesa) {
    final numeroMesa = mesa['numeroMesa'];
    final pedidos = mesa['pedidos'] as List;
    final totalMesa = controller.calcularTotalMesa(mesa);
    final totalItems = controller.contarItemsMesa(mesa);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => controller.mostrarDetallesMesa(numeroMesa),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mesa $numeroMesa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$totalItems item${totalItems != 1 ? 's' : ''} • ${pedidos.length} pedido${pedidos.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (totalMesa > 0) ...[
                        SizedBox(height: 8),
                        Text(
                          'Total: \$${totalMesa.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'ver mas',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF8B4513),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




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
  @override
  Widget build(BuildContext context) {
    final numeroMesa = widget.mesa['numeroMesa'];
    final pedidos = widget.mesa['pedidos'] as List;
    final controller = Get.find<OrdersController>();
    final totalMesa = controller.calcularTotalMesa(widget.mesa);
    
    return Column(
      children: [
        // Header del modal
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF8B4513),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa $numeroMesa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      selectedOrderIndex == -1 
                        ? '${pedidos.length} pedido${pedidos.length != 1 ? 's' : ''} activo${pedidos.length != 1 ? 's' : ''}'
                        : 'Pedido #${pedidos[selectedOrderIndex]['pedidoId']}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedOrderIndex != -1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedOrderIndex = -1;
                    });
                  },
                  icon: Icon(Icons.view_list, color: Colors.white),
                  tooltip: 'Ver todos los pedidos',
                ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        
        // Botones de selección de pedidos
        if (pedidos.length > 1)
          _buildOrderSelector(pedidos),
        
        // Contenido del modal
        Expanded(
          child: selectedOrderIndex == -1
            ? _buildAllOrdersView(pedidos)
            : _buildSingleOrderView(pedidos[selectedOrderIndex]),
        ),
        
        // Footer con total y botones de acción
        _buildFooter(pedidos, totalMesa, numeroMesa),
      ],
    );
  }

  Widget _buildOrderSelector(List pedidos) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Seleccionar cuenta:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E1F08),
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Botón "Todos"
                _buildOrderSelectorButton(
                  label: 'Todos',
                  isSelected: selectedOrderIndex == -1,
                  onTap: () {
                    setState(() {
                      selectedOrderIndex = -1;
                    });
                  },
                  color: Color(0xFF8B4513),
                ),
                SizedBox(width: 12),
                
                // Botones individuales por pedido
                ...pedidos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pedido = entry.value;
                  
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: _buildOrderSelectorButton(
                      label: 'Pedido #${pedido['pedidoId']}',
                      isSelected: selectedOrderIndex == index,
                      onTap: () {
                        setState(() {
                          selectedOrderIndex = index;
                        });
                      },
                      color: _getOrderColor(index),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSelectorButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOrdersView(List pedidos) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return _buildOrderCard(pedido, index);
      },
    );
  }

  Widget _buildSingleOrderView(Map<String, dynamic> pedido) {
    final detalles = pedido['detalles'] as List;
    final total = _calcularTotalPedido(pedido);
    final fecha = DateTime.parse(pedido['fecha']);
    final timeString = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del pedido individual con botón de pago
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getOrderColor(selectedOrderIndex).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pedido['nombreOrden'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          Text(
                            'Pedido #${pedido['pedidoId']} • $timeString',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Resumen de status de productos
                    _buildOrderStatusSummary(detalles),
                  ],
                ),
                
                // Botón de pago individual en vista de pedido específico
                if (total > 0 && _puedeSerPagado(pedido)) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmarPagoPedido(pedido, total),
                      icon: Icon(Icons.payment, color: Colors.white, size: 16),
                      label: Text(
                        'PAGAR PEDIDO \$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27AE60),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],

if (total == 0 || !_puedeSerPagado(pedido)) ...[
  SizedBox(height: 12),
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
        Icon(Icons.info_outline, color: Colors.orange, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Este pedido no puede ser pagado. Solo productos completados pueden ser facturados.',
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
],
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Lista de productos
          Expanded(
            child: detalles.isNotEmpty
              ? ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    return _buildOrderItem(detalles[index]);
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, 
                           size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Sin productos en este pedido',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar resumen de status de productos en un pedido
  Widget _buildOrderStatusSummary(List detalles) {
    final statusCount = <String, int>{};
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statusCount.entries.map((entry) {
        final status = entry.key;
        final count = entry.value;
        final color = _getStatusColor(status);
        
        return Container(
          margin: EdgeInsets.only(left: 4),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Producto individual con statusDetalle
  Widget _buildOrderItem(Map<String, dynamic> detalle) {
    final statusDetalle = detalle['statusDetalle'] ?? 'proceso';
    final isCancelado = statusDetalle == 'cancelado';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelado ? Colors.grey[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCancelado ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Emoji del producto
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCancelado 
                ? Colors.grey.withOpacity(0.1)
                : Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '🌮', 
                style: TextStyle(
                  fontSize: 24,
                  color: isCancelado ? Colors.grey : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detalle['nombreProducto'] ?? 'Producto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCancelado ? Colors.grey : Color(0xFF3E1F08),
                          decoration: isCancelado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    // Status del producto individual
                    _buildStatusChip(statusDetalle),
                  ],
                ),
                if (detalle['observaciones']?.isNotEmpty == true) ...[
                  SizedBox(height: 4),
                  Text(
                    detalle['observaciones'],
                    style: TextStyle(
                      color: isCancelado ? Colors.grey : Colors.grey[600],
                      fontSize: 14,
                      decoration: isCancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  'Precio unitario: \$${(detalle['precioUnitario'] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isCancelado ? Colors.grey : Colors.grey[600],
                    fontSize: 12,
                    decoration: isCancelado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Cantidad y total
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCancelado ? Colors.grey : Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${detalle['cantidad']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '\$${((detalle['precioUnitario'] ?? 0.0) * (detalle['cantidad'] ?? 1)).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCancelado ? Colors.grey : Color(0xFF8B4513),
                  fontSize: 14,
                  decoration: isCancelado ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card de pedido con botón de pago individual
  Widget _buildOrderCard(Map<String, dynamic> pedido, int index) {
    final detalles = pedido['detalles'] as List;
    final total = _calcularTotalPedido(pedido);
    final fecha = DateTime.parse(pedido['fecha']);
    final timeString = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getOrderColor(index).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del pedido con botón expandir
            InkWell(
              onTap: () {
                setState(() {
                  selectedOrderIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            'Pedido #${pedido['pedidoId']} • $timeString',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Resumen de status de productos
                        _buildOrderStatusSummary(detalles),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, 
                             size: 14, color: _getOrderColor(index)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (detalles.isNotEmpty) ...[
              SizedBox(height: 12),
              // Resumen de items (máximo 3)
              ...detalles.take(3).map((detalle) => 
                _buildOrderItemSummary(detalle)).toList(),
              
              if (detalles.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${detalles.length - 3} productos más...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              SizedBox(height: 12),
              Divider(),
              
              // Fila con total y botón de pago individual
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getOrderColor(index),
                        ),
                      ),
                    ],
                  ),
                  
                  // Botón de pago individual por pedido && _puedeSerPagado(pedido)
                if (total > 0 )
                    ElevatedButton.icon(
                      onPressed: () => _confirmarPagoPedido(pedido, total),
                      icon: Icon(Icons.payment, color: Colors.white, size: 16),
                      label: Text(
                        'PAGAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF27AE60),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                ],
              ),
            ] else ...[
              SizedBox(height: 8),
              Text(
                'Sin items agregados',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Resumen de item con statusDetalle
  Widget _buildOrderItemSummary(Map<String, dynamic> detalle) {
    final statusDetalle = detalle['statusDetalle'] ?? 'proceso';
    final isCancelado = statusDetalle == 'cancelado';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '🌮', 
            style: TextStyle(
              fontSize: 16,
              color: isCancelado ? Colors.grey : null,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              detalle['nombreProducto'] ?? 'Producto',
              style: TextStyle(
                fontSize: 14,
                decoration: isCancelado ? TextDecoration.lineThrough : null,
                color: isCancelado ? Colors.grey : Color(0xFF3E1F08),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status chip pequeño
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(statusDetalle),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCancelado 
                ? Colors.grey.withOpacity(0.1)
                : Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${detalle['cantidad']}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCancelado ? Colors.grey : Color(0xFF8B4513),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el status con colores y estilos apropiados
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
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
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
  }

  // Función para obtener color según status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'proceso':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
bool _puedeSerPagado(Map<String, dynamic> pedido) {
  final detalles = pedido['detalles'] as List;
  
  // Un pedido puede ser pagado si tiene al menos un producto que NO esté en 'proceso' o 'cancelado'
  for (var detalle in detalles) {
    final status = detalle['statusDetalle'] ?? 'proceso';
    if (status != 'proceso' && status != 'cancelado') {
      return true;
    }
  }
  return false;
}

  // Calcular total de un pedido considerando solo productos no cancelados
double _calcularTotalPedido(Map<String, dynamic> pedido) {
  double total = 0.0;
  final detalles = pedido['detalles'] as List;
  
  for (var detalle in detalles) {
    final status = detalle['statusDetalle'] ?? 'proceso';
    // Sumar todos EXCEPTO los cancelados
    if (status != 'cancelado') {
      total += (detalle['precioUnitario'] ?? 0.0) * (detalle['cantidad'] ?? 1);
    }
  }
  
  return total;
}

  // Obtener detalleIds de un pedido específico
List<int> _obtenerDetalleIdsDePedido(Map<String, dynamic> pedido) {
  List<int> detalleIds = [];
  final detalles = pedido['detalles'] as List;
  
  for (var detalle in detalles) {
    final status = detalle['statusDetalle'] ?? 'proceso';
    // Solo agregar detalles que estén 'completado'
    if (status == 'completado') {
      detalleIds.add(detalle['detalleId']);
    }
  }
  
  return detalleIds;
}


  // Confirmar pago de un pedido específico
  void _confirmarPagoPedido(Map<String, dynamic> pedido, double total) {
    final pedidoId = pedido['pedidoId'];
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final detalleIds = _obtenerDetalleIdsDePedido(pedido);
    final cantidadItems = detalleIds.length;
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Pago',
      text: '¿Confirmar el pago del pedido?\n\n'
            'Pedido: $nombreOrden\n'
            'ID: #$pedidoId\n'
            'Total: \$${total.toStringAsFixed(2)}\n'
            'Items: $cantidadItems\n\n'
            'Se procesarán todos los items de este pedido.',
      confirmBtnText: 'Confirmar Pago',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFF27AE60),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar diálogo de confirmación
        await _pagarPedidoEspecifico(pedido, detalleIds, total);
      },
    );
  }
Future<bool> _conectarImpresoraAutomaticamente() async {
    try {
      // Obtener dispositivos emparejados
      List<BluetoothDevice> bondedDevices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      // Buscar impresora en la lista (por nombre que contenga "printer" o "bluetooth")
      BluetoothDevice? impresora;
      for (var device in bondedDevices) {
        final deviceName = device.name?.toLowerCase() ?? '';
        if (deviceName.contains('printer') || 
            deviceName.contains('bluetooth') ||
            deviceName.contains('pos') ||
            deviceName.contains('receipt')) {
          impresora = device;
          break;
        }
      }
      
      if (impresora == null) {
        print('❌ No se encontró impresora Bluetooth emparejada');
        return false;
      }
      
      // Intentar conectar
      bluetoothConnection = await BluetoothConnection.toAddress(impresora.address);
      isBluetoothConnected = true;
      
      print('✅ Conectado a impresora: ${impresora.name}');
      return true;
      
    } catch (e) {
      print('❌ Error conectando a impresora: $e');
      isBluetoothConnected = false;
      return false;
    }
  }

  // ✅ FUNCIÓN MODIFICADA: Usar servicio universal
  Future<void> _pagarPedidoEspecifico(Map<String, dynamic> pedido, List<int> detalleIds, double totalEstimado) async {
    final controller = Get.find<OrdersController>();
    final pedidoId = pedido['pedidoId'];
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    
    try {
    

      // ✅ NUEVO: Intentar conectar a impresora (funciona en móvil Y desktop)
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

      // Cerrar loading
      Get.back();

      // ✅ NUEVO: Imprimir ticket universal (móvil o desktop)
      if (fallidos == 0 && impresoraConectada) {
        try {
          await printerService.imprimirTicket(pedido, totalReal);
        } catch (e) {
          print('❌ Error en impresión: $e');
          // Continuar sin interrumpir el flujo
        }
      }

      // Mostrar resultado
      if (fallidos == 0) {
        String mensaje = 'Pedido #$pedidoId pagado correctamente\n'
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
        
      } else if (exitosos > 0) {
        String mensaje = 'Pedido #$pedidoId procesado parcialmente\n'
                        'Exitosos: $exitosos items\nFallidos: $fallidos items\n'
                        'Total procesado: \${totalReal.toStringAsFixed(2)}';
        
        if (impresoraConectada && exitosos > 0) {
          try {
            await printerService.imprimirTicket(pedido, totalReal);
            mensaje += '\n✅ Ticket impreso';
          } catch (e) {
            mensaje += '\n❌ Error en impresión';
          }
        }
        
        Get.snackbar(
          'Pago Parcial',
          mensaje,
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
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Error al procesar pago del pedido: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      // ✅ NUEVO: Desconectar impresora universal
      await printerService.desconectar();
    }
  }

  // ✅ FUNCIÓN OPCIONAL: Configurar impresora manualmente
  void _configurarImpresora() async {
    try {
      List<String> impresoras = await printerService.obtenerImpresorasDisponibles();
      
      if (impresoras.isEmpty) {
        Get.snackbar(
          'Sin Impresoras',
          'No se encontraron impresoras disponibles',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      // Mostrar diálogo para seleccionar impresora
      Get.dialog(
        AlertDialog(
          title: Text('Seleccionar Impresora'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: impresoras.length,
              itemBuilder: (context, index) {
                final impresora = impresoras[index];
                return ListTile(
                  leading: Icon(printerService.isMobile ? Icons.bluetooth : Icons.print),
                  title: Text(impresora),
                  subtitle: Text(printerService.isMobile ? 'Bluetooth' : 'Sistema'),
                  onTap: () async {
                    Get.back();
                    
                    // Aquí puedes implementar conexión manual específica
                    Get.snackbar(
                      'Impresora Seleccionada',
                      'Impresora configurada: $impresora',
                      backgroundColor: Colors.green.withOpacity(0.8),
                      colorText: Colors.white,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al buscar impresoras: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ✅ FUNCIÓN OPCIONAL: Probar impresión
  void _probarImpresion() async {
    try {
      final connected = await printerService.conectarImpresoraAutomaticamente();
      
      if (!connected) {
        Get.snackbar(
          'Sin Conexión',
          'No se pudo conectar a ninguna impresora',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      // Crear pedido de prueba
      Map<String, dynamic> pedidoPrueba = {
        'numeroMesa': 99,
        'nombreOrden': 'PRUEBA SISTEMA',
        'pedidoId': 'TEST001',
        'detalles': [
          {
            'nombreProducto': 'Producto de Prueba',
            'cantidad': 1,
            'precioUnitario': 1.00,
            'statusDetalle': 'completado',
            'observaciones': 'Test de impresión',
          }
        ]
      };
      
      await printerService.imprimirTicket(pedidoPrueba, 1.00);
      
      Get.snackbar(
        'Prueba Exitosa',
        'Ticket de prueba enviado a la impresora',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      
    } catch (e) {
      Get.snackbar(
        'Error en Prueba',
        'Error al probar impresión: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      await printerService.desconectar();
    }
  }
  
  // ✅ AGREGAR BOTONES EN TU INTERFAZ
  Widget _buildPrinterControls() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _configurarImpresora,
              icon: Icon(Icons.settings, color: Colors.white),
              label: Text('CONFIGURAR IMPRESORA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _probarImpresion,
            icon: Icon(Icons.print, color: Colors.white),
            label: Text('PROBAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF27AE60),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }


  // ✅ NUEVO: Confirmar liberación de mesa
  void _confirmarLiberarMesa(int numeroMesa) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Liberar Mesa',
      text: '¿Está seguro de que quiere liberar la Mesa $numeroMesa?\n\n'
            'Esta acción marcará la mesa como disponible y limpiará todos los pedidos asociados.',
      confirmBtnText: 'Liberar Mesa',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C), // Rojo para indicar acción importante
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar diálogo de confirmación
        await _liberarMesa(numeroMesa);
      },
    );
  }

  // ✅ NUEVO: Liberar mesa usando el endpoint
  Future<void> _liberarMesa(int numeroMesa) async {
    final controller = Get.find<OrdersController>();
    
    try {
     

      Uri uri = Uri.parse('${controller.defaultApiServer}/mesas/liberarMesa/$numeroMesa/');
      
      print('📡 Liberando mesa $numeroMesa: $uri');
      final statusData = {
            'status': true, 
          };
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
              body: jsonEncode(statusData),

      );

      print('📡 Respuesta liberar mesa - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      // Cerrar loading
      Get.back();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Cerrar modal de detalles
          Get.back();
          
          // Mostrar mensaje de éxito
          Get.snackbar(
            'Mesa Liberada',
            'La Mesa $numeroMesa ha sido liberada correctamente',
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          
          // Recargar datos
          await controller.refrescarDatos();
        } else {
          _mostrarErrorLiberacion('Error en la respuesta del servidor: ${data['message'] ?? 'Error desconocido'}');
        }
      } else {
        _mostrarErrorLiberacion('Error del servidor (${response.statusCode})');
      }

    } catch (e) {
      // Cerrar loading si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al liberar mesa: $e');
      _mostrarErrorLiberacion('Error de conexión: $e');
    }
  }

  // ✅ NUEVO: Mostrar error de liberación
  void _mostrarErrorLiberacion(String mensaje) {
    Get.snackbar(
      'Error al Liberar Mesa',
      'No se pudo liberar la mesa: $mensaje',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      duration: Duration(seconds: 4),
    );
  }Future<void> _imprimirTicketVenta(Map<String, dynamic> pedido, double total) async {
  if (!isBluetoothConnected || bluetoothConnection == null) {
    print('❌ No hay conexión Bluetooth para imprimir');
    return;
  }

  try {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    
    List<int> bytes = [];
    
    // ===== HEADER DEL TICKET =====
    bytes += generator.text('COMEDOR "EL JOBO"',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    
    bytes += generator.text('Órdenes de Comida',
        styles: PosStyles(align: PosAlign.center));
    
    bytes += generator.text('================================',
        styles: PosStyles(align: PosAlign.center));
    
    // ===== INFORMACIÓN DEL PEDIDO =====
    final numeroMesa = pedido['numeroMesa'] ?? 'S/N';
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final pedidoId = pedido['pedidoId'] ?? 'S/N';
    final fecha = DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final horaStr = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    bytes += generator.text('TICKET DE VENTA');
    bytes += generator.text('--------------------------------');
    
    bytes += generator.row([
      PosColumn(text: 'Mesa:', width: 4),
      PosColumn(text: '$numeroMesa', width: 8, styles: PosStyles(bold: true)),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Pedido:', width: 4),
      PosColumn(text: '#$pedidoId', width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Cliente:', width: 4),
      PosColumn(text: '$nombreOrden', width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Fecha:', width: 4),
      PosColumn(text: '$fechaStr', width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Hora:', width: 4),
      PosColumn(text: '$horaStr', width: 8),
    ]);
    
    bytes += generator.text('================================');
    
    // ===== PRODUCTOS =====
    final detalles = pedido['detalles'] as List;
    
    bytes += generator.row([
      PosColumn(text: 'PRODUCTO', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: 'CANT', width: 3, styles: PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'TOTAL', width: 3, styles: PosStyles(bold: true, align: PosAlign.right)),
    ]);
    
    bytes += generator.text('--------------------------------');
    
    double subtotal = 0.0;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'cancelado') continue; // Omitir cancelados
      
      final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
      final cantidad = detalle['cantidad'] ?? 1;
      final precioUnitario = (detalle['precioUnitario'] ?? 0.0).toDouble();
      final totalItem = precioUnitario * cantidad;
      
      subtotal += totalItem;
      
      // Nombre del producto (puede ocupar múltiples líneas)
      if (nombreProducto.length > 20) {
        // Dividir nombre largo en múltiples líneas
        final palabras = nombreProducto.split(' ');
        String lineaActual = '';
        
        for (String palabra in palabras) {
          if ((lineaActual + palabra).length <= 20) {
            lineaActual += (lineaActual.isEmpty ? '' : ' ') + palabra;
          } else {
            if (lineaActual.isNotEmpty) {
              bytes += generator.text(lineaActual);
              lineaActual = palabra;
            } else {
              bytes += generator.text(palabra);
            }
          }
        }
        if (lineaActual.isNotEmpty) {
          bytes += generator.text(lineaActual);
        }
        
        // Cantidad y total en línea separada
        bytes += generator.row([
          PosColumn(text: '', width: 6),
          PosColumn(text: '$cantidad', width: 3, styles: PosStyles(align: PosAlign.center)),
          PosColumn(text: '\$${totalItem.toStringAsFixed(2)}', width: 3, 
              styles: PosStyles(align: PosAlign.right)),
        ]);
      } else {
        // Nombre corto, todo en una línea
        bytes += generator.row([
          PosColumn(text: nombreProducto, width: 6),
          PosColumn(text: '$cantidad', width: 3, styles: PosStyles(align: PosAlign.center)),
          PosColumn(text: '\$${totalItem.toStringAsFixed(2)}', width: 3, 
              styles: PosStyles(align: PosAlign.right)),
        ]);
      }
      
      // Agregar observaciones si existen
      final observaciones = detalle['observaciones'];
      if (observaciones != null && observaciones.toString().trim().isNotEmpty) {
        bytes += generator.text('  * $observaciones',
            styles: PosStyles(fontType: PosFontType.fontB));
      }
    }
    
    bytes += generator.text('--------------------------------');
    
    // ===== SOLO SUBTOTAL (SIN TOTAL) =====
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 8, 
          styles: PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: '\$${subtotal.toStringAsFixed(2)}', width: 4, 
          styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);
    
    // ✅ ELIMINADAS: Las líneas del TOTAL
    // ❌ bytes += generator.row([
    // ❌   PosColumn(text: 'TOTAL:', width: 8, 
    // ❌       styles: PosStyles(bold: true, height: PosTextSize.size2)),
    // ❌   PosColumn(text: '\$${total.toStringAsFixed(2)}', width: 4, 
    // ❌       styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    // ❌ ]);
    
    bytes += generator.text('================================');
    
    // ===== FOOTER =====
    bytes += generator.text('');
    bytes += generator.text('¡Gracias por su visita!',
        styles: PosStyles(align: PosAlign.center, bold: true));
    
    bytes += generator.text('');
    bytes += generator.text('Sistema de Restaurante',
        styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    
    bytes += generator.text('${DateTime.now().toString().substring(0, 19)}',
        styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));
    
    // Salto de líneas y corte de papel
    bytes += generator.feed(3);
    bytes += generator.cut();

    // ===== ENVIAR A IMPRESORA =====
    bluetoothConnection!.output.add(Uint8List.fromList(bytes));
    await bluetoothConnection!.output.allSent;
    
    print('✅ Ticket impreso correctamente');
    
  } catch (e) {
    print('❌ Error imprimiendo ticket: $e');
    // No lanzar excepción para no interrumpir el flujo de pago
  }
}
 Widget _buildFooter(List pedidos, double totalMesa, int numeroMesa) {
  final currentTotal = selectedOrderIndex == -1 
    ? totalMesa 
    : _calcularTotalPedido(pedidos[selectedOrderIndex]);
    
  final currentLabel = selectedOrderIndex == -1 
    ? 'Total Mesa:' 
    : 'Total Pedido:';
  final controller = Get.find<OrdersController>();
  
  // ✅ NUEVA VARIABLE: Verificar si hay productos en proceso
  final tieneProductosEnProceso = _mesaTieneProductosEnProceso(pedidos);
  
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFFF5F2F0),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      border: Border(
        top: BorderSide(color: Colors.grey[300]!),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Información del total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                if (selectedOrderIndex != -1 && pedidos.length > 1)
                  Text(
                    'Total general: ${totalMesa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            Text(
              '${currentTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: selectedOrderIndex == -1 
                  ? Color(0xFF8B4513) 
                  : _getOrderColor(selectedOrderIndex),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // ✅ MODIFICADO: Solo mostrar botones en vista "Todos" Y sin productos en proceso
        if (selectedOrderIndex == -1) ...[
          // ✅ NUEVO: Mostrar botón LIBERAR solo si NO hay productos en proceso
          if (!tieneProductosEnProceso) ...[
            Row(
              children: [
                SizedBox(width: 12),
                
                // Botón para liberar mesa
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarLiberarMesa(numeroMesa),
                    icon: Icon(
                      Icons.cleaning_services,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'LIBERAR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE74C3C), // Rojo para liberar
                      elevation: 4,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ✅ NUEVO: Mensaje informativo cuando hay productos en proceso
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
                  Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
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
          // Mensaje informativo en vista de pedido específico
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use el botón "PAGAR PEDIDO" arriba, o cambie a vista "Todos" para más opciones',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
bool _mesaTieneProductosEnProceso(List pedidos) {
  for (var pedido in pedidos) {
    final detalles = pedido['detalles'] as List;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'proceso') {
        return true; // Si encuentra UN producto en proceso, retorna true
      }
    }
  }
  return false; // Si no encuentra ningún producto en proceso
}

  // Función auxiliar para obtener colores únicos por pedido
  Color _getOrderColor(int index) {
    List<Color> colors = [
      Color(0xFF8B4513), // Marrón
      Color(0xFF2196F3), // Azul
      Color(0xFF4CAF50), // Verde
      Color(0xFFFF9800), // Naranja
      Color(0xFF9C27B0), // Púrpura
      Color(0xFFE91E63), // Rosa
    ];
    return colors[index % colors.length];
  }
}
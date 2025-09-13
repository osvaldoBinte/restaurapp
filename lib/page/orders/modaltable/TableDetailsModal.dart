import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

import 'table_details_controller.dart';

class TableDetailsModal extends StatelessWidget {
  final Map<String, dynamic> mesa;

  const TableDetailsModal({Key? key, required this.mesa}) : super(key: key);

  @override
Widget build(BuildContext context) {
  return GetBuilder<OrdersController>(
    builder: (ordersController) {
      return GetBuilder<TableDetailsController>(
        init: TableDetailsController()..inicializarConMesa(mesa),
        builder: (tableController) {
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
              
              // Header - ahora con acceso a ambos controladores
              _buildHeader(tableController, ordersController),

              // Selector de pedidos (solo si hay más de uno)
              if (tableController.pedidos.length > 1)
                _buildOrderSelector(tableController),

              // Lista de productos
              Expanded(
                child: Obx(() => tableController.selectedOrderIndex.value == -1
                    ? _buildAllProductsView(tableController)
                    : _buildSingleOrderProducts(tableController)),
              ),
              
              // Footer con total y acciones
              _buildFooter(tableController),
            ],
          );
        },
      );
    },
  );
}



Widget _buildHeader(TableDetailsController controller, OrdersController ordersController) {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mesa ${controller.numeroMesa}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            Text(
              '${controller.pedidos.length} pedido${controller.pedidos.length != 1 ? 's' : ''} activo${controller.pedidos.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        Row(
          children: [
            // Botón Atender Mesa (solo si hay productos en proceso)
            Obx(() {
              final tieneProductosEnProceso = controller.mesaTieneProductosEnProceso();
              
              if (tieneProductosEnProceso) {
                return IconButton(
                  onPressed: () => ordersController.atenderTodosLosPedidosMesa(controller.numeroMesa),
                  icon: Icon(Icons.cleaning_services),
                  tooltip: 'Atender mesa',
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xFFE74C3C).withOpacity(0.1),
                    foregroundColor: Color(0xFFE74C3C),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
            
            SizedBox(width: 8),
            
            // ✅ NUEVO: Botón Liberar Mesa (solo si NO hay productos en proceso)
            Obx(() {
              final tieneProductosEnProceso = controller.mesaTieneProductosEnProceso();
              
              // Solo mostrar si NO hay productos en proceso
              if (!tieneProductosEnProceso) {
                return IconButton(
                  onPressed: () => controller.confirmarLiberarMesa(),
                  icon: Icon(Icons.restore),
                  tooltip: 'Liberar Mesa ${controller.numeroMesa}',
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xFF27AE60).withOpacity(0.1),
                    foregroundColor: Color(0xFF27AE60),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
            
            SizedBox(width: 8),
            
            // Botón para agregar productos
            Obx(() => IconButton(
              onPressed: controller.manejarBotonAgregarProductos,
              icon: Icon(Icons.add_shopping_cart),
              tooltip: controller.selectedOrderIndex.value == -1 
                  ? (controller.pedidos.length == 1 ? 'Agregar Productos' : 'Nuevo Pedido')
                  : 'Agregar Productos',
              style: IconButton.styleFrom(
                backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                foregroundColor: Color(0xFF2196F3),
              ),
            )),
            
            // Botón actualizar
            Obx(() => IconButton(
              onPressed: controller.isUpdating.value 
                  ? null 
                  : controller.actualizarDatosManualmente,
              icon: controller.isUpdating.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh),
              tooltip: 'Actualizar',
            )),
            
            // Botón cerrar
            IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget _buildOrderSelector(TableDetailsController controller) {
  return Container(
    height: 60,
    margin: EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        // Ya no mostrar "Todos" - ir directo a tabs individuales
        // Tabs individuales
        ...controller.pedidos.asMap().entries.map((entry) {
          final index = entry.key;
          final pedido = entry.value;
          
         return Expanded(
              child: Obx(() {
                final isSelected = controller.selectedOrderIndex.value == index;
                return GestureDetector(
                  onTap: () => controller.seleccionarPedido(index),
                  child: Container(
                    height: 40,
                    margin: EdgeInsets.only(right: index < controller.pedidos.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF2196F3) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        ' #${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
        }).toList(),
      ],
    ),
  );
}
  Widget _buildAllProductsView(TableDetailsController controller) {
    final productos = controller.todosLosProductos;

    return productos.isEmpty
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
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductCard(controller, producto, true);
            },
          );
  }

  Widget _buildSingleOrderProducts(TableDetailsController controller) {
    final productos = controller.getProductosDePedido(controller.selectedOrderIndex.value);
    
    return productos.isEmpty
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
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductCard(controller, producto, false);
            },
          );
  }

Widget _buildProductCard(TableDetailsController controller, Map<String, dynamic> producto, bool mostrarInfoPedido) {
  final statusDetalle = producto['statusDetalle'] as String? ?? 'proceso';
  final isCancelado = statusDetalle.trim().toLowerCase() == 'cancelado';
  final isPagado = statusDetalle.trim().toLowerCase() == 'pagado';
  final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
  final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
  final subtotal = precioUnitario * cantidad;
  final categoria = producto['categoria'] as String? ?? '';
  final detalleId = producto['detalleId'] as int?;
  
  // Determinar si el producto está inactivo (cancelado o pagado)
  final isInactive = isCancelado || isPagado;

  // Debug simple del producto
  print('PRODUCTO $detalleId: "${producto['nombreProducto']}" status="${statusDetalle.trim().toLowerCase()}" inactive=$isInactive');

  // Si detalleId es null, no mostramos el producto
  if (detalleId == null) {
    print('❌ detalleId es null, no mostrando producto');
    return SizedBox.shrink();
  }

  return Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isInactive ? Colors.grey[200] : Color(0xFFF5F2F0),
      borderRadius: BorderRadius.circular(8),
      // Agregar un borde especial para productos pagados
      border: isPagado ? Border.all(color: Colors.green.withOpacity(0.3), width: 1) : null,
    ),
    child: Column(
      children: [
        Row(
          children: [
            // Emoji del producto
            Text(
              controller.getProductEmoji(categoria),
              style: TextStyle(
                fontSize: 24,
                color: isInactive ? Colors.grey : null,
              ),
            ),
            SizedBox(width: 12),
                         
            // Info del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombreProducto'] as String? ?? 'Producto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInactive ? Colors.grey : Color(0xFF3E1F08),
                      decoration: isCancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    '\$${precioUnitario.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      color: isInactive ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                      decoration: isCancelado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                                       
                  // Observaciones
                  if ((producto['observaciones'] as String?)?.isNotEmpty == true)
                    Text(
                      producto['observaciones'] as String,
                      style: TextStyle(
                        color: isInactive ? Colors.grey : Colors.grey[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        decoration: isCancelado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                                       
                  // Info del pedido (solo en vista "Todos")
                  if (mostrarInfoPedido)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: producto['colorPedido'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pedido #${producto['pedidoId']} • ${producto['nombreOrden'] as String? ?? 'Sin nombre'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: producto['colorPedido'] as Color,
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
                _buildStatusChip(controller, statusDetalle),
                                   
                SizedBox(height: 8),
                                   
                // Botones de estado (SOLO cuando está en proceso)
                if (['proceso', 'completado'].contains(statusDetalle)) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: statusDetalle == 'proceso' 
                          ? [
                              // Botón cancelar
                              IconButton(
                                onPressed: () => controller.cambiarEstadoProducto(producto, 'cancelado'),
                                icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                                constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                tooltip: 'Cancelar',
                              ),
                              
                              // Botón completar
                              IconButton(
                                onPressed: () => controller.cambiarEstadoProducto(producto, 'completado'),
                                icon: Icon(Icons.check_circle, color: Colors.green, size: 18),
                                constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                tooltip: 'Completar',
                              ),
                            ]
                          : [
                              // Solo botón cancelar
                              IconButton(
                                onPressed: () => controller.cambiarEstadoProducto(producto, 'cancelado'),
                                icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                                constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                                tooltip: 'Cancelar',
                              ),
                            ],
                      ),
                      
                      SizedBox(height: 4),
                    ],
                                   
                // Controles de cantidad (solo si NO está cancelado NI pagado)
                 if (statusDetalle.trim().toLowerCase() == 'proceso' ) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón disminuir
                      IconButton(
                        onPressed: () => controller.disminuirCantidad(producto),
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
                        onPressed: () => controller.aumentarCantidad(producto),
                        icon: Icon(Icons.add_circle, color: Color(0xFF8B4513), size: 20),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ] else ...[
                  // Solo mostrar cantidad para productos completados, cancelados o pagados
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusDetalle.trim().toLowerCase() == 'completado' 
                          ? Colors.green[100] 
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$cantidad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: statusDetalle.trim().toLowerCase() == 'completado' 
                            ? Colors.green[700] 
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Checkbox funcional (izquierda) - Solo para productos completados en vista de pedido específico
            Obx(() {
              // Verificar que detalleId no sea null antes de continuar
              if (detalleId == null) {
                return SizedBox(
                  width: 18,
                  height: 18,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }
              
              final isSelected = controller.productosSeleccionados.contains(detalleId);
              
              // Limpiar el statusDetalle de posibles espacios o caracteres extra
              final statusLimpio = statusDetalle.trim().toLowerCase();
              
              // Condiciones para poder seleccionar:
              final enVistaPedidoEspecifico = controller.selectedOrderIndex.value != -1;
              final estaCompletado = statusLimpio == 'completado';
              final noEstaInactivo = !isInactive;
              
              final puedeSeleccionar = noEstaInactivo && enVistaPedidoEspecifico && estaCompletado;
              
              // Debug simple y claro
              print('CHECKBOX $detalleId: orden=${controller.selectedOrderIndex.value}, status="$statusLimpio", activo=$noEstaInactivo, puede=$puedeSeleccionar');
              
              return GestureDetector(
                onTap: puedeSeleccionar ? () {
                  print('✅ SELECCIONANDO producto $detalleId');
                  controller.toggleProductoSeleccionado(detalleId!);
                } : () {
                  
                  print('❌ NO PUEDE seleccionar $detalleId - orden:${controller.selectedOrderIndex.value}, status:"$statusLimpio", activo:$noEstaInactivo');
                },
                child: Transform.scale(
                  scale: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF8B4513) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: puedeSeleccionar ? Color(0xFF8B4513) : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected 
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : SizedBox(
                          width: 18,
                          height: 18,
                        ),
                  ),
                ),
              );
            }),
            
            // Subtotal (derecha)
            Flexible(
              child: Text(
                'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isInactive ? Colors.grey : Color(0xFF8B4513),
                  decoration: isCancelado ? TextDecoration.lineThrough : null,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  Widget _buildStatusChip(TableDetailsController controller, String status) {
  Color statusColor = controller.getStatusColor(status);
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
    case 'pagado':
      statusIcon = Icons.payment;
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
}

Widget _buildFooter(TableDetailsController controller) {
  final tieneProductosEnProceso = controller.mesaTieneProductosEnProceso();
  
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
        // Total con indicador visual si hay productos seleccionados
        Obx(() {
          final totalParaFooter = controller.totalParaFooter;
          final labelTotal = controller.labelTotalFooter;
          final haySeleccionados = controller.productosSeleccionados.isNotEmpty;
          
          return Container(
            padding: haySeleccionados ? EdgeInsets.all(12) : EdgeInsets.zero,
            
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    labelTotal,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                ),
                Flexible(child: Text(
                  '\$${totalParaFooter.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),)
                
              ],
            ),
          );
        }),
        
        SizedBox(height: 16),
        
        // Botones de acción
        Obx(() {
          if (controller.selectedOrderIndex.value == -1) {
            // Vista "Todos"
            if (controller.pedidos.length == 1) {
              // Caso especial: Un solo pedido
              final pedido = controller.pedidos[0];
              
              if (controller.puedeSerPagado(pedido)) {
                // Si puede ser pagado, mostrar botón "PAGAR Y LIBERAR"
               return Obx(() => SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    // Deshabilitar botón cuando está cargando
    onPressed: controller.isUpdating.value 
        ? null 
        : () => controller.confirmarPagoYLiberacion(pedido),
    
    // Cambiar icono según el estado
    icon: controller.isUpdating.value
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Icon(Icons.payment, color: Colors.white),
    
    // Cambiar texto según el estado
    label: Text(
      controller.isUpdating.value 
          ? 'PROCESANDO...'
          : 'PAGAR Y LIBERAR MESA',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    
    style: ElevatedButton.styleFrom(
      // Cambiar color cuando está deshabilitado
      backgroundColor: controller.isUpdating.value 
          ? Colors.grey[400] 
          : Color(0xFF27AE60),
      padding: EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Quitar elevación cuando está cargando
      elevation: controller.isUpdating.value ? 0 : null,
    ),
  ),
));
              } else if (!tieneProductosEnProceso) {
                // Si no puede ser pagado pero no hay productos en proceso, solo liberar
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.confirmarLiberarMesa,
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
                );
              } else {
                // Hay productos en proceso, no mostrar botón
                return SizedBox.shrink();
              }
            } else {
              // Múltiples pedidos - Solo mostrar botón liberar si no hay productos en proceso
              if (!tieneProductosEnProceso) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.confirmarLiberarMesa,
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
                );
              } else {
                return SizedBox.shrink();
              }
            }
          } else {
           // Vista de pedido específico
final pedido = controller.pedidos[controller.selectedOrderIndex.value];

return Obx(() {
  final tipoBoton = controller.getTipoBotonPago();
  final productosSeleccionados = controller.getProductosSeleccionadosDelPedidoActual();
  final totalSeleccionados = controller.calcularTotalProductosSeleccionadosDelPedido();
  
  // ✅ AGREGAR: Variable para controlar el estado de carga
  final isProcessingPayment = controller.isUpdating.value; // O crear una nueva variable específica
  
  if (tipoBoton == 'ninguno') {
    // Si no hay productos seleccionados, mostrar botón tradicional
    if (controller.puedeSerPagado(pedido)) {
      final esUltimoPendiente = controller.esUltimoPedidoPendiente(pedido);
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          // ✅ MODIFICAR: Deshabilitar botón mientras carga
          onPressed: isProcessingPayment ? null : (esUltimoPendiente 
              ? () => controller.confirmarPagoYLiberacion(pedido)
              : () => controller.confirmarPagoPedido(pedido)),
          
          // ✅ MODIFICAR: Mostrar spinner o icono según el estado
          icon: isProcessingPayment 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.payment, color: Colors.white),
          
          // ✅ MODIFICAR: Cambiar texto mientras carga
          label: Text(
            isProcessingPayment 
                ? 'PROCESANDO...'
                : (esUltimoPendiente ? 'PAGAR Y LIBERAR MESA' : 'PAGAR PEDIDO'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            // ✅ MODIFICAR: Cambiar color mientras carga
            backgroundColor: isProcessingPayment 
                ? Colors.grey[400] 
                : Color(0xFF27AE60),
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            // ✅ AGREGAR: Desactivar elevation mientras carga
            elevation: isProcessingPayment ? 0 : null,
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  } else {
    // Hay productos seleccionados
    String textoBoton = tipoBoton == 'pagar_y_liberar' 
        ? 'PAGAR Y LIBERAR MESA'
        : 'PAGAR SELECCIONADOS';
    
    IconData iconoBoton = tipoBoton == 'pagar_y_liberar' 
        ? Icons.home 
        : Icons.payment;
    
    Color colorBoton = tipoBoton == 'pagar_y_liberar' 
        ? Color(0xFF27AE60) 
        : Color(0xFF2196F3);
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            // ✅ MODIFICAR: Deshabilitar botón mientras carga
            onPressed: isProcessingPayment 
                ? null 
                : () => controller.confirmarPagoProductosSeleccionados(),
            
            // ✅ MODIFICAR: Mostrar spinner o icono según el estado
            icon: isProcessingPayment 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(iconoBoton, color: Colors.white),
            
            // ✅ MODIFICAR: Cambiar texto mientras carga
            label: Text(
              isProcessingPayment 
                  ? 'PROCESANDO...'
                  : textoBoton,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              // ✅ MODIFICAR: Cambiar color mientras carga
              backgroundColor: isProcessingPayment 
                  ? Colors.grey[400] 
                  : colorBoton,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // ✅ AGREGAR: Desactivar elevation mientras carga
              elevation: isProcessingPayment ? 0 : null,
            ),
          ),
        ),
      ],
    );
  }
});
          }
        }),
        
        // Padding para navegación del sistema
        SizedBox(height: MediaQuery.of(Get.context!).viewPadding.bottom),
      ],
    ),
  );
}
}
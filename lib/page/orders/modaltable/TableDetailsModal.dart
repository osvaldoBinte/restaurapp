import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
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
                // Selector de pedidos (solo si hay más de uno y NO es grupo)
                if (tableController.pedidos.length > 1 &&
                    !tableController.esGrupo)
                  _buildOrderSelector(tableController),

                // Lista de productos
                Expanded(
                  child: Obx(() {
                    // ✅ Si es grupo siempre vista "Todos"
                    if (tableController.esGrupo) {
                      return _buildAllProductsView(tableController);
                    }

                    // ✅ Vista agrupada (sin tabs)
                    if (!tableController.mostrarVistaPedidos.value) {
                      return _buildAllProductsView(tableController);
                    }

                    // ✅ Vista por pedido específico o todos
                    return tableController.selectedOrderIndex.value == -1
                        ? _buildAllProductsView(tableController)
                        : _buildSingleOrderProducts(tableController);
                  }),
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

  Widget _buildHeader(
    TableDetailsController controller,
    OrdersController ordersController,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Nombre + Cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nombre del pedido con lápiz
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final pedidoActual =
                        controller.selectedOrderIndex.value >= 0
                        ? controller.pedidos[controller
                              .selectedOrderIndex
                              .value]
                        : controller.pedidos.isNotEmpty
                        ? controller.pedidos[0]
                        : null;
                    if (pedidoActual != null) {
                      controller.mostrarDialogoRenombrar(pedidoActual);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          controller.selectedOrderIndex.value >= 0
                              ? (controller.pedidos[controller
                                        .selectedOrderIndex
                                        .value]['nombreOrden'] ??
                                    'Sin nombre')
                              : controller.pedidos.isNotEmpty
                              ? (controller.pedidos[0]['nombreOrden'] ??
                                    'Sin nombre')
                              : 'Sin nombre',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF8B4513).withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón cerrar (siempre arriba a la derecha)
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),

          // Subtítulo mesa
          Text(
            'Mesa ${controller.numeroMesa} • ${controller.pedidos.length} pedido${controller.pedidos.length != 1 ? 's' : ''}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),

          SizedBox(height: 8),

          // Fila inferior: todos los botones de acción
          Row(
            children: [
              // Botón Atender Mesa
              Obx(() {
                if (controller.mesaTieneProductosEnProceso()) {
                  return IconButton(
                    onPressed: () => ordersController
                        .atenderTodosLosPedidosMesa(controller.numeroMesa),
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

              // Botón Liberar Mesa
              Obx(() {
                if (!controller.mesaTieneProductosEnProceso()) {
                  return IconButton(
                    onPressed: () => controller.confirmarLiberarMesa(),
                    icon: Icon(Icons.table_restaurant),
                    tooltip: 'Liberar Mesa ${controller.numeroMesa}',
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFE74C3C).withOpacity(0.1),
                      foregroundColor: Color(0xFFE74C3C),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
              // Botón Agrupar Mesa (solo si NO es grupo)
              Obx(() {
                final updating =
                    controller.isUpdating.value; // ✅ observable dentro del Obx
                if (!controller.esGrupo) {
                  return IconButton(
                    onPressed: updating
                        ? null
                        : () => controller.confirmarAgruparMesa(),
                    icon: Icon(Icons.table_chart),
                    tooltip: 'Agrupar Mesa',
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                      foregroundColor: Color(0xFF2196F3),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),

              // Botón Desagrupar (solo si ES grupo)
              Obx(() {
                final updating =
                    controller.isUpdating.value; // ✅ observable dentro del Obx
                final gId = controller.grupoId;
                if (controller.esGrupo && gId != null) {
                  return IconButton(
                    onPressed: updating
                        ? null
                        : () async {
                            Get.back();
                            await controller.desagruparMesa(gId);
                            final ordersController =
                                Get.find<OrdersController>();
                            await ordersController.refrescarDatos();
                          },
                    icon: Icon(Icons.table_rows),
                    tooltip: 'Desagrupar',
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800).withOpacity(0.1),
                      foregroundColor: Color(0xFFFF9800),
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
              // Botón Imprimir Ticket
              /* Obx(() => IconButton(
              onPressed: controller.isUpdating.value
                  ? null
                  : () {
                      final pedido = controller.selectedOrderIndex.value >= 0
                          ? controller.pedidos[controller.selectedOrderIndex.value]
                          : controller.pedidos[0];
                      controller.imprimirTicketManual(pedido);
                    },
              icon: controller.isUpdating.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF2196F3)),
                    )
                  : Icon(Icons.print),
              tooltip: 'Imprimir Ticket',
              style: IconButton.styleFrom(
                backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                foregroundColor: Color(0xFF2196F3),
              ),
            )),*/

              // Botón Agregar Productos
              Obx(
                () => IconButton(
                  onPressed: controller.manejarBotonAgregarProductos,
                  icon: Icon(Icons.add_shopping_cart),
                  tooltip: controller.selectedOrderIndex.value == -1
                      ? (controller.pedidos.length == 1
                            ? 'Agregar Productos'
                            : 'Nuevo Pedido')
                      : 'Agregar Productos',
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                    foregroundColor: Color(0xFF2196F3),
                  ),
                ),
              ),

              // Botón Actualizar
              Obx(
                () => IconButton(
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSelector(TableDetailsController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // ✅ Botón para alternar vista
          Obx(
            () => GestureDetector(
              onTap: () {
                controller.toggleVistaPedidos();
                // Al cambiar a vista agrupada, deseleccionar pedido específico
                if (!controller.mostrarVistaPedidos.value) {
                  controller.selectedOrderIndex.value = -1;
                } else {
                  controller.selectedOrderIndex.value = 0;
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: controller.mostrarVistaPedidos.value
                      ? Colors.grey[100]
                      : Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.mostrarVistaPedidos.value
                        ? Colors.grey[300]!
                        : Color(0xFF8B4513).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.mostrarVistaPedidos.value
                          ? Icons.list_alt
                          : Icons.receipt_long,
                      size: 16,
                      color: controller.mostrarVistaPedidos.value
                          ? Colors.grey[600]
                          : Color(0xFF8B4513),
                    ),
                    SizedBox(width: 6),
                    Text(
                      controller.mostrarVistaPedidos.value
                          ? 'Ver todos los productos'
                          : 'Ver por pedido',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: controller.mostrarVistaPedidos.value
                            ? Colors.grey[600]
                            : Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ Tabs de pedidos (solo si está en modo pedidos)
          Obx(
            () => controller.mostrarVistaPedidos.value
                ? SizedBox(
                    height: 40,
                    child: Row(
                      children: controller.pedidos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final pedido = entry.value;

                        return Expanded(
                          child: Obx(() {
                            final isSelected =
                                controller.selectedOrderIndex.value == index;
                            return GestureDetector(
                              onTap: () => controller.seleccionarPedido(index),
                              child: Container(
                                height: 40,
                                margin: EdgeInsets.only(
                                  right: index < controller.pedidos.length - 1
                                      ? 8
                                      : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(0xFF2196F3)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
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
                    ),
                  )
                : SizedBox.shrink(),
          ),
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
                Icon(
                  Icons.restaurant_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No hay productos en esta mesa',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
    final productos = controller.getProductosDePedido(
      controller.selectedOrderIndex.value,
    );

    return productos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Sin productos en este pedido',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  Widget _buildProductCard(
    TableDetailsController controller,
    Map<String, dynamic> producto,
    bool mostrarInfoPedido,
  ) {
    final statusDetalle = producto['statusDetalle'] as String? ?? 'proceso';
    final isCancelado = statusDetalle.trim().toLowerCase() == 'cancelado';
    final isPagado = statusDetalle.trim().toLowerCase() == 'pagado';
    final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
    final precioUnitario =
        (producto['precioUnitario'] as num?)?.toDouble() ?? 0.0;
    final subtotal = precioUnitario * cantidad;
    final categoria = producto['categoria'] as String? ?? '';
    final detalleId = producto['detalleId'] as int?;
    final isInactive = isCancelado || isPagado;

    // ✅ Card simplificado para grupos (sin detalleId)
    if (detalleId == null) {
      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isInactive ? Colors.grey[200] : Color(0xFFF5F2F0),
          borderRadius: BorderRadius.circular(8),
          border: isPagado
              ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Text(
              controller.getProductEmoji(categoria),
              style: TextStyle(
                fontSize: 24,
                color: isInactive ? Colors.grey : null,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombreProducto'] as String? ?? 'Producto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInactive ? Colors.grey : Color(0xFF3E1F08),
                      decoration: isCancelado
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    '\$${precioUnitario.toStringAsFixed(2)} c/u',
                    style: TextStyle(
                      color: isInactive ? Colors.grey : Colors.grey[600],
                      fontSize: 12,
                      decoration: isCancelado
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            _buildStatusChip(controller, statusDetalle),
            SizedBox(width: 8),
            Text(
              'x$cantidad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isInactive ? Colors.grey : Color(0xFF3E1F08),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '\$${subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isInactive ? Colors.grey : Color(0xFF8B4513),
                decoration: isCancelado ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Card completo para mesas simples (con detalleId)
    return Obx(() {
      final enEdicion = controller.productoEnEdicion.value == detalleId;

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isInactive ? Colors.grey[200] : Color(0xFFF5F2F0),
          borderRadius: BorderRadius.circular(8),
          border: isPagado
              ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
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
                          decoration: isCancelado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '\$${precioUnitario.toStringAsFixed(2)} c/u',
                        style: TextStyle(
                          color: isInactive ? Colors.grey : Colors.grey[600],
                          fontSize: 12,
                          decoration: isCancelado
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),

                      if ((producto['observaciones'] as String?)?.isNotEmpty ==
                          true)
                        Text(
                          producto['observaciones'] as String,
                          style: TextStyle(
                            color: isInactive ? Colors.grey : Colors.grey[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            decoration: isCancelado
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status y controles
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusChip(controller, statusDetalle),

                    SizedBox(height: 8),

                    if (['proceso', 'completado'].contains(statusDetalle)) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: statusDetalle == 'proceso'
                            ? [
                                IconButton(
                                  onPressed: () =>
                                      controller.cambiarEstadoProducto(
                                        producto,
                                        'cancelado',
                                      ),
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Cancelar',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      controller.cambiarEstadoProducto(
                                        producto,
                                        'completado',
                                      ),
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Completar',
                                ),
                              ]
                            : [
                                IconButton(
                                  onPressed: () =>
                                      controller.cambiarEstadoProducto(
                                        producto,
                                        'cancelado',
                                      ),
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Cancelar',
                                ),
                              ],
                      ),
                      SizedBox(height: 4),
                    ],

                    if (statusDetalle.trim().toLowerCase() == 'proceso' ||
                        statusDetalle.trim().toLowerCase() == 'completado') ...[
                      if (!enEdicion) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  controller.disminuirCantidad(producto),
                              icon: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 20,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  controller.activarEdicionCantidad(detalleId),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Color(0xFF8B4513).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$cantidad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF3E1F08),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Color(0xFF8B4513),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  controller.aumentarCantidad(producto),
                              icon: Icon(
                                Icons.add_circle,
                                color: Color(0xFF8B4513),
                                size: 20,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(height: 8),
                      ],
                    ] else ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              statusDetalle.trim().toLowerCase() == 'completado'
                              ? Colors.green[100]
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color:
                                statusDetalle.trim().toLowerCase() ==
                                    'completado'
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

            // Panel de edición inline
            if (enEdicion &&
                (statusDetalle.trim().toLowerCase() == 'proceso' ||
                    statusDetalle.trim().toLowerCase() == 'completado')) ...[
              Text(
                'cant $cantidad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF3E1F08),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF8B4513).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: controller.toggleModoEdicion,
                      child: Obx(
                        () => Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: controller.modoEdicion.value == 'aumentar'
                                ? Color(0xFF27AE60).withOpacity(0.1)
                                : Color(0xFFE74C3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            controller.modoEdicion.value == 'aumentar'
                                ? Icons.add
                                : Icons.remove,
                            color: controller.modoEdicion.value == 'aumentar'
                                ? Color(0xFF27AE60)
                                : Color(0xFFE74C3C),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: controller.cantidadEdicion.value,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cantidad',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Color(0xFF8B4513)),
                          ),
                          isDense: true,
                        ),
                        onChanged: (value) =>
                            controller.cantidadEdicion.value = value,
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: controller.cancelarEdicionCantidad,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey[700],
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              controller.confirmarCambioManual(producto),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  final isSelected = controller.productosSeleccionados.contains(
                    detalleId,
                  );
                  final statusLimpio = statusDetalle.trim().toLowerCase();
                  final enVistaPedidoEspecifico =
                      controller.selectedOrderIndex.value != -1;
                  final estaCompletado = statusLimpio == 'completado';
                  final noEstaInactivo = !isInactive;
                  final puedeSeleccionar =
                      noEstaInactivo &&
                      enVistaPedidoEspecifico &&
                      estaCompletado;

                  return GestureDetector(
                    onTap: puedeSeleccionar
                        ? () => controller.toggleProductoSeleccionado(detalleId)
                        : null,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFF8B4513) : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: puedeSeleccionar
                                ? Color(0xFF8B4513)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : SizedBox(width: 18, height: 18),
                      ),
                    ),
                  );
                }),

                Flexible(
                  child: Text(
                    'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isInactive ? Colors.grey : Color(0xFF8B4513),
                      decoration: isCancelado
                          ? TextDecoration.lineThrough
                          : null,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
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

  void _pagarSeleccionadosAgrupado(
    TableDetailsController controller,
    String tipoBoton,
  ) {
    final productos = controller.getProductosSeleccionadosDeTodos();
    final total = controller.calcularTotalSeleccionadosDeTodos();

    // Agrupar por pedidoId para el diálogo
    final pedidosAfectados = productos.map((p) => p['pedidoId']).toSet().length;

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: tipoBoton == 'pagar_y_liberar'
          ? 'Pagar y Liberar Mesa'
          : 'Pagar Seleccionados',
      text:
          '¿Confirmar el pago de los productos seleccionados?\n\n'
          'Productos: ${productos.length}\n'
          'Pedidos afectados: $pedidosAfectados\n'
          'Total: \$${total.toStringAsFixed(2)}'
          '${tipoBoton == 'pagar_y_liberar' ? '\n\n🏠 La mesa será liberada.' : ''}',
      confirmBtnText: tipoBoton == 'pagar_y_liberar'
          ? 'Pagar y Liberar'
          : 'Pagar Seleccionados',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: tipoBoton == 'pagar_y_liberar'
          ? Color(0xFF27AE60)
          : Color(0xFF2196F3),
      onConfirmBtnTap: () async {
        Navigator.of(Get.context!).pop();
        await Future.delayed(Duration(milliseconds: 100));

        if (controller.isUpdating.value) return;
        controller.isUpdating.value = true;

        try {
          // Extraer detalleIds
          final detalleIds = productos
              .map((p) => p['detalleId'] as int)
              .toList();

          final ordersController = Get.find<OrdersController>();

          // Pagar
          await ordersController.actualizarEstadoOrden(
            detalleIds,
            'pagado',
            completarTodos: true,
          );

          controller.productosSeleccionados.clear();

          // Si es pagar y liberar, liberar la mesa también
          if (tipoBoton == 'pagar_y_liberar') {
            await controller.liberarMesa();
          } else {
            Get.snackbar(
              'Pago Exitoso',
              '${detalleIds.length} productos pagados correctamente',
              backgroundColor: Colors.green.withOpacity(0.8),
              colorText: Colors.white,
              duration: Duration(seconds: 3),
            );
            await ordersController.refrescarDatos();
          }
        } catch (e) {
          Get.snackbar(
            'Error',
            'Error al procesar pago: $e',
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
        } finally {
          controller.isUpdating.value = false;
        }
      },
      onCancelBtnTap: () => Navigator.of(Get.context!).pop(),
    );
  }

  void _pagarTodosYLiberar(TableDetailsController controller) {
    final primerPedidoPagable = controller.pedidos.firstWhere(
      (p) => controller.puedeSerPagado(Map<String, dynamic>.from(p)),
      orElse: () => controller.pedidos[0],
    );
    controller.confirmarPagoYLiberacion(primerPedidoPagable);
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
        // Total
        Obx(() {
          final esVistaAgrupada = !controller.esGrupo &&
              controller.pedidos.length > 1 &&
              !controller.mostrarVistaPedidos.value;

          double totalMostrar;
          String labelMostrar;

          if (esVistaAgrupada) {
            final seleccionados = controller.getProductosSeleccionadosDeTodos();
            if (seleccionados.isNotEmpty) {
              totalMostrar = controller.calcularTotalSeleccionadosDeTodos();
              labelMostrar = 'Seleccionados (${seleccionados.length}):';
            } else {
              totalMostrar = controller.totalMesa;
              labelMostrar = 'Total Mesa:';
            }
          } else {
            totalMostrar = controller.totalParaFooter;
            labelMostrar = controller.labelTotalFooter;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  labelMostrar,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  '\$${totalMostrar.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
            ],
          );
        }),

        SizedBox(height: 16),

        // Botones de acción
        Obx(() {
          final esVistaAgrupada = !controller.esGrupo &&
              controller.pedidos.length > 1 &&
              !controller.mostrarVistaPedidos.value;

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // CASO 1: Vista agrupada (múltiples pedidos, toggle activado)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (esVistaAgrupada) {
            final seleccionados = controller.getProductosSeleccionadosDeTodos();
            final tieneSeleccionados = seleccionados.isNotEmpty;
            final tipoBoton = controller.getTipoBotonPagoAgrupado();
            final isProcessing = controller.isUpdating.value;
            final sinProceso = !tieneProductosEnProceso;

            // ✅ HAY seleccionados → botón de pago
            if (tieneSeleccionados) {
              final textoBoton = tipoBoton == 'pagar_y_liberar'
                  ? 'PAGAR Y LIBERAR MESA'
                  : 'PAGAR SELECCIONADOS';
              final iconoBoton = tipoBoton == 'pagar_y_liberar'
                  ? Icons.home
                  : Icons.payment;
              final colorBoton = tipoBoton == 'pagar_y_liberar'
                  ? Color(0xFF27AE60)
                  : Color(0xFF2196F3);

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _pagarSeleccionadosAgrupado(controller, tipoBoton),
                  icon: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(iconoBoton, color: Colors.white),
                  label: Text(
                    isProcessing ? 'PROCESANDO...' : textoBoton,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isProcessing ? Colors.grey[400] : colorBoton,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isProcessing ? 0 : null,
                  ),
                ),
              );
            }

            // ✅ SIN seleccionados: todos listos para pagar
            final todosListos = controller.pedidos.every(
              (p) => controller.puedeSerPagado(Map<String, dynamic>.from(p)),
            );

            if (todosListos) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () => _pagarTodosYLiberar(controller),
                  icon: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    isProcessing ? 'PROCESANDO...' : 'PAGAR TODO Y LIBERAR MESA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProcessing
                        ? Colors.grey[400]
                        : Color(0xFF27AE60),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isProcessing ? 0 : null,
                  ),
                ),
              );
            }

            // ✅ Sin proceso, nada que pagar → solo liberar
            if (sinProceso) {
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
            }

            return SizedBox.shrink();
          }

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // CASO 2: Vista "Todos" (selectedOrderIndex == -1)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          if (controller.selectedOrderIndex.value == -1) {
            if (controller.pedidos.length == 1) {
              final pedido = controller.pedidos[0];

              if (controller.puedeSerPagado(pedido)) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isUpdating.value
                        ? null
                        : () => controller.confirmarPagoYLiberacion(pedido),
                    icon: controller.isUpdating.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.payment, color: Colors.white),
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
                      backgroundColor: controller.isUpdating.value
                          ? Colors.grey[400]
                          : Color(0xFF27AE60),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: controller.isUpdating.value ? 0 : null,
                    ),
                  ),
                );
              } else if (!tieneProductosEnProceso) {
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
            } else {
              // Múltiples pedidos en vista "Todos" (grupo o sin toggle)
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
          }

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // CASO 3: Vista pedido específico (selectedOrderIndex >= 0)
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          final pedido =
              controller.pedidos[controller.selectedOrderIndex.value];
          final tipoBoton = controller.getTipoBotonPago();
          final isProcessing = controller.isUpdating.value;

          if (tipoBoton == 'ninguno') {
            if (controller.puedeSerPagado(pedido)) {
              final esUltimoPendiente =
                  controller.esUltimoPedidoPendiente(pedido);

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : (esUltimoPendiente
                          ? () =>
                              controller.confirmarPagoYLiberacion(pedido)
                          : () => controller.confirmarPagoPedido(pedido)),
                  icon: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    isProcessing
                        ? 'PROCESANDO...'
                        : (esUltimoPendiente
                            ? 'PAGAR Y LIBERAR MESA'
                            : 'PAGAR PEDIDO'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isProcessing ? Colors.grey[400] : Color(0xFF27AE60),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isProcessing ? 0 : null,
                  ),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          } else {
            final textoBoton = tipoBoton == 'pagar_y_liberar'
                ? 'PAGAR Y LIBERAR MESA'
                : 'PAGAR SELECCIONADOS';
            final iconoBoton =
                tipoBoton == 'pagar_y_liberar' ? Icons.home : Icons.payment;
            final colorBoton = tipoBoton == 'pagar_y_liberar'
                ? Color(0xFF27AE60)
                : Color(0xFF2196F3);

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () =>
                        controller.confirmarPagoProductosSeleccionados(),
                icon: isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(iconoBoton, color: Colors.white),
                label: Text(
                  isProcessing ? 'PROCESANDO...' : textoBoton,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isProcessing ? Colors.grey[400] : colorBoton,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isProcessing ? 0 : null,
                ),
              ),
            );
          }
        }),

        SizedBox(height: MediaQuery.of(Get.context!).viewPadding.bottom),
      ],
    ),
  );
}
}

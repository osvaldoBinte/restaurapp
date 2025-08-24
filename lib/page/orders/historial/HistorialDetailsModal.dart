import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/historial/historal_controller.dart';
import 'package:restaurapp/page/orders/historial/historial_details_controller.dart';

class HistorialDetailsModal extends StatelessWidget {
  final Map<String, dynamic> venta;
  
  const HistorialDetailsModal({Key? key, required this.venta}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Obtener o crear el controller
    final detailsController = Get.put(HistorialDetailsController());
    detailsController.inicializarConVenta(venta);
    
    return GetBuilder<HistorialController>(
      builder: (historialController) {
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
            
            // Header con botones de impresión
            _buildHeader(historialController, detailsController),
            
            // Información de la venta
            _buildVentaInfo(detailsController),
            
            // Controles de selección
            _buildSelectionControls(detailsController),
            
            // Lista de productos
            Expanded(
              child: _buildProductsList(detailsController),
            ),
            
            // Footer con total y botones de impresión
            _buildFooter(detailsController),
          ],
        );
      },
    );
  }
  
  Widget _buildHeader(HistorialController historialController, HistorialDetailsController detailsController) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venta #${detailsController.pedidoId}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              Text(
                'Mesa ${detailsController.numeroMesa}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              // Botón imprimir ticket completo
              GetBuilder<HistorialDetailsController>(
                builder: (controller) => IconButton(
                  onPressed: controller.puedeImprimir && !controller.isUpdating.value
                      ? controller.confirmarImprimirTicketCompleto
                      : null,
                  icon: Icon(Icons.print, color: Color(0xFF8B4513)),
                  tooltip: 'Imprimir Ticket Completo',
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 8),
              
              // Botón actualizar
              GetBuilder<HistorialDetailsController>(
                builder: (controller) => IconButton(
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
              
              SizedBox(width: 8),
              
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
  
  Widget _buildVentaInfo(HistorialDetailsController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Cliente:', controller.nombreOrden),
          _buildInfoRow('Fecha:', controller.formatearFecha(controller.fechaVenta)),
          _buildInfoRow('Estado:', controller.statusVenta),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSelectionControls(HistorialDetailsController controller) {
    return GetBuilder<HistorialDetailsController>(
      builder: (controller) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF8B4513).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF8B4513).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: Color(0xFF8B4513), size: 20),
            SizedBox(width: 8),
            
         Flexible(
  child: Text(
    'Toca los productos para seleccionarlos',
    style: TextStyle(
      color: Color(0xFF8B4513),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    overflow: TextOverflow.ellipsis, // 🔁 Evita desbordamiento si no cabe
    maxLines: 1, // Opcional: Limita a una línea
    softWrap: false, // Opcional: evita que se divida en varias líneas
  ),
),

            Spacer(),
            
            // Contador de seleccionados
            if (controller.productosSeleccionados.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.productosSeleccionados.length} seleccionados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            SizedBox(width: 8),
            
            // Botón seleccionar/deseleccionar todos
            TextButton(
              onPressed: controller.toggleSeleccionarTodos,
              child: Text(
                controller.productosSeleccionados.length == controller.productos.length
                    ? 'Deseleccionar'
                    : 'Seleccionar Todo',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size(0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductsList(HistorialDetailsController controller) {
    if (controller.productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No hay productos en esta venta',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return GetBuilder<HistorialDetailsController>(
      builder: (controller) => ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.productos.length,
        itemBuilder: (context, index) {
          final producto = controller.productos[index];
          // Generar detalleId si no existe
          final detalleId = (producto['detalleId'] as int?) ?? 
                            (producto['id'] as int?) ?? 
                            (producto['itemId'] as int?) ??
                            (producto['nombreProducto'] ?? producto['producto'] ?? 'Producto$index').hashCode;
          final isSelected = controller.productosSeleccionados.contains(detalleId);
          
          return _buildProductCard(producto, controller, isSelected);
        },
      ),
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> producto, HistorialDetailsController controller, bool isSelected) {
    final nombreProducto = producto['nombreProducto'] ?? producto['producto'] ?? 'Producto';
    final cantidad = (producto['cantidad'] as num?)?.toInt() ?? 1;
    final precioUnitario = (producto['precioUnitario'] as num?)?.toDouble() ??
                           (producto['precio'] as num?)?.toDouble() ?? 0.0;
    final subtotal = precioUnitario * cantidad;
    final observaciones = producto['observaciones'] ?? '';
    final statusDetalle = producto['statusDetalle'] ?? 'completado';
    
    // Generar detalleId si no existe (usar índice como fallback)
    final detalleId = (producto['detalleId'] as int?) ?? 
                      (producto['id'] as int?) ?? 
                      (producto['itemId'] as int?) ??
                      nombreProducto.hashCode; // Usar hashCode como último recurso
    
    print('🎯 ProductCard - detalleId: $detalleId, producto: $nombreProducto');
    
    return GestureDetector(
      onTap: () {
        print('👆 Tap en producto: $nombreProducto (detalleId: $detalleId)');
        controller.toggleProductoSeleccionado(detalleId);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF8B4513).withOpacity(0.1) : Color(0xFFF5F2F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF8B4513) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF8B4513).withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Indicador de selección
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF8B4513) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Color(0xFF8B4513) : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected 
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                
                SizedBox(width: 12),
                
                // Emoji del producto
                Text(
                  controller.getProductEmoji(nombreProducto),
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 12),
                
                // Info del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreProducto,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${precioUnitario.toStringAsFixed(2)} c/u',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      
                      // Observaciones
                      if (observaciones.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            observaciones,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Status y cantidad (lado derecho)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status chip
                    _buildStatusChip(statusDetalle, controller),
                    
                    SizedBox(height: 12),
                    
                    // Cantidad
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B4513).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$cantidad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status, HistorialDetailsController controller) {
    final statusColor = controller.getStatusColor(status);
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
          Icon(statusIcon, size: 12, color: statusColor),
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
  
  Widget _buildFooter(HistorialDetailsController controller) {
    return GetBuilder<HistorialDetailsController>(
      builder: (controller) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF5F2F0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Estadísticas de la venta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Items:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${controller.productos.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                  ],
                ),
               Flexible(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        controller.labelTotalFooter,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        '\$${controller.totalParaFooter.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B4513),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
),

              ],
            ),
            
            SizedBox(height: 16),
            
            // Botones de acción
            if (controller.tieneProductosSeleccionados)
              Column(
                children: [
                  // Botón imprimir seleccionados
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.confirmarImprimirProductosSeleccionados,
                      icon: Icon(Icons.print_outlined, color: Colors.white),
                      label: Text(
                        'IMPRIMIR SELECCIONADOS (${controller.productosSeleccionados.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            
            // Botón de cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: Colors.white),
                label: Text(
                  'CERRAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            // Padding para navegación del sistema
            SizedBox(height: MediaQuery.of(Get.context!).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}
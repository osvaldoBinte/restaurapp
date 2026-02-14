import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class OrderStatusModal extends StatelessWidget {
  final int pedidoId;
  
  const OrderStatusModal({Key? key, required this.pedidoId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.assignment, color: Color(0xFF8B4513), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cambiar Estado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Text(
              'Pedido #$pedidoId',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Botones de estado
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _actualizarYCerrar(controller, pedidoId, 'completado'),
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text(
                  'Marcar como Completado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _actualizarYCerrar(controller, pedidoId, 'cancelado'),
                icon: Icon(Icons.cancel, color: Colors.white),
                label: Text(
                  'Cancelar Pedido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Botón cancelar
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ CAMBIO: Convertir pedidoId a lista antes de llamar al controller
  Future<void> _actualizarYCerrar(OrdersController controller, int pedidoId, String nuevoEstado) async {
    try {
      // Cerrar modal inmediatamente para mejor UX
      Get.back();
      
      // ✅ CAMBIO: Pasar el pedidoId como lista
      await controller.actualizarEstadoOrden([pedidoId], nuevoEstado);
      
    } catch (e) {
      print('Error al actualizar estado: $e');
      // En caso de error, el controller ya maneja la visualización del error
    }
  }
}
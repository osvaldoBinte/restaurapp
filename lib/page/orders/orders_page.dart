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
import 'package:restaurapp/page/orders/modaltable/table_details_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class OrdersDashboardScreen extends StatelessWidget {
  final controller = Get.find<OrdersController>();
    final controllerTableDetailsController = Get.find<OrdersController>();

  OrdersDashboardScreen({Key? key}) : super(key: key);


@override
Widget build(BuildContext context) {
  // 🎯 RESPONSIVIDAD: Detectar tamaño de pantalla
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenHeight < 600;
  final isVerySmallScreen = screenHeight < 500;
  final isSmallWidth = screenWidth < 400;
  
  // 📐 ALTURA MÍNIMA ADAPTATIVA para el carousel
  double minCarouselHeight;
  double maxCarouselHeight;
  
  if (isVerySmallScreen) {
    minCarouselHeight = 140; // Aumentado para que el texto se vea mejor
    maxCarouselHeight = 180;
  } else if (isSmallScreen) {
    minCarouselHeight = 160; 
    maxCarouselHeight = 200;
  } else {
    minCarouselHeight = 180; 
    maxCarouselHeight = 240;
  }

  return Scaffold(
    backgroundColor: Color(0xFFF5F2F0),
    appBar: AppBar(
      backgroundColor: Color(0xFF8B4513),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallWidth ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'EJ',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
                fontSize: isSmallWidth ? 14 : 16,
              ),
            ),
          ),
          SizedBox(width: isSmallWidth ? 8 : 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comedor "El Jobo"',
                  style: TextStyle(
                    fontSize: isSmallWidth ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh, 
            color: Colors.white,
            size: isSmallWidth ? 20 : 24,
          ),
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
                  fontSize: isSmallScreen ? 14 : 16,
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
            // 🎯 CAROUSEL CON ALTURA FLEXIBLE - SOLUCIÓN PRINCIPAL
            Container(
              constraints: BoxConstraints(
                minHeight: minCarouselHeight,
                maxHeight: maxCarouselHeight, // Altura máxima más flexible
              ),
              child: _buildPendingOrdersCarousel(isSmallScreen, isVerySmallScreen, isSmallWidth),
            ),
            
            // 📋 LISTA DE MESAS - Usa el espacio restante
            Expanded(
              child: _buildTablesList(isSmallScreen, isSmallWidth),
            ),
          ],
        ),
      );
    }),
  );
}
Widget _buildPendingOrdersCarousel(bool isSmallScreen, bool isVerySmallScreen, bool isSmallWidth) {
  return Column(
    children: [
      // Header del carousel - MODIFICADO con botón Liberar Todo
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 10,
        ),
        child: Row(
          children: [
            Icon(
              Icons.restaurant_menu, 
              color: Color(0xFF8B4513),
              size: isSmallWidth ? 18 : 22,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Pedidos Pendientes',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ),
            
            Obx(() {
  final conteoMesas = controller.obtenerConteoMesasConPendientes();
  final isLoading = controller.isLiberandoTodasLasMesas.value;
  
  if (conteoMesas > 0) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: isLoading ? null : () => controller.liberarTodasLasMesas(), // ✅ Deshabilitar si está cargando
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallWidth ? 8 : 10,
            vertical: isSmallWidth ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isLoading 
                ? Colors.grey[400] // ✅ Color gris mientras carga
                : Color(0xFFE74C3C), // Color normal
            borderRadius: BorderRadius.circular(8),
            boxShadow: isLoading 
                ? [] // ✅ Sin sombra mientras carga
                : [
                    BoxShadow(
                      color: Color(0xFFE74C3C).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Mostrar loader o ícono normal
              isLoading 
                  ? SizedBox(
                      width: isSmallWidth ? 14 : 16,
                      height: isSmallWidth ? 14 : 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.done_all,
                      color: Colors.white,
                      size: isSmallWidth ? 14 : 16,
                    ),
              SizedBox(width: 4),
              Text(
                isLoading 
                    ? (isSmallWidth ? 'Proc...' : 'Procesando...')  // ✅ Texto mientras carga
                    : (isSmallWidth ? 'Todo' : 'Liberar Todo'),     // Texto normal
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallWidth ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // ✅ Solo mostrar contador si NO está cargando
              if (!isLoading && !isSmallWidth) ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$conteoMesas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  return SizedBox.shrink();
}),
            
            // Auto-refresh indicator (existente)
            Obx(() {
              if (controller.isAutoRefreshEnabled.value) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallWidth ? 4 : 6, 
                    vertical: 2
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 8,
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
      
      // Lista flexible que se adapta al contenido (sin cambios)
      Flexible(
        child: Obx(() {
          if (controller.pedidosIndividuales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle, 
                    size: isSmallScreen ? 24 : 32,
                    color: Colors.green
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No hay pedidos pendientes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(Get.context!).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
              scrollbars: true,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
              itemCount: controller.pedidosIndividuales.length,
              itemBuilder: (context, index) {
                final pedido = controller.pedidosIndividuales[index];
                return _buildCarouselCardIndividual(pedido, isSmallScreen, isVerySmallScreen, isSmallWidth);
              },
            ),
          );
        }),
      ),
    ],
  );
}

Widget _buildCarouselCardIndividual(Map<String, dynamic> detalle, bool isSmallScreen, bool isVerySmallScreen, bool isSmallWidth) {
  final numeroMesa = detalle['numeroMesa'];
  final nombreOrden = detalle['nombreOrden'] ?? 'Sin nombre';
  final pedidoId = detalle['detalleId'];
  final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
  final cantidad = detalle['cantidad'] ?? 1;
  final precio = (detalle['precio'] ?? 0.0).toDouble();
  final observaciones = detalle['observaciones'] ?? '';
  final fecha = DateTime.parse(detalle['fecha']);
  final timeString = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
       
  // 📐 DIMENSIONES BASE - Solo ancho, altura será automática
  double cardWidth;
  
  if (isSmallWidth) {
    cardWidth = 150;
  } else if (isSmallScreen) {
    cardWidth = 170;
  } else {
    cardWidth = 190;
  }
       
  return Container(
    width: cardWidth,
    // ✅ REMOVIDO: constraints con minHeight - ahora es completamente flexible
    margin: EdgeInsets.only(right: 12, bottom: isVerySmallScreen ? 4 : 8),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => controller.mostrarModalEstadoOrden(pedidoId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // ✅ REMOVIDO: constraints - la altura será automática
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
            mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE: min para que se ajuste al contenido
            children: [
              // 🔧 Nombre del producto - SIN límite de líneas
              Text(
                nombreProducto,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallWidth ? 12 : (isSmallScreen ? 13 : 14),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                // ✅ REMOVIDO: maxLines y overflow - ahora se expande automáticamente
              ),
              
              SizedBox(height: 6),
                           
              // 🔧 Cantidad
              Text(
                'Cant: $cantidad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallWidth ? 10 : (isSmallScreen ? 11 : 12),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
             
              SizedBox(height: 8),
                           
              // 🔧 Mesa - Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: isSmallScreen ? 3 : 4
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MESA $numeroMesa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallWidth ? 10 : (isSmallScreen ? 11 : 12),
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
                           
              // 🔧 Observaciones - SIN restricciones de líneas
              if (observaciones.isNotEmpty) ...[
                SizedBox(height: 6),
                Flexible(
                  child: Text(
                 '$observaciones',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  // ✅ REMOVIDO: maxLines y overflow - se expande automáticamente
                ),
                  )  // ✅ Flexible para que se ajuste al contenido
               
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
// 📋 LISTA DE MESAS RESPONSIVA
Widget _buildTablesList(bool isSmallScreen, bool isSmallWidth) {
  return Column(
    children: [
      // Header con divider adaptativo y botón Liberar Todo
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 6 : 8
        ),
        child: Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              child: Text(
                'Lista de Mesas',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E1F08),
                ),
              ),
            ),
            
            // Botón Liberar Todo - Aparece solo si hay mesas
           // Botón Liberar Todo - Aparece solo si hay mesas con pedidos completados
Obx(() {
  final conteoMesasCompletadas = controller.obtenerConteoMesasListasParaLiberar();
  final isLoading = controller.isLiberandoTodasLasMesas.value; // Usar el mismo controller
  
  if (conteoMesasCompletadas > 0) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      child: InkWell(
        // ✅ CAMBIO PRINCIPAL: Usar el método correcto
        onTap: isLoading ? null : () => controller.liberarMesasCompletadas(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallWidth ? 8 : 10,
            vertical: isSmallWidth ? 4 : 6,
          ),
          decoration: BoxDecoration(
            // Color verde para indicar que están completados
            color: isLoading 
                ? Colors.grey[400]
                : Color(0xFFE74C3C), // Verde para mesas completadas
            borderRadius: BorderRadius.circular(8),
            boxShadow: isLoading 
                ? []
                : [
                    BoxShadow(
                      color: Color(0xFF27AE60).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrar loader o ícono normal
              isLoading 
                  ? SizedBox(
                      width: isSmallWidth ? 14 : 16,
                      height: isSmallWidth ? 14 : 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.check_circle, // Icono de check para completados
                      color: Colors.white,
                      size: isSmallWidth ? 14 : 16,
                    ),
              SizedBox(width: 4),
              Text(
                isLoading 
                    ? (isSmallWidth ? 'Lib...' : 'Liberando...')
                    : (isSmallWidth ? 'Listos' : 'Liberar mesas'), // Texto más claro
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallWidth ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Mostrar contador si no está cargando
              if (!isLoading && !isSmallWidth) ...[
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$conteoMesasCompletadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  return SizedBox.shrink();
}),
            
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      
      // Lista de mesas
      Expanded(
        child: Obx(() {
          if (controller.mesasConPedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_restaurant, 
                    size: isSmallScreen ? 48 : 64,
                    color: Colors.grey[400]
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay mesas con pedidos activos',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            itemCount: controller.mesasConPedidos.length,
            itemBuilder: (context, index) {
              final mesa = controller.mesasConPedidos[index];
              return _buildTableCard(mesa, isSmallScreen, isSmallWidth);
            },
          );
        }),
      ),
    ],
  );
}
  // 🏪 CARD DE MESA RESPONSIVA
  Widget _buildTableCard(Map<String, dynamic> mesa, bool isSmallScreen, bool isSmallWidth) {
    final numeroMesa = mesa['numeroMesa'];
    final pedidos = mesa['pedidos'] as List;
    final totalMesa = controller.calcularTotalMesa(mesa);
    final totalItems = controller.contarItemsMesa(mesa);

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => controller.mostrarDetallesMesa(numeroMesa),

          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Padding adaptativo
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
                          fontSize: isSmallScreen ? 16 : 18, // Font adaptativo
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$totalItems item${totalItems != 1 ? 's' : ''} • ${pedidos.length} pedido${pedidos.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 10 : 12, // Font adaptativo
                        ),
                      ),
                      if (totalMesa > 0) ...[
                        SizedBox(height: 8),
                        Text(
                          'Total: \$${totalMesa.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14, // Font adaptativo
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSmallWidth) // Solo mostrar texto en pantallas anchas
                      Text(
                        'ver mas',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isSmallScreen ? 12 : 14, // Tamaño adaptativo
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

  // 🔄 CARD ORIGINAL PARA COMPATIBILITY (sin cambios)
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
  
}
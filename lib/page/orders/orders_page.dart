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
  final controller = Get.find<OrdersController>();

  OrdersDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎯 RESPONSIVIDAD: Detectar tamaño de pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;
    final isVerySmallScreen = screenHeight < 500;
    final isSmallWidth = screenWidth < 400;
    
    // 📐 FLEX ADAPTATIVO basado en tamaño de pantalla
    int carouselFlex;
    int tablesFlex;
    
    if (isVerySmallScreen) {
      carouselFlex = 1; // Mínimo espacio en pantallas muy pequeñas
      tablesFlex = 4;
    } else if (isSmallScreen) {
      carouselFlex = 2; // Menos espacio en pantallas pequeñas
      tablesFlex = 5;
    } else {
      carouselFlex = 3; // Espacio normal en pantallas medianas/grandes
      tablesFlex = 6;
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallWidth ? 6 : 8), // Padding adaptativo
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EJ',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallWidth ? 14 : 16, // Font size adaptativo
                ),
              ),
            ),
            SizedBox(width: isSmallWidth ? 8 : 12), // Spacing adaptativo
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comedor "El Jobo"',
                    style: TextStyle(
                      fontSize: isSmallWidth ? 16 : 18, // Font size adaptativo
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Auto-refresh status
                  Obx(() => Row(
                    children: [
                      Text(
                        'Órdenes Activas',
                        style: TextStyle(
                          fontSize: isSmallWidth ? 10 : 12, // Font size adaptativo
                          color: Colors.white70,
                        ),
                      ),
                      if (controller.isAutoRefreshEnabled.value) ...[
                        SizedBox(width: 4),
                        Container(
                          width: isSmallWidth ? 4 : 6, // Tamaño adaptativo
                          height: isSmallWidth ? 4 : 6,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Auto ${controller.autoRefreshInterval}s',
                          style: TextStyle(
                            fontSize: isSmallWidth ? 8 : 10, // Font size adaptativo
                            color: Colors.green[200],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón auto-refresh
          Obx(() => IconButton(
            icon: Icon(
              controller.isAutoRefreshEnabled.value 
                ? Icons.pause_circle_filled 
                : Icons.play_circle_filled,
              color: Colors.white,
              size: isSmallWidth ? 20 : 24, // Tamaño adaptativo
            ),
            tooltip: controller.isAutoRefreshEnabled.value 
              ? 'Pausar auto-refresh' 
              : 'Activar auto-refresh',
            onPressed: () => controller.toggleAutoRefresh(),
          )),
          
          // Botón refresh manual
          IconButton(
            icon: Icon(
              Icons.refresh, 
              color: Colors.white,
              size: isSmallWidth ? 20 : 24, // Tamaño adaptativo
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
                    fontSize: isSmallScreen ? 14 : 16, // Font size adaptativo
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
              // 🎯 CAROUSEL RESPONSIVO - Flex adaptativo
              Expanded(
                flex: carouselFlex,
                child: _buildPendingOrdersCarousel(isSmallScreen, isVerySmallScreen, isSmallWidth),
              ),
              
              // 📋 LISTA DE MESAS RESPONSIVA - Flex adaptativo  
              Expanded(
                flex: tablesFlex,
                child: _buildTablesList(isSmallScreen, isSmallWidth),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 🎠 CAROUSEL RESPONSIVO
  Widget _buildPendingOrdersCarousel(bool isSmallScreen, bool isVerySmallScreen, bool isSmallWidth) {
    return Container(
      child: Column(
        children: [
          // Header del carousel - Padding y font adaptativo
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu, 
                  color: Color(0xFF8B4513),
                  size: isSmallWidth ? 20 : 24, // Tamaño adaptativo
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pedidos Pendientes',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18, // Font size adaptativo
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                // Auto-refresh indicator
                Obx(() {
                  if (controller.isAutoRefreshEnabled.value) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallWidth ? 6 : 8, 
                        vertical: isSmallWidth ? 2 : 4
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isSmallWidth ? 4 : 6,
                            height: isSmallWidth ? 4 : 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Auto',
                            style: TextStyle(
                              fontSize: isSmallWidth ? 8 : 10,
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
          
          // Lista de cards
          Expanded(
            child: Obx(() {
              if (controller.pedidosIndividuales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle, 
                        size: isSmallScreen ? 32 : 48, // Tamaño adaptativo
                        color: Colors.green
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No hay pedidos pendientes',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isSmallScreen ? 12 : 14, // Font size adaptativo
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
                child: Container(
                  height: double.infinity,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                    itemCount: controller.pedidosIndividuales.length,
                    itemBuilder: (context, index) {
                      final pedido = controller.pedidosIndividuales[index];
                      return _buildCarouselCardIndividual(pedido, isSmallScreen, isVerySmallScreen, isSmallWidth);
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

  // 🃏 CARD INDIVIDUAL RESPONSIVA
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
         
    // 📐 DIMENSIONES ADAPTATIVAS
    double cardWidth;
    if (isSmallWidth) {
      cardWidth = 140; // Muy estrecho
    } else if (isSmallScreen) {
      cardWidth = 160; // Pantalla pequeña
    } else {
      cardWidth = 180; // Pantalla normal
    }
         
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: 12, bottom: isVerySmallScreen ? 2 : 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => controller.mostrarModalEstadoOrden(pedidoId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // Padding adaptativo
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
              mainAxisSize: MainAxisSize.min, // ✅ CLAVE: Evita overflow vertical
              children: [
                // Nombre del producto - Limitado y adaptativo
                Flexible(
                  child: Text(
                    nombreProducto,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallWidth ? 11 : (isSmallScreen ? 12 : 14), // Font adaptativo
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: isVerySmallScreen ? 1 : 2, // Líneas adaptativas
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isVerySmallScreen ? 2 : 4),
                             
                // Cantidad y precio - Compacto
                Text(
                  'Cant: $cantidad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallWidth ? 9 : (isSmallScreen ? 10 : 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
               
                SizedBox(height: isVerySmallScreen ? 2 : 8),
                             
                // Mesa - Compacto
                 Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 8, 
                      vertical: isSmallScreen ? 2 : 4
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'MESA $numeroMesa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallWidth ? 9 : (isSmallScreen ? 10 : 12),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                             
                // Spacer adaptativo
                       
                // Observaciones - Solo en pantallas normales
                if (observaciones.isNotEmpty && !isSmallScreen) ...[
                  Flexible(
                    child: Text(
                      observaciones,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 4),
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
        // Header con divider adaptativo
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
                  'Lista',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18, // Font adaptativo
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
                      size: isSmallScreen ? 48 : 64, // Tamaño adaptativo
                      color: Colors.grey[400]
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay mesas con pedidos activos',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16, // Font adaptativo
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
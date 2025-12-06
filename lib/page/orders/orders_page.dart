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
import 'package:restaurapp/page/orders/configuracion.dart';
import 'package:restaurapp/page/orders/modaltable/table_details_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class OrdersDashboardScreen extends StatelessWidget {
  final controller = Get.find<OrdersController>();
  final controllerTableDetailsController = Get.find<OrdersController>();

  OrdersDashboardScreen({Key? key}) : super(key: key);
  final configuracionController = Get.put(ConfiguracionController());

  @override
  Widget build(BuildContext context) {
    // 🎯 RESPONSIVIDAD: Detectar tamaño de pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;
    final isVerySmallScreen = screenHeight < 500;
    final isSmallWidth = screenWidth < 400;

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
                    '"El Jobo v1.1"',
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
              // ✅ CAROUSEL CON ALTURA DINÁMICA BASADA EN CONFIGURACIÓN
              Obx(() {
                final minCarouselHeight = configuracionController.obtenerAlturaMinCarousel(isVerySmallScreen, isSmallScreen);
                final maxCarouselHeight = configuracionController.obtenerAlturaMaxCarousel(isVerySmallScreen, isSmallScreen);
                
                return Container(
                  constraints: BoxConstraints(
                    minHeight: minCarouselHeight,
                    maxHeight: maxCarouselHeight,
                  ),
                  child: _buildPendingOrdersCarousel(
                    isSmallScreen,
                    isVerySmallScreen,
                    isSmallWidth,
                  ),
                );
              }),

              // 📋 LISTA DE MESAS - Usa el espacio restante
              Expanded(child: _buildTablesList(isSmallScreen, isSmallWidth)),
            ],
          ),
        );
      }),
    );
  }
  Widget _buildPendingOrdersCarousel(
    bool isSmallScreen,
    bool isVerySmallScreen,
    bool isSmallWidth,
  ) {
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
                final conteoMesas = controller
                    .obtenerConteoMesasConPendientes();
                final isLoading = controller.isLiberandoTodasLasMesas.value;

                if (conteoMesas > 0) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () => controller
                                .liberarTodasLasMesas(), // ✅ Deshabilitar si está cargando
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                                  ? (isSmallWidth
                                        ? 'Proc...'
                                        : 'Procesando...') // ✅ Texto mientras carga
                                  : (isSmallWidth
                                        ? 'Todo'
                                        : 'Liberar Todo'), // Texto normal
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
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

              //boton para cambiar estilo 
                Container(
                margin: EdgeInsets.only(left: 8),
                child: InkWell(
                  onTap: () => configuracionController.mostrarModalConfiguracion(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallWidth ? 6 : 8,
                      vertical: isSmallWidth ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8B4513).withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: isSmallWidth ? 14 : 16,
                    ),
                  ),
                ),
              ),
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
                      color: Colors.green,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                ),
                itemCount: controller.pedidosIndividuales.length,
                itemBuilder: (context, index) {
                  final pedido = controller.pedidosIndividuales[index];
                  return _buildCarouselCardIndividual(
                    pedido,
                    isSmallScreen,
                    isVerySmallScreen,
                    isSmallWidth,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselCardIndividual(
  Map<String, dynamic> detalle,
  bool isSmallScreen,
  bool isVerySmallScreen,
  bool isSmallWidth,
) {
  final numeroMesa = detalle['numeroMesa'];
  final nombreOrden = detalle['nombreOrden'] ?? 'Sin nombre';
  final pedidoId = detalle['detalleId'];
  final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
  final cantidad = detalle['cantidad'] ?? 1;
  final precio = (detalle['precio'] ?? 0.0).toDouble();
  final observaciones = detalle['observaciones'] ?? '';
  final fecha = DateTime.parse(detalle['fecha']);
  final timeString =
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  return Container(
    child: Obx(() {
      final cardWidth = configuracionController.obtenerAnchoCard(isSmallWidth, isSmallScreen);
      
      return Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: 12, bottom: isVerySmallScreen ? 4 : 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => controller.mostrarModalEstadoOrden(pedidoId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // ✅ ALTURA FIJA CON SCROLL INTERNO
              height: _calcularAlturaCard(isVerySmallScreen, isSmallScreen),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ NOMBRE DEL PRODUCTO - TAMAÑO Y COLOR PERSONALIZABLES
                    Obx(() => Text(
                      nombreProducto,
                      style: TextStyle(
                        color: configuracionController.obtenerColorTexto(),
                        fontSize: configuracionController.obtenerTamanoFuente(isSmallWidth, isSmallScreen),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    )),

                    SizedBox(height: 6),

                    // ✅ CANTIDAD - TAMAÑO SECUNDARIO Y COLOR PERSONALIZABLES
                    Obx(() => Text(
                      'Cant: $cantidad',
                      style: TextStyle(
                        color: configuracionController.obtenerColorTexto().withOpacity(0.9),
                        fontSize: configuracionController.obtenerTamanoFuenteSecundario(isSmallWidth, isSmallScreen),
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    )),

                    SizedBox(height: 8),

                    // Mesa - Badge (mantiene color blanco para contraste)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MESA $numeroMesa',
                        style: TextStyle(
                          color: Colors.white, // Mantener blanco para legibilidad
                          fontSize: isSmallWidth ? 10 : (isSmallScreen ? 11 : 12),
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),

                    // ✅ OBSERVACIONES - TAMAÑO SECUNDARIO Y COLOR PERSONALIZABLES
                    if (observaciones.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Obx(() => Text(
                        '$observaciones',
                        style: TextStyle(
                          color: configuracionController.obtenerColorTexto().withOpacity(0.7),
                          fontSize: configuracionController.obtenerTamanoFuenteSecundario(isSmallWidth, isSmallScreen),
                          height: 1.2,
                        ),
                        // ✅ TEXTO SIN RESTRICCIONES - EL SCROLL MANEJA EL OVERFLOW
                      )),
                    ],
                    
                    // ✅ ESPACIADO ADICIONAL PARA MEJOR SCROLL
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );
}

// ✅ FUNCIÓN AUXILIAR PARA CALCULAR ALTURA FIJA DE LA CARD
double _calcularAlturaCard(bool isVerySmallScreen, bool isSmallScreen) {
  if (isVerySmallScreen) {
    return 120; // Altura fija más pequeña para pantallas muy pequeñas
  } else if (isSmallScreen) {
    return 140; // Altura fija para pantallas pequeñas
  } else {
    return 160; // Altura fija para pantallas normales
  }
}
  Widget _buildTablesList(bool isSmallScreen, bool isSmallWidth) {
    return Column(
      children: [
        // Header adaptativo para diferentes tamaños de pantalla
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: isSmallWidth
              ? _buildCompactHeader(
                  isSmallScreen,
                ) // Layout compacto para pantallas muy pequeñas
              : _buildNormalHeader(isSmallScreen), // Layout normal
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
                      color: Colors.grey[400],
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
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
              ),
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

  // Header normal para pantallas medianas y grandes
  Widget _buildNormalHeader(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
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
        _buildLiberarButton(false), // No es pantalla muy pequeña
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  // Header compacto para pantallas muy pequeñas
  Widget _buildCompactHeader(bool isSmallScreen) {
    return Column(
      children: [
        // Título centrado
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[400])),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Mesas', // Título más corto
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E1F08),
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[400])),
          ],
        ),

        // Botón debajo del título si hay mesas completadas
        Obx(() {
          final conteoMesasCompletadas = controller
              .obtenerConteoMesasListasParaLiberar();
          if (conteoMesasCompletadas > 0) {
            return Container(
              margin: EdgeInsets.only(top: 8),
              child: _buildLiberarButton(true), // Es pantalla muy pequeña
            );
          }
          return SizedBox(height: 8); // Espaciado mínimo si no hay botón
        }),
      ],
    );
  }

  // Widget del botón liberar reutilizable
  Widget _buildLiberarButton(bool isVerySmall) {
    return Obx(() {
      final conteoMesasCompletadas = controller
          .obtenerConteoMesasListasParaLiberar();
      final isLoading = controller.isLiberandoTodasLasMesas.value;

      if (conteoMesasCompletadas == 0) {
        return SizedBox.shrink();
      }

      return InkWell(
        onTap: isLoading ? null : () => controller.liberarMesasCompletadas(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 12 : 10,
            vertical: isVerySmall ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: isLoading ? Colors.grey[400] : Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isLoading
                ? []
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
              isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  isLoading
                      ? 'Liberando...'
                      : (isVerySmall ? 'Liberar Completadas' : 'Liberar mesas'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmall ? 13 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isLoading) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$conteoMesasCompletadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // 🏪 CARD DE MESA RESPONSIVA
  Widget _buildTableCard(
    Map<String, dynamic> mesa,
    bool isSmallScreen,
    bool isSmallWidth,
  ) {
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
            padding: EdgeInsets.all(
              isSmallScreen ? 12 : 16,
            ), // Padding adaptativo
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
                            fontSize: isSmallScreen
                                ? 12
                                : 14, // Font adaptativo
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
                primerPedido != null
                    ? primerPedido['nombreOrden'] ?? 'Sin nombre'
                    : 'Sin pedidos',
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
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

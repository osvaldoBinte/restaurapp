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
import 'package:restaurapp/page/orders/historial/historal_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

class HistorialPage extends StatelessWidget {
  final controller = Get.find<HistorialController>();

  HistorialPage({Key? key}) : super(key: key);

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
      
      // 🆕 AppBar con selector de fecha y estadísticas
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: Text('Historial de Ventas'),
        elevation: 0,
        actions: [
          // Botón selector de fecha
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _mostrarSelectorFecha(context),
            tooltip: 'Cambiar fecha',
          ),
          // Botón de auto-refresh toggle
          Obx(() => IconButton(
            icon: Icon(
              controller.isAutoRefreshEnabled.value 
                ? Icons.sync 
                : Icons.sync_disabled,
            ),
            onPressed: controller.toggleAutoRefresh,
            tooltip: controller.isAutoRefreshEnabled.value 
              ? 'Auto-refresh activado' 
              : 'Auto-refresh desactivado',
          )),
        ],
      ),
      
      body: Obx(() {
        if (controller.isLoading.value && controller.historialVentas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando historial...',
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
              // 🆕 Panel de estadísticas del día
              _buildEstadisticasPanel(isSmallScreen),
              
              // 🆕 Lista de historial de ventas
              Expanded(
                child: _buildHistorialList(isSmallScreen, isSmallWidth),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 🆕 PANEL DE ESTADÍSTICAS DEL DÍA
  Widget _buildEstadisticasPanel(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFF7A3E11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: isSmallScreen ? 16 : 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ventas del ${controller.fechaFormateada}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Indicador de auto-refresh
              Obx(() => controller.isAutoRefreshEnabled.value
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Auto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total del Día',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Obx(() => Text(
                      '\$${controller.totalVentasDelDia.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Órdenes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Obx(() => Text(
                      '${controller.totalOrdenesDelDia}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 LISTA DE HISTORIAL DE VENTAS
  Widget _buildHistorialList(bool isSmallScreen, bool isSmallWidth) {
    return Column(
      children: [
        // Header con divider
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
    'Historial de Ventas',
    style: TextStyle(
      fontSize: isSmallScreen ? 16 : 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF3E1F08),
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    softWrap: false,
  ),
),

              Expanded(
                child: Divider(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        
        // Lista de ventas
        Expanded(
          child: Obx(() {
            if (controller.historialVentas.isEmpty && !controller.isLoading.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long, 
                      size: isSmallScreen ? 48 : 64,
                      color: Colors.grey[400]
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay ventas registradas',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Para la fecha ${controller.fechaFormateada}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarSelectorFecha(Get.context!),
                      icon: Icon(Icons.calendar_today, size: 18),
                      label: Text('Cambiar Fecha'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              itemCount: controller.historialVentas.length + (controller.hasMoreData.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.historialVentas.length) {
                  // Widget de "Cargar más" al final de la lista
                  return _buildCargarMasWidget(isSmallScreen);
                }
                
                final venta = controller.historialVentas[index];
                return _buildVentaCard(venta, isSmallScreen, isSmallWidth);
              },
            );
          }),
        ),
      ],
    );
  }

  // 🆕 CARD DE VENTA INDIVIDUALWidget 
  _buildVentaCard(Map<String, dynamic> venta, bool isSmallScreen, bool isSmallWidth) {
  final pedidoId = venta['pedidoId']?.toString() ?? venta['id']?.toString() ?? 'N/A';
  final numeroMesa = venta['numeroMesa']?.toString() ?? 'N/A';
  final cliente = venta['nombreOrden']?.toString() ?? venta['cliente']?.toString() ?? 'Cliente';
  final total = venta['total']?.toString() ?? venta['totalVenta']?.toString() ?? '0.00';
  final fecha = venta['fecha']?.toString() ?? venta['fechaVenta']?.toString() ?? '';
  final estado = venta['status']?.toString() ?? venta['estado']?.toString() ?? 'N/A';

  // Formatear hora si la fecha incluye tiempo
  String horaFormateada = '';
  try {
    if (fecha.isNotEmpty) {
      final DateTime fechaDateTime = DateTime.parse(fecha);
      horaFormateada = '${fechaDateTime.hour.toString().padLeft(2, '0')}:${fechaDateTime.minute.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    horaFormateada = '';
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 350;

      return Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => controller.mostrarDetallesVenta(venta),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de la venta
                  Container(
                    width: isSmallScreen ? 40 : 45,
                    height: isSmallScreen ? 40 : 45,
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: Color(0xFF8B4513),
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: 12),

                  // Contenido principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Cliente + hora
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cliente,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E1F08),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isCompact && horaFormateada.isNotEmpty)
                              Text(
                                horaFormateada,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),

                        /// Info mesa e ID
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Mesa $numeroMesa',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                            Text(
                              '•',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                            Text(
                              'ID: $pedidoId',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        /// Total y estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
  child: Text(
    '\$${double.tryParse(total)?.toStringAsFixed(2) ?? total}',
    style: TextStyle(
      fontSize: isSmallScreen ? 14 : 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF8B4513),
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    softWrap: false,
  ),
),

                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getEstadoColor(estado),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Icono de navegación
                  if (!isCompact) ...[
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isSmallScreen ? 12 : 14,
                      color: Color(0xFF8B4513),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


  // 🆕 WIDGET PARA CARGAR MÁS DATOS
  Widget _buildCargarMasWidget(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Cargando más...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            );
          } else {
            return ElevatedButton(
              onPressed: controller.cargarMasDatos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Cargar Más',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  // 🆕 MÉTODO PARA MOSTRAR SELECTOR DE FECHA
  void _mostrarSelectorFecha(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(controller.fechaConsulta.value),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B4513),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      await controller.cambiarFechaConsulta(fechaSeleccionada);
    }
  }

  // 🆕 MÉTODO PARA OBTENER COLOR DEL ESTADO
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
      return Colors.green;
      case 'pagado':
        return Colors.blue;
      case 'proceso':
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
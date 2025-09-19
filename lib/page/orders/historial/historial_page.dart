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
           IconButton(
    icon: Icon(Icons.refresh),
    onPressed: controller.refrescarDatos,
    tooltip: 'Recargar datos',
  ),
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
            // Panel de estadísticas existente
            _buildEstadisticasPanel(isSmallScreen),
            
            // USAR UNA DE ESTAS OPCIONES:
            _buildCompactPaginationControls(),        
            // _buildMinimalPaginationControls(),     // Opción 2: Minimalista
            
            Expanded(
              child: _buildHistorialList(isSmallScreen, isSmallWidth),
            ),
          ],
          ),
        );
      }),
    );
  }

Widget _buildCompactPaginationControls() {
  return Obx(() {
    if (!controller.showPaginationControls.value) {
      return SizedBox.shrink();
    }

    // Debug: Verificar valores actuales
    print('🔍 Debug Paginación:');
    print('   Página actual: ${controller.currentPage.value}');
    print('   Total páginas: ${controller.totalPages.value}');
    print('   Hay más datos: ${controller.hasMoreData.value}');
    print('   Datos en lista: ${controller.historialVentas.length}');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dropdown compacto
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mostrar:',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              SizedBox(width: 4),
              Container(
                height: 28,
                padding: EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.pageSize.value,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    isDense: true,
                    onChanged: (int? newValue) {
                      if (newValue != null && !controller.isLoading.value) {
                        print('🔄 Cambiando pageSize a: $newValue');
                        controller.cambiarPageSize(newValue);
                      }
                    },
                    items: controller.pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value', style: TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Controles de navegación inteligentes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactNavButton(
                icon: Icons.keyboard_double_arrow_left,
                // ✅ Habilitar si no estamos en página 1 y no está cargando
                onPressed: (controller.currentPage.value > 1 && !controller.isLoading.value)
                    ? () {
                        print('🏠 Ir a primera página');
                        controller.primeraPagina();
                      }
                    : null,
                size: 16,
              ),
              _buildCompactNavButton(
                icon: Icons.chevron_left,
                // ✅ Habilitar si no estamos en página 1 y no está cargando
                onPressed: (controller.currentPage.value > 1 && !controller.isLoading.value)
                    ? () {
                        print('⬅️ Página anterior: ${controller.currentPage.value - 1}');
                        controller.paginaAnterior();
                      }
                    : null,
                size: 16,
              ),
              
              // Información de página con indicador de carga
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.isLoading.value)
                      Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(right: 4),
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                        ),
                      ),
                    Text(
                      '${controller.currentPage.value}/${controller.totalPages.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildCompactNavButton(
                icon: Icons.chevron_right,
                // ✅ Habilitar si no estamos en la última página y no está cargando
                onPressed: (controller.currentPage.value < controller.totalPages.value && !controller.isLoading.value)
                    ? () {
                        print('➡️ Página siguiente: ${controller.currentPage.value + 1}');
                        controller.paginaSiguiente();
                      }
                    : null,
                size: 16,
              ),
              _buildCompactNavButton(
                icon: Icons.keyboard_double_arrow_right,
                // ✅ Habilitar si no estamos en la última página y no está cargando
                onPressed: (controller.currentPage.value < controller.totalPages.value && !controller.isLoading.value)
                    ? () {
                        print('🏁 Ir a última página: ${controller.totalPages.value}');
                        controller.ultimaPagina();
                      }
                    : null,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  });
}


Widget _buildCompactNavButton({
  required IconData icon,
  required VoidCallback? onPressed,
  required double size,
}) {
  final isEnabled = onPressed != null;
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(2),
      splashColor: isEnabled ? Color(0xFF8B4513).withOpacity(0.2) : null,
      highlightColor: isEnabled ? Color(0xFF8B4513).withOpacity(0.1) : null,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: isEnabled 
              ? Border.all(color: Color(0xFF8B4513).withOpacity(0.3), width: 0.5)
              : null,
        ),
        child: Icon(
          icon,
          size: size,
          color: isEnabled ? Color(0xFF8B4513) : Colors.grey[400],
        ),
      ),
    ),
  );
}

// ✅ WIDGET MEJORADO: Mensaje con información de paginación real
Widget _buildNoPedidosMessage() {
  return Obx(() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay pedidos para mostrar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Página ${controller.currentPage.value} de ${controller.totalPages.value}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          
          // ✅ Información adicional basada en la paginación
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFF8B4513).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                if (controller.totalPages.value > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hay ${controller.totalPages.value} páginas disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                Text(
                  controller.totalPages.value > 1 
                      ? 'Usa los controles para navegar entre páginas'
                      : 'Esta es la única página disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B4513).withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ Indicadores de navegación disponible
          if (controller.totalPages.value > 1)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.currentPage.value > 1) ...[
                    Icon(Icons.arrow_back, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Anterior disponible',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                  if (controller.currentPage.value > 1 && controller.currentPage.value < controller.totalPages.value)
                    SizedBox(width: 16),
                  if (controller.currentPage.value < controller.totalPages.value) ...[
                    Icon(Icons.arrow_forward, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Siguiente disponible',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  });
}
void _showPageSizeBottomSheet() {
  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Registros por página',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3E1F08),
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: controller.pageSizeOptions.map((size) {
              return Obx(() => ChoiceChip(
                label: Text('$size'),
                selected: controller.pageSize.value == size,
                onSelected: (selected) {
                  if (selected) {
                    controller.cambiarPageSize(size);
                    Get.back();
                  }
                },
                selectedColor: Color(0xFF8B4513).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: controller.pageSize.value == size 
                    ? Color(0xFF8B4513) 
                    : Colors.grey[700],
                  fontWeight: controller.pageSize.value == size 
                    ? FontWeight.w600 
                    : FontWeight.normal,
                ),
              ));
            }).toList(),
          ),
          SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// OPCIÓN 2: CONTROLES SÚPER MINIMALISTAS
Widget _buildMinimalPaginationControls() {
  return Obx(() {
    if (!controller.showPaginationControls.value || controller.historialVentas.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dropdown súper compacto
          GestureDetector(
            onTap: () => _showPageSizeBottomSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${controller.pageSize.value}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.expand_more, size: 14, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Navegación compacta
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTinyNavButton(Icons.first_page, 
                  controller.currentPage.value > 1 ? controller.primeraPagina : null),
                _buildTinyNavButton(Icons.chevron_left, 
                  controller.currentPage.value > 1 ? controller.paginaAnterior : null),
                
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    '${controller.currentPage.value}/${controller.totalPages.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
                
                _buildTinyNavButton(Icons.chevron_right, 
                  controller.currentPage.value < controller.totalPages.value ? controller.paginaSiguiente : null),
                _buildTinyNavButton(Icons.last_page, 
                  controller.currentPage.value < controller.totalPages.value ? controller.ultimaPagina : null),
              ],
            ),
          ),
        ],
      ),
    );
  });
}

Widget _buildTinyNavButton(IconData icon, VoidCallback? onPressed) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 12,
          color: onPressed != null ? Color(0xFF8B4513) : Colors.grey[400],
        ),
      ),
    ),
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
             
            ],
          ),
          SizedBox(height: 12),
          
         
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

Widget _buildPaginationControls() {
  return Obx(() {
    if (!controller.showPaginationControls.value || controller.historialVentas.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selector de page_size
          Row(
            children: [
              Text(
                'Mostrar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3E1F08),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.pageSize.value,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        controller.cambiarPageSize(newValue);
                      }
                    },
                    items: controller.pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Text(
                ' registros por página',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Controles de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botones de navegación izquierda
              Row(
                children: [
                  _buildNavButton(
                    icon: Icons.first_page,
                    onPressed: controller.currentPage.value > 1 
                      ? controller.primeraPagina 
                      : null,
                    tooltip: 'Primera página',
                  ),
                  SizedBox(width: 4),
                  _buildNavButton(
                    icon: Icons.chevron_left,
                    onPressed: controller.currentPage.value > 1 
                      ? controller.paginaAnterior 
                      : null,
                    tooltip: 'Página anterior',
                  ),
                ],
              ),
              
              // Información de página actual
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Página ${controller.currentPage.value} de ${controller.totalPages.value}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
              
              // Botones de navegación derecha
              Row(
                children: [
                  _buildNavButton(
                    icon: Icons.chevron_right,
                    onPressed: controller.currentPage.value < controller.totalPages.value 
                      ? controller.paginaSiguiente 
                      : null,
                    tooltip: 'Página siguiente',
                  ),
                  SizedBox(width: 4),
                  _buildNavButton(
                    icon: Icons.last_page,
                    onPressed: controller.currentPage.value < controller.totalPages.value 
                      ? controller.ultimaPagina 
                      : null,
                    tooltip: 'Última página',
                  ),
                ],
              ),
            ],
          ),
          
          // Input directo de página (opcional)
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ir a página:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(width: 8),
              Container(
                width: 60,
                height: 30,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    hintText: '${controller.currentPage.value}',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  onSubmitted: (value) {
                    final pageNumber = int.tryParse(value);
                    if (pageNumber != null && pageNumber >= 1 && pageNumber <= controller.totalPages.value) {
                      controller.irAPagina(pageNumber);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

Widget _buildNavButton({
  required IconData icon,
  required VoidCallback? onPressed,
  required String tooltip,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null 
              ? Color(0xFF8B4513) 
              : Colors.grey[400],
          ),
        ),
      ),
    ),
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
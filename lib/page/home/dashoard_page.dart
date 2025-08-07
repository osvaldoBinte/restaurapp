import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // AGREGADO para PointerDeviceKind
import 'package:get/get.dart';
import 'package:restaurapp/page/VentasService/VentasService.dart';
import 'package:restaurapp/page/categoria/categoria.dart';
import 'package:restaurapp/page/categoria/listarcategoria/listas_categoria.dart';
import 'package:restaurapp/page/home/dashboard_controller.dart';
import 'package:restaurapp/page/home/home_pc_controller.dart';
import 'package:restaurapp/page/menu/listarmenu/listar_controller.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/table/table_page.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends StatelessWidget {
  // Usar el DashboardController específico
  final DashboardController controller = Get.put(DashboardController());
  
  // Instanciar el VentasController
  final VentasController ventasController = Get.put(VentasController());
  
  // Acceder al HomeController para navegación
  HomeController get homeController => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: Column(
        children: [
          // Top AppBar
          _buildTopAppBar(),
          
          // Main Dashboard Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }
              
              return SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // ✅ Charts and Recent Orders Row con Scroll Horizontal
                    _buildMainContentWithScroll(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Page Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                Text(
                  'Resumen general del restaurante',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            Spacer(),
            
            // 🆕 Widget de Ventas de Hoy
            _buildVentasWidget(),
            
            SizedBox(width: 16),
            
            // Manual Refresh Button
            IconButton(
              onPressed: () {
                controller.refrescarTodo();
                ventasController.refrescarVentas(); // 🆕 También refrescar ventas
              },
              icon: Icon(Icons.refresh, color: Color(0xFF8B4513)),
              tooltip: 'Actualizar datos',
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Widget para mostrar las ventas del día
  Widget _buildVentasWidget() {
    return Obx(() {
      if (ventasController.isLoading.value) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF8B4513).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Cargando...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
        );
      }

      if (ventasController.error.value.isNotEmpty) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF8B4513).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF8B4513).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_money,
              size: 16,
              color: Color(0xFF8B4513),
            ),
            SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ventas Hoy',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  ventasController.totalVentasFormateado,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando dashboard...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  // ✅ NUEVO: Stats Cards con Scroll Horizontal
  
  // ✅ NUEVO: Contenido Principal con Scroll Horizontal
  Widget _buildMainContentWithScroll() {
    return Container(
      height: 600, // Altura fija para evitar overflow
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(Get.context!).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
          scrollbars: true, // Mostrar scrollbar para indicar scroll horizontal
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          children: [
            // Sección 1: Crear Categoría
            Container(
              width: 500, // Ancho fijo
              child: _buildSalesChart(),
            ),
            SizedBox(width: 24),
            
            // Sección 2: Gestión de Menús
            Container(
              width: 500, // Ancho fijo
              child: _buildPopularProducts(),
            ),
            SizedBox(width: 24),
            
            // Sección 3: Gestión de Mesas
            Container(
              width: 500, // Ancho fijo
              child: _buildQuickActions(),
            ),
            SizedBox(width: 24), // Padding final
          ],
        ),
      ),
    );
  }

Widget _buildStatCard(String title, String value, IconData icon, Color color, String action) {
  return GestureDetector(
    onTap: () => homeController.navegarA(action),
    child: Container(
      width: 200, // ✅ REDUCIDO: de 220 a 200px para pantallas muy pequeñas
      padding: EdgeInsets.all(16), // ✅ REDUCIDO: de 20 a 16px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ AGREGADO: Tamaño mínimo necesario
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10), // ✅ REDUCIDO: de 12 a 10px
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20), // ✅ REDUCIDO: de 24 a 20px
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14), // ✅ REDUCIDO
            ],
          ),
          SizedBox(height: 12), // ✅ REDUCIDO: de 16 a 12px
          Flexible( // ✅ AGREGADO: Flexible para evitar overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22, // ✅ REDUCIDO: de 24 a 22px
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E1F08),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 2), // ✅ REDUCIDO: de 4 a 2px
          Flexible( // ✅ AGREGADO: Flexible para evitar overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // ✅ REDUCIDO: de 12 a 11px
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildSalesChart() {
    return Container(
      height: 550, // Altura fija para evitar conflictos de layout
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // ✅ AGREGADO: Para evitar overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear Categoría',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Usar el widget CategoryListScreen embebido
          Expanded(
            child: CategoryListScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularProducts() {
    return Container(
      height: 550, // Altura fija para evitar conflictos de layout
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // ✅ AGREGADO: Para evitar overflow
                child: Text(
                  'Gestión de Menús',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => ListarTodoMenuPage(isEmbedded: false)),
                child: Text(
                  'Completa',
                  style: TextStyle(color: Color(0xFF8B4513)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Usar el widget ListarTodoMenuPage embebido
          Expanded(
            child: ListarTodoMenuPage(
              isEmbedded: true,
              
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 550, // ✅ CAMBIADO: Altura consistente con otras secciones
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // ✅ AGREGADO: Para evitar overflow
                child: Text(
                  'Gestión de Mesas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => TablesScreen()),
                child: Text(
                  'Completa',
                  style: TextStyle(color: Color(0xFF8B4513)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Usar el widget TablesScreen embebido
          Expanded(
            child: TablesScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductoPopular producto) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F2F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getProductEmoji(producto.categoria),
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                Text(
                  '${producto.cantidadVendida} vendidos • ${producto.categoria}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${producto.ingresos.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  String _getProductEmoji(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'quesadillas':
        return '🌮';
      case 'bebidas':
        return '🥤';
      case 'postres':
        return '🍰';
      case 'extras':
        return '🥄';
      default:
        return '🍽️';
    }
  }
}

// Custom Painter para la gráfica de líneas (sin cambios)
class LineChartPainter extends CustomPainter {
  final List<VentaDiaria> ventasData;

  LineChartPainter(this.ventasData);

  @override
  void paint(Canvas canvas, Size size) {
    if (ventasData.isEmpty) return;

    final paint = Paint()
      ..color = Color(0xFF8B4513)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Color(0xFF8B4513).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Encontrar valores min y max para escalar
    final maxValue = ventasData.map((v) => v.total).reduce((a, b) => a > b ? a : b);
    final minValue = ventasData.map((v) => v.total).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    // Calcular puntos
    final points = <Offset>[];
    final fillPoints = <Offset>[];
    
    for (int i = 0; i < ventasData.length; i++) {
      final x = (i / (ventasData.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (ventasData[i].total - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      points.add(Offset(x, y));
      
      // Para el área de relleno
      if (i == 0) {
        fillPoints.add(Offset(x, size.height)); // Punto inferior izquierdo
      }
      fillPoints.add(Offset(x, y));
      if (i == ventasData.length - 1) {
        fillPoints.add(Offset(x, size.height)); // Punto inferior derecho
      }
    }

    // Dibujar área de relleno
    if (fillPoints.length > 2) {
      final fillPath = Path();
      fillPath.moveTo(fillPoints[0].dx, fillPoints[0].dy);
      for (int i = 1; i < fillPoints.length; i++) {
        fillPath.lineTo(fillPoints[i].dx, fillPoints[i].dy);
      }
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Dibujar línea principal
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      
      // Crear línea curva suave
      for (int i = 1; i < points.length; i++) {
        final currentPoint = points[i];
        final previousPoint = points[i - 1];
        
        final controlPoint1 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          previousPoint.dy,
        );
        final controlPoint2 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          currentPoint.dy,
        );
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          currentPoint.dx, currentPoint.dy,
        );
      }
      
      canvas.drawPath(path, paint);
    }

    // Dibujar puntos
    for (final point in points) {
      canvas.drawCircle(point, 6, dotBorderPaint);
      canvas.drawCircle(point, 4, dotPaint);
    }

    // Dibujar líneas de grid horizontales (opcionales)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
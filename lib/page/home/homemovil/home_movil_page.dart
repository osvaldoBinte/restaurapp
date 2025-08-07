import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'dart:ui';

import 'package:restaurapp/page/home/homemovil/home_movil_controller.dart';

class HomeMovilPage extends StatelessWidget {
  const HomeMovilPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeMovilController controller = Get.put(HomeMovilController());
    
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0), // Color de fondo beige claro
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Color(0xFF8B4513), // Marrón chocolate
          elevation: 0,
        ),
      ),
      body: Obx(() => Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5F2F0), // Beige claro
                  Color(0xFFE8DDD4), // Beige más oscuro
                  Color(0xFFDDD0C0), // Beige dorado
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: CurvePainter(),
            ),
          ),
          Center(
            child: controller.pages[controller.selectedIndex.value],
          ),
        ],
      )),
      bottomNavigationBar: _buildConvexBottomBar(controller),
    );
  }

  Widget _buildConvexBottomBar(HomeMovilController controller) {
    // 🎨 Colores definidos directamente
    final Color activeColor = Color(0xFFFFFFFF);        // Marrón chocolate (activo)
    final Color backgroundColor = Color(0xFFFFFFFF);     // Blanco para fondo del navbar
    final Color tabIconColor = Color(0xFFFFFFFF);       // Gris para íconos inactivos
    final Color selectedTabColor = Color(0xFF8B4513);   // Naranja chocolate para tab seleccionado
    
    final List<String> labels = [
     
    'Orden',
    'Pedios',
      'Perfil'
    ];
    
    return ConvexAppBar(
      style: TabStyle.react,
      items: List.generate(labels.length, (index) {
        return TabItem(
          icon: controller.getTabIcon(
            index,
            size: index == controller.selectedIndex.value ? 26.0 : 22.0,
            color: index == controller.selectedIndex.value ? activeColor : tabIconColor,
          ),
          title: labels[index],
        );
      }),
      backgroundColor: backgroundColor,
      activeColor: activeColor,
      color: tabIconColor,
      height: 65,
      top: -25,
      curveSize: 100,
      initialActiveIndex: controller.selectedIndex.value,
      onTap: (int index) {
        controller.changePage(index);
        print('🔄 Tab seleccionado: $index (${labels[index]})');
      },
      elevation: 8,
      gradient: LinearGradient(
        colors: [
          selectedTabColor,
          selectedTabColor.withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}

// 🎨 OPCIONAL: Si necesitas el CurvePainter también actualizado
class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE4B5).withOpacity(0.3), // Moccasin transparente
          Color(0xFFDEB887).withOpacity(0.2), // Burlywood transparente
          Color(0xFFD2B48C).withOpacity(0.1), // Tan transparente
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    var path = Path();
    
    // Crear curvas decorativas
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.6,
      size.width * 0.5, size.height * 0.65
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.6
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Segunda curva más sutil
    var paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8B4513).withOpacity(0.1), // Marrón chocolate muy transparente
          Color(0xFFD2691E).withOpacity(0.05), // Naranja chocolate muy transparente
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    var path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.5, size.height * 0.75,
      size.width, size.height * 0.8
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
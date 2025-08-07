// home_wrapper.dart - Versión corregida sin errores

import 'dart:math'; // ✅ CORRECTO: import necesario para sqrt()
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/home/home_pc_page.dart';
import 'package:restaurapp/page/home/homemovil/home_movil_page.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Obtener información de la pantalla
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final mediaQuery = MediaQuery.of(context);
        final orientation = mediaQuery.orientation;
        final devicePixelRatio = mediaQuery.devicePixelRatio;
        
        // Calcular DPI aproximado para distinguir dispositivos
        final physicalWidth = screenWidth * devicePixelRatio;
        final physicalHeight = screenHeight * devicePixelRatio;
        
        // Detectar si es dispositivo móvil real (no tablet)
        final isMobileDevice = _isMobileDevice(physicalWidth, physicalHeight, devicePixelRatio);
        
        // Lógica de detección mejorada
        if (isMobileDevice) {
          // 📱 DISPOSITIVO MÓVIL REAL (independiente de orientación)
          return HomeMovilPage();
        } else if (screenWidth < 900 && orientation == Orientation.portrait) {
          // 📱 TABLET EN VERTICAL (usar interfaz móvil)
          return HomeMovilPage();
        } else if (screenWidth >= 900 || orientation == Orientation.landscape) {
          // 🖥️ TABLET HORIZONTAL O DESKTOP
          return HomePCPage();
        } else {
          // 📱 FALLBACK: Pantallas pequeñas
          return HomeMovilPage();
        }
      },
    );
  }
  
  // Método para detectar si es dispositivo móvil real
  bool _isMobileDevice(double physicalWidth, double physicalHeight, double devicePixelRatio) {
    // Convertir a pulgadas físicas aproximadas
    final physicalWidthInches = physicalWidth / (devicePixelRatio * 160);
    final physicalHeightInches = physicalHeight / (devicePixelRatio * 160);
    
    // ✅ CORRECCIÓN: usar math.sqrt() en lugar de .sqrt()
    final diagonalInches = sqrt(physicalWidthInches * physicalWidthInches + 
                              physicalHeightInches * physicalHeightInches);
    
    // Si la diagonal es menor a 7 pulgadas, probablemente es móvil
    return diagonalInches < 7.0;
  }
}

// RECOMENDADO: Versión simplificada sin cálculos complejos

class HomeWrapperSimple extends StatelessWidget {
  const HomeWrapperSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final orientation = MediaQuery.of(context).orientation;
        
        // Detectar plataforma
        final isWeb = kIsWeb;
        final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
        final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
        
        // 🎯 LÓGICA SIMPLE Y EFECTIVA
        if (isDesktop || isWeb) {
          // 🖥️ SIEMPRE DESKTOP en computadoras o web
          return HomePCPage();
        } else if (isMobile) {
          // 📱 Dispositivos móviles - considerar orientación
          if (screenWidth >= 900 && orientation == Orientation.landscape) {
            // 🖥️ TABLET EN HORIZONTAL con pantalla grande → Desktop UI
            return HomePCPage();
          } else {
            // 📱 MÓVIL normal o tablet en vertical
            return HomeMovilPage();
          }
        } else {
          // Fallback para casos no identificados
          return screenWidth >= 900 ? HomePCPage() : HomeMovilPage();
        }
      },
    );
  }
}

// VERSIÓN MÁS SIMPLE: Solo por tamaño y orientación (SIN detección de plataforma)

class HomeWrapperUltraSimple extends StatelessWidget {
  const HomeWrapperUltraSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final orientation = MediaQuery.of(context).orientation;
        
        // 📏 BREAKPOINTS SIMPLES
        if (screenWidth >= 1200) {
          // 🖥️ DESKTOP: Pantallas muy grandes
          return HomePCPage();
        } else if (screenWidth >= 900 && orientation == Orientation.landscape) {
          // 🖥️ TABLET HORIZONTAL: Usar interfaz desktop
          return HomePCPage();
        } else {
          // 📱 MÓVIL: Todo lo demás
          return HomeMovilPage();
        }
      },
    );
  }
}

// responsive_controller.dart - Controller sin cambios (funciona bien)

class ResponsiveController extends GetxController {
  var isMobile = false.obs;
  var isTablet = false.obs;
  var isDesktop = false.obs;
  var screenWidth = 0.0.obs;
  var screenHeight = 0.0.obs;
  var orientation = Orientation.portrait.obs;
  var deviceType = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    updateScreenInfo();
    
    // Escuchar cambios de tamaño de ventana
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateScreenInfo();
    });
  }
  
  void updateScreenInfo() {
    final context = Get.context;
    if (context != null) {
      final mediaQuery = MediaQuery.of(context);
      screenWidth.value = mediaQuery.size.width;
      screenHeight.value = mediaQuery.size.height;
      orientation.value = mediaQuery.orientation;
      
      _updateDeviceType();
    }
  }
  
  void _updateDeviceType() {
    final width = screenWidth.value;
    final height = screenHeight.value;
    final isLandscape = orientation.value == Orientation.landscape;
    
    if (width >= 1200) {
      isMobile.value = false;
      isTablet.value = false;
      isDesktop.value = true;
      deviceType.value = 'Desktop';
    } else if (width >= 900 && isLandscape) {
      isMobile.value = false;
      isTablet.value = true;
      isDesktop.value = false;
      deviceType.value = 'Tablet Horizontal';
    } else if (width >= 600) {
      isMobile.value = false;
      isTablet.value = true;
      isDesktop.value = false;
      deviceType.value = 'Tablet Vertical';
    } else {
      isMobile.value = true;
      isTablet.value = false;
      isDesktop.value = false;
      deviceType.value = 'Móvil';
    }
    
    print('📱 Device: ${deviceType.value} (${width.toInt()}x${height.toInt()})');
  }
}

// Widget de debug para mostrar información (OPCIONAL - útil para testing)

class ScreenDebugInfo extends StatelessWidget {
  const ScreenDebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ResponsiveController());
    
    return Positioned(
      top: 40,
      right: 10,
      child: Obx(() => Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 ${controller.deviceType.value}',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              '${controller.screenWidth.value.toInt()}x${controller.screenHeight.value.toInt()}',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              '${controller.orientation.value.name}',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      )),
    );
  }
}
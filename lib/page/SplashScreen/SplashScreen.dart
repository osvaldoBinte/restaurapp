import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/SplashScreen/Splash_controller.dart';
// import 'splash_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  
  late final SplashController controller;
  late AnimationController _logoAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar controller
    controller = Get.put(SplashController());
    _setupAnimations();
  }

  void _setupAnimations() {
    // Controller para el logo
    _logoAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Controller para fade
    _fadeAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animación de escala del logo
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Animación de rotación sutil del logo
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Animación de fade para el texto
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    ));

    // Animación de slide para el texto
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animaciones
    _logoAnimationController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _fadeAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // Colores personalizados (usando los mismos del login)
  static const Map<int, Color> customColors = {
    50: Color(0xFFF5F2F0),
    100: Color(0xFFE8DDD6),
    200: Color(0xFFD4C2B1),
    300: Color(0xFFBFA78C),
    400: Color(0xFFAF9373),
    500: Color(0xFF8B4513),
    600: Color(0xFF7A3E11),
    700: Color(0xFF66340E),
    800: Color(0xFF522A0B),
    900: Color(0xFF3E1F08),
  };

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              customColors[50]!,
              customColors[100]!,
              customColors[200]!,
              customColors[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Parte superior con logo
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animado
                      AnimatedBuilder(
                        animation: _logoAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Transform.rotate(
                              angle: _logoRotationAnimation.value,
                              child: Container(
                                height: isTablet ? 160 : 140,
                                width: isTablet ? 160 : 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: customColors[400]!.withOpacity(0.4),
                                      blurRadius: 25,
                                      offset: Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.asset(
                                    'assest/logo/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.restaurant,
                                        size: isTablet ? 80 : 70,
                                        color: customColors[500],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Nombre de la app con animación
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'RestaurApp',
                            style: TextStyle(
                              fontSize: isTablet ? 36 : 32,
                              fontWeight: FontWeight.bold,
                              color: customColors[800],
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      
                      // Subtítulo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'Gestión Inteligente',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              color: customColors[600],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Parte inferior con loading
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading indicator personalizado
                    Obx(() => AnimatedOpacity(
                      opacity: controller.isLoading.value ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            // Indicador de carga circular personalizado
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  customColors[500]!,
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Mensaje de carga
                            Text(
                              controller.loadingMessage.value,
                              style: TextStyle(
                                color: customColors[600],
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )),
                    
                    SizedBox(height: 40),
                    
                    // Versión de la app (opcional)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: customColors[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
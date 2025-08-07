import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/login/LoginController.dart';
// import 'login_controller.dart'; // Importa el controller

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Instancia del controller con tag único para evitar recreación
  late final LoginController controller;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar controller con tag único para evitar duplicados
    controller = Get.put(LoginController(), tag: 'login_controller');
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // No eliminar el controller aquí para evitar problemas
    super.dispose();
  }

  // Colores personalizados
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final maxWidth = isTablet ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              customColors[50]!,
              customColors[100]!,
              customColors[200]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: maxWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo con animación
                        Container(
                          height: isTablet ? 140 : 120,
                          width: isTablet ? 140 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: customColors[400]!.withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assest/logo/logo.png', // Corregido el typo
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 60,
                                  color: customColors[500],
                                );
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 50 : 40),
                        
                        // Título de bienvenida
                        Text(
                          'Bienvenido',
                          style: TextStyle(
                            fontSize: isTablet ? 36 : 32,
                            fontWeight: FontWeight.bold,
                            color: customColors[800],
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: customColors[600],
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 50 : 40),
                        
                        // Mensaje de error
                        Obx(() {
                          if (controller.errorMessage.value.isNotEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage.value,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        }),
                        
                        // Formulario de login
                        Container(
                          padding: EdgeInsets.all(isTablet ? 32 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: customColors[400]!.withOpacity(0.2),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: controller.formKey,
                            child: Column(
                              children: [
                                // Campo de email
                                TextFormField(
                                  controller: controller.emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: customColors[500],
                                      size: isTablet ? 24 : 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[500]!, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: customColors[50]!.withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, 
                                      vertical: isTablet ? 20 : 16
                                    ),
                                  ),
                                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                                  validator: controller.validateEmail,
                                ),
                                
                                SizedBox(height: isTablet ? 24 : 20),
                                
                                // Campo de contraseña
                                Obx(() => TextFormField(
                                  controller: controller.passwordController,
                                  obscureText: controller.obscurePassword.value,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                                    prefixIcon: Icon(
                                      Icons.lock_outlined,
                                      color: customColors[500],
                                      size: isTablet ? 24 : 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        controller.obscurePassword.value 
                                            ? Icons.visibility_outlined 
                                            : Icons.visibility_off_outlined,
                                        color: customColors[500],
                                        size: isTablet ? 24 : 20,
                                      ),
                                      onPressed: controller.togglePasswordVisibility,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[500]!, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: customColors[50]!.withOpacity(0.5),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, 
                                      vertical: isTablet ? 20 : 16
                                    ),
                                  ),
                                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                                  validator: controller.validatePassword,
                                )),
                                
                                SizedBox(height: isTablet ? 20 : 16),
                                
                                // ¿Olvidaste tu contraseña?
                                
                                
                                SizedBox(height: isTablet ? 32 : 24),
                                
                                // Botón de iniciar sesión
                                Obx(() => SizedBox(
                                  width: double.infinity,
                                  height: isTablet ? 64 : 56,
                                  child: ElevatedButton(
                                    onPressed: controller.isLoading.value ? null : controller.login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: customColors[500],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                    ),
                                    child: controller.isLoading.value
                                        ? SizedBox(
                                            height: isTablet ? 24 : 20,
                                            width: isTablet ? 24 : 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
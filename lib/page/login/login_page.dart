import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Agregado para textInputAction
import 'package:get/get.dart';
import 'package:restaurapp/page/login/LoginController.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final LoginController controller;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Agregados FocusNodes para mejor control del foco
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController(), tag: 'login_controller');
    _setupAnimations();
    
    // Configuración adicional para escritorio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDesktopOptimizations();
    });
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

  void _setupDesktopOptimizations() {
    // Asegurar que el primer campo tenga foco en desktop
    if (Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_emailFocusNode);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
                                  Icons.restaurant,
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
                                // Campo de email - MEJORADO
                                TextFormField(
                                  controller: controller.emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: [AutofillHints.email],
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Correo electrónico',
                                    hintText: 'ejemplo@correo.com',
                                    labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                                    hintStyle: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: customColors[500],
                                      size: isTablet ? 24 : 20,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[500]!, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red, width: 1),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red, width: 2),
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
                                
                                // Campo de contraseña - MEJORADO
                                Obx(() => TextFormField(
                                  controller: controller.passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: controller.obscurePassword.value,
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: [AutofillHints.password],
                                  onFieldSubmitted: (_) {
                                    if (!controller.isLoading.value) {
                                      controller.login();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    hintText: 'Ingresa tu contraseña',
                                    labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
                                    hintStyle: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.grey[400],
                                    ),
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
                                      tooltip: controller.obscurePassword.value 
                                          ? 'Mostrar contraseña' 
                                          : 'Ocultar contraseña',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: customColors[500]!, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red, width: 1),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.red, width: 2),
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
                                
                                // Enlace "¿Olvidaste tu contraseña?"
                               
                                
                                SizedBox(height: isTablet ? 32 : 24),
                                
                                // Botón de iniciar sesión - MEJORADO
                                Obx(() => SizedBox(
                                  width: double.infinity,
                                  height: isTablet ? 64 : 56,
                                  child: ElevatedButton(
                                    onPressed: controller.isLoading.value ? null : () async {
                                      // Ocultar teclado antes de enviar
                                      FocusScope.of(context).unfocus();
                                      await controller.login();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: customColors[500],
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: customColors[300],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: controller.isLoading.value ? 0 : 3,
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
                                
                                // Información adicional para desarrollo/debug
                                if (kDebugMode) ...[
                                  SizedBox(height: 20),
                                  Text(
                                    'Plataforma: ${Theme.of(context).platform}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Información de soporte en desktop
                        if (isTablet) ...[
                          Text(
                            'Usa Tab para navegar entre campos',
                            style: TextStyle(
                              fontSize: 12,
                              color: customColors[600]!.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
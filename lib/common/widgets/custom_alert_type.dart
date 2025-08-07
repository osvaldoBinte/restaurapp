import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:restaurapp/common/theme/Theme_colors.dart';
import 'package:restaurapp/common/widgets/animated_success_check.dart';

enum CustomAlertType { info, confirm, warning, success, error }

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? imagePath;
  final CustomAlertType type;
  final Widget? customWidget;
  // Campos adicionales para el tipo info
  final String? driverName;
  final String? rating;
  final String? carModel;
  final String? licensePlate;
  final int? totalTrips;
  final String? profileImageUrl;
 
  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.imagePath,
    required this.type,
    this.customWidget,
    this.driverName,
    this.rating,
    this.carModel,
    this.licensePlate,
    this.totalTrips,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = MediaQuery.of(context).size.height * 0.85;
          return Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: type == CustomAlertType.info
                ? _buildInfoDialog(context)
                : _buildStandardDialog(context),
          );
        },
      ),
    );
  }

  Widget _buildInfoDialog(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Foto de perfil con calificación
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Text(driverName?.substring(0, 1).toUpperCase() ?? 'U')
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(rating ?? '0.0'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              // Información del conductor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      licensePlate ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${totalTrips ?? 0} viajes',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Información del vehículo
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  imagePath ?? 'assets/images/viajes/taxi.png',
                  width: 100,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    carModel ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primaryColor, 
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onConfirm ?? () => Navigator.of(context).pop(),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStandardDialog(BuildContext context) {
    Color headerColor;
    Widget headerContent;
    
    switch (type) {
      case CustomAlertType.success:
        headerColor = AdminColors.successColor;
        headerContent = const AnimatedSuccessCheck();
        break;
      case CustomAlertType.error:
        headerColor = AdminColors.errorColor;
        headerContent = const AnimatedExclamationMark();
        break;
      case CustomAlertType.warning:
        headerColor = AdminColors.primaryColor;
        headerContent = const AnimatedScanningWaves(); 
        break;
      case CustomAlertType.confirm:
      default:
        headerColor = AdminColors.primaryColor;
        headerContent = const AnimatedExclamationMark();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (no scrolleable)
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(child: headerContent),
          ),
          
          // Contenido (scrolleable)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título y mensaje
                  if (title.isNotEmpty || message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: AdminColors.headingSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: type == CustomAlertType.success
                                    ? AdminColors.successColor
                                    : type == CustomAlertType.error
                                        ? AdminColors.errorColor
                                        : AdminColors.textSecondaryColoralert, // Changed from textTertiaryColor
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (title.isNotEmpty && message.isNotEmpty)
                            const SizedBox(height: 8),
                          if (message.isNotEmpty)
                            Text(
                              message,
                              style: AdminColors.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                    
                  // Widget personalizado
                  if (customWidget != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: customWidget!,
                    ),
                ],
              ),
            ),
          ),
          
          // Botones (no scrolleable)
          if ((confirmText.isNotEmpty || cancelText?.isNotEmpty == true) &&
              customWidget == null)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: _buildButtons(context),
            ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    // Determinar el color del botón según el tipo de alerta
    final buttonColor = type == CustomAlertType.error
        ? AdminColors.errorColor 
        : type == CustomAlertType.success
            ? AdminColors.successColor
            : AdminColors.primaryColor;
        
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (cancelText != null) ...[
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size(0, 40),
                foregroundColor: AdminColors.textSecondaryColor,
              ),
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(
                cancelText!,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              minimumSize: Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onConfirm ?? () => Navigator.of(context).pop(),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedGears extends StatefulWidget {
  const AnimatedGears({Key? key}) : super(key: key);

  @override
  _AnimatedGearsState createState() => _AnimatedGearsState();
}

class _AnimatedGearsState extends State<AnimatedGears>
    with TickerProviderStateMixin {
  late AnimationController _gearController;
  late Animation<double> _gear1Rotation;
  late Animation<double> _gear2Rotation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _gearController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _gear1Rotation = Tween<double>(
      begin: 0,
      end: math.pi * 2,
    ).animate(_gearController);

    // El segundo engranaje gira en dirección opuesta
    _gear2Rotation = Tween<double>(
      begin: 0,
      end: -math.pi * 2,
    ).animate(_gearController);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Engranaje grande
        AnimatedBuilder(
          animation: _gear1Rotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _gear1Rotation.value,
              child: Icon(
                Icons.settings,
                size: 50,
                color: Colors.white.withOpacity(0.9),
              ),
            );
          },
        ),
        // Engranaje pequeño
        Positioned(
          top: -5,
          right: -5,
          child: AnimatedBuilder(
            animation: _gear2Rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _gear2Rotation.value,
                child: Icon(
                  Icons.settings,
                  size: 28,
                  color: Colors.white.withOpacity(0.7),
                ),
              );
            },
          ),
        ),
        // Partículas de trabajo
        ..._buildWorkParticles(),
      ],
    );
  }

  List<Widget> _buildWorkParticles() {
    return List.generate(4, (index) {
      return AnimatedBuilder(
        animation: _gearController,
        builder: (context, child) {
          final progress = (_gearController.value + (index * 0.25)) % 1.0;
          final angle = progress * math.pi * 2;
          final radius = 35.0;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;
          final opacity = math.sin(progress * math.pi);
          
          return Positioned(
            left: x,
            top: y,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellowAccent.withOpacity(0.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _gearController.dispose();
    super.dispose();
  }
}

// 📡 ANIMACIÓN 4: Ondas de Búsqueda/Escaneado
class AnimatedScanningWaves extends StatefulWidget {
  const AnimatedScanningWaves({Key? key}) : super(key: key);

  @override
  _AnimatedScanningWavesState createState() => _AnimatedScanningWavesState();
}

class _AnimatedScanningWavesState extends State<AnimatedScanningWaves>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _scanController;
  late Animation<double> _waveAnimation;
  late Animation<double> _scanAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ondas expansivas
        ...List.generate(3, (index) => _buildWave(index)),
        // Ícono central de radar/búsqueda
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _scanAnimation.value * math.pi * 2,
              child: Icon(
                Icons.radar,
                size: 32,
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWave(int index) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = index * 0.3;
        final progress = (_waveAnimation.value - delay) % 1.0;
        final opacity = (1 - progress).clamp(0.0, 1.0);
        final scale = progress * 3 + 0.5;
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity * 0.6,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _scanController.dispose();
    super.dispose();
  }
}
class ShoppingItem {
  final IconData icon;
  final Color color;
  final Offset offset;

  ShoppingItem({
    required this.icon,
    required this.color,
    required this.offset,
  });
}

class AnimatedExclamationMark extends StatefulWidget {
  const AnimatedExclamationMark({Key? key}) : super(key: key);

  @override
  _AnimatedExclamationMarkState createState() => _AnimatedExclamationMarkState();
}

class _AnimatedExclamationMarkState extends State<AnimatedExclamationMark>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.1)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_mainController);

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white.withOpacity(0.7),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle(
        speed: random.nextDouble() * 2 + 1,
        theta: random.nextDouble() * math.pi * 2,
        radius: random.nextDouble() * 20 + 10,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Particles
        ..._buildParticles(),
        // Main exclamation mark
        AnimatedBuilder(
          animation: Listenable.merge([_mainController, _colorAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Text(
                  '¡',
                  style: TextStyle(
                    color: _colorAnimation.value,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = _particleController.value;
          final opacity = (1 - progress).clamp(0.0, 1.0);
          final scale = (1 - progress * 0.5).clamp(0.0, 1.0);
          
          return Positioned(
            left: math.cos(particle.theta) * particle.radius * progress * 2,
            top: math.sin(particle.theta) * particle.radius * progress * 2,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

class Particle {
  final double speed;
  final double theta;
  final double radius;

  Particle({
    required this.speed,
    required this.theta,
    required this.radius,
  });
}

// Clase SuccessParticle (para la animación de éxito)
class SuccessParticle {
  final Color color;
  final double angle;
  final double distance;
  final double size;
  final double duration;

  SuccessParticle({
    required this.color,
    required this.angle,
    required this.distance,
    required this.size,
    required this.duration,
  });
}

// Nueva animación de check para alertas de éxito
class AnimatedSuccessCheck extends StatefulWidget {
  const AnimatedSuccessCheck({Key? key}) : super(key: key);

  @override
  _AnimatedSuccessCheckState createState() => _AnimatedSuccessCheckState();
}

class _AnimatedSuccessCheckState extends State<AnimatedSuccessCheck>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _circleController;
  late AnimationController _particlesController;
  late Animation<double> _checkAnimation;
  late Animation<double> _circleAnimation;
  late Animation<double> _scaleAnimation;
  final List<SuccessParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Animación del círculo
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );

    // Animación del check
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCubic,
    );

    // Animación de partículas
    _particlesController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animación de escala para efecto de rebote
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_circleController);
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 12; i++) {
      final double angle = i * (math.pi * 2) / 12;
      _particles.add(SuccessParticle(
        color: AdminColors.successColor,
        angle: angle,
        distance: random.nextDouble() * 15 + 25,
        size: random.nextDouble() * 5 + 3,
        duration: random.nextDouble() * 0.3 + 0.7,
      ));
    }
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _checkController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _particlesController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Partículas
          ..._buildParticles(),
          
          // Círculo principal
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AdminColors.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AdminColors.successColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Check mark
          AnimatedBuilder(
            animation: _checkAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(30, 30),
                painter: CheckPainter(
                  progress: _checkAnimation.value,
                  color: Colors.white,
                  strokeWidth: 4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particlesController,
        builder: (context, child) {
          final progress = _particlesController.value;
          final distance = particle.distance * progress;
          final opacity = (1 - progress) * particle.duration;
          
          return Positioned(
            left: 50 + (math.cos(particle.angle) * distance),
            top: 50 + (math.sin(particle.angle) * distance),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  color: particle.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: particle.color.withOpacity(0.5),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _circleController.dispose();
    _particlesController.dispose();
    super.dispose();
  }
}


void showCustomAlert({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    String? imagePath,
    required CustomAlertType type,
    Widget? customWidget,
  }) {
 showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: CustomAlertDialog(
                title: title,
                message: message,
                confirmText: confirmText,
                cancelText: cancelText,
                onConfirm: onConfirm,
                onCancel: onCancel,
                imagePath: imagePath,
                type: type,
                customWidget: customWidget,
              ),
            ),
          ),
        );
      },
    );
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:restaurapp/common/theme/Theme_colors.dart';

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
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );

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

class CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    if (progress < 0.5) {
      final segmentProgress = progress * 2;
      final startPoint = Offset(size.width * 0.25, size.height * 0.5);
      final controlPoint = Offset(
        size.width * 0.25 + (size.width * 0.15 * segmentProgress),
        size.height * 0.5 + (size.height * 0.15 * segmentProgress),
      );
      
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(controlPoint.dx, controlPoint.dy);
    } else {
      path.moveTo(size.width * 0.25, size.height * 0.5);
      path.lineTo(size.width * 0.4, size.height * 0.65);
      
      final segmentProgress = (progress - 0.5) * 2;
      final startPoint = Offset(size.width * 0.4, size.height * 0.65);
      final endPoint = Offset(
        size.width * 0.4 + (size.width * 0.35 * segmentProgress),
        size.height * 0.65 - (size.height * 0.35 * segmentProgress),
      );
      
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(endPoint.dx, endPoint.dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckPainter oldDelegate) => oldDelegate.progress != progress;
}

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
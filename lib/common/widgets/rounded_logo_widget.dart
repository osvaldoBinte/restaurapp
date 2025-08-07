import 'package:flutter/material.dart';

class RoundedLogoWidget extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BoxFit fit;

  const RoundedLogoWidget({
    Key? key,
    required this.height,
    this.width,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.padding,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      constraints: BoxConstraints(
        maxWidth: width ?? MediaQuery.of(context).size.width * 0.7,
        maxHeight: height,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/logo.png',
          fit: fit,
        ),
      ),
    );
  }
}

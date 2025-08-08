import 'dart:convert';
import 'package:flutter/material.dart';

class Base64ImageperfilWidget extends StatelessWidget {
  final String? base64String;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? errorWidget;

  const Base64ImageperfilWidget({
    Key? key,
    required this.base64String,
    this.width = 150,
    this.height = 150,
    this.fit = BoxFit.cover,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no hay imagen, mostrar el widget de error o un icono por defecto
    if (base64String == null || base64String!.isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    try {
      // Procesamos el string para extraer solo la parte base64
      String processedBase64 = base64String!;
      
      // Si el string comienza con 'data:', extraemos solo la parte después de 'base64,'
      if (base64String!.startsWith('data:')) {
        final int startIndex = base64String!.indexOf('base64,');
        if (startIndex != -1) {
          processedBase64 = base64String!.substring(startIndex + 7); // 'base64,'.length = 7
        }
      }
      
      // Intentamos decodificar la imagen base64
      final decodedBytes = base64Decode(processedBase64);
      return Image.memory(
        decodedBytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error al renderizar imagen: $error');
          return errorWidget ?? _defaultErrorWidget();
        },
      );
    } catch (e) {
      // Si hay un error en la decodificación, mostrar el widget de error
      print('❌ Error en Base64ImageperfilWidget: $e');
      return errorWidget ?? _defaultErrorWidget();
    }
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: width / 2,
        color: Colors.grey[600],
      ),
    );
  }
}
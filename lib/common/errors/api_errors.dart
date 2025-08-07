import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class ApiExceptionCustom implements Exception {
  String message;
  final Response? response;
  List<int>? failedProductIds; // ✅ NUEVO: Para almacenar IDs de productos que fallaron

  ApiExceptionCustom({this.message = '', this.response, this.failedProductIds});

  String getMessage(code) {
    switch (code) {
      case 200:
        return "Petición exitosa";
      case 400:
        return "Error de server";
      case 401:
        return "No autorizado";
      case 404:
        return "Recurso no encontrado";
      case 500:
        return "Error interno del servidor";

      default:
        return "Error desconocido";
    }
  }

  void validateMesage() {
    String errorMessage = '';
    if (response != null && response?.statusCode != 500) {
      if (response!.body.toString() != '') {
        final dataUTF8 = utf8.decode(response!.bodyBytes);
        try {
          final body = jsonDecode(dataUTF8);
          if (body is Map<String, dynamic> && body.containsKey('message')) {
            errorMessage = body['message'];
            
            // ✅ NUEVO: Extraer IDs de productos que fallaron
            if (body.containsKey('data') && body['data'] is List) {
              failedProductIds = List<int>.from(body['data']);
              print('🚨 Productos que fallaron: $failedProductIds');
            }
          } else {
            errorMessage = getMessage(response!.statusCode);
          }
        } catch (e) {
          errorMessage = getMessage(response!.statusCode);
        }
      } else {
        errorMessage = getMessage(response!.statusCode);
      }
    } else if (response == null && errorMessage != '') {
      errorMessage = message;
    } else {
      errorMessage = getMessage(response?.statusCode);
    }
    message = errorMessage;
  }

  @override
  String toString() {
    return "ApiException: $message (Status Code: ${response?.statusCode.toString()})";
  }
}

String convertMessageException({required dynamic error}) {
  switch (error) {
    case SocketException:
      return 'Servicio no disponible intente mas tarde';
    case ClientException:
      return 'Conexion Cerrada';
    case TimeoutException:
      return 'La peticion tardo mas  de lo usual, intente de nuevo';
    default:
      return error.toString();
  }
}
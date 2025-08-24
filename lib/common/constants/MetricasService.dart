// metricas_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restaurapp/common/constants/constants.dart';

class MetricasService {
  static Future<Map<String, dynamic>?> obtenerTotalPorCategorias({String? fecha}) async {
    try {
      // Si no se proporciona fecha, usar la fecha actual
      final fechaConsulta = fecha ?? DateTime.now().toString().split(' ')[0];
      
      final url = Uri.parse('${AppConstants.serverBase}/menu/obtenerTotalPorTodasCategorias/?fecha=$fechaConsulta');
      
      print('🔍 Consultando métricas: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      print('📊 Respuesta código: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Datos recibidos: $data');
        return data;
      } else {
        print('❌ Error en la respuesta: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo métricas por categorías: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> obtenerTotalPorCategoriasRango({
    required String fechaInicio,
    required String fechaFin,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.serverBase}/menu/obtenerTotalPorTodasCategorias/?fechaInicio=$fechaInicio&fechaFin=$fechaFin');
      
      print('🔍 Consultando métricas por rango: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Datos de rango recibidos: $data');
        return data;
      } else {
        print('❌ Error en la respuesta del rango: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo métricas por rango: $e');
      return null;
    }
  }
}
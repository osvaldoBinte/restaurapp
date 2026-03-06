// metricas_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:restaurapp/common/constants/constants.dart';

class MetricasService {
  // GET - Listar todas las categorías
  static Future<List<Map<String, dynamic>>?> listarCategorias() async {
    try {
      final url = Uri.parse('${AppConstants.serverBase}/menu/listarCategoriaMetricas/');
      
      print('📋 Listando categorías: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      print('📋 Respuesta código: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final categorias = data.map((item) => item as Map<String, dynamic>).toList();
        print('✅ Categorías recibidas: ${categorias.length}');
        return categorias;
      } else {
        print('❌ Error listando categorías: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error listando categorías: $e');
      return null;
    }
  }

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

  // POST - Crear categoría de métricas
  static Future<Map<String, dynamic>?> crearCategoriaMetricas({
    required String nombreCategoria,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.serverBase}/menu/crearCategoriaMetricas/');
      
      print('📝 Creando categoría de métricas: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombreCategoria': nombreCategoria,
        }),
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      print('📝 Respuesta código: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Categoría creada: $data');
        return data;
      } else {
        print('❌ Error creando categoría: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creando categoría de métricas: $e');
      return null;
    }
  }

  // PUT - Modificar categoría de métricas
  static Future<Map<String, dynamic>?> modificarCategoriaMetricas({
    required int id,
    required String nombreCategoria,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.serverBase}/menu/modificarCategoriaMetricas/$id/');
      
      print('✏️ Modificando categoría de métricas: $url');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombreCategoria': nombreCategoria,
        }),
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      print('✏️ Respuesta código: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Categoría modificada: $data');
        return data;
      } else {
        print('❌ Error modificando categoría: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error modificando categoría de métricas: $e');
      return null;
    }
  }

  // DELETE - Eliminar categoría de métricas
  static Future<bool> eliminarCategoriaMetricas({
    required int id,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.serverBase}/menu/eliminarCategoriaMetricas/$id/');
      
      print('🗑️ Eliminando categoría de métricas: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: AppConstants.requestTimeoutSeconds));

      print('🗑️ Respuesta código: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Categoría eliminada exitosamente');
        return true;
      } else {
        print('❌ Error eliminando categoría: ${response.statusCode}');
        print('❌ Respuesta body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error eliminando categoría de métricas: $e');
      return false;
    }
  }
}
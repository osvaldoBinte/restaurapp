import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VentasController extends GetxController {
  // Variables reactivas
  var isLoading = false.obs;
  var totalVentas = 0.0.obs;
  var fechaInicio = ''.obs;
  var fechaFin = ''.obs;
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Cargar datos automáticamente al inicializar
    obtenerVentasDeHoy();
  }

  /// Obtiene las ventas totales para la fecha actual
  Future<void> obtenerVentasDeHoy() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Obtener fecha actual en formato YYYY-MM-DD
      final hoy = DateTime.now();
      final fechaFormateada = "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('https://tecnologi.icu/restaurante/ordenes/TotalVentasPorFecha/?fecha_inicio=$fechaFormateada&fecha_fin=$fechaFormateada'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Actualizar variables reactivas
        totalVentas.value = data['totalVentas']?.toDouble() ?? 0.0;
        fechaInicio.value = data['fecha_inicio'] ?? fechaFormateada;
        fechaFin.value = data['fecha_fin'] ?? fechaFormateada;
        
        print('✅ Ventas obtenidas correctamente: \$${totalVentas.value}');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      error.value = 'Error al cargar ventas: $e';
      print('❌ Error en obtenerVentasDeHoy: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtiene las ventas para un rango de fechas específico
  Future<void> obtenerVentasPorRango(DateTime inicio, DateTime fin) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Formatear fechas
      final fechaInicioStr = "${inicio.year}-${inicio.month.toString().padLeft(2, '0')}-${inicio.day.toString().padLeft(2, '0')}";
      final fechaFinStr = "${fin.year}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('https://tecnologi.icu/restaurante/ordenes/TotalVentasPorFecha/?fecha_inicio=$fechaInicioStr&fecha_fin=$fechaFinStr'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        totalVentas.value = data['totalVentas']?.toDouble() ?? 0.0;
        fechaInicio.value = data['fecha_inicio'] ?? fechaInicioStr;
        fechaFin.value = data['fecha_fin'] ?? fechaFinStr;
        
        print('✅ Ventas por rango obtenidas: \$${totalVentas.value}');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      error.value = 'Error al cargar ventas por rango: $e';
      print('❌ Error en obtenerVentasPorRango: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresca los datos de ventas del día actual
  Future<void> refrescarVentas() async {
    await obtenerVentasDeHoy();
  }

  /// Getter para obtener el total de ventas formateado
  String get totalVentasFormateado {
    return '\$${totalVentas.value.toStringAsFixed(2)}';
  }

  /// Getter para verificar si hay datos
  bool get tieneDatos {
    return totalVentas.value > 0;
  }
}
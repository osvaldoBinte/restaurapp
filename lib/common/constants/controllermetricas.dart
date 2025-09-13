// metricas_controller.dart - VERSION ACTUALIZADA PARA NUEVA ESTRUCTURA JSON
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurapp/common/constants/MetricasService.dart';

class MetricasController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> categorias = <Map<String, dynamic>>[].obs;
  final RxDouble totalGeneral = 0.0.obs;
  final RxInt cantidadGeneralItems = 0.obs;
  final RxString fechaConsulta = ''.obs;
  
  final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  
  @override
  void onInit() {
    super.onInit();
    // Por defecto usar la fecha de hoy
    fechaConsulta.value = DateTime.now().toString().split(' ')[0];
  }

  Future<void> cargarMetricasPorCategorias({String? fecha}) async {
    try {
      isLoading.value = true;
      error.value = '';
      categorias.clear();
      totalGeneral.value = 0.0;
      cantidadGeneralItems.value = 0;
      
      final fechaConsultar = fecha ?? DateTime.now().toString().split(' ')[0];
      fechaConsulta.value = fechaConsultar;
      
      final response = await MetricasService.obtenerTotalPorCategorias(fecha: fechaConsultar);
      
      print('🔍 Respuesta completa del API: $response'); // Debug
      
      if (response != null) {
        // Extraer totalGeneral directamente
        if (response['totalGeneral'] != null) {
          final totalGeneralData = response['totalGeneral'];
          if (totalGeneralData is Map<String, dynamic>) {
            totalGeneral.value = _parseToDouble(totalGeneralData['total']);
            cantidadGeneralItems.value = _parseToInt(totalGeneralData['cantidad']);
          } else {
            // Si totalGeneral no es un objeto, usar como valor directo
            totalGeneral.value = _parseToDouble(totalGeneralData);
          }
          print('📊 Total desde totalGeneral: ${totalGeneral.value}, Items: ${cantidadGeneralItems.value}');
        }
        
        // Procesar categorías con nueva estructura
        final categoriasTemporales = <Map<String, dynamic>>[];
        
        // Excluir totalGeneral del procesamiento de categorías
        final categoryKeys = response.keys.where((key) => key != 'totalGeneral').toList();
        
        for (String categoryKey in categoryKeys) {
          final categoryData = response[categoryKey];
          
          if (categoryData is Map<String, dynamic>) {
            // Nueva estructura: cada categoría es un objeto con total y cantidad
            final total = _parseToDouble(categoryData['total']);
            final cantidad = _parseToInt(categoryData['cantidad']);
            
            // Solo agregar categorías que tengan datos
            if (total > 0 || cantidad > 0) {
              categoriasTemporales.add({
                'categoria': _formatearNombreCategoria(categoryKey),
                'total': total,
                'cantidad': cantidad,
                'clave': categoryKey, // Mantener la clave original para referencia
              });
            }
          }
        }
        
        // Ordenar categorías por total (descendente)
        categoriasTemporales.sort((a, b) => 
          _parseToDouble(b['total']).compareTo(_parseToDouble(a['total']))
        );
        
        categorias.value = categoriasTemporales;
        
        // Verificar consistencia de datos
        final totalCalculado = categorias.fold(0.0, (sum, cat) => 
          sum + _parseToDouble(cat['total'])
        );
        
        final cantidadCalculada = categorias.fold(0, (sum, cat) => 
          sum + _parseToInt(cat['cantidad'])
        );
        
        print('📋 Categorías procesadas: ${categorias.length}');
        print('💰 Total API: ${totalGeneral.value}, Total calculado: $totalCalculado');
        print('📦 Cantidad API: ${cantidadGeneralItems.value}, Cantidad calculada: $cantidadCalculada');
        
        // Si hay discrepancia, usar valores calculados
        if ((totalGeneral.value - totalCalculado).abs() > 0.01) {
          print('⚠️ Discrepancia en totales, usando valor calculado');
          totalGeneral.value = totalCalculado;
        }
        
        if (cantidadGeneralItems.value != cantidadCalculada) {
          print('⚠️ Discrepancia en cantidades, usando valor calculado');
          cantidadGeneralItems.value = cantidadCalculada;
        }
        
      } else {
        error.value = 'No se pudieron obtener las métricas';
      }
      
    } catch (e) {
      error.value = 'Error al cargar métricas: ${e.toString()}';
      print('❌ Error en cargarMetricasPorCategorias: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Nuevo método para formatear nombres de categorías
  String _formatearNombreCategoria(String categoria) {
    final mapeoNombres = {
      'menuPrincipal': 'Menú Principal',
      'desechables': 'Desechables',
      'pan': 'Pan',
      'extras': 'Extras',
      'bebidas': 'Bebidas',
      'cafe': 'Café',
      'postres': 'Postres',
    };
    
    return mapeoNombres[categoria] ?? categoria.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Método auxiliar para parsear a double de forma segura
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Limpiar formato de moneda si existe
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // Método auxiliar para parsear a int de forma segura
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  String get totalGeneralFormateado {
    print('💰 Formateando total: ${totalGeneral.value}'); // Debug
    return formatoMoneda.format(totalGeneral.value);
  }
  
  String formatearMonto(dynamic monto) {
    final valor = _parseToDouble(monto);
    return formatoMoneda.format(valor);
  }

  String get fechaFormateada {
    try {
      final fecha = DateTime.parse(fechaConsulta.value);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return fechaConsulta.value;
    }
  }

  // Métodos para manejo de fechas (sin cambios)
  void refrescarMetricas() {
    cargarMetricasPorCategorias(fecha: fechaConsulta.value);
  }

  Future<void> cambiarFecha(DateTime nuevaFecha) async {
    final fechaString = nuevaFecha.toString().split(' ')[0];
    await cargarMetricasPorCategorias(fecha: fechaString);
  }

  Future<void> irAHoy() async {
    await cambiarFecha(DateTime.now());
  }

  Future<void> navegarFecha(int dias) async {
    final fechaActual = DateTime.parse(fechaConsulta.value);
    final nuevaFecha = fechaActual.add(Duration(days: dias));
    
    // No permitir fechas futuras más allá de hoy
    if (nuevaFecha.isAfter(DateTime.now())) {
      Get.snackbar(
        'Fecha no válida',
        'No puedes consultar fechas futuras',
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange[800],
        icon: Icon(Icons.warning, color: Colors.orange),
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    await cambiarFecha(nuevaFecha);
  }

  String get etiquetaFecha {
    final fechaConsulta = DateTime.parse(this.fechaConsulta.value);
    final hoy = DateTime.now();
    final ayer = hoy.subtract(Duration(days: 1));
    
    // Normalizar fechas (solo día, mes, año)
    final fechaConsultaNorm = DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day);
    final hoyNorm = DateTime(hoy.year, hoy.month, hoy.day);
    final ayerNorm = DateTime(ayer.year, ayer.month, ayer.day);
    
    if (fechaConsultaNorm == hoyNorm) {
      return 'Hoy';
    } else if (fechaConsultaNorm == ayerNorm) {
      return 'Ayer';
    } else {
      final diferencia = hoyNorm.difference(fechaConsultaNorm).inDays;
      if (diferencia > 0) {
        return diferencia == 1 ? 'Ayer' : 'Hace $diferencia días';
      } else {
        return 'En ${diferencia.abs()} días';
      }
    }
  }

  bool get esHoy {
    final fechaConsulta = DateTime.parse(this.fechaConsulta.value);
    final hoy = DateTime.now();
    return fechaConsulta.year == hoy.year && 
           fechaConsulta.month == hoy.month && 
           fechaConsulta.day == hoy.day;
  }

  bool get puedeIrSiguiente {
    final fechaConsulta = DateTime.parse(this.fechaConsulta.value);
    final manana = fechaConsulta.add(Duration(days: 1));
    return manana.isBefore(DateTime.now()) || _esMismaFecha(manana, DateTime.now());
  }

  bool _esMismaFecha(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year && 
           fecha1.month == fecha2.month && 
           fecha1.day == fecha2.day;
  }

  List<Map<String, dynamic>> get fechasRapidas {
    final hoy = DateTime.now();
    final fechas = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 7; i++) {
      final fecha = hoy.subtract(Duration(days: i));
      fechas.add({
        'fecha': fecha,
        'label': i == 0 ? 'Hoy' : (i == 1 ? 'Ayer' : DateFormat('dd/MM').format(fecha)),
        'esSeleccionada': _esMismaFecha(fecha, DateTime.parse(fechaConsulta.value)),
      });
    }
    
    return fechas;
  }

  Future<void> establecerFecha(String fechaString) async {
    try {
      final fecha = DateTime.parse(fechaString);
      await cambiarFecha(fecha);
    } catch (e) {
      print('❌ Error al establecer fecha: $e');
      Get.snackbar(
        'Error',
        'Formato de fecha inválido',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[800],
        icon: Icon(Icons.error, color: Colors.red),
      );
    }
  }

  // Nuevo método para obtener información adicional de una categoría
  Map<String, dynamic>? obtenerDetalleCategoria(String clave) {
    return categorias.firstWhereOrNull((cat) => cat['clave'] == clave);
  }

  // Nuevo método para obtener el porcentaje de una categoría
  double obtenerPorcentajeCategoria(String clave) {
    final categoria = obtenerDetalleCategoria(clave);
    if (categoria == null || totalGeneral.value == 0) return 0.0;
    
    final totalCategoria = _parseToDouble(categoria['total']);
    return (totalCategoria / totalGeneral.value) * 100;
  }

  // Método para obtener las categorías más importantes (top 3)
  List<Map<String, dynamic>> get categoriasTop3 {
    if (categorias.length <= 3) return categorias.toList();
    return categorias.take(3).toList();
  }

  // Método para verificar si hay datos
  bool get tieneDatos {
    return categorias.isNotEmpty && totalGeneral.value > 0;
  }
}
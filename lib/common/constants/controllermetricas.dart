// metricas_controller.dart - CORREGIDO
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurapp/common/constants/MetricasService.dart';

class MetricasController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> categorias = <Map<String, dynamic>>[].obs;
  final RxDouble totalGeneral = 0.0.obs;
  final RxString fechaConsulta = ''.obs;
  
  final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  
  @override
  void onInit() {
    super.onInit();
    fechaConsulta.value = DateTime.now().toString().split(' ')[0];
  }


  Future<void> cargarMetricasPorCategorias({String? fecha}) async {
    try {
      isLoading.value = true;
      error.value = '';
      categorias.clear();
      totalGeneral.value = 0.0;
      
      final fechaConsultar = fecha ?? DateTime.now().toString().split(' ')[0];
      fechaConsulta.value = fechaConsultar;
      
      final response = await MetricasService.obtenerTotalPorCategorias(fecha: fechaConsultar);
      
      print('🔍 Respuesta completa del API: $response'); // Debug
      
      if (response != null) {
        // 🆕 LÓGICA CORREGIDA - Prioritizar totalGeneral de la respuesta
        if (response['totalGeneral'] != null) {
          totalGeneral.value = _parseToDouble(response['totalGeneral']);
          print('📊 Total desde totalGeneral: ${totalGeneral.value}');
        } else if (response['total'] != null) {
          totalGeneral.value = _parseToDouble(response['total']);
          print('📊 Total desde total: ${totalGeneral.value}');
        }
        
        // Procesar categorías
        if (response['categorias'] != null) {
          categorias.value = List<Map<String, dynamic>>.from(response['categorias']);
        } else if (response['data'] != null) {
          categorias.value = List<Map<String, dynamic>>.from(response['data']);
        } else if (response is List) {
          categorias.value = List<Map<String, dynamic>>.from(response as Iterable);
        } else {
          // 🆕 EXTRACCIÓN MEJORADA - Excluir campos de totales
          final keys = response.keys.where((key) => 
            key != 'total' && 
            key != 'totalGeneral' && 
            key != 'fecha' && 
            !key.endsWith('_cantidad')
          ).toList();
          
          print('🔑 Categorías encontradas: $keys'); // Debug
          
          categorias.value = keys.map((key) => {
            'categoria': key,
            'total': _parseToDouble(response[key]),
            'cantidad': _parseToInt(response[key + '_cantidad']),
          }).toList();
        }
        
        // 🆕 Solo calcular total si no viene en la respuesta
        if (totalGeneral.value == 0.0 && categorias.isNotEmpty) {
          totalGeneral.value = categorias.fold(0.0, (sum, cat) => 
            sum + _parseToDouble(cat['total'])
          );
          print('📊 Total calculado desde categorías: ${totalGeneral.value}');
        }
        
        print('📋 Categorías procesadas: ${categorias.length}');
        print('💰 Total final: ${totalGeneral.value}');
        
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

  // 🆕 Método auxiliar para parsear a double de forma segura
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

  // 🆕 Método auxiliar para parsear a int de forma segura
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

  void refrescarMetricas() {
    cargarMetricasPorCategorias(fecha: fechaConsulta.value);
  }

  Future<void> cambiarFecha(DateTime nuevaFecha) async {
    final fechaString = nuevaFecha.toString().split(' ')[0];
    await cargarMetricasPorCategorias(fecha: fechaString);
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:restaurapp/common/constants/constants.dart';

// Modelos para las métricas del dashboard
class DashboardStats {
  final int ordenesPendientes;
  final int ordenesCompletadas;
  final int mesasOcupadas;
  final int mesasDisponibles;
  final double ventasHoy;
  final double ventasMes;
  final int clientesHoy;
  final int productosVendidos;

  DashboardStats({
    required this.ordenesPendientes,
    required this.ordenesCompletadas,
    required this.mesasOcupadas,
    required this.mesasDisponibles,
    required this.ventasHoy,
    required this.ventasMes,
    required this.clientesHoy,
    required this.productosVendidos,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      ordenesPendientes: 0,
      ordenesCompletadas: 0,
      mesasOcupadas: 0,
      mesasDisponibles: 0,
      ventasHoy: 0.0,
      ventasMes: 0.0,
      clientesHoy: 0,
      productosVendidos: 0,
    );
  }
}

class VentaDiaria {
  final DateTime fecha;
  final double total;
  final int ordenes;

  VentaDiaria({
    required this.fecha,
    required this.total,
    required this.ordenes,
  });
}

class ProductoPopular {
  final String nombre;
  final int cantidadVendida;
  final double ingresos;
  final String categoria;

  ProductoPopular({
    required this.nombre,
    required this.cantidadVendida,
    required this.ingresos,
    required this.categoria,
  });
}

class OrdenReciente {
  final int id;
  final String nombreOrden;
  final int numeroMesa;
  final String status;
  final DateTime fecha;
  final double total;
  final int cantidadItems;

  OrdenReciente({
    required this.id,
    required this.nombreOrden,
    required this.numeroMesa,
    required this.status,
    required this.fecha,
    required this.total,
    required this.cantidadItems,
  });
}

/// Controller específico para el Dashboard
class DashboardController extends GetxController {
  // Estados de carga
  var isLoading = false.obs;
  var isLoadingStats = false.obs;
  var isLoadingCharts = false.obs;
  var isLoadingRecientes = false.obs;

  // Datos del dashboard
  var dashboardStats = DashboardStats.empty().obs;
  var ventasSemanales = <VentaDiaria>[].obs;
  var productosPopulares = <ProductoPopular>[].obs;
  var ordenesRecientes = <OrdenReciente>[].obs;
  
  // Configuraciones
  var selectedTimeRange = 'Hoy'.obs; // 'Hoy', 'Semana', 'Mes'
  var autoRefreshEnabled = true.obs;
  
  String defaultApiServer = AppConstants.serverBase;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    cargarDatosDashboard();
    
    // Iniciar auto-refresh si está habilitado
    if (autoRefreshEnabled.value) {
      _startAutoRefresh();
    }
  }

  /// Iniciar actualización automática cada 30 segundos
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!Get.isRegistered<DashboardController>()) {
        timer.cancel();
        return;
      }
      if (autoRefreshEnabled.value) {
        refrescarStats();
      }
    });
  }

  /// Detener auto-refresh
  void stopAutoRefresh() {
    autoRefreshEnabled.value = false;
    _refreshTimer?.cancel();
  }

  /// Reanudar auto-refresh
  void resumeAutoRefresh() {
    autoRefreshEnabled.value = true;
    _startAutoRefresh();
  }

  /// Cargar todos los datos del dashboard
  Future<void> cargarDatosDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([
        obtenerEstadisticas(),
        obtenerVentasSemanales(),
        obtenerProductosPopulares(),
        obtenerOrdenesRecientes(),
      ]);
    } catch (e) {
      _showError('Error al cargar dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener estadísticas generales
  Future<void> obtenerEstadisticas() async {
    try {
      isLoadingStats.value = true;
      
      // Simular delay de red
      await Future.delayed(Duration(milliseconds: 800));
      
      // TODO: Reemplazar con llamada real a la API
      // Uri uri = Uri.parse('$defaultApiServer/dashboard/estadisticas/');
      // final response = await http.get(uri, headers: {...});
      
      // Datos simulados más realistas
      dashboardStats.value = DashboardStats(
        ordenesPendientes: _generateRandomInRange(8, 15),
        ordenesCompletadas: _generateRandomInRange(35, 60),
        mesasOcupadas: _generateRandomInRange(5, 12),
        mesasDisponibles: _generateRandomInRange(8, 15),
        ventasHoy: _generateRandomDouble(1800.0, 3200.0),
        ventasMes: _generateRandomDouble(40000.0, 65000.0),
        clientesHoy: _generateRandomInRange(18, 35),
        productosVendidos: _generateRandomInRange(70, 120),
      );
      
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      _showError('Error al cargar estadísticas');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Obtener ventas de la última semana
  Future<void> obtenerVentasSemanales() async {
    try {
      isLoadingCharts.value = true;
      
      await Future.delayed(Duration(milliseconds: 600));
      
      // Generar datos más realistas para la semana
      final now = DateTime.now();
      ventasSemanales.value = List.generate(7, (index) {
        final fecha = now.subtract(Duration(days: 6 - index));
        final baseAmount = 1200.0;
        final variation = (index % 3) * 400.0 + (index * 150.0);
        final weekendBonus = (fecha.weekday >= 6) ? 600.0 : 0.0;
        
        return VentaDiaria(
          fecha: fecha,
          total: baseAmount + variation + weekendBonus + _generateRandomDouble(-200, 200),
          ordenes: 6 + (index * 2) + (fecha.weekday >= 6 ? 4 : 0) + _generateRandomInRange(-2, 3),
        );
      });
      
    } catch (e) {
      print('Error al obtener ventas semanales: $e');
      _showError('Error al cargar gráfica de ventas');
    } finally {
      isLoadingCharts.value = false;
    }
  }

  /// Obtener productos más vendidos
  Future<void> obtenerProductosPopulares() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      final productosEjemplo = [
        ProductoPopular(nombre: 'Quesadilla de Pastor', cantidadVendida: _generateRandomInRange(35, 55), ingresos: 0, categoria: 'Quesadillas'),
        ProductoPopular(nombre: 'Agua de Horchata', cantidadVendida: _generateRandomInRange(25, 40), ingresos: 0, categoria: 'Bebidas'),
        ProductoPopular(nombre: 'Quesadilla Combinada', cantidadVendida: _generateRandomInRange(20, 35), ingresos: 0, categoria: 'Quesadillas'),
        ProductoPopular(nombre: 'Café con Leche', cantidadVendida: _generateRandomInRange(15, 30), ingresos: 0, categoria: 'Bebidas'),
        ProductoPopular(nombre: 'Flan Napolitano', cantidadVendida: _generateRandomInRange(12, 25), ingresos: 0, categoria: 'Postres'),
        ProductoPopular(nombre: 'Quesadilla de Pollo', cantidadVendida: _generateRandomInRange(18, 28), ingresos: 0, categoria: 'Quesadillas'),
        ProductoPopular(nombre: 'Agua de Jamaica', cantidadVendida: _generateRandomInRange(20, 32), ingresos: 0, categoria: 'Bebidas'),
      ];

      // Calcular ingresos basados en precios estimados
      productosPopulares.value = productosEjemplo.map((producto) {
        double precioUnitario;
        switch (producto.categoria.toLowerCase()) {
          case 'quesadillas':
            precioUnitario = 55.0;
            break;
          case 'bebidas':
            precioUnitario = 25.0;
            break;
          case 'postres':
            precioUnitario = 35.0;
            break;
          default:
            precioUnitario = 40.0;
        }
        
        return ProductoPopular(
          nombre: producto.nombre,
          cantidadVendida: producto.cantidadVendida,
          ingresos: producto.cantidadVendida * precioUnitario,
          categoria: producto.categoria,
        );
      }).toList();

      // Ordenar por cantidad vendida
      productosPopulares.sort((a, b) => b.cantidadVendida.compareTo(a.cantidadVendida));
      
    } catch (e) {
      print('Error al obtener productos populares: $e');
      _showError('Error al cargar productos populares');
    }
  }

  /// Obtener órdenes recientes
  Future<void> obtenerOrdenesRecientes() async {
    try {
      isLoadingRecientes.value = true;
      
      await Future.delayed(Duration(milliseconds: 400));
      
      final now = DateTime.now();
      final statusOptions = ['pendiente', 'preparando', 'listo', 'entregado'];
      
      ordenesRecientes.value = List.generate(8, (index) {
        final minutosAtras = (index + 1) * 7 + _generateRandomInRange(0, 10);
        return OrdenReciente(
          id: 200 - index,
          nombreOrden: 'Orden Mesa ${_generateRandomInRange(1, 12)}',
          numeroMesa: _generateRandomInRange(1, 12),
          status: statusOptions[_generateRandomInRange(0, statusOptions.length - 1)],
          fecha: now.subtract(Duration(minutes: minutosAtras)),
          total: _generateRandomDouble(85.0, 280.0),
          cantidadItems: _generateRandomInRange(1, 6),
        );
      });
      
    } catch (e) {
      print('Error al obtener órdenes recientes: $e');
      _showError('Error al cargar órdenes recientes');
    } finally {
      isLoadingRecientes.value = false;
    }
  }

  /// Cambiar rango de tiempo y recargar datos
  void cambiarRangoTiempo(String rango) {
    if (selectedTimeRange.value != rango) {
      selectedTimeRange.value = rango;
      // Recargar datos según el nuevo rango
      Future.wait([
        obtenerEstadisticas(),
        obtenerVentasSemanales(),
      ]);
    }
  }

  /// Refrescar solo las estadísticas (para auto-refresh)
  Future<void> refrescarStats() async {
    try {
      await Future.wait([
        obtenerEstadisticas(),
        obtenerOrdenesRecientes(),
      ]);
    } catch (e) {
      print('Error en auto-refresh: $e');
    }
  }

  /// Refrescar todos los datos manualmente
  Future<void> refrescarTodo() async {
    await cargarDatosDashboard();
    Get.snackbar(
      'Actualizado',
      'Dashboard actualizado correctamente',
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 2),
      backgroundColor: Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  // Métodos de utilidad (mantener del código original)
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Color(0xFFFF9800);
      case 'preparando':
        return Color(0xFF2196F3);
      case 'listo':
        return Color(0xFF4CAF50);
      case 'entregado':
        return Color(0xFF9E9E9E);
      default:
        return Color(0xFF8B4513);
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Icons.access_time;
      case 'preparando':
        return Icons.restaurant;
      case 'listo':
        return Icons.check_circle;
      case 'entregado':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  String formatearTiempoRelativo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    
    if (diff.inMinutes < 1) {
      return 'Ahora';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else {
      return 'Hace ${diff.inDays}d';
    }
  }

  // Propiedades calculadas
  double get porcentajeMesasOcupadas {
    final total = dashboardStats.value.mesasOcupadas + dashboardStats.value.mesasDisponibles;
    if (total == 0) return 0.0;
    return (dashboardStats.value.mesasOcupadas / total) * 100;
  }

  double get eficienciaOrdenes {
    final total = dashboardStats.value.ordenesPendientes + dashboardStats.value.ordenesCompletadas;
    if (total == 0) return 0.0;
    return (dashboardStats.value.ordenesCompletadas / total) * 100;
  }

  // Métodos de utilidad privados
  int _generateRandomInRange(int min, int max) {
    return min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1));
  }

  double _generateRandomDouble(double min, double max) {
    final random = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
    return min + (random * (max - min));
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[600],
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
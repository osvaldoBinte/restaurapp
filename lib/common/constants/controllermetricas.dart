// metricas_controller.dart - VERSION CON GESTIÓN DE CATEGORÍAS Y LISTADO
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurapp/common/constants/MetricasService.dart';
import 'package:restaurapp/common/theme/Theme_colors.dart';
import 'package:restaurapp/common/widgets/custom_alert_type.dart';

class MetricasController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> categorias = <Map<String, dynamic>>[].obs;
  final RxDouble totalGeneral = 0.0.obs;
  final RxInt cantidadGeneralItems = 0.obs;
  final RxString fechaConsulta = ''.obs;
  
  // Propiedades para gestión de categorías
  final RxBool isLoadingCategoria = false.obs;
  final RxString errorCategoria = ''.obs;
  final RxBool mostrarListaCategorias = false.obs; // false = métricas, true = lista categorías

  // 🆕 Nueva propiedad para lista de categorías del menú
  final RxList<Map<String, dynamic>> listaCategorias = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingListaCategorias = false.obs;
  
  final formatoMoneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  
  @override
  void onInit() {
    super.onInit();
    // Por defecto usar la fecha de hoy
    fechaConsulta.value = DateTime.now().toString().split(' ')[0];
    // Cargar lista de categorías al iniciar
    cargarListaCategorias();
  }

  // ============================================================
  // 🆕 NUEVO MÉTODO PARA LISTAR CATEGORÍAS
  // ============================================================

  /// Cargar la lista de categorías del menú
  Future<void> cargarListaCategorias() async {
    try {
      isLoadingListaCategorias.value = true;
      
      print('📋 Cargando lista de categorías del menú...');
      
      final categorias = await MetricasService.listarCategorias();
      
      if (categorias != null) {
        listaCategorias.value = categorias;
        print('✅ Categorías cargadas: ${categorias.length}');
        
        // Imprimir detalles de cada categoría
        for (var cat in categorias) {
          print('  📦 ${cat['nombreCategoria']} (ID: ${cat['id']}, Status: ${cat['status']})');
        }
      } else {
        print('❌ No se pudieron cargar las categorías');
        listaCategorias.clear();
      }
    } catch (e) {
      print('❌ Error al cargar lista de categorías: $e');
      listaCategorias.clear();
    } finally {
      isLoadingListaCategorias.value = false;
    }
  }

  /// Obtener solo categorías activas
  List<Map<String, dynamic>> get categoriasActivas {
    return listaCategorias.where((cat) => cat['status'] == true).toList();
  }

  /// Obtener nombres de categorías activas
  List<String> get nombresCategoriasActivas {
    return categoriasActivas
        .map((cat) => cat['nombreCategoria'] as String)
        .toList();
  }

  /// Buscar categoría por ID
  Map<String, dynamic>? obtenerCategoriaPorId(int id) {
    try {
      return listaCategorias.firstWhere((cat) => cat['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Buscar categoría por nombre
  Map<String, dynamic>? obtenerCategoriaPorNombre(String nombre) {
    try {
      return listaCategorias.firstWhere(
        (cat) => cat['nombreCategoria'].toString().toLowerCase() == nombre.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // MÉTODOS PARA GESTIÓN DE CATEGORÍAS (ACTUALIZADOS)
  // ============================================================

  /// Crear una nueva categoría de métricas
  Future<bool> crearCategoria({
    required String nombreCategoria,
  }) async {
    try {
      isLoadingCategoria.value = true;
      errorCategoria.value = '';
      
      print('📝 Creando categoría: $nombreCategoria');
      
      final response = await MetricasService.crearCategoriaMetricas(
        nombreCategoria: nombreCategoria,
      );
      
      if (response != null) {
        Get.snackbar(
          'Éxito',
          'Categoría "$nombreCategoria" creada correctamente',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green[800],
          icon: Icon(Icons.check_circle, color: Colors.green),
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
        
        // Recargar tanto métricas como la lista de categorías
        await cargarListaCategorias();
        refrescarMetricas();
        return true;
      } else {
        errorCategoria.value = 'No se pudo crear la categoría';
        _mostrarErrorCategoria('No se pudo crear la categoría');
        return false;
      }
    } catch (e) {
      errorCategoria.value = 'Error al crear categoría: ${e.toString()}';
      print('❌ Error en crearCategoria: $e');
      _mostrarErrorCategoria('Error al crear la categoría');
      return false;
    } finally {
      isLoadingCategoria.value = false;
    }
  }

  /// Modificar una categoría existente
  Future<bool> modificarCategoria({
    required int id,
    required String nombreCategoria,
  }) async {
    try {
      isLoadingCategoria.value = true;
      errorCategoria.value = '';
      
      print('✏️ Modificando categoría ID $id: $nombreCategoria');
      
      final response = await MetricasService.modificarCategoriaMetricas(
        id: id,
        nombreCategoria: nombreCategoria,
      );
      
      if (response != null) {
        Get.snackbar(
          'Éxito',
          'Categoría modificada correctamente',
          backgroundColor: Colors.blue.withOpacity(0.1),
          colorText: Colors.blue[800],
          icon: Icon(Icons.edit, color: Colors.blue),
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
        
        // Recargar tanto métricas como la lista de categorías
        await cargarListaCategorias();
        refrescarMetricas();
        return true;
      } else {
        errorCategoria.value = 'No se pudo modificar la categoría';
        _mostrarErrorCategoria('No se pudo modificar la categoría');
        return false;
      }
    } catch (e) {
      errorCategoria.value = 'Error al modificar categoría: ${e.toString()}';
      print('❌ Error en modificarCategoria: $e');
      _mostrarErrorCategoria('Error al modificar la categoría');
      return false;
    } finally {
      isLoadingCategoria.value = false;
    }
  }
/// Eliminar una categoría
Future<bool> eliminarCategoria({
  required int id,
  required String nombreCategoria,
}) async {
  try {
    // Variable para capturar la confirmación
    bool confirmar = false;
    
    // Confirmación antes de eliminar usando showCustomAlert
    showCustomAlert(
      context: Get.context!,
      title: 'Confirmar eliminación',
      message: '¿Estás seguro de eliminar la categoría "$nombreCategoria"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      type: CustomAlertType.warning,
      onConfirm: () async {
        confirmar = true;
        Navigator.of(Get.context!).pop();
        
        // ✅ EJECUTAR LA ELIMINACIÓN AQUÍ DENTRO DEL onConfirm
        isLoadingCategoria.value = true;
        errorCategoria.value = '';
        
        print('🗑️ Eliminando categoría ID $id');
        
        final eliminado = await MetricasService.eliminarCategoriaMetricas(id: id);
        
        if (eliminado) {
          Get.snackbar(
            'Éxito',
            'Categoría "$nombreCategoria" eliminada correctamente',
            backgroundColor: Colors.orange.withOpacity(0.1),
            colorText: Colors.orange[800],
            icon: Icon(Icons.delete, color: Colors.orange),
            duration: Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
          );
          
          // Recargar tanto métricas como la lista de categorías
          await cargarListaCategorias();
          refrescarMetricas();
        } else {
          errorCategoria.value = 'No se pudo eliminar la categoría';
          _mostrarErrorCategoria('No se pudo eliminar la categoría');
        }
        
        isLoadingCategoria.value = false;
      },
      onCancel: () {
        confirmar = false;
        Navigator.of(Get.context!).pop();
        print('🚫 Eliminación cancelada por el usuario');
      },
    );
    
    return confirmar;
    
  } catch (e) {
    errorCategoria.value = 'Error al eliminar categoría: ${e.toString()}';
    print('❌ Error en eliminarCategoria: $e');
    _mostrarErrorCategoria('Error al eliminar la categoría');
    return false;
  }
}
  Future<void> mostrarDialogoCrearCategoria() async {
    final TextEditingController nombreController = TextEditingController();
    
    // Resetear el estado antes de abrir el diálogo
    isLoadingCategoria.value = false;
    errorCategoria.value = '';
    
    showCustomAlert(
      context: Get.context!,
      title: 'Crear Nueva Métrica',
      message: '',
      confirmText: 'Guardar',
      cancelText: 'Cancelar',
      type: CustomAlertType.confirm,
      customWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre de la métrica',
              hintText: 'Ej: Ventas, Clientes, etc.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          SizedBox(height: 16),
          // Botones personalizados
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                   // nombreController.dispose();
                    Navigator.of(Get.context!).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoadingCategoria.value
                      ? null
                      : () async {
                          final nombre = nombreController.text.trim();
                          if (nombre.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'El nombre de la categoría no puede estar vacío',
                              backgroundColor: Colors.red.withOpacity(0.1),
                              colorText: Colors.red[800],
                              icon: Icon(Icons.error, color: Colors.red),
                              snackPosition: SnackPosition.BOTTOM,
                              duration: Duration(seconds: 2),
                            );
                            return;
                          }
                          
                          print('---------- Intentando crear categoría con nombre "$nombre"');
                          final creado = await crearCategoria(nombreCategoria: nombre);
                          print('---------- Resultado de creación: $creado');
                          
                          if (creado) {
                           // nombreController.dispose();
                            Navigator.of(Get.context!).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryColor,
                    minimumSize: Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoadingCategoria.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Guardar',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                ),
              ),
            ],
          )),
        ],
      ),
      onConfirm: null,
      onCancel: null,
    );
  }

  /// Mostrar diálogo para modificar categoría
  Future<void> mostrarDialogoModificarCategoria({
    required int id,
    required String nombreActual,
  }) async {
    final TextEditingController nombreController = TextEditingController(
      text: nombreActual,
    );
    
    // Resetear el estado antes de abrir el diálogo
    isLoadingCategoria.value = false;
    errorCategoria.value = '';
    
    showCustomAlert(
      context: Get.context!,
      title: 'Modificar Métrica',
      message: '',
      confirmText: 'Guardar',
      cancelText: 'Cancelar',
      type: CustomAlertType.confirm,
      customWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre de la métrica',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          SizedBox(height: 16),
          // Botones personalizados
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                 //   nombreController.dispose();
                    Navigator.of(Get.context!).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoadingCategoria.value
                      ? null
                      : () async {
                          final nombre = nombreController.text.trim();
                          if (nombre.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'El nombre de la categoría no puede estar vacío',
                              backgroundColor: Colors.red.withOpacity(0.1),
                              colorText: Colors.red[800],
                              icon: Icon(Icons.error, color: Colors.red),
                              snackPosition: SnackPosition.BOTTOM,
                              duration: Duration(seconds: 2),
                            );
                            return;
                          }
                          
                          if (nombre == nombreActual) {
                            Get.snackbar(
                              'Sin cambios',
                              'El nombre no ha cambiado',
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              colorText: Colors.orange[800],
                              icon: Icon(Icons.info, color: Colors.orange),
                              snackPosition: SnackPosition.BOTTOM,
                              duration: Duration(seconds: 2),
                            );
                      //      nombreController.dispose();
                            Navigator.of(Get.context!).pop();
                            return;
                          }
                          
                          print('---------- Intentando modificar categoría con ID $id y nombre "$nombre"');
                          final modificado = await modificarCategoria(
                            id: id,
                            nombreCategoria: nombre,
                          );
                          print('---------- Resultado de modificación: $modificado');
                          
                          if (modificado) {
                         //   nombreController.dispose();
                            Navigator.of(Get.context!).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primaryColor,
                    minimumSize: Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoadingCategoria.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Guardar',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                ),
              ),
            ],
          )),
        ],
      ),
      onConfirm: null,
      onCancel: null,
    );
  }

  void _mostrarErrorCategoria(String mensaje) {
    Get.snackbar(
      'Error',
      mensaje,
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red[800],
      icon: Icon(Icons.error, color: Colors.red),
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  // ============================================================
  // MÉTODOS ORIGINALES (sin cambios)
  // ============================================================
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
      
      print('🔍 Respuesta completa del API: $response');
      
      if (response != null) {
        if (response['totalGeneral'] != null) {
          final totalGeneralData = response['totalGeneral'];
          if (totalGeneralData is Map<String, dynamic>) {
            totalGeneral.value = _parseToDouble(totalGeneralData['total']);
            cantidadGeneralItems.value = _parseToInt(totalGeneralData['cantidad']);
          } else {
            totalGeneral.value = _parseToDouble(totalGeneralData);
          }
          print('📊 Total desde totalGeneral: ${totalGeneral.value}, Items: ${cantidadGeneralItems.value}');
        }
        
        final categoriasTemporales = <Map<String, dynamic>>[];
        final categoryKeys = response.keys.where((key) => key != 'totalGeneral').toList();
        
        for (String categoryKey in categoryKeys) {
          final categoryData = response[categoryKey];
          
          if (categoryData is Map<String, dynamic>) {
            final total = _parseToDouble(categoryData['total']);
            final cantidad = _parseToInt(categoryData['cantidad']);
            
            final categoriaId = _parseToInt(categoryData['categoria_id']);
            final categoriaNombre = categoryData['categoria_nombre'] ?? _formatearNombreCategoria(categoryKey);
            
            if (total > 0 || cantidad > 0) {
              categoriasTemporales.add({
                'categoria_id': categoriaId,
                'categoria': categoriaNombre,
                'total': total,
                'cantidad': cantidad,
                'clave': categoryKey,
              });
              
              print('📦 Categoría agregada: ID=$categoriaId, Nombre=$categoriaNombre, Total=$total');
            }
          }
        }
        
        categoriasTemporales.sort((a, b) => 
          _parseToDouble(b['total']).compareTo(_parseToDouble(a['total']))
        );
        
        categorias.value = categoriasTemporales;
        
        final totalCalculado = categorias.fold(0.0, (sum, cat) => 
          sum + _parseToDouble(cat['total'])
        );
        
        final cantidadCalculada = categorias.fold(0, (sum, cat) => 
          sum + _parseToInt(cat['cantidad'])
        );
        
        print('📋 Categorías procesadas: ${categorias.length}');
        print('💰 Total API: ${totalGeneral.value}, Total calculado: $totalCalculado');
        print('📦 Cantidad API: ${cantidadGeneralItems.value}, Cantidad calculada: $cantidadCalculada');
        
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

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

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
    print('💰 Formateando total: ${totalGeneral.value}');
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

  Future<void> irAHoy() async {
    await cambiarFecha(DateTime.now());
  }

  Future<void> navegarFecha(int dias) async {
    final fechaActual = DateTime.parse(fechaConsulta.value);
    final nuevaFecha = fechaActual.add(Duration(days: dias));
    
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

  Map<String, dynamic>? obtenerDetalleCategoria(String clave) {
    return categorias.firstWhereOrNull((cat) => cat['clave'] == clave);
  }

  double obtenerPorcentajeCategoria(String clave) {
    final categoria = obtenerDetalleCategoria(clave);
    if (categoria == null || totalGeneral.value == 0) return 0.0;
    
    final totalCategoria = _parseToDouble(categoria['total']);
    return (totalCategoria / totalGeneral.value) * 100;
  }

  List<Map<String, dynamic>> get categoriasTop3 {
    if (categorias.length <= 3) return categorias.toList();
    return categorias.take(3).toList();
  }

  bool get tieneDatos {
    return categorias.isNotEmpty && totalGeneral.value > 0;
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Modelo para Mesa
class Mesa {
  final int id;
  final int numeroMesa;
  final bool status;

  Mesa({
    required this.id,
    required this.numeroMesa,
    required this.status,
  });

  factory Mesa.fromJson(Map<String, dynamic> json) {
    return Mesa(
      id: json['id'],
      numeroMesa: json['numeroMesa'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroMesa': numeroMesa,
      'status': status,
    };
  }
}

// Controller GetX para gestión de mesas
class TablesController extends GetxController {
  var isLoading = false.obs;
  var isCreating = false.obs;
  var isUpdating = false.obs;
  var isDeleting = false.obs;

  var mesas = <Mesa>[].obs;
  var filteredMesas = <Mesa>[].obs;
  var searchText = ''.obs;
  var selectedFilter = 'Todas'.obs; // 'Todas', 'Activas', 'Inactivas'

  String defaultApiServer = AppConstants.serverBase;

  @override
  void onInit() {
    super.onInit();
    listarMesas();
    
    // Escuchar cambios en el texto de búsqueda
    ever(searchText, (_) => _filtrarMesas());
    ever(selectedFilter, (_) => _filtrarMesas());
  }

  /// Listar todas las mesas
  Future<void> listarMesas() async {
    try {
      isLoading.value = true;

      Uri uri = Uri.parse('$defaultApiServer/mesas/listarMesas/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Listar mesas - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        mesas.value = data.map((json) => Mesa.fromJson(json)).toList();
        _filtrarMesas();
        
        print('✅ ${mesas.length} mesas cargadas');
      } else {
        //_mostrarError('Error al cargar mesas', 'No se pudieron cargar las mesas');
      }

    } catch (e) {
      print('Error al listar mesas: $e');
      _mostrarError('Error de Conexión', 'No se pudo conectar al servidor $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Crear nueva mesa
  Future<bool> crearMesa(int numeroMesa) async {
    try {
      isCreating.value = true;

      // Validar que no exista una mesa con el mismo número
      if (mesas.any((mesa) => mesa.numeroMesa == numeroMesa)) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.warning,
          title: 'Mesa duplicada',
          text: 'Ya existe una mesa con el número $numeroMesa',
          confirmBtnText: 'Entendido',
          confirmBtnColor: Color(0xFFFF9800),
        );
        return false;
      }

      final mesaData = {
        'numeroMesa': numeroMesa,
      };

      print('📤 Creando mesa: ${jsonEncode(mesaData)}');

      Uri uri = Uri.parse('$defaultApiServer/mesas/crearMesa/');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(mesaData),
      );

      print('📡 Crear mesa - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {

            if (Get.isRegistered<OrdersController>()) {
        final OrdersController controller = Get.find<OrdersController>();
        await controller.cargarDatos();
        print('✅ Datos del menú recargados');
      }
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Mesa Creada!',
          text: 'La mesa $numeroMesa ha sido creada exitosamente',
          confirmBtnText: 'Perfecto',
          confirmBtnColor: Color(0xFF4CAF50),
          onConfirmBtnTap: () => Get.back(),
        );

        // Recargar lista de mesas
        await listarMesas();
        return true;

      } else {
        final errorData = jsonDecode(response.body);
        _mostrarError(
          'Error al crear mesa',
          errorData['message'] ?? 'No se pudo crear la mesa'
        );
        return false;
      }

    } catch (e) {
      print('Error al crear mesa: $e');
      _mostrarError('Error de Conexión', 'No se pudo conectar al servidor $e');
      return false;
    } finally {
      isCreating.value = false;
    }
  }
  


Future<bool> modificarStatusMesa(int mesaId) async {
  try {
    isUpdating.value = true; // Cambiado a true al inicio

    final statusData = {
      'status': true, 
    };

    print('📤 Modificando status mesa $mesaId: ${jsonEncode(statusData)}');

    // URL corregida - agregando '/restaurante/' si es necesario
    Uri uri = Uri.parse('$defaultApiServer/mesas/liberarMesa/$mesaId/');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(statusData),
    );

    print('📡 Modificar status - Código: ${response.statusCode}');
    print('📄 Respuesta: ${response.body}');

    if (response.statusCode == 200) {
      final mesa = mesas.firstWhereOrNull((m) => m.id == mesaId);
      
          if (Get.isRegistered<OrdersController>()) {
        final OrdersController controller = Get.find<OrdersController>();
        await controller.cargarDatos();
        print('✅ Datos del menú recargados');
      }
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.success,
        title: '¡Status Actualizado!',
        text: 'La mesa ${mesa?.numeroMesa ?? mesaId} ha sido liberada',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFF4CAF50),
        autoCloseDuration: Duration(seconds: 2),
      );

      // Recargar lista de mesas
      await listarMesas();
      return true;

    } else {
      final errorData = jsonDecode(response.body);
      _mostrarError(
        'Error al actualizar mesa',
        errorData['error'] ?? errorData['message'] ?? 'No se pudo actualizar el status'
      );
      return false;
    }

  } catch (e) {
    print('Error al modificar status: $e');
    _mostrarError('Error de Conexión', 'No se pudo conectar al servidor: $e');
    return false;
  } finally {
    isUpdating.value = false;
  }
}
  /// Eliminar mesa
  Future<bool> eliminarMesa(int mesaId) async {
    try {
      isDeleting.value = true;

      print('🗑️ Eliminando mesa $mesaId');

      Uri uri = Uri.parse('$defaultApiServer/mesas/eliminarMesa/$mesaId/');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Eliminar mesa - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final mesa = mesas.firstWhereOrNull((m) => m.id == mesaId);
        
          final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Mesa Eliminada!',
          text: 'La mesa ${mesa?.numeroMesa ?? mesaId} ha sido eliminada exitosamente',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF4CAF50),
          autoCloseDuration: Duration(seconds: 2),
        );

        // Recargar lista de mesas
        await listarMesas();
        return true;

      } else {
        final errorData = jsonDecode(response.body);
        _mostrarError(
          'Error al eliminar mesa',
          errorData['message'] ?? 'No se pudo eliminar la mesa'
        );
        return false;
      }

    } catch (e) {
      print('Error al eliminar mesa: $e');
      _mostrarError('Error de Conexión', 'No se pudo conectar al servidor $e');
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Mostrar modal para crear mesa
  void mostrarModalCrearMesa() {
    final TextEditingController numeroController = TextEditingController();
  final controller = Get.find<CreateOrderController>();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_restaurant,
                  color: Color(0xFF8B4513),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),

              // Título
              Text(
                'Nueva Mesa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ingresa el número de la nueva mesa',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Campo número de mesa
              TextField(
                controller: numeroController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número de Mesa',
                  hintText: 'Ej: 5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF8B4513)),
                  prefixIcon: Icon(Icons.numbers, color: Color(0xFF8B4513)),
                ),
                autofocus: true,
              ),
              SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                      onPressed: isCreating.value
                          ? null
                          : () async {
                              final numeroText = numeroController.text.trim();
                              if (numeroText.isEmpty) {
                                QuickAlert.show(
                                  context: Get.context!,
                                  type: QuickAlertType.warning,
                                  title: 'Campo requerido',
                                  text: 'Por favor ingresa el número de mesa',
                                  confirmBtnText: 'OK',
                                  confirmBtnColor: Color(0xFFFF9800),
                                );
                                return;
                              }

                              final numero = int.tryParse(numeroText);
                              if (numero == null || numero <= 0) {
                                QuickAlert.show(
                                  context: Get.context!,
                                  type: QuickAlertType.warning,
                                  title: 'Número inválido',
                                  text: 'Por favor ingresa un número válido mayor a 0',
                                  confirmBtnText: 'OK',
                                  confirmBtnColor: Color(0xFFFF9800),
                                );
                                return;
                              }

                              final success = await crearMesa(numero);
                              if (success) {
                               controller.cargarDatosIniciales();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isCreating.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Creando...'),
                              ],
                            )
                          : Text(
                              'Crear Mesa',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: !isCreating.value,
    );
  }

  /// Confirmar eliminación de mesa
  void confirmarEliminarMesa(Mesa mesa) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: '¿Eliminar Mesa?',
      text: '¿Estás seguro de que quieres eliminar la Mesa ${mesa.numeroMesa}? Esta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Color(0xFFE74C3C),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el dialog de confirmación
        await eliminarMesa(mesa.id);
      },
    );
  }

  /// Confirmar cambio de status
  void confirmarCambioStatus(Mesa mesa) {
    final nuevoStatus = !mesa.status;
    final accion = nuevoStatus ? 'activar' : 'desactivar';
    
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: '¿Cambiar Status?',
      text: '¿Estás seguro de que quieres $accion la Mesa ${mesa.numeroMesa}?',
      confirmBtnText: accion.capitalize!,
      cancelBtnText: 'Cancelar',
      confirmBtnColor: nuevoStatus ? Color(0xFF4CAF50) : Color(0xFFFF9800),
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el dialog de confirmación
        await modificarStatusMesa(mesa.id, );
      },
    );
  }

  /// Filtrar mesas según búsqueda y filtro
  void _filtrarMesas() {
    var mesasFiltradas = mesas.where((mesa) {
      // Filtro por texto
      final cumpleBusqueda = searchText.value.isEmpty ||
          mesa.numeroMesa.toString().contains(searchText.value.toLowerCase()) ||
          mesa.id.toString().contains(searchText.value.toLowerCase());

      // Filtro por status
      final cumpleStatus = selectedFilter.value == 'Todas' ||
          (selectedFilter.value == 'Activas' && mesa.status) ||
          (selectedFilter.value == 'Inactivas' && !mesa.status);

      return cumpleBusqueda && cumpleStatus;
    }).toList();

    // Ordenar por número de mesa
    mesasFiltradas.sort((a, b) => a.numeroMesa.compareTo(b.numeroMesa));
    
    filteredMesas.value = mesasFiltradas;
  }

  /// Actualizar texto de búsqueda
  void buscarMesas(String texto) {
    searchText.value = texto;
  }

  /// Cambiar filtro
  void cambiarFiltro(String filtro) {
    selectedFilter.value = filtro;
  }

  /// Refrescar datos
  Future<void> refrescarDatos() async {
    await listarMesas();
  }

  /// Mostrar error con QuickAlert
  void _mostrarError(String titulo, String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: titulo,
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }

  /// Obtener estadísticas
  int get totalMesas => mesas.length;
  int get mesasActivas => mesas.where((mesa) => mesa.status).length;
  int get mesasInactivas => mesas.where((mesa) => !mesa.status).length;
  double get porcentajeActivas => totalMesas > 0 ? (mesasActivas / totalMesas) * 100 : 0;
}
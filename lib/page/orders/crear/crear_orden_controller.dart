import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Modelos para las entidades
class Category {
  final int id;
  final String nombreCategoria;
  final String descripcion;
  final bool status;

  Category({
    required this.id,
    required this.nombreCategoria,
    required this.descripcion,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      nombreCategoria: json['nombreCategoria'] ?? '',
      descripcion: json['descripcion'] ?? '',
      status: json['status'] ?? false,
    );
  }
}

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
      id: json['id'] ?? 0,
      numeroMesa: json['numeroMesa'] ?? 0,
      status: json['status'] ?? false,
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final String precio;
  final int tiempoPreparacion;
  final String imagen;
  final String categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tiempoPreparacion,
    required this.imagen,
    required this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio']?.toString() ?? '0', // ✅ Convertir a string si no lo es
      tiempoPreparacion: json['tiempoPreparacion'] ?? 0,
      imagen: json['imagen']?.toString() ?? '', // ✅ Manejar null y convertir a string
      categoria: json['categoria']?.toString() ?? '', // ✅ Manejar null
    );
  }

  double get precioDouble => double.tryParse(precio) ?? 0.0;
  
  bool get tieneImagen => imagen.isNotEmpty;
  
  String get imagenSegura => imagen.isEmpty ? 'assets/images/no-image.png' : imagen;
}

class CartItem {
  final Producto producto;
  int cantidad;
  String observaciones;

  CartItem({
    required this.producto,
    required this.cantidad,
    this.observaciones = '',
  });

  double get subtotal => producto.precioDouble * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'productoId': producto.id,
      'cantidad': cantidad,
      'observaciones': observaciones.isEmpty ? '' : observaciones, // ✅ Asegurar que no sea null
    };
  }
}

// Controller GetX para crear órdenes
class CreateOrderController extends GetxController {
  var isLoading = false.obs;
  var isLoadingCategories = false.obs;
  var isLoadingProducts = false.obs;
  var isLoadingMesas = false.obs;
  var isCreatingOrder = false.obs;
  var searchText = ''.obs;

  var categorias = <Category>[].obs;
  var mesas = <Mesa>[].obs;
  var todosLosProductos = <Producto>[].obs;
  var productosPorCategoria = <Producto>[].obs;
  var cartItems = <CartItem>[].obs;

  var selectedCategoryIndex = 0.obs;
  var selectedMesa = Rx<Mesa?>(null);
  var nombreOrden = ''.obs;

  String defaultApiServer = AppConstants.serverBase;
 var isSearching = false.obs;
  var searchQuery = ''.obs;
  var searchResults = <Producto>[].obs;
  var showSearchResults = false.obs;
  var isLoadingSearch = false.obs;
  @override
  void onInit() {
    super.onInit();
    cargarDatosIniciales();
  }/// ✅ CORREGIDO: Buscar productos por nombre usando POST con body
Future<void> buscarProductos(String query) async {
  try {
    searchQuery.value = query.trim();
    
    // Si la búsqueda está vacía, ocultar resultados
    if (searchQuery.value.isEmpty) {
      showSearchResults.value = false;
      searchResults.clear();
      return;
    }

    // Mostrar que estamos buscando
    isLoadingSearch.value = true;
    showSearchResults.value = true;

    // Preparar datos para enviar en el body
    final searchData = {
      'nombre': searchQuery.value
    };

    Uri uri = Uri.parse('$defaultApiServer/menu/buscarProductoMenu/');
    
    print('🔍 Buscando productos: ${searchQuery.value}');
    print('📡 URL de búsqueda: $uri');
    print('📤 Datos de búsqueda en body: $searchData');

    // ✅ OPCIÓN 1: GET con body (no estándar pero funcional)
    final request = http.Request('GET', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    request.body = jsonEncode(searchData);
    
    final streamedResponse = await request.send().timeout(Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);

    print('📡 Búsqueda - Código: ${response.statusCode}');
    print('📄 Respuesta: ${response.body}');

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        searchResults.clear();
        return;
      }
      
      final dynamic decodedData = jsonDecode(response.body);
      
      if (decodedData is! List) {
        throw Exception('Formato de respuesta inválido - esperaba una lista');
      }
      
      final List<dynamic> data = decodedData;
      
      // Parsear productos encontrados
      searchResults.value = data
          .map((json) {
            try {
              return Producto.fromJson(json);
            } catch (e) {
              print('⚠️ Error al parsear producto de búsqueda: $json - Error: $e');
              return null;
            }
          })
          .where((producto) => producto != null)
          .cast<Producto>()
          .toList();
          
      print('✅ Productos encontrados: ${searchResults.length}');
      
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error en búsqueda: $e');
    searchResults.clear();
    
   
  } finally {
    isLoadingSearch.value = false;
  }
}
  void limpiarBusqueda() {
    searchQuery.value = '';
    searchResults.clear();
    showSearchResults.value = false;
    isLoadingSearch.value = false;
  }

  /// ✅ NUEVO: Cerrar búsqueda y volver a categorías
  void cerrarBusqueda() {
    limpiarBusqueda();
    // Recargar productos de la categoría actual
    if (categorias.isNotEmpty && selectedCategoryIndex.value < categorias.length) {
      final categoria = categorias[selectedCategoryIndex.value];
      obtenerProductosPorCategoria(categoria.id);
    }
  }

  /// Cargar todos los datos necesarios al inicializar
  Future<void> cargarDatosIniciales() async {
    isLoading.value = true;
    try {
      await Future.wait([
        obtenerCategorias(),
        obtenerMesas(),
        obtenerTodosLosProductos(),
      ]);
      
      // Cargar productos de la primera categoría por defecto
      if (categorias.isNotEmpty) {
        await obtenerProductosPorCategoria(categorias.first.id);
      }
    } catch (e) {
      print('❌ Error en cargarDatosIniciales: $e');
      _mostrarError('Error de Inicialización', 'No se pudieron cargar los datos iniciales: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener todas las categorías
  Future<void> obtenerCategorias() async {
    try {
      isLoadingCategories.value = true;
      
      Uri uri = Uri.parse('$defaultApiServer/menu/listarCategorias/');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30)); // ✅ Agregar timeout

      print('📡 Categorías - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Verificar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        // ✅ Verificar que sea una lista
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido - esperaba una lista');
        }
        
        final List<dynamic> data = decodedData;
        categorias.value = data
            .map((json) {
              try {
                return Category.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear categoría: $json - Error: $e');
                return null;
              }
            })
            .where((cat) => cat != null && cat.status) // Solo categorías activas y válidas
            .cast<Category>()
            .toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
     // _mostrarError('Error al cargar categorías', 'No se pudieron cargar las categorías: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Obtener todas las mesas
  Future<void> obtenerMesas() async {
    try {
      isLoadingMesas.value = true;
      
      Uri uri = Uri.parse('$defaultApiServer/mesas/listarMesas/');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30)); // ✅ Agregar timeout

      print('📡 Mesas - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Verificar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        // ✅ Verificar que sea una lista
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido - esperaba una lista');
        }
        
        final List<dynamic> data = decodedData;
        mesas.value = data
            .map((json) {
              try {
                return Mesa.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear mesa: $json - Error: $e');
                return null;
              }
            })
            .cast<Mesa>()
            .toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener mesas: $e');
     // _mostrarError('Error al cargar mesas', 'No se pudieron cargar las mesas: $e');
    } finally {
      isLoadingMesas.value = false;
    }
  }

  /// Obtener todo el menú - 🔧 CORREGIDO para manejar null
  Future<void> obtenerTodosLosProductos() async {
    try {
      isLoadingProducts.value = true;
      
      Uri uri = Uri.parse('$defaultApiServer/menu/listarTodoMenu/');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30)); // ✅ Agregar timeout

      print('📡 Todo el menú - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Verificar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        // ✅ Verificar que sea una lista
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido - esperaba una lista');
        }
        
        final List<dynamic> data = decodedData;
        
        // 🔧 SOLUCIÓN: Filtrar y manejar productos con campos null
        todosLosProductos.value = data
            .map((json) {
              try {
                return Producto.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear producto: $json - Error: $e');
                return null; // Retornar null si hay error en el parsing
              }
            })
            .where((producto) => producto != null) // Filtrar productos null
            .cast<Producto>() // Cast seguro después del filtrado
            .toList();
            
        print('✅ Productos cargados correctamente: ${todosLosProductos.length}');
        
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener todo el menú: $e');
    //  _mostrarError('Error al cargar menú', 'No se pudo cargar el menú: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Obtener productos por categoría - 🔧 CORREGIDO para manejar null
  Future<void> obtenerProductosPorCategoria(int categoriaId) async {
    try {
      isLoadingProducts.value = true;
      
      Uri uri = Uri.parse('$defaultApiServer/menu/listarMenuPorCategoria/$categoriaId/');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30)); // ✅ Agregar timeout

      print('📡 Productos por categoría $categoriaId - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        // ✅ Verificar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        // ✅ Verificar que sea una lista
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido - esperaba una lista');
        }
        
        final List<dynamic> data = decodedData;
        
        // 🔧 SOLUCIÓN: Mismo manejo de null que en obtenerTodosLosProductos
        productosPorCategoria.value = data
            .map((json) {
              try {
                return Producto.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear producto por categoría: $json - Error: $e');
                return null;
              }
            })
            .where((producto) => producto != null)
            .cast<Producto>()
            .toList();
            
      } else {
        // Si falla, usar productos de esa categoría del listado completo
        _filtrarProductosPorCategoria(categoriaId);
      }
    } catch (e) {
      print('❌ Error al obtener productos por categoría: $e');
      // Si falla, usar productos de esa categoría del listado completo
      _filtrarProductosPorCategoria(categoriaId);
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Filtrar productos por categoría del listado completo (fallback)
  void _filtrarProductosPorCategoria(int categoriaId) {
    try {
      final categoria = categorias.firstWhereOrNull((cat) => cat.id == categoriaId);
      if (categoria != null) {
        productosPorCategoria.value = todosLosProductos
            .where((producto) => producto.categoria == categoria.nombreCategoria)
            .toList();
      } else {
        productosPorCategoria.value = [];
      }
    } catch (e) {
      print('❌ Error en _filtrarProductosPorCategoria: $e');
      productosPorCategoria.value = [];
    }
  }

  /// Cambiar categoría seleccionada
  void cambiarCategoria(int index) {
    try {
      if (index < categorias.length && index >= 0) {
        selectedCategoryIndex.value = index;
        final categoria = categorias[index];
        obtenerProductosPorCategoria(categoria.id);
      }
    } catch (e) {
      print('❌ Error en cambiarCategoria: $e');
    }
  }

  /// Seleccionar mesa
  void seleccionarMesa(Mesa? mesa) {
    try {
      selectedMesa.value = mesa;
    } catch (e) {
      print('❌ Error en seleccionarMesa: $e');
    }
  }

  void agregarAlCarrito(Producto producto, {String observaciones = '', bool cerrarDialog = false}) {
    try {
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.producto.id == producto.id && item.observaciones == observaciones
      );

      if (existingItemIndex >= 0) {
        cartItems[existingItemIndex].cantidad++;
      } else {
        cartItems.add(CartItem(
          producto: producto,
          cantidad: 1,
          observaciones: observaciones,
        ));
      }

      // Cerrar dialog si se especifica
      if (cerrarDialog && Get.isDialogOpen == true) {
        Get.back();
      }
    } catch (e) {
      print('❌ Error en agregarAlCarrito: $e');
      _mostrarError('Error', 'No se pudo agregar el producto al carrito');
    }
  }

  /// Aumentar cantidad de un item en el carrito
  void aumentarCantidad(int index) {
    try {
      if (index < cartItems.length && index >= 0) {
        cartItems[index].cantidad++;
        cartItems.refresh();
      }
    } catch (e) {
      print('❌ Error en aumentarCantidad: $e');
    }
  }

  /// Disminuir cantidad de un item en el carrito
  void disminuirCantidad(int index) {
    try {
      if (index < cartItems.length && index >= 0) {
        if (cartItems[index].cantidad > 1) {
          cartItems[index].cantidad--;
          cartItems.refresh();
        } else {
          cartItems.removeAt(index);
        }
      }
    } catch (e) {
      print('❌ Error en disminuirCantidad: $e');
    }
  }

  /// Remover item del carrito
  void removerDelCarrito(int index) {
    try {
      if (index < cartItems.length && index >= 0) {
        cartItems.removeAt(index);
      }
    } catch (e) {
      print('❌ Error en removerDelCarrito: $e');
    }
  }

  /// Limpiar carrito
  void limpiarCarrito() {
    try {
      cartItems.clear();
      nombreOrden.value = '';
      selectedMesa.value = null;
    } catch (e) {
      print('❌ Error en limpiarCarrito: $e');
    }
  }

  /// Calcular total del carrito
  double get totalCarrito {
    try {
      return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    } catch (e) {
      print('❌ Error en totalCarrito: $e');
      return 0.0;
    }
  }

  /// Obtener cantidad total de items en el carrito
  int get cantidadTotalItems {
    try {
      return cartItems.fold(0, (sum, item) => sum + item.cantidad);
    } catch (e) {
      print('❌ Error en cantidadTotalItems: $e');
      return 0;
    }
  }

  /// Generar nombre de orden por defecto
  String _generarNombreOrdenPorDefecto() {
    try {
      final now = DateTime.now();
      return 'Orden Mesa ${selectedMesa.value?.numeroMesa ?? 'Sin Mesa'}';
    } catch (e) {
      print('❌ Error en _generarNombreOrdenPorDefecto: $e');
      return 'Orden Sin Nombre';
    }
  }

  // ✅ FUNCIÓN PRINCIPAL CORREGIDA
  Future<bool> crearOrden({String? nombreOrdenCustom}) async {
    try {
      // ✅ Validaciones mejoradas
      if (selectedMesa.value == null) {
        await _mostrarAlertaAsync(
          QuickAlertType.warning,
          'Mesa requerida',
          'Por favor selecciona una mesa antes de continuar',
          'Entendido',
          Color(0xFFFF9800),
        );
        return false;
      }

      if (cartItems.isEmpty) {
        await _mostrarAlertaAsync(
          QuickAlertType.warning,
          'Carrito vacío',
          'Agrega productos al carrito antes de crear la orden',
          'Entendido',
          Color(0xFFFF9800),
        );
        return false;
      }

      isCreatingOrder.value = true;

      // ✅ Manejo seguro del nombre
      String nombreFinal;
      try {
        nombreFinal = (nombreOrdenCustom?.isNotEmpty == true) 
            ? nombreOrdenCustom! 
            : _generarNombreOrdenPorDefecto();
      } catch (e) {
        print('⚠️ Error generando nombre, usando por defecto');
        nombreFinal = 'Orden ${DateTime.now().millisecondsSinceEpoch}';
      }

      // ✅ Construcción segura del orderData
      final orderData = <String, dynamic>{
        'nombreOrden': nombreFinal,
        'mesaId': selectedMesa.value!.id,
        'productos': cartItems.map((item) {
          try {
            return item.toJson();
          } catch (e) {
            print('⚠️ Error serializando item: $e');
            // Versión manual como fallback
            return {
              'productoId': item.producto.id,
              'cantidad': item.cantidad,
              'observaciones': item.observaciones ?? '',
            };
          }
        }).toList(),
        'status': 'proceso',
      };

      print('📤 Creando orden: ${jsonEncode(orderData)}');

      // ✅ Validar URL del servidor
      if (defaultApiServer.isEmpty) {
        throw Exception('URL del servidor no configurada');
      }

      Uri uri = Uri.parse('$defaultApiServer/ordenes/crearOrden/');
      print('📡 URL de creación: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      ).timeout(Duration(seconds: 30)); // ✅ Timeout

      print('📡 Crear orden - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Manejo seguro de la respuesta
        try {
          final responseData = response.body.isNotEmpty 
              ? jsonDecode(response.body) 
              : <String, dynamic>{};
          print('✅ Orden creada exitosamente: $responseData');
        } catch (e) {
          print('⚠️ Error decodificando respuesta exitosa: $e');
          // Continuamos porque la orden se creó correctamente
        }
        
        // Limpiar carrito
        limpiarCarrito();
        
        // Esperar un momento antes de mostrar el alert
        await Future.delayed(Duration(milliseconds: 300));
        
          final controller2 = Get.find<OrdersController>();
          controller2.cargarDatos();
     

        return true;

      } else {
        // ✅ Manejo mejorado de errores del servidor
        String errorMessage = 'Error desconocido del servidor';
        try {
          if (response.body.isNotEmpty) {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message']?.toString() ?? 
                          errorData['error']?.toString() ?? 
                          'Error del servidor (${response.statusCode})';
          } else {
            errorMessage = 'Error del servidor (${response.statusCode}) - Sin mensaje';
          }
        } catch (e) {
          errorMessage = 'Error del servidor (${response.statusCode}) - Respuesta inválida';
        }
        
        await _mostrarAlertaAsync(
          QuickAlertType.error,
          'Error al crear orden',
          errorMessage,
          'OK',
          Color(0xFFE74C3C),
        );
        return false;
      }

    } catch (e) {
      print('❌ Error crítico al crear orden: $e');
      
      String errorMessage = 'Error de conexión desconocido';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'No se puede conectar al servidor. Verifica la conexión.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Error en el formato de datos del servidor.';
      } else {
        errorMessage = 'Error de conexión: ${e.toString()}';
      }
      
      await _mostrarAlertaAsync(
        QuickAlertType.error,
        'Error de Conexión',
        errorMessage,
        'OK',
        Color(0xFFE74C3C),
      );
      return false;
    } finally {
      isCreatingOrder.value = false;
    }
  }

  // ✅ NUEVA FUNCIÓN: Mostrar alertas de forma asíncrona y segura
  Future<void> _mostrarAlertaAsync(
    QuickAlertType type,
    String title,
    String text,
    String confirmBtnText,
    Color confirmBtnColor,
  ) async {
    try {
      if (Get.context != null) {
        await QuickAlert.show(
          context: Get.context!,
          type: type,
          title: title,
          text: text,
          confirmBtnText: confirmBtnText,
          confirmBtnColor: confirmBtnColor,
          barrierDismissible: false,
        );
      } else {
        print('⚠️ No se puede mostrar alerta - contexto no disponible');
      }
    } catch (e) {
      print('❌ Error mostrando alerta: $e');
    }
  }

  /// Refrescar todos los datos
  Future<void> refrescarDatos() async {
    try {
      await cargarDatosIniciales();
    } catch (e) {
      print('❌ Error en refrescarDatos: $e');
      _mostrarError('Error', 'No se pudieron refrescar los datos');
    }
  }

  /// Mostrar error con QuickAlert
  void _mostrarError(String titulo, String mensaje) {
    try {
      if (Get.context != null) {
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: titulo,
          text: mensaje,
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );
      } else {
        print('⚠️ No se puede mostrar error - contexto no disponible: $titulo - $mensaje');
      }
    } catch (e) {
      print('❌ Error mostrando mensaje de error: $e');
    }
  }

  /// Validar si se puede crear la orden
  bool get puedeCrearOrden {
    try {
      return selectedMesa.value != null && 
             cartItems.isNotEmpty && 
             !isCreatingOrder.value;
    } catch (e) {
      print('❌ Error en puedeCrearOrden: $e');
      return false;
    }
  }
}
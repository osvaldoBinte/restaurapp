// add_products_to_order_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Reutilizar las clases existentes
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
      precio: json['precio']?.toString() ?? '0',
      tiempoPreparacion: json['tiempoPreparacion'] ?? 0,
      imagen: json['imagen']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
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
      'observaciones': observaciones.isEmpty ? '' : observaciones,
    };
  }
}

// ✅ NUEVO CONTROLLER PARA AGREGAR PRODUCTOS A PEDIDO EXISTENTE
class AddProductsToOrderController extends GetxController {
  // Variables observables
  var isLoading = false.obs;
  var isLoadingCategories = false.obs;
  var isLoadingProducts = false.obs;
  var isAddingProducts = false.obs;

var mesaId = 0.obs;
var grupoId = 0.obs;
var tipoDestino = ''.obs; // 'pedido', 'mesa', 'grupo'
  // Datos del pedido actual
  var pedidoId = 0.obs;
  var numeromesa = 0.obs;
  var nombreOrden = ''.obs;

  // Listas de datos
  var categorias = <Category>[].obs;
  var todosLosProductos = <Producto>[].obs;
  var productosPorCategoria = <Producto>[].obs;
  var cartItems = <CartItem>[].obs;

  // Índice de categoría seleccionada
  var selectedCategoryIndex = 0.obs;

  String defaultApiServer = AppConstants.serverBase;
 var isSearching = false.obs;
  var searchQuery = ''.obs;
  var searchResults = <Producto>[].obs;
  var showSearchResults = false.obs;
  var isLoadingSearch = false.obs;
    var searchText = ''.obs;
  // ✅ Inicializar con el ID del pedido
void inicializarConPedido(int pedidoIdParam, int numeroMesaParam, String nombreOrdenParam) {
  pedidoId.value = pedidoIdParam;
  numeromesa.value = numeroMesaParam;
  nombreOrden.value = nombreOrdenParam;
  mesaId.value = 0;
  grupoId.value = 0;
  tipoDestino.value = 'pedido';
  cartItems.clear();
  cargarDatosIniciales();
}

// ✅ Inicializar por mesa simple
void inicializarConMesa(int mesaIdParam, int numeroMesaParam) {
  pedidoId.value = 0;
  numeromesa.value = numeroMesaParam;
  nombreOrden.value = 'Mesa $numeroMesaParam';
  mesaId.value = mesaIdParam;
  grupoId.value = 0;
  tipoDestino.value = 'mesa';
  cartItems.clear();
  cargarDatosIniciales();
}

// ✅ Inicializar por grupo
void inicializarConGrupo(int grupoIdParam, String nombreGrupoParam) {
  pedidoId.value = 0;
  numeromesa.value = 0;
  nombreOrden.value = nombreGrupoParam;
  mesaId.value = 0;
  grupoId.value = grupoIdParam;
  tipoDestino.value = 'grupo';
  cartItems.clear();
  cargarDatosIniciales();
}
  @override
  void onInit() {
    super.onInit();
    // No cargar datos automáticamente - esperar a que se llame inicializarConPedido
  }
/// ✅ CORREGIDO: Buscar productos por nombre usando POST con body
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

Future<void> cargarDatosIniciales() async {
  // ✅ Validar según tipo de destino, no solo pedidoId
  final tieneDestino = tipoDestino.value == 'pedido'
      ? pedidoId.value > 0
      : tipoDestino.value == 'mesa'
          ? mesaId.value > 0
          : grupoId.value > 0;

  if (!tieneDestino && tipoDestino.value.isEmpty) {
    print('⚠️ No se puede cargar datos sin destino configurado');
    return;
  }

  isLoading.value = true;
  try {
    await Future.wait([
      obtenerCategorias(),
      obtenerTodosLosProductos(),
    ]);
    if (categorias.isNotEmpty) {
      await obtenerProductosPorCategoria(categorias.first.id);
    }
  } catch (e) {
    print('❌ Error en cargarDatosIniciales: $e');
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
      ).timeout(Duration(seconds: 30));

      print('📡 Categorías - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido');
        }
        
        final List<dynamic> data = decodedData;
        categorias.value = data
            .map((json) {
              try {
                return Category.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear categoría: $e');
                return null;
              }
            })
            .where((cat) => cat != null && cat.status)
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

  /// Obtener todo el menú
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
      ).timeout(Duration(seconds: 30));

      print('📡 Todo el menú - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido');
        }
        
        final List<dynamic> data = decodedData;
        
        todosLosProductos.value = data
            .map((json) {
              try {
                return Producto.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear producto: $e');
                return null;
              }
            })
            .where((producto) => producto != null)
            .cast<Producto>()
            .toList();
            
        print('✅ Productos cargados: ${todosLosProductos.length}');
        
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener menú: $e');
    //  _mostrarError('Error al cargar menú', 'No se pudo cargar el menú: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Obtener productos por categoría
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
      ).timeout(Duration(seconds: 30));

      print('📡 Productos por categoría $categoriaId - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        final dynamic decodedData = jsonDecode(response.body);
        
        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido');
        }
        
        final List<dynamic> data = decodedData;
        
        productosPorCategoria.value = data
            .map((json) {
              try {
                return Producto.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear producto por categoría: $e');
                return null;
              }
            })
            .where((producto) => producto != null)
            .cast<Producto>()
            .toList();
            
      } else {
        // Fallback: filtrar del listado completo
        _filtrarProductosPorCategoria(categoriaId);
      }
    } catch (e) {
      print('❌ Error al obtener productos por categoría: $e');
      _filtrarProductosPorCategoria(categoriaId);
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Filtrar productos por categoría (fallback)
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

  /// Agregar producto al carrito temporal
  void agregarAlCarrito(Producto producto, {String observaciones = ''}) {
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

      print('✅ Producto agregado al carrito: ${producto.nombre}');
    } catch (e) {
      print('❌ Error en agregarAlCarrito: $e');
      _mostrarError('Error', 'No se pudo agregar el producto al carrito');
    }
  }

  /// Aumentar cantidad de un item
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

  /// Disminuir cantidad de un item
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

  /// Limpiar carrito
  void limpiarCarrito() {
    try {
      cartItems.clear();
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

  /// ✅ FUNCIÓN PRINCIPAL: Agregar productos al pedido existente
 Future<bool> agregarProductosAPedido() async {
  try {
    if (cartItems.isEmpty) {
      await _mostrarAlertaAsync(
        QuickAlertType.warning,
        'Carrito vacío',
        'Agrega productos antes de continuar',
        'Entendido',
        Color(0xFFFF9800),
      );
      return false;
    }

    isAddingProducts.value = true;

    // ✅ Construir body según tipo de destino
    final Map<String, dynamic> requestData = {
      'productos': cartItems.map((item) => item.toJson()).toList(),
    };

    if (tipoDestino.value == 'pedido') {
      requestData['pedidoId'] = pedidoId.value;
    } else if (tipoDestino.value == 'mesa') {
      requestData['mesaId'] = mesaId.value;
    } else if (tipoDestino.value == 'grupo') {
      requestData['grupoId'] = grupoId.value;
    }

    print('📤 Tipo destino: ${tipoDestino.value}');
    print('📤 Body: ${jsonEncode(requestData)}');

    Uri uri = Uri.parse('$defaultApiServer/ordenes/agregarProductosAPedido/');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestData),
    ).timeout(Duration(seconds: 30));

    print('📡 Status: ${response.statusCode}');
    print('📄 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      limpiarCarrito();
      try {
        final OrdersController ordersController = Get.find<OrdersController>();
        ordersController.refrescarDatos();
      } catch (e) {
        print('⚠️ No se pudo refrescar: $e');
      }
      return true;
    } else {
      String errorMessage = 'Error del servidor (${response.statusCode})';
      try {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message']?.toString() ??
                        errorData['error']?.toString() ??
                        errorMessage;
        }
      } catch (e) {}

      await _mostrarAlertaAsync(
        QuickAlertType.error,
        'Error al agregar productos',
        errorMessage,
        'OK',
        Color(0xFFE74C3C),
      );
      return false;
    }
  } catch (e) {
    print('❌ Error: $e');
    await _mostrarAlertaAsync(
      QuickAlertType.error,
      'Error de Conexión',
      'Error: ${e.toString()}',
      'OK',
      Color(0xFFE74C3C),
    );
    return false;
  } finally {
    isAddingProducts.value = false;
  }
}

  /// Mostrar alertas de forma asíncrona
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
        print('⚠️ No se puede mostrar error: $titulo - $mensaje');
      }
    } catch (e) {
      print('❌ Error mostrando mensaje de error: $e');
    }
  }

  /// Validar si se pueden agregar productos
bool get puedeAgregarProductos {
  try {
    final tieneDestino = tipoDestino.value == 'pedido'
        ? pedidoId.value > 0
        : tipoDestino.value == 'mesa'
            ? mesaId.value > 0
            : grupoId.value > 0; // grupo
    return tieneDestino && cartItems.isNotEmpty && !isAddingProducts.value;
  } catch (e) {
    return false;
  }
}

  /// Refrescar datos
  Future<void> refrescarDatos() async {
    try {
      await cargarDatosIniciales();
    } catch (e) {
      print('❌ Error en refrescarDatos: $e');
      _mostrarError('Error', 'No se pudieron refrescar los datos');
    }
  }
}
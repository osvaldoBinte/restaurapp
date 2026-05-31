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

// Modelo para mesa simple dentro de un grupo
class MesaSimple {
  final int id;
  final int numeroMesa;

  MesaSimple({required this.id, required this.numeroMesa});

  factory MesaSimple.fromJson(Map<String, dynamic> json) {
    return MesaSimple(
      id: json['id'],
      numeroMesa: json['numeroMesa'],
    );
  }
}

class Mesa {
  final int id;
  final int numeroMesa;
  final bool status;
  final bool esGrupo;
  final int? grupoId;
  final String? etiquetaGrupo;
  final List<MesaSimple>? mesasDelGrupo;
  final String? mesaNombre; 
  Mesa({
    required this.id,
    required this.numeroMesa,
    required this.status,
    this.esGrupo = false,
    this.grupoId,
    this.etiquetaGrupo,
    this.mesasDelGrupo,
     this.mesaNombre,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mesa && other.id == id && other.esGrupo == esGrupo;
  }

  @override
  int get hashCode => id.hashCode ^ esGrupo.hashCode;

  factory Mesa.fromJson(Map<String, dynamic> json) {
    final esGrupo = json['esGrupo'] ?? false;

    if (esGrupo) {
      return Mesa(
        id: json['grupoId'] ?? 0,
        numeroMesa: 0,
        status: json['status'] ?? false,
        esGrupo: true,
        grupoId: json['grupoId'],
        etiquetaGrupo: json['etiquetaGrupo'],
        mesasDelGrupo: json['mesas'] != null
            ? (json['mesas'] as List).map((m) => MesaSimple.fromJson(m)).toList()
            : null,
      );
    }

    return Mesa(
      id: json['id'] ?? 0,
      numeroMesa: json['numeroMesa'] ?? 0,
      status: json['status'] ?? false,
      esGrupo: false,
      mesaNombre: json['mesaNombre'] as String?, // ← nuevo
    );
  }

String get displayName {
    if (esGrupo) {
      final nombres = mesasDelGrupo?.map((m) => 'M${m.numeroMesa}').join(', ') ?? '';
      return '${etiquetaGrupo ?? 'Grupo'} ($nombres)';
    }

    // Mesa 12 (Jardin)  ó  Mesa 9  si mesaNombre es null
    final sufijo = (mesaNombre != null && mesaNombre!.isNotEmpty)
        ? ' ($mesaNombre)'
        : '';
    return 'Mesa $numeroMesa$sufijo';
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
  }

  Future<void> buscarProductos(String query) async {
    try {
      searchQuery.value = query.trim();

      if (searchQuery.value.isEmpty) {
        showSearchResults.value = false;
        searchResults.clear();
        return;
      }

      isLoadingSearch.value = true;
      showSearchResults.value = true;

      final searchData = {'nombre': searchQuery.value};
      Uri uri = Uri.parse('$defaultApiServer/menu/buscarProductoMenu/');

      print('🔍 Buscando productos: ${searchQuery.value}');
      print('📡 URL de búsqueda: $uri');

      final request = http.Request('GET', uri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      request.body = jsonEncode(searchData);

      final streamedResponse = await request.send().timeout(Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Búsqueda - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          searchResults.clear();
          return;
        }

        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is! List) {
          throw Exception('Formato de respuesta inválido - esperaba una lista');
        }

        searchResults.value = decodedData
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

  void cerrarBusqueda() {
    limpiarBusqueda();
    if (categorias.isNotEmpty && selectedCategoryIndex.value < categorias.length) {
      final categoria = categorias[selectedCategoryIndex.value];
      obtenerProductosPorCategoria(categoria.id);
    }
  }

  Future<void> cargarDatosIniciales() async {
    isLoading.value = true;
    try {
      await Future.wait([
        obtenerCategorias(),
        obtenerMesas(),
        obtenerTodosLosProductos(),
      ]);

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
        if (response.body.isEmpty) throw Exception('Respuesta vacía del servidor');

        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is! List) throw Exception('Formato de respuesta inválido');

        categorias.value = decodedData
            .map((json) => Category.fromJson(json))
            .toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }
Future<void> refrescarMesasSilencioso() async {
  try {
    Uri uri = Uri.parse('$defaultApiServer/mesas/listarMesas/');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
print(  '📡 Refrescando mesas - Código: ${response.statusCode}');
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final List<dynamic> data = jsonDecode(response.body);
      final nuevasMesas = data
          .map((json) { try { return Mesa.fromJson(json); } catch (e) { return null; } })
          .where((m) => m != null)
          .cast<Mesa>()
          .toList();

      mesas.value = nuevasMesas;

      if (selectedMesa.value != null) {
        final mesaActualizada = nuevasMesas.firstWhereOrNull(
          (m) => m.id == selectedMesa.value!.id && m.esGrupo == selectedMesa.value!.esGrupo,
        );
        selectedMesa.value = mesaActualizada;
      }
    }
  } catch (e) {
    print('❌ Error refrescando mesas: $e');
  }
  // ✅ Sin tocar isLoadingMesas
}
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
      ).timeout(Duration(seconds: 30));

      print('📡 Mesas - Código: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) throw Exception('Respuesta vacía del servidor');

        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is! List) throw Exception('Formato de respuesta inválido');

        final nuevasMesas = decodedData
            .map((json) {
              try {
                return Mesa.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear mesa: $json - Error: $e');
                return null;
              }
            })
            .where((mesa) => mesa != null)
            .cast<Mesa>()
            .toList();

        mesas.value = nuevasMesas;

        // Re-sincronizar selectedMesa con la nueva lista
        if (selectedMesa.value != null) {
          final mesaActualizada = nuevasMesas.firstWhereOrNull(
            (m) => m.id == selectedMesa.value!.id && m.esGrupo == selectedMesa.value!.esGrupo,
          );
          selectedMesa.value = mesaActualizada;
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener mesas: $e');
    } finally {
      isLoadingMesas.value = false;
    }
  }

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
        if (response.body.isEmpty) throw Exception('Respuesta vacía del servidor');

        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is! List) throw Exception('Formato de respuesta inválido');

        todosLosProductos.value = decodedData
            .map((json) {
              try {
                return Producto.fromJson(json);
              } catch (e) {
                print('⚠️ Error al parsear producto: $json - Error: $e');
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
      print('❌ Error al obtener todo el menú: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

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
        if (response.body.isEmpty) throw Exception('Respuesta vacía del servidor');

        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is! List) throw Exception('Formato de respuesta inválido');

        productosPorCategoria.value = decodedData
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
        _filtrarProductosPorCategoria(categoriaId);
      }
    } catch (e) {
      print('❌ Error al obtener productos por categoría: $e');
      _filtrarProductosPorCategoria(categoriaId);
    } finally {
      isLoadingProducts.value = false;
    }
  }

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
        (item) => item.producto.id == producto.id && item.observaciones == observaciones,
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

      if (cerrarDialog && Get.isDialogOpen == true) {
        Get.back();
      }
    } catch (e) {
      print('❌ Error en agregarAlCarrito: $e');
      _mostrarError('Error', 'No se pudo agregar el producto al carrito');
    }
  }

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

  void removerDelCarrito(int index) {
    try {
      if (index < cartItems.length && index >= 0) {
        cartItems.removeAt(index);
      }
    } catch (e) {
      print('❌ Error en removerDelCarrito: $e');
    }
  }

  void limpiarCarrito() {
    try {
      cartItems.clear();
      nombreOrden.value = '';
      selectedMesa.value = null;
    } catch (e) {
      print('❌ Error en limpiarCarrito: $e');
    }
  }

  double get totalCarrito {
    try {
      return cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    } catch (e) {
      print('❌ Error en totalCarrito: $e');
      return 0.0;
    }
  }

  int get cantidadTotalItems {
    try {
      return cartItems.fold(0, (sum, item) => sum + item.cantidad);
    } catch (e) {
      print('❌ Error en cantidadTotalItems: $e');
      return 0;
    }
  }

String _generarNombreOrdenPorDefecto() {
  try {
    final mesa = selectedMesa.value;
    if (mesa == null) return ' Sin Mesa';

    if (mesa.esGrupo) {
      return ' ${mesa.etiquetaGrupo ?? 'Grupo'}';
    }

    final sufijo = (mesa.mesaNombre != null && mesa.mesaNombre!.isNotEmpty)
        ? ' ${mesa.mesaNombre}'
        : '';
    return ' Mesa ${mesa.numeroMesa}$sufijo';
  } catch (e) {
    print('❌ Error en _generarNombreOrdenPorDefecto: $e');
    return ' Sin Nombre';
  }
}
  Future<bool> crearOrden({String? nombreOrdenCustom}) async {
    try {
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

      String nombreFinal;
      try {
        nombreFinal = (nombreOrdenCustom?.isNotEmpty == true)
            ? nombreOrdenCustom!
            : _generarNombreOrdenPorDefecto();
      } catch (e) {
        print('⚠️ Error generando nombre, usando por defecto');
        nombreFinal = 'Orden ${DateTime.now().millisecondsSinceEpoch}';
      }

      final mesa = selectedMesa.value!;
      final Map<String, dynamic> orderData = {
        'nombreOrden': nombreFinal,
        if (mesa.esGrupo) 'grupoId': mesa.grupoId else 'mesaId': mesa.id,
        'productos': cartItems.map((item) {
          try {
            return item.toJson();
          } catch (e) {
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

      if (defaultApiServer.isEmpty) throw Exception('URL del servidor no configurada');

      Uri uri = Uri.parse('$defaultApiServer/ordenes/crearOrden/');
      print('📡 URL de creación: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      ).timeout(Duration(seconds: 30));

      print('📡 Crear orden - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
          print('✅ Orden creada exitosamente: $responseData');
        } catch (e) {
          print('⚠️ Error decodificando respuesta exitosa: $e');
        }

        limpiarCarrito();

        await Future.delayed(Duration(milliseconds: 300));

        final controller2 = Get.find<OrdersController>();
        controller2.cargarDatos();

        return true;
      } else {
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

  Future<void> refrescarDatos() async {
    try {
      await cargarDatosIniciales();
    } catch (e) {
      print('❌ Error en refrescarDatos: $e');
      _mostrarError('Error', 'No se pudieron refrescar los datos');
    }
  }

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

  bool get puedeCrearOrden {
    try {
      return selectedMesa.value != null && cartItems.isNotEmpty && !isCreatingOrder.value;
    } catch (e) {
      print('❌ Error en puedeCrearOrden: $e');
      return false;
    }
  }
}
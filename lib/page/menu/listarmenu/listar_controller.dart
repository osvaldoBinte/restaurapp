import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quickalert/quickalert.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/menu/menu.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Modelo para el menú
class Menu {
  final int id;
  final String nombre;
  final String descripcion;
  final String precio;
  final int tiempoPreparacion;
  final String imagen;
  final int categoriaId; // Cambiado de categoria a categoriaId como int
  final String? categoriaNombre; // Nuevo campo opcional para el nombre de la categoría

  Menu({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tiempoPreparacion,
    required this.imagen,
    required this.categoriaId,
    this.categoriaNombre,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: json['precio'] ?? '0.00',
      tiempoPreparacion: json['tiempoPreparacion'] ?? 0,
      imagen: json['imagen'] ?? '',
      categoriaId: json['categoriaId'] ?? json['categoria_id'] ?? 0, // Flexible para diferentes formatos de API
      categoriaNombre: json['categoriaNombre'] ?? json['categoria_nombre'] ?? json['categoria'] ?? '',
    );
  }

  double get precioNumerico => double.tryParse(precio) ?? 0.0;
}

// Modelo para las categorías
class Categoria {
  final int id;
  final String nombre;
  

  Categoria({
    required this.id,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }
}

// Controller para listar menús
class ListarMenuController extends GetxController {
  var isLoading = false.obs;
  var isDeleting = false.obs;
  var isLoadingCategorias = false.obs;
  var menus = <Menu>[].obs;
  var categorias = <Categoria>[].obs;
  var filteredMenus = <Menu>[].obs;
  var searchText = ''.obs;
  var selectedCategoryId = 0.obs; // 0 significa "Todas"
  
  String defaultApiServer = AppConstants.serverBase;
  
  // Lista de categorías para el filtro (incluyendo "Todas")
  List<Map<String, dynamic>> get categoriasParaFiltro {
    final cats = <Map<String, dynamic>>[
      {'id': 0, 'nombre': 'Todas'}
    ];
    cats.addAll(categorias.map((cat) => {'id': cat.id, 'nombre': cat.nombre}).toList());
    return cats;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    
    // Escuchar cambios en búsqueda y filtro
    ever(searchText, (_) => filtrarMenus());
    ever(selectedCategoryId, (_) => filtrarMenus());
  }

  /// Inicializar datos
  Future<void> _initializeData() async {
    await Future.wait([
      cargarCategorias(),
      listarTodoMenu(),
    ]);
  }

  /// Método para cargar las categorías
  Future<void> cargarCategorias() async {
    try {
      isLoadingCategorias.value = true;

      Uri uri = Uri.parse('$defaultApiServer/menu/listarCategorias/');
      print('🌐 Obteniendo categorías desde: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Código de respuesta categorías: ${response.statusCode}');
      print('📄 Respuesta del servidor categorías: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        categorias.value = data.map((json) => Categoria.fromJson(json)).toList();
        
        print('✅ ${categorias.length} categorías cargadas exitosamente');
      } else {
        print('⚠️ Error al cargar categorías: ${response.statusCode}');
      }

    } catch (e) {
      print('🚨 Error al obtener categorías: $e');
    } finally {
      isLoadingCategorias.value = false;
    }
  }

  /// Método para obtener todos los menús
  Future<void> listarTodoMenu() async {
    try {
      isLoading.value = true;

      Uri uri = Uri.parse('$defaultApiServer/menu/listarTodoMenu/');
      print('🌐 Obteniendo menús desde: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        menus.value = data.map((json) => Menu.fromJson(json)).toList();
        filtrarMenus(); // Aplicar filtros iniciales
        
        print('✅ ${menus.length} menús cargados exitosamente');
      } else {
       
      }

    } catch (e) {
      print('🚨 Error al obtener menús: $e');
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar para obtener los menús',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Método para eliminar un menú
  Future<bool> eliminarMenu(int menuId) async {
    try {
      isDeleting.value = true;

      Uri uri = Uri.parse('$defaultApiServer/menu/eliminarMenu/$menuId/');
      print('🗑️ Eliminando menú desde: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminar de la lista local
        menus.removeWhere((menu) => menu.id == menuId);
        filtrarMenus();
        final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.success,
          title: '¡Eliminado!',
          text: 'El menú ha sido eliminado correctamente',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFF4CAF50),
          autoCloseDuration: Duration(seconds: 2),
        );

        return true;
      } else {
        String errorMessage = 'Error al eliminar el menú (${response.statusCode})';
        
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          // Si no es JSON válido, usar mensaje por defecto
        }

        QuickAlert.show(
          context: Get.context!,
          type: QuickAlertType.error,
          title: 'Error al Eliminar',
          text: errorMessage,
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );

        return false;
      }

    } catch (e) {
      print('🚨 Error al eliminar menú: $e');
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: 'Error de Conexión',
        text: 'No se pudo conectar para eliminar el menú',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Método para filtrar menús
  void filtrarMenus() {
    var filtered = menus.where((menu) {
      final matchesSearch = searchText.value.isEmpty ||
          menu.nombre.toLowerCase().contains(searchText.value.toLowerCase()) ||
          menu.descripcion.toLowerCase().contains(searchText.value.toLowerCase());
      
      final matchesCategory = selectedCategoryId.value == 0 ||
          menu.categoriaId == selectedCategoryId.value;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    filteredMenus.value = filtered;
  }

  /// Método para cambiar texto de búsqueda
  void cambiarBusqueda(String text) {
    searchText.value = text;
  }

  /// Método para cambiar categoría seleccionada
  void cambiarCategoria(int categoriaId) {
    selectedCategoryId.value = categoriaId;
  }

  /// Método para obtener el nombre de una categoría por su ID
  String obtenerNombreCategoria(int categoriaId) {
    final categoria = categorias.firstWhereOrNull((cat) => cat.id == categoriaId);
    return categoria?.nombre ?? 'Sin categoría ${categoria?.nombre}';
  }

  /// Método para refrescar lista
  Future<void> refrescarLista() async {
    await _initializeData();
  }
}

class ListarTodoMenuPage extends StatelessWidget {
  final bool isEmbedded;
  final VoidCallback? onMenuUpdated;

  const ListarTodoMenuPage({
    Key? key,
    this.isEmbedded = false,
    this.onMenuUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isEmbedded ? _buildEmbeddedVersion() : _buildFullScreenVersion();
  }
 Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando menús...',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Obteniendo datos del servidor',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildEmbeddedVersion() {
    final controller = Get.find<ListarMenuController>();
    return Column(
      children: [
        // Header compacto con búsqueda
        _buildCompactHeader(controller),
        SizedBox(height: 12),
        
        // ✅ AGREGADO: RefreshIndicator envolviendo la lista
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refrescarLista,
            color: Color(0xFF8B4513),
            backgroundColor: Colors.white,
            displacement: 40.0,
            strokeWidth: 2.5,
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingWidget();
              }
              
              if (controller.filteredMenus.isEmpty) {
                // ✅ IMPORTANTE: SingleChildScrollView para que funcione el pull-to-refresh
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(Get.context!).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            controller.menus.isEmpty
                                ? 'No hay menús registrados'
                                : 'No se encontraron menús',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Desliza hacia abajo para actualizar',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (controller.menus.isEmpty) ...[
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateMenuModal(),
                              icon: Icon(Icons.add),
                              label: Text('Crear Primer Menú'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF8B4513),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                physics: AlwaysScrollableScrollPhysics(), // ✅ IMPORTANTE
                itemCount: controller.filteredMenus.length,
                itemBuilder: (context, index) {
                  final menu = controller.filteredMenus[index];
                  return _buildCompactMenuCard(menu, controller);
                },
              );
            }),
          ),
        ),
      ],
    );
  }
  Widget _buildFullScreenVersion() {
    
    final controller = Get.find<ListarMenuController>();
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EJ',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comedor "El Jobo"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Lista de Menús',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(Get.context!),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateMenuModal(),
            tooltip: 'Crear nuevo menú',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refrescarLista(),
            tooltip: 'Refrescar lista',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Estadísticas y búsqueda completas
            _buildFullHeader(controller),
            SizedBox(height: 20),
            
            // Filtros por categoría
            _buildCategoryFilters(controller),
            SizedBox(height: 20),
            
            // Lista de menús más detallada
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando menús...'),
                      ],
                    ),
                  );
                }
                
                if (controller.filteredMenus.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          controller.menus.isEmpty 
                            ? 'No hay menús registrados'
                            : 'No se encontraron menús con los filtros aplicados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        if (controller.menus.isEmpty) ...[
                          ElevatedButton.icon(
                            onPressed: () => _showCreateMenuModal(),
                            icon: Icon(Icons.add),
                            label: Text('Crear Primer Menú'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  controller.cambiarBusqueda('');
                                  controller.cambiarCategoria(0);
                                },
                                icon: Icon(Icons.clear_all),
                                label: Text('Limpiar Filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showCreateMenuModal(),
                                icon: Icon(Icons.add),
                                label: Text('Nuevo Menú'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B4513),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: controller.filteredMenus.length,
                  itemBuilder: (context, index) {
                    final menu = controller.filteredMenus[index];
                    return _buildFullMenuCard(menu, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // Botón flotante para crear menú
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMenuModal(),
        backgroundColor: Color(0xFF8B4513),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Menú',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(ListarMenuController controller) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            child: TextField(
              onChanged: controller.cambiarBusqueda,
              decoration: InputDecoration(
                hintText: 'Buscar menús...',
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF8B4513)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF8B4513)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: Color(0xFFF5F2F0),
                filled: true,
              ),
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Botón crear compacto
        GestureDetector(
          onTap: () => _showCreateMenuModal(),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
        SizedBox(width: 8),
        Obx(() => GestureDetector(
            onTap: controller.isLoading.value ? null : () => controller.refrescarLista(),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: controller.isLoading.value ? Colors.grey[400] : Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          )),
        SizedBox(width: 8),
        Obx(() => Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFF3498DB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${controller.filteredMenus.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildFullHeader(ListarMenuController controller) {
    return Column(
      children: [
        // Estadísticas
        Obx(() {
          final totalMenus = controller.menus.length;
          final totalValue = controller.menus.fold(0.0, (sum, menu) => sum + menu.precioNumerico);
          final avgPrice = totalMenus > 0 ? totalValue / totalMenus : 0.0;
          
          return Row(
            children: [
              Expanded(child: _buildStatCard('Total Menús', totalMenus.toString(), Icons.restaurant_menu, Color(0xFF8B4513))),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Categorías', controller.categorias.length.toString(), Icons.category, Color(0xFF2196F3))),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Precio Promedio', '\$${avgPrice.toStringAsFixed(2)}', Icons.monetization_on, Color(0xFF4CAF50))),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Filtrados', controller.filteredMenus.length.toString(), Icons.filter_list, Color(0xFFFF9800))),
            ],
          );
        }),
        
        SizedBox(height: 16),
        
        // Barra de búsqueda
        TextField(
          onChanged: controller.cambiarBusqueda,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o descripción...',
            prefixIcon: Icon(Icons.search, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1F08),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(ListarMenuController controller) {
    return Container(
      height: 40,
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.categoriasParaFiltro.length,
        itemBuilder: (context, index) {
          final categoria = controller.categoriasParaFiltro[index];
          final categoriaId = categoria['id'] as int;
          final categoriaNombre = categoria['nombre'] as String;
          final isSelected = controller.selectedCategoryId.value == categoriaId;
          
          return GestureDetector(
            onTap: () => controller.cambiarCategoria(categoriaId),
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF8B4513) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Color(0xFF8B4513) : Colors.grey[300]!,
                ),
              ),
              child: Text(
                categoriaNombre,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF8B4513),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildCompactMenuCard(Menu menu, ListarMenuController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen del menú
          _buildMenuImage(menu, 50),
          
          SizedBox(width: 12),
          
          // Información del menú
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF3E1F08),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                   '${menu.categoriaNombre}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$${menu.precio}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón editar
              GestureDetector(
                onTap: () => _showEditMenuModal(menu),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Color(0xFF8B4513),
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Botón eliminar
              GestureDetector(
                onTap: () => _showDeleteConfirmation(menu, controller),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullMenuCard(Menu menu, ListarMenuController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del menú
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: _buildMenuImage(menu, double.infinity, height: 120),
          ),
          
          // Información del menú
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF3E1F08),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  Text(
                    menu.descripcion,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 8),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.obtenerNombreCategoria(menu.categoriaId),
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Precio y botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${menu.precio}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón editar
                          GestureDetector(
                            onTap: () => _showEditMenuModal(menu),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(0xFF8B4513).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Color(0xFF8B4513),
                                size: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Botón eliminar
                          GestureDetector(
                            onTap: () => _showDeleteConfirmation(menu, controller),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuImage(Menu menu, double width, {double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFF8B4513).withOpacity(0.1),
        borderRadius: BorderRadius.circular(height != null ? 12 : 8),
      ),
      child: menu.imagen != null && menu.imagen!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(height != null ? 12 : 8),
              child: Image.network(
                '${AppConstants.serverBase}${menu.imagen}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.restaurant,
                    color: Color(0xFF8B4513),
                    size: height != null ? 48 : 24,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.restaurant,
              color: Color(0xFF8B4513),
              size: height != null ? 48 : 24,
            ),
    );
  }

  // Modal para crear menú
  void _showCreateMenuModal() {
   final controller2 = Get.find<CreateOrderController>();
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header del modal
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Crear Nuevo Menú',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Contenido del modal
                Expanded(
                  child: CreateEditMenuScreen(isModal: true),
                ),
              ],
            ),
          ),
        );
      },
    ).then((result) {
      // Si se creó exitosamente, refrescar la lista
      if (result == true) {
        final controller = Get.find<ListarMenuController>();
        controller2.cargarDatosIniciales();
        controller.refrescarLista();
final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        if (onMenuUpdated != null) {
          onMenuUpdated!();
        }
      }
    });
  }

  // Modal para editar menú
  void _showEditMenuModal(Menu menu) {
    // Convertir Menu a Map para pasarlo al modal
    Map<String, dynamic> menuData = {
      'id': menu.id,
      'nombre': menu.nombre,
      'descripcion': menu.descripcion,
      'precio': menu.precioNumerico,
      'tiempoPreparacion': menu.tiempoPreparacion,
      'categoriaId': menu.categoriaId, // Ahora es int
      'imagen': menu.imagen,
    };

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header del modal
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editar Menú',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              menu.nombre,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Contenido del modal
                Expanded(
                  child: CreateEditMenuScreen(
                    menuData: menuData,
                    isModal: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((result) {
      // Si se editó exitosamente, refrescar la lista
      if (result == true) {
        final controller = Get.find<ListarMenuController>();
        controller.refrescarLista();

          final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        if (onMenuUpdated != null) {
          onMenuUpdated!();
        }
      }
    });
  }

  void _showDeleteConfirmation(Menu menu, ListarMenuController controller) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Confirmar Eliminación',
      text: '¿Estás seguro de que quieres eliminar "${menu.nombre}"?\n\nEsta acción no se puede deshacer.',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Get.back(); // Cerrar el diálogo
        
        final success = await controller.eliminarMenu(menu.id);
        if (success && onMenuUpdated != null) {
          onMenuUpdated!();
        }
      },
    );
  }
}
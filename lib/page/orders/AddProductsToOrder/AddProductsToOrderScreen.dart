// add_products_to_order_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/AddProductsToOrder/AddProductsToOrderController.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' hide Category;
class AddProductsToOrderScreen extends StatelessWidget {
  final AddProductsToOrderController controller = Get.put(AddProductsToOrderController());
  final TextEditingController _searchController = TextEditingController();

  AddProductsToOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar Productos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            if (controller.pedidoId.value > 0)
              Text(
                'Mesa ${controller.numeromesa.value} • Pedido #${controller.pedidoId.value}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        )),
        backgroundColor: Color(0xFF8B4513),
        elevation: 0,
        // ✅ NUEVO: Botones de acción con búsqueda
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              controller.showSearchResults.value ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              if (controller.showSearchResults.value) {
                _searchController.clear();
                controller.cerrarBusqueda();
              } else {
                // Activar modo búsqueda
                controller.showSearchResults.value = true;
              }
            },
          )),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              controller.refrescarDatos();
              _searchController.clear();
              controller.limpiarBusqueda();
            },
          ),
        ],
      ),
      
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando menú...',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.pedidoId.value == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No se ha seleccionado un pedido válido',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text('Regresar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Info del pedido actual
            _buildOrderInfo(),
            
            // ✅ NUEVO: Buscador o Categorías (condicional)
            controller.showSearchResults.value 
                ? _buildSearchSection() 
                : _buildCategoriesSection(),
            
            // Menu Items (búsqueda o por categoría)
            Expanded(
              child: controller.showSearchResults.value 
                  ? _buildSearchResults()
                  : _buildMenuItems(),
            ),
          ],
        );
      }),
      
      floatingActionButton: Obx(() => controller.cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCart(),
              backgroundColor: Color(0xFF8B4513),
              icon: Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(
                'Ver Productos (\$${controller.totalCarrito.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : SizedBox.shrink()),
    );
  }

  /// ✅ NUEVO: Widget para la sección de búsqueda
  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Título de búsqueda
          Row(
            children: [
              Icon(Icons.search, color: Color(0xFF8B4513)),
              SizedBox(width: 8),
              Text(
                'Buscar productos para agregar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3E1F08),
                ),
              ),
              Spacer(),
              // Contador de resultados
              _buildSearchCounter(),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Campo de búsqueda
          Container(
            height: 45,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Actualizar variable observable
                controller.searchText.value = value;
                
                // Buscar con debounce
                Future.delayed(Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    controller.buscarProductos(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Escribe el nombre del producto...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF8B4513)),
                suffixIcon: _buildClearButton(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8B4513)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(fontSize: 14),
            ),
          ),
          
          // Indicador de búsqueda activa
          _buildSearchIndicator(),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Widget para mostrar resultados de búsqueda
  Widget _buildSearchResults() {
    return Obx(() {
      // Estado de carga de búsqueda
      if (controller.isLoadingSearch.value && controller.searchQuery.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
              ),
              SizedBox(height: 16),
              Text(
                'Buscando productos...',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                ),
              ),
              Text(
                '"${controller.searchQuery.value}"',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }

      // Sin query de búsqueda
      if (controller.searchQuery.value.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Escribe para buscar productos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Busca productos para agregar al pedido',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      // Sin resultados
      if (controller.searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Sin resultados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No se encontraron productos con "${controller.searchQuery.value}"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  controller.cerrarBusqueda();
                },
                icon: Icon(Icons.category),
                label: Text('Ver por categorías'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      // Mostrar resultados
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final producto = controller.searchResults[index];
          return _buildMenuItem(producto, isSearchResult: true);
        },
      );
    });
  }

  // ✅ NUEVO: Widgets auxiliares para la búsqueda
  Widget _buildSearchCounter() {
    return Obx(() => controller.searchResults.isNotEmpty
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${controller.searchResults.length}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : SizedBox.shrink());
  }

  Widget _buildClearButton() {
    return Obx(() => controller.searchText.value.isNotEmpty
        ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              controller.searchText.value = '';
              controller.limpiarBusqueda();
            },
          )
        : SizedBox.shrink());
  }

  Widget _buildSearchIndicator() {
    return Obx(() => controller.searchQuery.value.isNotEmpty
        ? Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF8B4513).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Color(0xFF8B4513)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Buscando: "${controller.searchQuery.value}"',
                    style: TextStyle(
                      color: Color(0xFF8B4513),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (controller.isLoadingSearch.value)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                    ),
                  ),
              ],
            ),
          )
        : SizedBox.shrink());
  }

  /// Info del pedido actual
  Widget _buildOrderInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Obx(() => Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Color(0xFF8B4513),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.nombreOrden.value.isNotEmpty 
                      ? controller.nombreOrden.value
                      : 'Orden sin nombre',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                Text(
                  'Mesa ${controller.numeromesa.value} • Pedido #${controller.pedidoId.value}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ACTIVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        if (controller.isLoadingCategories.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
            ),
          );
        }

        if (controller.categorias.isEmpty) {
          return Center(
            child: Text(
              'No hay categorías disponibles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(Get.context!).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
            scrollbars: false,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: controller.categorias.length,
            itemBuilder: (context, index) {
              final categoria = controller.categorias[index];
              return _buildCategoryItem(categoria, index);
            },
          ),
        );
      }),
    );
  }

  // ✅ CORREGIDO: Widget separado para cada item de categoría
  Widget _buildCategoryItem(Category categoria, int index) {
    return Obx(() {
      final isSelected = controller.selectedCategoryIndex.value == index;
      
      return GestureDetector(
        onTap: () {
          print('📱 Categoría seleccionada: $index');
          controller.cambiarCategoria(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF8B4513) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected ? Colors.black26 : Colors.black12,
                blurRadius: isSelected ? 6 : 4,
                offset: Offset(0, isSelected ? 3 : 2),
              ),
            ],
            border: Border.all(
              color: isSelected ? Color(0xFF8B4513) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  _getCategoryIcon(categoria.nombreCategoria),
                  key: ValueKey('icon_${isSelected}_$index'),
                  color: isSelected ? Colors.white : Color(0xFF8B4513),
                  size: 18,
                ),
              ),
              SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF8B4513),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                child: Text(
                  categoria.nombreCategoria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Lista de productos del menú
  Widget _buildMenuItems() {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando productos...',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.productosPorCategoria.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No hay productos en esta categoría',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.productosPorCategoria.length,
        itemBuilder: (context, index) {
          final producto = controller.productosPorCategoria[index];
          return _buildMenuItem(producto);
        },
      );
    });
  }

  /// ✅ MODIFICADO: Card de producto individual con soporte para búsqueda
  Widget _buildMenuItem(Producto producto, {bool isSearchResult = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white, 
              isSearchResult ? Color(0xFFF0F9FF) : Color(0xFFFAF9F8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: isSearchResult 
              ? Border.all(color: Color(0xFF8B4513).withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          children: [
            // ✅ NUEVO: Indicador de resultado de búsqueda
            if (isSearchResult)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 14, color: Color(0xFF8B4513)),
                    SizedBox(width: 4),
                    Text(
                      'Resultado de búsqueda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        producto.categoria,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Contenido del producto
            Row(
              children: [
                // Product image/emoji
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getProductEmoji(producto.categoria),
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      if (producto.descripcion.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          producto.descripcion,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        '\$${producto.precioDouble.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      if (producto.tiempoPreparacion > 0) ...[
                        SizedBox(height: 2),
                        Text(
                          '⏱️ ${producto.tiempoPreparacion} min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Add to cart button
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _showAddToCartDialog(producto),
                    icon: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




  _showAddToCartDialog(Producto producto) {
  final TextEditingController observacionesController = TextEditingController();
  
  Get.bottomSheet(
    Builder(
      builder: (context) => SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle del bottomsheet
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              
              // Icono
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_shopping_cart,
                  color: Color(0xFF8B4513),
                  size: 40,
                ),
              ),
              SizedBox(height: 16),
              
              // Título
              Text(
                'Agregar al carrito',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              SizedBox(height: 16),
              
              // Info del producto
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F2F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF8B4513).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${producto.precioDouble.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (producto.descripcion.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        producto.descripcion,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Campo de observaciones - MEJORADO
              TextField(
                controller: observacionesController,
                autofocus: false,
                enableInteractiveSelection: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  hintText: 'Ej: Sin cebolla, extra queso...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF8B4513)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF8B4513).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF8B4513)),
                  prefixIcon: Icon(Icons.edit_note, color: Color(0xFF8B4513)),
                ),
                maxLines: 3,
                style: TextStyle(color: Color(0xFF3E1F08)),
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
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.agregarAlCarrito(
                          producto,
                          observaciones: observacionesController.text.trim(),
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Agregar al carrito',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // ✅ ESPACIADO SIMPLIFICADO
              SizedBox(
                height: (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                    ? 24 // Desktop: espaciado fijo
                    : (MediaQuery.of(context).viewInsets.bottom > 0 
                        ? 16 // Móvil con teclado: mínimo
                        : MediaQuery.of(context).viewPadding.bottom + 16), // Móvil sin teclado: normal
              ),
            ],
          ),
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
  );
}
  /// Modal del carrito
  void _showCart() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productos a Agregar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      Obx(() => Text(
                        'Al pedido #${controller.pedidoId.value}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      )),
                    ],
                  ),
                  
                  Row(
                    children: [
                      if (controller.cartItems.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            controller.limpiarCarrito();
                          },
                          child: Text('Limpiar', style: TextStyle(color: Colors.red)),
                        ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Cart items
            Expanded(
              child: Obx(() => controller.cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No has agregado productos',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona productos del menú para agregarlos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = controller.cartItems[index];
                        return _buildCartItem(cartItem, index);
                      },
                    )),
            ),
            
            Obx(() => controller.cartItems.isNotEmpty
                ? Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F2F0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E1F08),
                              ),
                            ),
                            Text(
                              '\$${controller.totalCarrito.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Botón de confirmar
                        SizedBox(
                          width: double.infinity,
                          child: Obx(() => ElevatedButton(
                            onPressed: controller.puedeAgregarProductos
                                ? () => _confirmAddProducts()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.puedeAgregarProductos
                                  ? Color(0xFF8B4513)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: controller.isAddingProducts.value
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Agregando productos...'),
                                    ],
                                  )
                                : Text(
                                    'Agregar ${controller.cartItems.length} producto${controller.cartItems.length != 1 ? 's' : ''} al pedido',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  /// Item del carrito
  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F2F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            _getProductEmoji(cartItem.producto.categoria),
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.producto.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                Text(
                  '\$${cartItem.producto.precioDouble.toStringAsFixed(2)} c/u',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (cartItem.observaciones.isNotEmpty)
                  Text(
                    cartItem.observaciones,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => controller.disminuirCantidad(index),
                icon: Icon(Icons.remove_circle, color: Colors.red),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cartItem.cantidad.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => controller.aumentarCantidad(index),
                icon: Icon(Icons.add_circle, color: Color(0xFF8B4513)),
              ),
            ],
          ),
          Text(
            '\$${cartItem.subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmar agregar productos
  Future<void> _confirmAddProducts() async {
    final success = await controller.agregarProductosAPedido();
    if (success) {
      final ordersController = Get.find<OrdersController>();
      ordersController.refrescarDatos();
      Get.back(); // Cerrar el modal del carrito
      Get.back(); // Regresar a la pantalla anterior
    }
  }

  // Helper methods
  IconData _getCategoryIcon(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower.contains('bebida')) return Icons.local_drink;
    if (categoriaLower.contains('postre')) return Icons.cake;
    if (categoriaLower.contains('extra')) return Icons.add_circle;
    return Icons.restaurant_menu;
  }

  String _getProductEmoji(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower.contains('bebida')) return '🥤';
    if (categoriaLower.contains('postre')) return '🍰';
    if (categoriaLower.contains('extra')) return '🥄';
    return '🌮';
  }
}
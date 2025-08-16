import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/categoria/listarcategoria/category_list_controller.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';

class CategoryListScreen extends StatelessWidget {
  final controller = Get.find<CategoryListController>();
  final TextEditingController _searchController = TextEditingController();

  CategoryListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) => controller.filtrarCategorias(query),
                      decoration: InputDecoration(
                        hintText: 'Buscar categorías...',
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
                
                // Botón crear categoría
                GestureDetector(
                  onTap: () => _showCreateCategoryModal(context),
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
                
                // Botón refrescar
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
                
                // Contador de categorías
                Obx(() => Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${controller.categories.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          // Lista de categorías
          Expanded(
            child: Obx(() {
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
                        'Cargando categorías...',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.filteredCategories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        controller.categories.isEmpty 
                            ? 'No hay categorías registradas'
                            : 'No se encontraron categorías',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        controller.categories.isEmpty
                            ? 'Agrega la primera categoría'
                            : 'Prueba con otros términos de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ✅ CORRECCIÓN PRINCIPAL: ReorderableListView mejorado
              return RefreshIndicator(
                onRefresh: controller.refrescarLista,
                color: Color(0xFF8B4513),
                child: ReorderableListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.filteredCategories.length,
                  // ✅ CRÍTICO: Función onReorder mejorada con validaciones
                  onReorder: (oldIndex, newIndex) {
                    _handleReorder(oldIndex, newIndex);
                  },
                  // ✅ CRÍTICO: Mejorar itemBuilder con mejor manejo de errores
                  itemBuilder: (context, index) {
                    // Validar que el índice sea válido
                    if (index >= controller.filteredCategories.length) {
                      return Container(key: ValueKey('empty_$index'));
                    }
                    
                    final categoria = controller.filteredCategories[index];
                    
                    // Validar que la categoría tenga un ID válido
                    if (categoria['id'] == null) {
                      return Container(key: ValueKey('invalid_$index'));
                    }
                    
                    return _buildDraggableCategoryCard(categoria, index, context);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Método separado para manejar reordenamiento
  void _handleReorder(int oldIndex, int newIndex) {
    try {
      // Validar índices
      if (oldIndex < 0 || newIndex < 0 || 
          oldIndex >= controller.filteredCategories.length || 
          newIndex > controller.filteredCategories.length) {
        print('❌ Índices inválidos: oldIndex=$oldIndex, newIndex=$newIndex');
        return;
      }

      // Ajustar el índice si se mueve hacia abajo
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      print('🔄 Reordenando: $oldIndex -> $newIndex');
      
      // Crear una copia de la lista
      final List<Map<String, dynamic>> items = List.from(controller.filteredCategories);
      
      // Validar que tenemos elementos suficientes
      if (items.length <= oldIndex || newIndex < 0 || newIndex >= items.length) {
        print('❌ Error en reordenamiento: lista inconsistente');
        return;
      }
      
      // Mover el elemento
      final Map<String, dynamic> item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      
      // Actualizar la lista observable
      controller.filteredCategories.value = items;
      
      // Actualizar en el servidor
      controller.actualizarOrdenCategorias(items);
      
    } catch (e) {
      print('❌ Error en reordenamiento: $e');
      // Recargar la lista original si hay error
      controller.refrescarLista();
    }
  }

  // ✅ CORRECCIÓN: Widget card mejorado con contexto local
  Widget _buildDraggableCategoryCard(Map<String, dynamic> categoria, int index, BuildContext context) {
    return Card(
      key: ValueKey(categoria['id']), 
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
            colors: [Colors.white, Color(0xFFFAF9F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Número de orden
                Icon( Icons.drag_handle, color: Colors.grey[400]),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // Ícono de la categoría
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF8B4513).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.category,
                      color: Color(0xFF8B4513),
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // Información de la categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria['nombreCategoria'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${categoria['id']}',
                          style: TextStyle(
                            color: Color(0xFF8B4513),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ✅ CORRECCIÓN: Botón de editar con contexto local
                Obx(() => IconButton(
                  onPressed: controller.isUpdating.value 
                      ? null 
                      : () => controller.mostrarModalEdicion(categoria),
                  icon: controller.isUpdating.value
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                          ),
                        )
                      : Icon(
                          Icons.edit,
                          color: Color(0xFF8B4513),
                          size: 20,
                        ),
                  tooltip: 'Editar categoría',
                )),
                
                // ✅ CORRECCIÓN: Botón de eliminar con contexto local
                Obx(() => IconButton(
                  onPressed: controller.isDeleting.value 
                      ? null 
                      : () => controller.confirmarEliminacion(categoria),
                  icon: controller.isDeleting.value
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                  tooltip: 'Eliminar categoría',
                )),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Descripción
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF5F2F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoria['descripcion'] ?? 'Sin descripción',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CORRECCIÓN: Modal mejorado
  void _showCreateCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle del modal
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header del modal
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300] ?? Colors.grey),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Nueva Categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // Contenido del modal
              Expanded(
                child: CreateCategoryModalContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ CORRECCIÓN: CategoryController mejorado
class CategoryController extends GetxController {
  final RxBool isLoading = false.obs;
  var categorias = <Map<String, dynamic>>[].obs;
  String defaultApiServer = AppConstants.serverBase;

  Future<bool> crearCategoriaConValidacion({
    required String nombre,
    required String descripcion,
  }) async {
    isLoading.value = true;
    
    try {
      // Validaciones locales
      if (nombre.trim().isEmpty) {
        _mostrarError('El nombre de la categoría es requerido');
        return false;
      }
      
      if (descripcion.trim().isEmpty) {
        _mostrarError('La descripción de la categoría es requerida');
        return false;
      }

      if (nombre.trim().length < 2) {
        _mostrarError('El nombre debe tener al menos 2 caracteres');
        return false;
      }

      // Preparar datos para enviar
      final Map<String, dynamic> categoriaData = {
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
      };

      print('📡 Enviando datos de categoría: $categoriaData');

      // Realizar petición HTTP
      final Uri uri = Uri.parse('$defaultApiServer/menu/crearCategoriaMenu/');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(categoriaData),
      );

      print('📡 Respuesta del servidor - Código: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      // Manejar respuesta
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Verificar si la respuesta indica éxito
        if (responseData['success'] == true || response.statusCode == 201) {
          // Éxito - mostrar mensaje
          _mostrarExito('Categoría creada exitosamente');
          
          // ✅ CORRECCIÓN: Verificar si existe el controller antes de usarlo
          if (Get.isRegistered<CategoryListController>()) {
            final controller = Get.find<CategoryListController>();
            controller.listarCategorias();
          }
          
          // Recargar datos del menú si existe CreateOrderController
          await _recargarDatosMenu();
          
          return true;
        } else {
          // El servidor respondió pero indica error
          final mensaje = responseData['message'] ?? 'Error desconocido del servidor';
          _mostrarError('Error al crear categoría: $mensaje');
          return false;
        }
      } else {
        // Error HTTP
        String mensajeError = 'Error del servidor (${response.statusCode})';
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            mensajeError = errorData['message'];
          } else if (errorData['error'] != null) {
            mensajeError = errorData['error'];
          }
        } catch (e) {
          // Si no se puede parsear el error, usar mensaje genérico
        }
        
        _mostrarError(mensajeError);
        return false;
      }

    } on http.ClientException catch (e) {
      print('❌ Error de conexión: $e');
      _mostrarError('Error de conexión. Verifica tu internet.');
      return false;
    } catch (e) {
      print('❌ Error inesperado: $e');
      _mostrarError('Error inesperado: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _recargarDatosMenu() async {
    try {
      // Buscar si existe CreateOrderController
      if (Get.isRegistered<CreateOrderController>()) {
        final CreateOrderController controller = Get.find<CreateOrderController>();
        await controller.cargarDatosIniciales();
        print('✅ Datos del menú recargados');
      } else {
        print('ℹ️ CreateOrderController no encontrado - no se recargaron datos');
      }
    } catch (e) {
      print('⚠️ Error al recargar datos del menú: $e');
    }
  }

  // ✅ CORRECCIÓN: Métodos de mostrar mensajes mejorados
  void _mostrarError(String mensaje) {
    final context = Get.context;
    if (context != null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: mensaje,
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
    } else {
      print('❌ ERROR: $mensaje');
    }
  }

  void _mostrarExito(String mensaje) {
    final context = Get.context;
    if (context != null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Éxito',
        text: mensaje,
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFF27AE60),
      );
    } else {
      print('✅ ÉXITO: $mensaje');
    }
  }

  void _mostrarAdvertencia(String mensaje) {
    final context = Get.context;
    if (context != null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Advertencia',
        text: mensaje,
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
    } else {
      print('⚠️ ADVERTENCIA: $mensaje');
    }
  }
}

// ✅ Widget CreateCategoryModalContent sin cambios (ya estaba correcto)
class CreateCategoryModalContent extends StatefulWidget {
  CreateCategoryModalContent({Key? key}) : super(key: key);

  @override
  _CreateCategoryModalContentState createState() => _CreateCategoryModalContentState();
}

class _CreateCategoryModalContentState extends State<CreateCategoryModalContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isInitialized = false;
  Timer? _debounceTimer;
  
  late final CategoryController categoryController;

  @override
  void initState() {
    super.initState();
    categoryController = Get.put(CategoryController(), permanent: false);
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            SizedBox(height: 24),
            _buildDescriptionField(),
            Spacer(),
            _buildActionButtons(context),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Nombre de la categoría',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
            ),
            prefixIcon: Icon(Icons.label, color: Color(0xFF8B4513)),
            fillColor: Colors.white,
            filled: true,
          ),
          textInputAction: TextInputAction.next,
          autocorrect: true,
          enableSuggestions: true,
          textCapitalization: TextCapitalization.words,
          onFieldSubmitted: (value) {
            FocusScope.of(context).nextFocus();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el nombre';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Descripción de la categoría',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
            ),
            fillColor: Colors.white,
            filled: true,
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.done,
          autocorrect: true,
          enableSuggestions: true,
          textCapitalization: TextCapitalization.sentences,
          onFieldSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la descripción';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _clearFields(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF8B4513)),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Limpiar',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
              onPressed: categoryController.isLoading.value 
                  ? null 
                  : () => _saveCategory(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryController.isLoading.value 
                    ? Colors.grey 
                    : Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: categoryController.isLoading.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Guardando...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )),
          ),
        ],
      ),
    );
  }

  void _clearFields(BuildContext context) {
    if (mounted) {
      _nameController.clear();
      _descriptionController.clear();
      
      FocusScope.of(context).unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campos limpiados'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF8B4513),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: 20,
            right: 20,
          ),
        ),
      );
    }
  }

  void _saveCategory(BuildContext context) async {
    if (!mounted) return;
    
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      try {
        final success = await categoryController.crearCategoriaConValidacion(
          nombre: _nameController.text.trim(),
          descripcion: _descriptionController.text.trim(),
        );
        
        if (!mounted) return;
        
        if (success) {
          _clearFields(context);
          Navigator.of(context).pop(true);
          
          Future.delayed(Duration(milliseconds: 300), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Categoría creada exitosamente'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Error al crear categoría: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.1,
                left: 20,
                right: 20,
              ),
            ),
          );
        }
      }
    }
  }

  Map<String, String>? getFormData() {
    if (_formKey.currentState!.validate()) {
      return {
        'nombre': _nameController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
      };
    }
    return null;
  }

  void clearFromParent() {
    if (mounted) {
      _nameController.clear();
      _descriptionController.clear();
    }
  }
}
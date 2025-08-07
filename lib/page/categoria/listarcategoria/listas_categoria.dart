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
  final CategoryListController controller = Get.put(CategoryListController());
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
      // Botón crear categoría compacto
      GestureDetector(
        onTap: () => _showCreateCategoryModal(context), // Ajusta según tu método
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
            '${controller.categories.length}', // Ajusta según tu observable
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
                      Obx(() => Text(
                        controller.categories.isEmpty 
                            ? 'No hay categorías registradas'
                            : 'No se encontraron categorías',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      SizedBox(height: 8),
                      Obx(() => Text(
                        controller.categories.isEmpty
                            ? 'Agrega la primera categoría'
                            : 'Prueba con otros términos de búsqueda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      )),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refrescarLista,
                color: Color(0xFF8B4513),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.filteredCategories.length,
                  itemBuilder: (context, index) {
                    final categoria = controller.filteredCategories[index];
                    return _buildCategoryCard(categoria);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      
    );
  }

  // Método para mostrar el modal
  void _showCreateCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal use toda la pantalla
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // 90% de la pantalla
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
                    bottom: BorderSide(color: Colors.grey[300]!),
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

  Widget _buildCategoryCard(Map<String, dynamic> categoria) {
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
                // Ícono de la categoría
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xFF8B4513).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.category,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // Información de la categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria['nombreCategoria'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E1F08),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${categoria['id']}',
                          style: TextStyle(
                            color: Color(0xFF8B4513),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botón de eliminar
                Obx(() => IconButton(
                  onPressed: controller.isDeleting.value 
                      ? null 
                      : () => controller.confirmarEliminacion(categoria),
                  icon: controller.isDeleting.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 24,
                        ),
                )),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Descripción
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF5F2F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                categoria['descripcion'] ?? 'Sin descripción',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ MODIFICACIÓN 1: Cambiar a StatefulWidget
class CreateCategoryModalContent extends StatefulWidget {
  CreateCategoryModalContent({Key? key}) : super(key: key);

  @override
  _CreateCategoryModalContentState createState() => _CreateCategoryModalContentState();
}

// ✅ MODIFICACIÓN 2: Crear el State
class _CreateCategoryModalContentState extends State<CreateCategoryModalContent> {
  // Controllers para los campos de texto
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // ✅ NUEVO: Variables para optimización
  bool _isInitialized = false;
  Timer? _debounceTimer;
  
  late final CategoryController categoryController;

  @override
  void initState() {
    super.initState();
    // ✅ MODIFICADO: Inicializar el controlador aquí
    categoryController = Get.put(CategoryController(), permanent: false);
    _isInitialized = true;
  }

  @override
  void dispose() {
    // ✅ NUEVO: Limpiar recursos
    _nameController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  // ✅ NUEVO: Método separado para el contenido
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campos de entrada
            _buildNameField(),
            
            SizedBox(height: 24),
            
            _buildDescriptionField(),
            
            Spacer(),
            
            // Botones con manejo del teclado
            _buildActionButtons(context),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVO: Widget separado para el campo nombre
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
          // ✅ NUEVO: Configuraciones importantes para móvil en modales
          textInputAction: TextInputAction.next,
          autocorrect: true,
          enableSuggestions: true,
          textCapitalization: TextCapitalization.words,
          // ✅ CRÍTICO: Para modales, manejar mejor el foco
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

  // ✅ NUEVO: Widget separado para el campo descripción
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
          // ✅ NUEVO: Configuraciones importantes para móvil en modales
          textInputAction: TextInputAction.done,
          autocorrect: true,
          enableSuggestions: true,
          textCapitalization: TextCapitalization.sentences,
          // ✅ CRÍTICO: Para modales, manejar el "done" del teclado
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

  // ✅ NUEVO: Widget separado para los botones con manejo del teclado
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      // ✅ CRÍTICO: Para modales, manejar correctamente el teclado
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

  // ✅ MODIFICADO: Mejorar método para limpiar campos en modal
  void _clearFields(BuildContext context) {
    if (mounted) {
      _nameController.clear();
      _descriptionController.clear();
      
      // ✅ CRÍTICO: En modales, cerrar el teclado es más importante
      FocusScope.of(context).unfocus();
      
      // ✅ NUEVO: Feedback visual para modales (más sutil)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campos limpiados'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF8B4513),
          behavior: SnackBarBehavior.floating, // ✅ Mejor para modales
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: 20,
            right: 20,
          ),
        ),
      );
    }
  }

  // ✅ MODIFICADO: Mejorar método para guardar en modal
  void _saveCategory(BuildContext context) async {
    // ✅ NUEVO: Verificar que el widget aún esté montado
    if (!mounted) return;
    
    // ✅ CRÍTICO: En modales, cerrar el teclado antes de procesar
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      try {
        // Usar el controller para crear la categoría
        final success = await categoryController.crearCategoriaConValidacion(
          nombre: _nameController.text.trim(),
          descripcion: _descriptionController.text.trim(),
        );
        
        // ✅ NUEVO: Verificar mounted antes de continuar
        if (!mounted) return;
        
        // Si fue exitoso
        if (success) {
          // ✅ NUEVO: En modales, cerrar después del éxito
          _clearFields(context);
          
          // ✅ OPCIONAL: Cerrar el modal automáticamente
          Navigator.of(context).pop(true); // true indica éxito
          
          // ✅ NUEVO: Mostrar mensaje de éxito (se verá en la pantalla padre)
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
        // ✅ NUEVO: Manejo de errores en modal
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

  // ✅ NUEVO: Método para obtener datos del formulario (útil para el modal padre)
  Map<String, String>? getFormData() {
    if (_formKey.currentState!.validate()) {
      return {
        'nombre': _nameController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
      };
    }
    return null;
  }

  // ✅ NUEVO: Método para limpiar desde el widget padre
  void clearFromParent() {
    if (mounted) {
      _nameController.clear();
      _descriptionController.clear();
    }
  }
}

// Necesitarás importar esta clase también
class CategoryController extends GetxController {
  final RxBool isLoading = false.obs;
  
  // Lista de categorías (si las necesitas para mostrar)
  var categorias = <Map<String, dynamic>>[].obs;
  
  String defaultApiServer = AppConstants.serverBase;
  // Tu implementación del CategoryController aquí
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
            final CategoryListController controller = Get.put(CategoryListController());

          controller.listarCategorias();
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
  void _mostrarError(String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      title: 'Error',
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
  }
 void _mostrarExito(String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.success,
      title: 'Éxito',
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFF27AE60),
    );
  }
  /// Mostrar mensaje de advertencia
  void _mostrarAdvertencia(String mensaje) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.warning,
      title: 'Advertencia',
      text: mensaje,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFF39C12),
    );
  }

}
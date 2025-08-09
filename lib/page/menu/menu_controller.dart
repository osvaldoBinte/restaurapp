import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/menu/listarmenu/listar_controller.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
import 'package:restaurapp/page/orders/orders_controller.dart';

// Modelo para las categorías - CORREGIDO
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
      nombre: json['nombreCategoria'] ?? '', // Usar nombreCategoria del JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nombreCategoria': nombre,
    };
  }

  // ✅ AGREGADO: Override de operadores para evitar duplicados
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Categoria(id: $id, nombre: $nombre)';
}

// Controller GetX para crear y editar menús - CORREGIDO
class MenuController extends GetxController {
  var isLoading = false.obs;
  var isCreating = false.obs;
  var isUpdating = false.obs;
  var categories = <Categoria>[].obs;
  var message = ''.obs;
  
  // Variables observables para el formulario
  var selectedCategoryId = Rxn<int>();
  var selectedImage = Rxn<File>();
  var previewUpdate = 0.obs;
  
  // Variables para modo edición
  var isEditMode = false.obs;
  var editingMenuId = Rxn<int>();
  var currentImageUrl = Rxn<String>();
  
  String defaultApiServer = AppConstants.serverBase;

  @override
  void onInit() {
    super.onInit();
    obtenerCategorias();
  }

  /// Método para inicializar en modo creación - CORREGIDO
  void initializeForCreate() {
    print('🔄 Inicializando modo CREACIÓN');
    isEditMode.value = false;
    editingMenuId.value = null;
    currentImageUrl.value = null;
    clearForm();
    
    // ✅ IMPORTANTE: Recargar categorías para asegurar datos frescos
    obtenerCategorias();
  }

  /// Método para inicializar en modo edición - CORREGIDO
  void initializeForEdit(Map<String, dynamic> menuData) {
    print('🔄 Inicializando modo EDICIÓN');
    print('   - Datos recibidos: $menuData');
    
    isEditMode.value = true;
    editingMenuId.value = menuData['id'];
    currentImageUrl.value = menuData['imagen'];
    selectedImage.value = null;
    
    // ✅ CORREGIDO: Esperar a que las categorías se carguen antes de asignar
    if (categories.isEmpty) {
      print('   - Categorías vacías, cargando primero...');
      obtenerCategorias().then((_) {
        _asignarCategoriaEdicion(menuData);
      });
    } else {
      _asignarCategoriaEdicion(menuData);
    }
    
    updatePreview();
  }

  // ✅ NUEVO: Método auxiliar para asignar categoría en edición
  void _asignarCategoriaEdicion(Map<String, dynamic> menuData) {
    final categoriaId = menuData['categoriaId'];
    print('   - Intentando asignar categoria ID: $categoriaId');
    print('   - Categorías disponibles: ${categories.map((c) => 'ID:${c.id}').join(', ')}');
    
    if (categoriaId != null) {
      final existe = categories.any((cat) => cat.id == categoriaId);
      if (existe) {
        selectedCategoryId.value = categoriaId;
        print('   ✅ Categoría $categoriaId asignada correctamente');
      } else {
        print('   ⚠️ Categoría $categoriaId no encontrada en la lista');
        selectedCategoryId.value = null;
      }
    } else {
      selectedCategoryId.value = null;
      print('   ⚠️ No se proporcionó categoriaId');
    }
  }

  /// Método para obtener categorías disponibles - MEJORADO
  Future<void> obtenerCategorias({BuildContext? context}) async {
    try {
      isLoading.value = true;
      
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
        
        // ✅ CORREGIDO: Limpiar lista antes de llenar para evitar duplicados
        categories.clear();
        
        // ✅ CORREGIDO: Filtrar duplicados por ID antes de agregar
        final categoriasUnicas = <Categoria>[];
        final idsVistos = <int>{};
        
        for (var json in data) {
          final categoria = Categoria.fromJson(json);
          if (!idsVistos.contains(categoria.id)) {
            categoriasUnicas.add(categoria);
            idsVistos.add(categoria.id);
          }
        }
        
        categories.value = categoriasUnicas;
        
        print('✅ ${categories.length} categorías únicas cargadas:');
        for (var cat in categories) {
          print('   - ID: ${cat.id}, Nombre: ${cat.nombre}');
        }
        
        // ✅ MEJORADO: Validar categoría seleccionada después de cargar
        _validarCategoriaSeleccionada();
        
      } else {
         print('⚠️ Error al cargar categorías: ${response.statusCode}');
        if (context?.mounted == true) {
          mostrarErrorCategorias(context!, 'No se pudieron obtener las categorías disponibles');
        }
      }
      
    } catch (e) {
      print('🚨 Error al obtener categorías: $e');
        if (context?.mounted == true) {
        mostrarErrorCategorias(context!, 'No se pudo conectar para obtener las categorías');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NUEVO: Método para validar categoría seleccionada
  void _validarCategoriaSeleccionada() {
    if (selectedCategoryId.value != null) {
      final existe = categories.any((cat) => cat.id == selectedCategoryId.value);
      if (!existe) {
        print('⚠️ Categoría seleccionada (${selectedCategoryId.value}) no existe, limpiando...');
        selectedCategoryId.value = null;
      } else {
        print('✅ Categoría seleccionada (${selectedCategoryId.value}) es válida');
      }
    }
  }

  // ✅ NUEVO: Método auxiliar para mostrar errores de categorías
 void mostrarErrorCategorias(BuildContext context, String mensaje) {
    if (!context.mounted) return; // ✅ Verificar que el context esté activo
    
    
  }
  /// Método para establecer la categoría seleccionada - MEJORADO
  void setSelectedCategory(int? categoryId) {
    print('📋 Estableciendo categoría: $categoryId');
    
    if (categoryId != null) {
      final existe = categories.any((cat) => cat.id == categoryId);
      if (existe) {
        selectedCategoryId.value = categoryId;
        print('   ✅ Categoría $categoryId establecida correctamente');
      } else {
        print('   ⚠️ Categoría $categoryId no existe en la lista');
        selectedCategoryId.value = null;
      }
    } else {
      selectedCategoryId.value = null;
      print('   ✅ Categoría limpiada (null)');
    }
    
    updatePreview();
  }

  /// Método para obtener el nombre de una categoría por su ID
  String obtenerNombreCategoria(int categoriaId) {
    final categoria = categories.firstWhereOrNull((cat) => cat.id == categoriaId);
    final nombre = categoria?.nombre ?? 'Sin categoría';
    print('🏷️ Nombre para categoria $categoriaId: $nombre');
    return nombre;
  }

  /// Método para limpiar la imagen seleccionada
  void clearSelectedImage() {
    selectedImage.value = null;
    updatePreview();
  }

  /// Método para actualizar la vista previa
  void updatePreview() {
    previewUpdate.value++;
  }

  /// Método para limpiar todo el formulario - MEJORADO
  void clearForm() {
    print('🧹 Limpiando formulario completo');
    selectedCategoryId.value = null;
    selectedImage.value = null;
    currentImageUrl.value = null;
    updatePreview();
  }

  /// Método para crear un nuevo menú
  Future<bool> crearMenu({
    required String nombre,
    required String descripcion,
    required double precio,
    int? tiempoPreparacion,
    File? imagenFile,
    required int categoriaId,
        required BuildContext context, // ✅ Agregar context como parámetro

  }) async {
    try {
      isCreating.value = true;
      message.value = '';
      
      Uri uri = Uri.parse('$defaultApiServer/menu/crearMenu/');
      
      print('🌐 Enviando POST a: $uri');
      
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['nombre'] = nombre.trim();
      request.fields['descripcion'] = descripcion.trim();
      request.fields['precio'] = precio.toString();
      request.fields['tiempoPreparacion'] = (tiempoPreparacion ?? 0).toString();
      request.fields['categoriaId'] = categoriaId.toString();
      
      if (imagenFile != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'imagen',
          imagenFile.path,
        );
        request.files.add(multipartFile);
        print('📸 Imagen agregada: ${imagenFile.path}');
      } else {
        request.fields['imagen'] = "";
      }
      
      print('📝 Datos enviados como form-data (CREATE):');
      print('   - nombre: "${request.fields['nombre']}"');
      print('   - descripcion: "${request.fields['descripcion']}"');
      print('   - precio: "${request.fields['precio']}"');
      print('   - tiempoPreparacion: "${request.fields['tiempoPreparacion']}"');
      print('   - categoriaId: "${request.fields['categoriaId']}"');
      print('   - imagen: ${imagenFile != null ? "Archivo adjunto" : "Sin imagen"}');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');
      
       if (response.statusCode == 200 || response.statusCode == 201) {
        message.value = 'Menú creado exitosamente';
        final controller2 = Get.find<CreateOrderController>();
        controller2.cargarDatosIniciales();
        

         final controller = Get.find<ListarMenuController>();
        controller2.cargarDatosIniciales();
        controller.refrescarLista();
final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        // ✅ VERIFICAR: Context antes de mostrar alert
        if (context.mounted) {
          QuickAlert.show(
            context: context, // ✅ Usar context del widget
            type: QuickAlertType.success,
            title: '¡Éxito!',
            text: 'Menú "$nombre" creado correctamente',
            confirmBtnText: 'OK',
            confirmBtnColor: Color(0xFF8B4513),
            autoCloseDuration: Duration(seconds: 3),
          );
        }
        
        return true;
        
      } else {
        return _handleErrorResponse(response, request, imagenFile, context);
      }
      
    } catch (e) {
      return _handleException(e, 'crearMenu',context);
    } finally {
      isCreating.value = false;
    }
  }

  /// Método para actualizar un menú existente
  Future<bool> actualizarMenu({
    required int menuId,
    required String nombre,
    required String descripcion,
    required double precio,
    int? tiempoPreparacion,
    File? imagenFile,
    required int categoriaId,
        required BuildContext context, // ✅ Agregar context como parámetro

  }) async {
    try {
      isUpdating.value = true;
      message.value = '';
      
      Uri uri = Uri.parse('$defaultApiServer/menu/modificarMenu/$menuId/');
      
      print('🌐 Enviando PUT a: $uri');
      
      var request = http.MultipartRequest('PUT', uri);
      
      request.fields['nombre'] = nombre.trim();
      request.fields['descripcion'] = descripcion.trim();
      request.fields['precio'] = precio.toString();
      request.fields['tiempoPreparacion'] = (tiempoPreparacion ?? 0).toString();
      request.fields['categoriaId'] = categoriaId.toString();
      
      // Solo agregar imagen si se seleccionó una nueva
      if (imagenFile != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'imagen',
          imagenFile.path,
        );
        request.files.add(multipartFile);
        print('📸 Nueva imagen agregada: ${imagenFile.path}');
      } else {
        // Si no hay nueva imagen, mantener la actual (o vacío si no había)
        request.fields['imagen'] = "";
        print('📸 Manteniendo imagen actual o sin imagen');
      }
      
      print('📝 Datos enviados como form-data (UPDATE):');
      print('   - menuId: $menuId');
      print('   - nombre: "${request.fields['nombre']}"');
      print('   - descripcion: "${request.fields['descripcion']}"');
      print('   - precio: "${request.fields['precio']}"');
      print('   - tiempoPreparacion: "${request.fields['tiempoPreparacion']}"');
      print('   - categoriaId: "${request.fields['categoriaId']}"');
      print('   - imagen: ${imagenFile != null ? "Nueva imagen adjunta" : "Sin cambio de imagen"}');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta del servidor: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        message.value = 'Menú actualizado exitosamente';
       final controller2 = Get.find<CreateOrderController>();
         controller2.cargarDatosIniciales();
          final controller = Get.find<ListarMenuController>();
        controller2.cargarDatosIniciales();
        controller.refrescarLista();
final controller3 = Get.find<OrdersController>();
          controller3.cargarDatos();
        if (context.mounted) {
          QuickAlert.show(
            context: context, // ✅ Usar context del widget
            type: QuickAlertType.success,
            title: '¡Éxito!',
            text: 'Menú "$nombre" actualizado correctamente',
            confirmBtnText: 'OK',
            confirmBtnColor: Color(0xFF8B4513),
            autoCloseDuration: Duration(seconds: 3),
          );
        }
        return true;
        
      } else {
        return _handleErrorResponse(response, request, imagenFile, context);
      }
      
    } catch (e) {
      return _handleException(e, 'actualizarMenu', context);
    } finally {
      isUpdating.value = false;
    }
  }

  /// Método unificado para manejar errores de respuesta
  bool _handleErrorResponse(http.Response response, http.MultipartRequest request, File? imagenFile,BuildContext context, ) {
        if (!context.mounted) return false; // ✅ Verificar context

    if (response.statusCode == 400) {
      String errorMessage = 'Error en los datos enviados';
      
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is String) {
          errorMessage = errorData;
        } else {
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Todos los campos son obligatorios';
        }
      } catch (e) {
        errorMessage = response.body.replaceAll('"', '');
      }
      
      message.value = errorMessage;
      
     QuickAlert.show(
        context: context, // ✅ Usar context del widget
        type: QuickAlertType.error,
        title: 'Error de Validación (400)',
        text: '$errorMessage\n\nDatos enviados como form-data:\n'
              '• nombre: "${request.fields['nombre']}"\n'
              '• descripcion: "${request.fields['descripcion']}"\n'
              '• precio: "${request.fields['precio']}"\n'
              '• tiempoPreparacion: "${request.fields['tiempoPreparacion']}"\n'
              '• categoriaId: "${request.fields['categoriaId']}"\n'
              '• imagen: ${imagenFile != null ? "Archivo adjunto" : "Sin imagen"}',
        confirmBtnText: 'Revisar',
        confirmBtnColor: Color(0xFFE74C3C),
      );
      
      return false;
      
    } else {
      String errorMessage = 'Error del servidor (${response.statusCode})';
      
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'Error: ${response.reasonPhrase}';
      }
      
      message.value = errorMessage;
      
        QuickAlert.show(
        context: context, // ✅ Usar context del widget
        type: QuickAlertType.error,
        title: 'Error del Servidor',
        text: 'Error del servidor',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFE74C3C),
      );
      return false;
    }
  }

  /// Método unificado para manejar excepciones
   bool _handleException(dynamic e, String methodName, BuildContext context) {
    if (!context.mounted) return false; // ✅ Verificar context
    
    String errorMessage = 'Error de conexión: ${e.toString()}';
    message.value = errorMessage;
    
    print('🚨 Error en $methodName: $e');
    
    QuickAlert.show(
      context: context, // ✅ Usar context del widget
      type: QuickAlertType.error,
      title: 'Error de Conexión',
      text: 'No se pudo conectar al servidor.\nVerifica tu conexión a internet.',
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFE74C3C),
    );
    
    return false;
  }

  /// Método para validar datos antes de enviar
  bool validarDatos({
    required String nombre,
    required String descripcion,
    required String precio,
    required int? categoriaId,
    required BuildContext context, // ✅ Agregar context
  }) {
    if (!context.mounted) return false; // ✅ Verificar context
    
    if (nombre.isEmpty) {
      QuickAlert.show(
        context: context, // ✅ Usar context del widget
        type: QuickAlertType.warning,
        title: 'Campo Requerido',
        text: 'El nombre del menú es requerido',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }
    
    if (descripcion.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Campo Requerido',
        text: 'La descripción es requerida',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }
    
    if (precio.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Campo Requerido',
        text: 'El precio es requerido',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }
    
    final precioValue = double.tryParse(precio);
    if (precioValue == null || precioValue <= 0) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Precio Inválido',
        text: 'Ingresa un precio válido mayor a 0',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }
    
    if (categoriaId == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Categoría Requerida',
        text: 'Selecciona una categoría para el menú',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
      return false;
    }
    
    return true;
  }

  /// Método conveniente que combina validación y creación/actualización
   Future<bool> guardarMenuConValidacion({
    required String nombre,
    required String descripcion,
    required String precio,
    String? tiempoPreparacion,
    File? imagenFile,
    required int? categoriaId,
    required BuildContext context, // ✅ Agregar context
  }) async {
    if (!validarDatos(
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      categoriaId: categoriaId,
      context: context, // ✅ Pasar context
    )) {
      return false;
    }
    
    final precioValue = double.parse(precio);
    final tiempoValue = tiempoPreparacion?.isNotEmpty == true 
        ? int.tryParse(tiempoPreparacion!) 
        : null;
    
    if (isEditMode.value && editingMenuId.value != null) {
      // Modo actualización
      return await actualizarMenu(
        menuId: editingMenuId.value!,
        nombre: nombre,
        descripcion: descripcion,
        precio: precioValue,
        tiempoPreparacion: tiempoValue,
        imagenFile: imagenFile,
        categoriaId: categoriaId!,
        context: context, // ✅ Pasar context
      );
    } else {
      // Modo creación
      return await crearMenu(
        nombre: nombre,
        descripcion: descripcion,
        precio: precioValue,
        tiempoPreparacion: tiempoValue,
        imagenFile: imagenFile,
        categoriaId: categoriaId!,
        context: context, // ✅ Pasar context
      );
    }
  }

  /// Método legacy para mantener compatibilidad
  Future<bool> crearMenuConValidacion({
    required String nombre,
    required String descripcion,
    required String precio,
    String? tiempoPreparacion,
    File? imagenFile,
    required int? categoriaId,
    required BuildContext context, // ✅ Agregar context
  }) async {
    return await guardarMenuConValidacion(
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      tiempoPreparacion: tiempoPreparacion,
      imagenFile: imagenFile,
      categoriaId: categoriaId,
      context: context, // ✅ Usar context de GetX
    );
  }

  Future<File?> seleccionarImagenGaleria(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      if (context.mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'No se pudo seleccionar la imagen',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );
      }
      return null;
    }
  }

   Future<File?> tomarFotoCamara(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error al tomar foto: $e');
      if (context.mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'No se pudo tomar la foto',
          confirmBtnText: 'OK',
          confirmBtnColor: Color(0xFFE74C3C),
        );
      }
      return null;
    }
  }

  /// Método actualizado para mostrar opciones de imagen
   void mostrarOpcionesImagen(BuildContext context) {
    if (!context.mounted) return; // ✅ Verificar context
    
    QuickAlert.show(
      context: context, // ✅ Usar context del widget
      type: QuickAlertType.custom,
      title: 'Seleccionar Imagen',
      text: '¿Cómo quieres agregar la imagen?',
      widget: Column(
        children: [
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final image = await seleccionarImagenGaleria(context);
                    if (image != null) {
                      selectedImage.value = image;
                      updatePreview();
                    }
                  },
                  icon: Icon(Icons.photo_library),
                  label: Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final image = await tomarFotoCamara(context);
                    if (image != null) {
                      selectedImage.value = image;
                      updatePreview();
                    }
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      confirmBtnText: 'Cancelar',
      confirmBtnColor: Colors.grey,
    );
  }

  /// Getters para el estado de loading
  bool get isProcessing => isCreating.value || isUpdating.value;
  
  /// Getter para el texto del botón
  String get buttonText {
    if (isEditMode.value) {
      return isUpdating.value ? 'Actualizando...' : 'Actualizar Menú';
    } else {
      return isCreating.value ? 'Guardando...' : 'Guardar Menú';
    }
  }
  
  /// Getter para el título de la pantalla
  String get screenTitle {
    return isEditMode.value ? 'Editar Menú' : 'Crear Nuevo Menú';
  }
  
  /// Getter para el título del header
  String get headerTitle {
    return isEditMode.value ? 'Editar Platillo' : 'Nuevo Platillo';
  }
  
  /// Getter para el subtítulo del header
  String get headerSubtitle {
    return isEditMode.value ? 'Modifica la información del platillo' : 'Agrega un nuevo platillo al menú';
  }
}
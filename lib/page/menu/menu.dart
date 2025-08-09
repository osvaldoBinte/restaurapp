import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/widgets/base64.dart';
import 'package:restaurapp/page/menu/menu_controller.dart';
// ✅ MODIFICACIÓN 1: Cambiar CreateEditMenuScreen a StatefulWidget
class CreateEditMenuScreen extends StatefulWidget {
  final Map<String, dynamic>? menuData;
  final bool isModal;

  CreateEditMenuScreen({
    Key? key, 
    this.menuData,
    this.isModal = false,
  }) : super(key: key);

  @override
  _CreateEditMenuScreenState createState() => _CreateEditMenuScreenState();
}

// ✅ MODIFICACIÓN 2: Crear el State y mover los controladores aquí
class _CreateEditMenuScreenState extends State<CreateEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _timeController = TextEditingController();
  
  // ✅ NUEVO: Variable para evitar múltiples inicializaciones
  bool _isInitialized = false;
  
  late final MenuController menuController;

  @override
  void initState() {
    super.initState();
    // ✅ MODIFICADO: Inicializar el controlador aquí
    menuController = Get.put(MenuController(), permanent: false);
    _initializeController();
  }

  void _initializeController() {
    if (_isInitialized) return;
    
    // Inicializar según el modo
    if (widget.menuData != null) {
      // Modo edición
      menuController.initializeForEdit(widget.menuData!);
      _populateForm();
    } else {
      // Modo creación
      menuController.initializeForCreate();
    }
    
    _isInitialized = true;
  }

  void _populateForm() {
    if (widget.menuData != null) {
      _nameController.text = widget.menuData!['nombre'] ?? '';
      _descriptionController.text = widget.menuData!['descripcion'] ?? '';
      _priceController.text = widget.menuData!['precio']?.toString() ?? '';
      _timeController.text = widget.menuData!['tiempoPreparacion']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    // ✅ NUEVO: Limpiar controladores
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si es modal, no mostrar Scaffold
    if (widget.isModal) {
      return _buildContent();
    }
    
    // Si no es modal, mostrar pantalla completa
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      color: widget.isModal ? Colors.white : Color(0xFFF5F2F0),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dinámico (solo si no es modal)
              if (!widget.isModal) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Obx(() => Icon(
                        menuController.isEditMode.value 
                            ? Icons.edit_note 
                            : Icons.restaurant_menu,
                        size: 48,
                        color: Colors.white,
                      )),
                      SizedBox(height: 12),
                      Obx(() => Text(
                        menuController.headerTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )),
                      Obx(() => Text(
                        menuController.headerSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
              
              // Información Básica
              _buildSectionTitle('Información Básica'),
              SizedBox(height: 12),
              _buildInputCard(
                title: 'Nombre del Platillo',
                child: TextFormField(
                  controller: _nameController,
                  // ✅ MODIFICADO: Optimizar el callback onChanged
                  onChanged: (value) {
                    // Usar debounce para evitar múltiples llamadas
                    _debounceUpdatePreview();
                  },
                  decoration: _buildInputDecoration(
                    'Ej: Quesadilla de Pollo',
                    Icons.restaurant,
                  ),
                  // ✅ NUEVO: Configuraciones importantes para móvil
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
              ),
              
              SizedBox(height: 16),
              
              // Descripción
              _buildInputCard(
                title: 'Descripción',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  onChanged: (value) => _debounceUpdatePreview(),
                  decoration: _buildInputDecoration(
                    'Describe los ingredientes y preparación...',
                    null,
                  ),
                  // ✅ NUEVO: Configuraciones para móvil
                  textInputAction: TextInputAction.newline,
                  autocorrect: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
              ),
              
              SizedBox(height: 24),
              
              // Precio y tiempo
              _buildSectionTitle('Precio y Preparación'),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      title: 'Precio (MXN)',
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) => _debounceUpdatePreview(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: _buildInputDecoration(
                          '0.00',
                          Icons.attach_money,
                        ),
                        // ✅ NUEVO: Configuraciones para móvil
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio es requerido';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Precio inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildInputCard(
                      title: 'Tiempo (min) - Opcional',
                      child: TextFormField(
                        controller: _timeController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _debounceUpdatePreview(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _buildInputDecoration(
                          '0',
                          Icons.timer,
                        ),
                        // ✅ NUEVO: Configuraciones para móvil
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // ✅ MODIFICADO: Categoría con mejor manejo del estado
              _buildSectionTitle('Categoría'),
              SizedBox(height: 12),
              _buildInputCard(
                title: 'Seleccionar Categoría',
                child: _buildCategoryDropdown(),
              ),
              
              SizedBox(height: 24),
              
              // Imagen
              _buildSectionTitle('Imagen del Platillo'),
              SizedBox(height: 12),
              _buildImageSection(),
              
              SizedBox(height: 24),
              
              // Vista previa (solo si no es modal)
              if (!widget.isModal) ...[
                _buildSectionTitle('Vista Previa'),
                SizedBox(height: 12),
                _buildPreviewCard(),
                SizedBox(height: 32),
              ],
              
              // Botones
              _buildActionButtons(),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NUEVO: Debounce para updatePreview
  Timer? _debounceTimer;
  
  void _debounceUpdatePreview() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        menuController.updatePreview();
      }
    });
  }

  // ✅ NUEVO: Widget separado para el dropdown de categoría
  Widget _buildCategoryDropdown() {
    return Obx(() {
      if (menuController.isLoading.value) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Cargando categorías...'),
            ],
          ),
        );
      }
      
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: menuController.selectedCategoryId.value,
            hint: Text('Seleccionar categoría'),
            isExpanded: true,
            items: menuController.categories.map((categoria) {
              return DropdownMenuItem<int>(
                value: categoria.id,
                child: Text(categoria.nombre),
              );
            }).toList(),
            onChanged: (value) {
              if (mounted) {
                menuController.setSelectedCategory(value);
              }
            },
          ),
        ),
      );
    });
  }

  // ✅ NUEVO: Widget separado para la sección de imagen
  Widget _buildImageSection() {
    return _buildInputCard(
      title: 'Seleccionar Imagen',
      child: Column(
        children: [
          // Vista previa de la imagen
          Container(
            width: double.infinity,
            height: widget.isModal ? 150 : 200,
            decoration: BoxDecoration(
              color: Color(0xFFF5F2F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildImagePreview(),
          ),
          SizedBox(height: 16),
          // Botones para manejar imagen
          _buildImageButtons(),
        ],
      ),
    );
  }

  // ✅ MODIFICADO: Widget para vista previa de imagen
  Widget _buildImagePreview() {
    return Obx(() {
      if (menuController.selectedImage.value != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            menuController.selectedImage.value!,
            fit: BoxFit.cover,
          ),
        );
      } else if (menuController.currentImageUrl.value != null && 
         menuController.currentImageUrl.value!.isNotEmpty) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Base64ImageperfilWidget(
      base64String: menuController.currentImageUrl.value,
      width: double.infinity, // O el ancho que necesites
      height: 200, // O la altura que necesites
      fit: BoxFit.cover,
      errorWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Error al cargar imagen',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: widget.isModal ? 40 : 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8),
            Text(
              'Sin imagen seleccionada',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: widget.isModal ? 14 : 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Toca el botón para agregar una imagen',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        );
      }
    });
  }

  // ✅ NUEVO: Widget separado para botones de imagen
  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => menuController.mostrarOpcionesImagen(context),
            icon: Obx(() => Icon(
              menuController.selectedImage.value != null || 
              (menuController.currentImageUrl.value?.isNotEmpty == true)
                  ? Icons.change_circle 
                  : Icons.add_photo_alternate
            )),
            label: Obx(() => Text(
              menuController.selectedImage.value != null || 
              (menuController.currentImageUrl.value?.isNotEmpty == true)
                  ? 'Cambiar' 
                  : 'Seleccionar',
              style: TextStyle(fontSize: widget.isModal ? 12 : 14),
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: widget.isModal ? 8 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Obx(() {
          final hasNewImage = menuController.selectedImage.value != null;
          final hasCurrentImage = menuController.currentImageUrl.value?.isNotEmpty == true;
          
          if (hasNewImage || hasCurrentImage) {
            return Row(
              children: [
                SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    if (hasNewImage) {
                      menuController.clearSelectedImage();
                    } else if (hasCurrentImage && menuController.isEditMode.value) {
                      _showDeleteImageConfirmation();
                    }
                  },
                  icon: Icon(Icons.delete, color: Colors.red, size: widget.isModal ? 20 : 24),
                  tooltip: hasNewImage 
                      ? 'Eliminar imagen seleccionada' 
                      : 'Eliminar imagen actual',
                ),
              ],
            );
          }
          return SizedBox.shrink();
        }),
      ],
    );
  }

  // ✅ NUEVO: Widget separado para botones de acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _clearForm(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF8B4513)),
              padding: EdgeInsets.symmetric(vertical: widget.isModal ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Limpiar',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontSize: widget.isModal ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Obx(() => ElevatedButton(
            onPressed: menuController.isProcessing 
                ? null 
                : () => _saveMenu(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: widget.isModal ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: menuController.isProcessing
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
                        menuController.buttonText.split('...')[0] + '...',
                        style: TextStyle(fontSize: widget.isModal ? 14 : 16),
                      ),
                    ],
                  )
                : Text(
                    menuController.buttonText,
                    style: TextStyle(
                      fontSize: widget.isModal ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          )),
        ),
      ],
    );
  }

  // ... [Mantener todos los demás métodos sin cambios: _buildSectionTitle, _buildInputCard, 
  // _buildInputDecoration, _buildPreviewCard, _buildPreviewImage, _showDeleteImageConfirmation, 
  // _clearForm, _saveMenu]

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: widget.isModal ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B4513),
      ),
    );
  }

  Widget _buildInputCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: EdgeInsets.all(widget.isModal ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: widget.isModal ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E1F08),
              ),
            ),
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: widget.isModal ? 12 : 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF8B4513), width: 2),
      ),
      prefixIcon: icon != null ? Icon(icon, color: Color(0xFF8B4513), size: widget.isModal ? 20 : 24) : null,
      fillColor: Colors.white,
      filled: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12, 
        vertical: widget.isModal ? 8 : 12,
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Obx(() {
     final name = _nameController.text.isNotEmpty ? _nameController.text : 'Nombre del platillo';
      final description = _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Descripción del platillo';
      final price = _priceController.text.isNotEmpty ? _priceController.text : '0.00';
      final time = _timeController.text.isNotEmpty ? _timeController.text : '0';
      
      final categoryName = menuController.selectedCategoryId.value != null 
          ? menuController.obtenerNombreCategoria(menuController.selectedCategoryId.value!)
          : 'Sin categoría';

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildPreviewImage(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$ $price',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      if (time != '0')
                        Text(
                          '${time} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPreviewImage() {
    return Obx(() {
      if (menuController.selectedImage.value != null) {
        // Nueva imagen seleccionada
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            menuController.selectedImage.value!,
            fit: BoxFit.cover,
          ),
        );
      } else if (menuController.currentImageUrl.value != null && 
                 menuController.currentImageUrl.value!.isNotEmpty) {
        // Imagen actual del servidor
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            '${AppConstants.serverBase}${menuController.currentImageUrl.value}',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.restaurant_menu,
                color: Color(0xFF8B4513),
                size: 30,
              );
            },
          ),
        );
      } else {
        // Placeholder
        return Icon(
          Icons.restaurant_menu,
          color: Color(0xFF8B4513),
          size: 30,
        );
      }
    });
  }

  void _showDeleteImageConfirmation() {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.confirm,
      title: 'Eliminar Imagen',
      text: '¿Estás seguro de que quieres eliminar la imagen actual?',
      confirmBtnText: 'Eliminar',
      cancelBtnText: 'Cancelar',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Get.back();
        menuController.currentImageUrl.value = null;
        menuController.updatePreview();
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _timeController.clear();
    menuController.clearForm();
  }

void _saveMenu() async {
    if (_formKey.currentState!.validate() && menuController.selectedCategoryId.value != null) {
      final success = await menuController.guardarMenuConValidacion(
        nombre: _nameController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        precio: _priceController.text.trim(),
        tiempoPreparacion: _timeController.text.trim(),
        imagenFile: menuController.selectedImage.value,
        categoriaId: menuController.selectedCategoryId.value,
        context: context, // ✅ Pasar context del widget
      );
      
      if (success && !menuController.isEditMode.value) {
        if (!widget.isModal) {
          _clearForm();
        }
      }
      
      if (success && menuController.isEditMode.value) {
       
      }
    } else if (menuController.selectedCategoryId.value == null) {
      QuickAlert.show(
        context: context, // ✅ Usar context del widget
        type: QuickAlertType.warning,
        title: 'Categoría Requerida',
        text: 'Por favor selecciona una categoría',
        confirmBtnText: 'OK',
        confirmBtnColor: Color(0xFFF39C12),
      );
    }
  }

}
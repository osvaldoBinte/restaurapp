
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'dart:convert';

import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/page/categoria/listarcategoria/category_list_controller.dart';
import 'package:restaurapp/page/orders/crear/crear_orden_controller.dart';
class EditCategoryModalContent extends StatefulWidget {
  final Map<String, dynamic> categoria;

  const EditCategoryModalContent({
    Key? key,
    required this.categoria,
  }) : super(key: key);

  @override
  _EditCategoryModalContentState createState() => _EditCategoryModalContentState();
}

class _EditCategoryModalContentState extends State<EditCategoryModalContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  
  late final CategoryListController categoryController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controllers con datos existentes
    _nameController = TextEditingController(
      text: widget.categoria['nombreCategoria'] ?? ''
    );
    _descriptionController = TextEditingController(
      text: widget.categoria['descripcion'] ?? ''
    );
    
    // Obtener el controller existente
    categoryController = Get.find<CategoryListController>();
    
    // Escuchar cambios en los campos
    _nameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentName = _nameController.text.trim();
    final currentDescription = _descriptionController.text.trim();
    final originalName = widget.categoria['nombreCategoria'] ?? '';
    final originalDescription = widget.categoria['descripcion'] ?? '';
    
    setState(() {
      _hasChanges = currentName != originalName || currentDescription != originalDescription;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la categoría actual
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF8B4513).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF8B4513), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Editando Categoría ID: ${widget.categoria['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (_hasChanges) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Hay cambios sin guardar',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Campo nombre
            _buildNameField(),
            
            SizedBox(height: 24),
            
            // Campo descripción
            _buildDescriptionField(),
            
            Spacer(),
            
            // Botones de acción
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
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa el nombre';
            }
            if (value.trim().length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
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
            if (value == null || value.trim().isEmpty) {
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
              onPressed: _hasChanges ? () => _restoreOriginal() : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _hasChanges ? Color(0xFF8B4513) : Colors.grey[400]!,
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Restaurar',
                style: TextStyle(
                  color: _hasChanges ? Color(0xFF8B4513) : Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Botón Guardar
          Expanded(
            flex: 2,
            child: Obx(() => ElevatedButton(
              onPressed: (!_hasChanges || categoryController.isUpdating.value) 
                  ? null 
                  : () => _saveChanges(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: (!_hasChanges || categoryController.isUpdating.value)
                    ? Colors.grey 
                    : Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: categoryController.isUpdating.value
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )),
          ),
        ],
      ),
    );
  }

  void _cancelEdit(BuildContext context) {
    if (_hasChanges) {
      // Mostrar confirmación si hay cambios
      QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: 'Descartar Cambios',
        text: '¿Estás seguro de salir?\nSe perderán los cambios realizados.',
        confirmBtnText: 'Salir',
        cancelBtnText: 'Continuar Editando',
        confirmBtnColor: Color(0xFFE74C3C),
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); // Cerrar confirmación
          Navigator.of(context).pop(); // Cerrar modal de edición
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _restoreOriginal() {
    setState(() {
      _nameController.text = widget.categoria['nombreCategoria'] ?? '';
      _descriptionController.text = widget.categoria['descripcion'] ?? '';
    });
    FocusScope.of(context).unfocus();
  }

  void _saveChanges(BuildContext context) async {
    if (!mounted) return;
    
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState!.validate()) {
      try {
        final success = await categoryController.modificarCategoria(
          id: widget.categoria['id'],
          nombre: _nameController.text.trim(),
          descripcion: _descriptionController.text.trim(),
        );
        
        if (!mounted) return;
        
        if (success) {
          // Cerrar el modal
          Navigator.of(context).pop(true);
          
          // Mostrar mensaje de éxito en la pantalla padre
          Future.delayed(Duration(milliseconds: 300), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Categoría actualizada exitosamente'),
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
                  Expanded(child: Text('Error al actualizar categoría: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
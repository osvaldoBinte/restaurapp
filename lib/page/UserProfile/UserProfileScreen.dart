// user_profile_screen.dart (simplificado)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/framework/preferences_service.dart';
import 'package:restaurapp/page/UserProfile/UserProfileController.dart';
import 'package:restaurapp/page/VentasService/VentasService.dart';
import 'package:restaurapp/page/categoria/listarcategoria/listas_categoria.dart';
import 'package:restaurapp/page/menu/listarmenu/listar_controller.dart';
import 'package:restaurapp/page/table/table_page.dart';
import 'package:restaurapp/page/user/UserManagementScreen.dart';
// user_profile_screen.dart (simplificado)
class UserProfileScreen extends StatelessWidget {
  final UserProfileController controller = Get.put(UserProfileController());
  // 🆕 Agregar el VentasController
  final VentasController ventasController = Get.put(VentasController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
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
                  'Cargando perfil...',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // App Bar con imagen de perfil
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Color(0xFF8B4513),
              // 🆕 Agregar botón de refrescar en el AppBar
              actions: [
                
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B4513), Color(0xFF7A3E11)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 60),
                      // Avatar del usuario
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Información básica
                      Obx(() => Text(
                        controller.userName.value.isNotEmpty 
                          ? controller.userName.value 
                          : 'Usuario',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )),
                      SizedBox(height: 4),
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.userRole.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenido del perfil
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🆕 Sección de ventas (solo para admins)
                    Obx(() {
                      if (controller.isAdmin.value) {
                        return Column(
                          children: [
                            _buildVentasSection(),
                            SizedBox(height: 24),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    }),
                    
                    // Información Personal (solo email)
                    _buildPersonalInfoSection(),
                    
                    SizedBox(height: 24),
                    
                    // Acciones rápidas
                    Obx(() {
                      if (controller.isAdmin.value) {
                        return Column(
                          children: [
                            _buildQuickActionsSection(),
                            SizedBox(height: 24),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    }),
                    
                    SizedBox(height: 24),
                    
                    // Gestión (solo para admins)
                    Obx(() {
                      if (controller.isAdmin.value) {
                        return Column(
                          children: [
                            _buildManagementSection(),
                            SizedBox(height: 24),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    }),
                    
                    // Configuración
                    _buildSettingsSection(),
                    
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // 🆕 Widget para mostrar la sección de ventas
  Widget _buildVentasSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Color(0xFF8B4513),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventas de Hoy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    Text(
                      'Resumen de ventas del día',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de refrescar solo para ventas
              IconButton(
                onPressed: () => ventasController.refrescarVentas(),
                icon: Obx(() => ventasController.isLoading.value
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                        ),
                      )
                    : Icon(Icons.refresh, color: Color(0xFF8B4513))
                ),
                tooltip: 'Refrescar ventas',
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Contenido de ventas
          Obx(() {
            if (ventasController.isLoading.value) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                ),
              );
            }
            
            if (ventasController.error.value.isNotEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ventasController.error.value,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF8B4513).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ventasController.totalVentasFormateado,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          ventasController.fechaInicio.value.isNotEmpty
                              ? ventasController.fechaInicio.value
                              : DateTime.now().toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        Text(
                          'Total del Día',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
              ],
            );
          }),
        ],
      ),
    );
  }

  // Mantén todos tus métodos existentes...


  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Información Personal',
      icon: Icons.person,
      children: [
        Obx(() => _buildEditableField(
          'Nombre Completo',
          controller.nameController,
          Icons.person_outline,
        )),
        SizedBox(height: 16),
        Obx(() => _buildEditableField(
          'Email',
          controller.emailController,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        )),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return _buildSection(
      title: 'Acciones Rápidas',
      icon: Icons.flash_on,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Ver Menús',
                subtitle: 'Explorar menús disponibles',
                icon: Icons.restaurant_menu,
                color: Color(0xFF2196F3),
                onTap: () => _showMenusModal(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Ver Mesas',
                subtitle: 'Gestionar mesas del restaurante',
                icon: Icons.table_restaurant,
                color: Color(0xFF4CAF50),
                onTap: () => _showTablesModal(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUsersModal() {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width,
          height: Get.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF9C27B0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.people, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Usuarios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Administra los usuarios del sistema',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido del modal
              Expanded(
                child: Container(
                  child: UserManagementScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
  Widget _buildManagementSection() {
    return _buildSection(
      title: 'Gestión de Administrador',
      icon: Icons.admin_panel_settings,
      children: [
        _buildActionButton(
          title: 'Gestión de Categorías',
          subtitle: 'Administrar categorías de menús',
          icon: Icons.category,
          color: Color(0xFFFF9800),
          onTap: () => _showCategoriesModal(),
          fullWidth: true,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          title: 'Gestión de Usuarios',
          subtitle: 'Administrar usuarios del sistema',
          icon: Icons.people,
          color: Color(0xFF9C27B0),
          onTap: () => _showUsersModal(),
          fullWidth: true,
        ),
      ],
    );
  }

  // Métodos para mostrar modales
  void _showMenusModal() {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width,
          height: Get.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menús Disponibles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Explora todos los menús del restaurante',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido del modal
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: ListarTodoMenuPage(isEmbedded: true),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showTablesModal() {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width,
          height: Get.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.table_restaurant, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Mesas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Administra las mesas del restaurante',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido del modal
              Expanded(
                child: Container(
                  child:TablesScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showCategoriesModal() {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width,
          height: Get.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFFF5F2F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header del modal
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.category, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Categorías',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Administra las categorías de menús',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido del modal
              Expanded(
                child: Container(
                  child: CategoryListScreen(),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      title: 'Configuración',
      icon: Icons.settings,
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.logout, color: Colors.red, size: 20),
          ),
          title: Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Salir de la aplicación'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => controller.logout(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (fullWidth) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E1F08),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ],
                ),
                if (!fullWidth) ...[
                  SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF8B4513)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController fieldController,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E1F08),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: fieldController,
          enabled: controller.isEditing.value && !controller.isUpdating.value,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: controller.isEditing.value ? Color(0xFF8B4513) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF8B4513)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            fillColor: controller.isEditing.value ? Colors.white : Colors.grey.shade50,
            filled: true,
          ),
        ),
      ],
    );
  }
}
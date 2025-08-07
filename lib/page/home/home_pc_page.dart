import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/page/home/home_pc_controller.dart';


class HomePCPage extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(context),
          
          // Main Content Area
          Expanded(
            child: Obx(() => controller.currentPage),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    // Detectar si es una pantalla pequeña (tablet o menor)
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1024; // Ajusta este valor según tus necesidades
    
    return Container(
      width: isSmallScreen ? 80 : 260, // Ancho reducido para pantallas pequeñas
      decoration: BoxDecoration(
        color: Color(0xFF8B4513),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          _buildLogoHeader(isSmallScreen),
          
          Divider(color: Colors.white24),
          
          // Navigation Items
          Expanded(
            child: _buildNavigationItems(isSmallScreen),
          ),
          
          // User Info
          _buildUserInfo(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildLogoHeader(bool isSmallScreen) {
    if (isSmallScreen) {
      // Solo mostrar el logo "EJ" centrado
      return Container(
        padding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'EJ',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      );
    }

    // Diseño completo para pantallas grandes
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'EJ',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comedor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '"El Jobo"',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(bool isSmallScreen) {
    return Obx(() {
      if (controller.isLoadingUserData.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      }

      final visibleItems = controller.visibleNavigationItems;
      
      return ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          return Obx(() => _buildNavItem(
            item.icon,
            item.title,
            controller.selectedIndex.value == index,
            () => controller.changePage(index),
            isSmallScreen
          ));
        },
      );
    });
  }

  Widget _buildNavItem(IconData icon, String title, bool isSelected, VoidCallback onTap, bool isSmallScreen) {
    if (isSmallScreen) {
      // Solo mostrar el icono con tooltip
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Tooltip(
          message: title,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Diseño completo para pantallas grandes
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 22, 
          color: isSelected ? Colors.white : Colors.white70
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildUserInfo(bool isSmallScreen) {
    if (isSmallScreen) {
      // Solo mostrar el avatar y botón de logout
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF8B4513)),
            ),
            SizedBox(height: 12),
            // Botón de cerrar sesión compacto
            Tooltip(
              message: 'Cerrar Sesión',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => UserService.confirmarCerrarSesion(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Diseño completo para pantallas grandes
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información del usuario
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF8B4513)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Usuario',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Obx(() => Text(
                      controller.isAdmin.value ? 'Administrador' : 'Usuario',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Botón de cerrar sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => UserService.confirmarCerrarSesion(),
              icon: Icon(Icons.logout, size: 18),
              label: Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.9),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget adicional para mostrar cuando una página no está implementada
class ComingSoonPage extends StatelessWidget {
  final String pageName;
  final IconData icon;
  final String description;

  const ComingSoonPage({
    Key? key,
    required this.pageName,
    required this.icon,
    this.description = 'Esta sección estará disponible próximamente',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFF8B4513).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: Color(0xFF8B4513),
              ),
            ),
            SizedBox(height: 24),
            Text(
              pageName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E1F08),
              ),
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.find<HomeController>().changePage(0),
              icon: Icon(Icons.arrow_back),
              label: Text('Volver al Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
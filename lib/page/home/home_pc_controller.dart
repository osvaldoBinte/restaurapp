
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/user/UserManagementScreen.dart';
import 'package:restaurapp/page/home/dashoard_page.dart';
import 'package:restaurapp/page/home/home_pc_page.dart';
import 'package:restaurapp/page/orders/orders_page.dart';
import 'package:restaurapp/page/orders/pagedesktop/ordenes_page_desktop.dart';

class HomeController extends GetxController {
  final RxBool forceUpdate = false.obs;
  final RxBool isSessionActive = false.obs;
  final RxBool isAdmin = false.obs;
  final RxBool isLoadingUserData = true.obs;
  
  // Páginas principales del dashboard
  final List<Widget> _allPages = [
    DashboardPage(),
    OrdersDashboardScreen(),
    OrderScreen(), // Página principal del menú
    UserManagementScreen(),
  ];

  // Títulos de las páginas principales
  final List<String> _allTitles = [
    'Dashboard',
    'Órdenes',
    'Menu',
    'Usuarios'
  ];

  // Iconos de navegación
  final List<IconData> _allIcons = [
    Icons.dashboard,
    Icons.restaurant_menu,
    Icons.restaurant_menu,
    Icons.people,
  ];

  // Indicadores de cuáles páginas requieren admin
  final List<bool> _requiresAdmin = [
    true,   // Dashboard - solo admin
    false,  // Órdenes - todos los usuarios
     false, 
    true,   // Usuarios - solo admin
  ];

  // Getters que filtran según el rol del usuario
  List<Widget> get pages {
    if (isAdmin.value) {
      return _allPages;
    } else {
      return _allPages
          .asMap()
          .entries
          .where((entry) => !_requiresAdmin[entry.key])
          .map((entry) => entry.value)
          .toList();
    }
  }

  List<String> get titles {
    if (isAdmin.value) {
      return _allTitles;
    } else {
      return _allTitles
          .asMap()
          .entries
          .where((entry) => !_requiresAdmin[entry.key])
          .map((entry) => entry.value)
          .toList();
    }
  }

  List<IconData> get icons {
    if (isAdmin.value) {
      return _allIcons;
    } else {
      return _allIcons
          .asMap()
          .entries
          .where((entry) => !_requiresAdmin[entry.key])
          .map((entry) => entry.value)
          .toList();
    }
  }

  // Obtener las páginas visibles según el rol
  List<NavigationItem> get visibleNavigationItems {
    List<NavigationItem> items = [];
    
    for (int i = 0; i < _allPages.length; i++) {
      if (isAdmin.value || !_requiresAdmin[i]) {
        items.add(NavigationItem(
          page: _allPages[i],
          title: _allTitles[i],
          icon: _allIcons[i],
          originalIndex: i,
        ));
      }
    }
    
    return items;
  }

  final RxInt selectedIndex = 0.obs;
  final RxString currentRoute = '/orders'.obs; // Por defecto órdenes (accesible para todos)

  @override
  void onInit() {
    super.onInit();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    isLoadingUserData.value = true;
    
    try {
      // Primero verificar desde SharedPreferences
      final isAdminFromPrefs = await UserService.isUserAdmin();
      
      // Luego obtener datos actualizados del servidor
      final userData = await UserService.obtenerUsuario();
      
      if (userData != null) {
        isAdmin.value = userData['isAdmin'] ?? false;
      } else {
        // Si falla la llamada al servidor, usar datos de SharedPreferences
        isAdmin.value = isAdminFromPrefs;
      }
      
      // Configurar página inicial según el rol
      if (isAdmin.value) {
        changePage(0); // Dashboard para admin
        currentRoute.value = '/dashboard';
      } else {
        changePage(0); // Índice 0 de las páginas visibles (Órdenes para usuarios normales)
        currentRoute.value = '/orders';
      }
      
      isSessionActive.value = true;
    } catch (e) {
      print('Error al inicializar datos del usuario: $e');
      // En caso de error, asumir usuario normal
      isAdmin.value = false;
      changePage(0);
      currentRoute.value = '/orders';
    } finally {
      isLoadingUserData.value = false;
    }
  }

  /// Cambiar página del navigation rail/drawer
  void changePage(int index) {
    final visibleItems = visibleNavigationItems;
    
    if (index < visibleItems.length) {
      selectedIndex.value = index;
      
      // Actualizar ruta según el índice original de la página
      final originalIndex = visibleItems[index].originalIndex;
      switch (originalIndex) {
        case 0:
          currentRoute.value = '/dashboard';
          break;
        case 1:
          currentRoute.value = '/orders';
          break;
        case 2:
          currentRoute.value = '/users';
          break;
      }
    }
  }

  /// Navegar a sección específica
  void navegarA(String seccion) {
    final visibleItems = visibleNavigationItems;
    
    switch (seccion) {
      case 'dashboard':
        if (isAdmin.value) {
          final dashboardIndex = visibleItems.indexWhere((item) => item.originalIndex == 0);
          if (dashboardIndex != -1) changePage(dashboardIndex);
        }
        break;
      case 'ordenes':
        final ordenesIndex = visibleItems.indexWhere((item) => item.originalIndex == 1);
        if (ordenesIndex != -1) changePage(ordenesIndex);
        break;
      case 'usuarios':
        if (isAdmin.value) {
          final usuariosIndex = visibleItems.indexWhere((item) => item.originalIndex == 2);
          if (usuariosIndex != -1) changePage(usuariosIndex);
        }
        break;
      case 'nueva_orden':
        Get.toNamed('/new-order');
        break;
      default:
        changePage(0);
    }
  }

  /// Cambiar vista
  void cambiarVista(String vista) {
    navegarA(vista);
  }

  /// Obtener página actual
  Widget get currentPage {
    final visibleItems = visibleNavigationItems;
    if (selectedIndex.value < visibleItems.length) {
      return visibleItems[selectedIndex.value].page;
    }
    return visibleItems.isNotEmpty ? visibleItems[0].page : Container();
  }

  /// Obtener título actual
  String get currentTitle {
    final visibleItems = visibleNavigationItems;
    if (selectedIndex.value < visibleItems.length) {
      return visibleItems[selectedIndex.value].title;
    }
    return visibleItems.isNotEmpty ? visibleItems[0].title : '';
  }

  /// Resetear para nueva sesión
  void resetForNewSession() {
    selectedIndex.value = 0;
    isSessionActive.value = true;
    forceUpdate.value = !forceUpdate.value;
    _initializeUserData();
  }

  /// Verificar si una ruta está activa
  bool isRouteActive(String route) {
    return currentRoute.value == route;
  }

  /// Finalizar sesión
  void endSession() {
    isSessionActive.value = false;
    selectedIndex.value = 0;
    currentRoute.value = '/orders';
    isAdmin.value = false;
  }

  /// Refrescar datos del usuario
  Future<void> refreshUserData() async {
    await _initializeUserData();
  }

  @override
  void onClose() {
    endSession();
    super.onClose();
  }
}

// Clase auxiliar para elementos de navegación
class NavigationItem {
  final Widget page;
  final String title;
  final IconData icon;
  final int originalIndex;

  NavigationItem({
    required this.page,
    required this.title,
    required this.icon,
    required this.originalIndex,
  });
}
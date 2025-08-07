import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/orders/orders_page.dart';

// Importa tus pantallas aquí
// import 'package:restaurapp/page/orders/orders_dashboard_screen.dart';
// import 'package:restaurapp/page/orders/order_screen.dart';

class OrdenesPageDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        title: Text(
          'Gestión de Órdenes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildResponsiveLayout(),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la pantalla es muy pequeña (móvil), mostrar en tabs
        if (constraints.maxWidth < 800) {
          return _buildMobileLayout();
        }
        
        // Para pantallas grandes, mostrar lado a lado
        return _buildDesktopLayout();
      },
    );
  }

  // Layout para pantallas grandes (escritorio/tablet horizontal)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // OrdersDashboardScreen - ocupa más espacio (70%)
        Expanded(
          flex: 7,
          child: Container(
            margin: EdgeInsets.all(8),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Header del dashboard
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Dashboard de Órdenes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ),
                  // Contenido del dashboard
                  Expanded(
                    child: OrdersDashboardScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        SizedBox(width: 8),
        
        // OrderScreen - ocupa menos espacio (30%)
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.all(8),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Header del panel de órdenes
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Panel de Órdenes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  // Contenido del panel
                  Expanded(
                    child: OrderScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Layout para móviles (con tabs)
  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              labelColor: Color(0xFF8B4513),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Color(0xFF8B4513),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: 'Dashboard',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long),
                  text: 'Órdenes',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Dashboard
                Container(
                  padding: EdgeInsets.all(16),
                  child: OrdersDashboardScreen(),
                ),
                // Tab 2: Órdenes
                Container(
                  padding: EdgeInsets.all(16),
                  child: OrderScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

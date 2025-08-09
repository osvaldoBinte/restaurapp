import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/orders/crear/crear_orden.dart';
import 'package:restaurapp/page/orders/orders_page.dart';

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
        // ✅ DEFINIR BREAKPOINTS MÁS GRANULARES
        if (constraints.maxWidth < 600) {
          // Móvil muy pequeño - Solo tabs
          return _buildMobileLayout();
        } else if (constraints.maxWidth < 900) {
          // Pantalla pequeña/tablet - Flex equilibrado
          return _buildSmallScreenLayout(constraints);
        } else if (constraints.maxWidth < 1200) {
          // Pantalla mediana - Flex moderado  
          return _buildMediumScreenLayout(constraints);
        } else {
          // Pantalla grande - Flex original
          return _buildLargeScreenLayout(constraints);
        }
      },
    );
  }

  // ✅ NUEVA FUNCIÓN: Layout para pantallas pequeñas (600-900px)
  Widget _buildSmallScreenLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Dashboard - menos espacio en pantalla pequeña
        Expanded(
          flex: 4, // ✅ REDUCIDO: Era 7, ahora 4
          child: _buildDashboardContainer(),
        ),
        
        SizedBox(width: 8),
        
        // OrderScreen - más espacio en pantalla pequeña
        Expanded(
          flex: 6, // ✅ AUMENTADO: Era 3, ahora 6
          child: _buildOrderContainer(),
        ),
      ],
    );
  }

  // ✅ NUEVA FUNCIÓN: Layout para pantallas medianas (900-1200px)
  Widget _buildMediumScreenLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Dashboard - espacio moderado
        Expanded(
          flex: 5, // ✅ EQUILIBRADO: Entre pequeño y grande
          child: _buildDashboardContainer(),
        ),
        
        SizedBox(width: 8),
        
        // OrderScreen - espacio moderado
        Expanded(
          flex: 5, // ✅ EQUILIBRADO: 50/50
          child: _buildOrderContainer(),
        ),
      ],
    );
  }

  // ✅ FUNCIÓN MEJORADA: Layout para pantallas grandes (1200px+)
  Widget _buildLargeScreenLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Dashboard - más espacio en pantalla grande
        Expanded(
          flex: 7, // ✅ ORIGINAL: Mantener para pantallas grandes
          child: _buildDashboardContainer(),
        ),
        
        SizedBox(width: 8),
        
        // OrderScreen - menos espacio en pantalla grande  
        Expanded(
          flex: 3, // ✅ ORIGINAL: Mantener para pantallas grandes
          child: _buildOrderContainer(),
        ),
      ],
    );
  }

  // ✅ FUNCIÓN REFACTORIZADA: Container del Dashboard
  Widget _buildDashboardContainer() {
    return Container(
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
            Expanded(
              child: OrdersDashboardScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FUNCIÓN REFACTORIZADA: Container de las Órdenes
  Widget _buildOrderContainer() {
    return Container(
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
    );
  }

  // ✅ FUNCIÓN MEJORADA: Layout para móviles con mejor diseño
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
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.dashboard, size: 20),
                  text: 'Dashboard',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long, size: 20),
                  text: 'Crear Orden',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Dashboard
                Container(
                  padding: EdgeInsets.all(8), // ✅ REDUCIDO: Mejor para móvil
                  child: OrdersDashboardScreen(),
                ),
                // Tab 2: Órdenes  
                Container(
                  padding: EdgeInsets.all(8), // ✅ REDUCIDO: Mejor para móvil
                  child: OrderScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FUNCIÓN ALTERNATIVA: Layout con flex dinámico más suave
  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ CALCULAR FLEX DINÁMICAMENTE BASADO EN ANCHO
        double width = constraints.maxWidth;
        
        int dashboardFlex;
        int orderFlex;
        
        if (width < 700) {
          // Pantalla muy pequeña - OrderScreen más grande
          dashboardFlex = 3;
          orderFlex = 7;
        } else if (width < 900) {
          // Pantalla pequeña - Equilibrado pero favoreciendo OrderScreen
          dashboardFlex = 4;
          orderFlex = 6;
        } else if (width < 1100) {
          // Pantalla mediana - Más equilibrado
          dashboardFlex = 5;
          orderFlex = 5;
        } else if (width < 1400) {
          // Pantalla grande - Favoreciendo Dashboard
          dashboardFlex = 6;
          orderFlex = 4;
        } else {
          // Pantalla muy grande - Dashboard dominante
          dashboardFlex = 7;
          orderFlex = 3;
        }

        return Row(
          children: [
            Expanded(
              flex: dashboardFlex,
              child: _buildDashboardContainer(),
            ),
            
            SizedBox(width: 8),
            
            Expanded(
              flex: orderFlex,
              child: _buildOrderContainer(),
            ),
          ],
        );
      },
    );
  }
}

// ✅ OPCIONAL: Widget helper para debug de tamaños
class DebugScreenSize extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(8),
          color: Colors.black.withOpacity(0.7),
          child: Text(
            'Ancho: ${constraints.maxWidth.toInt()}px',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
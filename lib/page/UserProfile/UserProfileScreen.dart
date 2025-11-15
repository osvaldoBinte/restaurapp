// user_profile_screen.dart (simplificado)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/constants/constants.dart';
import 'package:restaurapp/common/constants/controllermetricas.dart';
import 'package:restaurapp/common/constants/userservice.dart';
import 'package:restaurapp/framework/preferences_service.dart';
import 'package:restaurapp/page/UserProfile/UserProfileController.dart';
import 'package:restaurapp/page/VentasService/VentasService.dart';
import 'package:restaurapp/page/categoria/listarcategoria/listas_categoria.dart';
import 'package:restaurapp/page/menu/listarmenu/listar_controller.dart';
import 'package:restaurapp/page/orders/historial/historal_controller.dart';
import 'package:restaurapp/page/orders/historial/historial_page.dart';
import 'package:restaurapp/page/table/table_page.dart';
import 'package:restaurapp/page/user/UserManagementScreen.dart';


class UserProfileScreen extends StatelessWidget {
  final UserProfileController controller = Get.put(UserProfileController());
  final VentasController ventasController = Get.put(VentasController());
  final MetricasController metricasController = Get.put(MetricasController());

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
              actions: [],
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
                    // Sección de ventas (solo para admins)
                    Obx(() {
                      if (controller.isAdmin.value) {
                        return Column(
                          children: [
                            _buildVentasSection(),
                                                        SizedBox(height: 24),

                            _buildMetricasYHistorial(),
                            SizedBox(height: 24),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    }),
                    
                    // Información Personal
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


void _showHistorialModal() {
  // Asegurar que el controller esté inicializado y forzar carga
  Get.delete<HistorialController>();
  
  // Crear nueva instancia
  final historialCtrl = Get.put(HistorialController());
  
  // Forzar carga inmediata
  WidgetsBinding.instance.addPostFrameCallback((_) {
    historialCtrl.cargarDatos();
  });
  Get.dialog(
    Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          color: Color(0xFFF5F2F0),
        ),
        child: Column(
          children: [
            // ... resto del código
            Expanded(
              child: ClipRRect(
                child: HistorialPage(),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
  // 🆕 Widget para mostrar la sección de ventas CON MÉTRICAS

  
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
Widget _buildMetricasYHistorial() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
       // 🆕 Botón para ver métricas por categorías
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showMetricasModal(),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF2196F3).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.analytics, 
                              color: Color(0xFF2196F3), 
                              size: 20
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ver Métricas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Por Categorías',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                 Expanded(
                  child: GestureDetector(
                    onTap: () => _showHistorialModal(),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF2196F3).withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2196F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.analytics, 
                              color: Color(0xFF2196F3), 
                              size: 20
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'historial',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ultimas ventas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ],
    ),
  );
}

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
// 🆕 Modal para mostrar métricas por categorías CON SELECTOR DE FECHA
void _showMetricasModal() {
  // Cargar datos al abrir el modal
  metricasController.cargarMetricasPorCategorias();
  
  Get.dialog(
    Dialog(
      // Modal que cubre toda la pantalla
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        // Ocupa todo el ancho y alto de la pantalla
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          color: Color(0xFFF5F2F0),
        ),
        child: Column(
          children: [
            // Header del modal - Responsivo
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(Get.context!).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.zero, // Sin bordes redondeados
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Fila principal del header
                    Row(
                      children: [
                        // Icono
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.analytics, color: Colors.white, size: 20),
                        ),
                        SizedBox(width: 12),
                        
                        // Títulos con Expanded para evitar overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Métricas por Categorías',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              // Selector de fecha clickeable
                              GestureDetector(
                                onTap: () => _mostrarSelectorFecha(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Obx(() => Text(
                                        metricasController.fechaFormateada,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Botones en fila horizontal responsiva
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón de fecha rápida (hoy)
                            Container(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _cambiarAFechaHoy(),
                                icon: Icon(Icons.today, color: Colors.white, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                tooltip: 'Ir a hoy',
                              ),
                            ),
                            SizedBox(width: 8),
                            // Botón de refrescar
                            Container(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => metricasController.refrescarMetricas(),
                                icon: Obx(() => metricasController.isLoading.value
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.refresh, color: Colors.white, size: 18)
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Botón de cerrar
                            Container(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Get.back(),
                                icon: Icon(Icons.close, color: Colors.white, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Navegación rápida de fechas
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botón día anterior
                        _buildFechaNavButton(
                          icon: Icons.chevron_left,
                          label: 'Anterior',
                          onPressed: () => _cambiarFecha(-1),
                        ),
                        // Indicador de fecha actual
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Obx(() => Text(
                            _obtenerEtiquetaFecha(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                        ),
                        // Botón día siguiente
                        _buildFechaNavButton(
                          icon: Icons.chevron_right,
                          label: 'Siguiente',
                          onPressed: () => _cambiarFecha(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenido del modal - Completamente expandido
            Expanded(
              child: Obx(() {
                if (metricasController.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Cargando métricas...',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (metricasController.error.value.isNotEmpty) {
                  return Center(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Error al cargar métricas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              metricasController.error.value,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => metricasController.refrescarMetricas(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Reintentar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumen total responsivo con más información
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: Get.width > 400 ? 20 : 16,
                        ),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total General',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: Get.width > 400 ? 16 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                metricasController.totalGeneralFormateado,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Get.width > 400 ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                            // Mostrar cantidad total de items si está disponible
                            Obx(() {
                              if (metricasController.cantidadGeneralItems.value > 0) {
                                return Column(
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      '${metricasController.cantidadGeneralItems.value} items en total',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              }
                              return SizedBox.shrink();
                            }),
                          ],
                        ),
                      ),

                      // Lista de categorías
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Desglose por Categorías',
                          style: TextStyle(
                            fontSize: Get.width > 400 ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Lista completamente expandida
                      Expanded(
                        child: metricasController.categorias.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: Get.width > 400 ? 64 : 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        'Para la fecha seleccionada',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 16),
                                itemCount: metricasController.categorias.length,
                                itemBuilder: (context, index) {
                                  final categoria = metricasController.categorias[index];
                                  final nombre = categoria['categoria'] ?? 'Sin categoría';
                                  final total = categoria['total'] ?? 0.0;
                                  final cantidad = categoria['cantidad'] ?? 0;
                                  final porcentaje = metricasController.totalGeneral.value > 0 
                                      ? (total / metricasController.totalGeneral.value * 100) 
                                      : 0.0;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icono con color diferente según categoría
                                          Container(
                                            width: 45,
                                            height: 45,
                                            decoration: BoxDecoration(
                                              color: _obtenerColorCategoria(categoria['clave'] ?? '').withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _obtenerIconoCategoria(categoria['clave'] ?? ''),
                                              color: _obtenerColorCategoria(categoria['clave'] ?? ''),
                                              size: 22,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          
                                          // Contenido principal expandido
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Nombre de categoría
                                                Text(
                                                  nombre,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: Get.width > 400 ? 16 : 14,
                                                    color: Color(0xFF3E1F08),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                                SizedBox(height: 4),
                                                
                                                // Información de cantidad si está disponible
                                                if (cantidad > 0)
                                                  Text(
                                                    'cantidad total: $cantidad',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                SizedBox(height: 8),
                                                
                                                // Barra de progreso
                                                Container(
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: FractionallySizedBox(
                                                    alignment: Alignment.centerLeft,
                                                    widthFactor: (porcentaje / 100).clamp(0.0, 1.0),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: _obtenerColorCategoria(categoria['clave'] ?? ''),
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          SizedBox(width: 8),
                                          
                                          // Información de precio y porcentaje
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              // Monto - Con tamaño adaptativo
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  metricasController.formatearMonto(total),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: Get.width > 400 ? 16 : 14,
                                                    color: _obtenerColorCategoria(categoria['clave'] ?? ''),
                                                  ),
                                                  maxLines: 1,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              
                                             
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// Métodos auxiliares para el modal

Widget _buildFechaNavButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Container(
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(32, 32),
      ),
      tooltip: label,
    ),
  );
}

String _obtenerEtiquetaFecha() {
  return metricasController.etiquetaFecha;
}

void _cambiarFecha(int dias) {
  metricasController.navegarFecha(dias);
}

void _cambiarAFechaHoy() {
  metricasController.irAHoy();
}

void _mostrarSelectorFecha() async {
  final fechaSeleccionada = await showDatePicker(
    context: Get.context!,
    initialDate: DateTime.parse(metricasController.fechaConsulta.value),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    locale: Locale('es', 'ES'),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xFF2196F3),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (fechaSeleccionada != null) {
    await metricasController.cambiarFecha(fechaSeleccionada);
  }
}

// Métodos para personalizar iconos y colores por categoría
IconData _obtenerIconoCategoria(String clave) {
  switch (clave) {
    case 'menuPrincipal':
      return Icons.restaurant;
    case 'desechables':
      return Icons.eco;
    case 'pan':
      return Icons.bakery_dining;
    case 'extras':
      return Icons.add_circle;
    case 'bebidas':
      return Icons.local_drink;
    case 'cafe':
      return Icons.coffee;
    case 'postres':
      return Icons.cake;
    default:
      return Icons.restaurant_menu;
  }
}

Color _obtenerColorCategoria(String clave) {
  switch (clave) {
    case 'menuPrincipal':
      return Color(0xFF2196F3); // Azul
    case 'desechables':
      return Color(0xFF4CAF50); // Verde
    case 'pan':
      return Color(0xFFFF9800); // Naranja
    case 'extras':
      return Color(0xFF9C27B0); // Púrpura
    case 'bebidas':
      return Color(0xFF00BCD4); // Cian
    case 'cafe':
      return Color(0xFF795548); // Marrón
    case 'postres':
      return Color(0xFFE91E63); // Rosa
    default:
      return Color(0xFF607D8B); // Gris azulado
  }
}

// 🆕 MÉTODOS AUXILIARES PARA EL SELECTOR DE FECHA


  // Métodos para mostrar otros modales existentes
  void _showMenusModal() {
  Get.dialog(
    Dialog(
      // ✅ CAMBIO 1: Eliminar insetPadding para cubrir toda la pantalla
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        // ✅ CAMBIO 2: Usar dimensiones completas
        width: Get.width,
        height: Get.height,
        decoration: BoxDecoration(
          color: Color(0xFFF5F2F0),
          // ✅ CAMBIO 3: Eliminar borderRadius para pantalla completa
          // O usar borderRadius solo si quieres esquinas redondeadas
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2196F3),
                // ✅ CAMBIO 4: Sin borderRadius en el header (opcional)
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
              Expanded(
                child: Container(
                  child: TablesScreen(),
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
                Flexible(
  child: Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF8B4513),
    ),
    overflow: TextOverflow.ellipsis, // Opcional: para evitar desbordamientos
    maxLines: 1, // Opcional: limita las líneas si es necesario
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
                
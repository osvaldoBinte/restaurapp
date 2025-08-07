import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/user/UserManagementController.dart';

class UserManagementScreen extends StatelessWidget {
  // Inicializar el controller
  final UserManagementController controller = Get.put(UserManagementController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EJ',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comedor "El Jobo"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshUsers,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: controller.showCreateUserDialog,
            tooltip: 'Agregar Usuario',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con búsqueda y filtros
          _buildHeader(),
          
          // Lista de usuarios
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.usuarios.isEmpty) {
                return _buildLoadingState();
              }
              
              if (controller.usuarios.isEmpty && !controller.isLoading.value) {
                return _buildEmptyState();
              }
              
              final filteredUsers = controller.filteredUsers;
              
              if (filteredUsers.isEmpty) {
                return _buildNoResultsState();
              }
              
              return _buildUsersList(filteredUsers);
            }),
          ),
        ],
      ),
      
      // FAB para agregar usuario
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showCreateUserDialog,
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
        icon: Icon(Icons.person_add),
        label: Text('Nuevo Usuario'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Búsqueda
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F2F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o email...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF8B4513)),
                      suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: controller.clearSearch,
                          )
                        : SizedBox.shrink()),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: Colors.white),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filtros',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Filtros rápidos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: UserFilter.values.map((filter) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Obx(() => FilterChip(
                    label: Text(filter.displayName),
                    selected: controller.selectedFilter.value == filter,
                    onSelected: (_) => controller.changeFilter(filter),
                    selectedColor: Color(0xFF8B4513),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: controller.selectedFilter.value == filter 
                        ? Colors.white 
                        : Color(0xFF8B4513),
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: Color(0xFF8B4513),
                      width: 1,
                    ),
                  )),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Contador de resultados
          Obx(() {
            final total = controller.usuarios.length;
            final filtered = controller.filteredUsers.length;
            
            return Row(
              children: [
                Icon(Icons.group, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '$filtered de $total usuario${total != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                if (controller.isRefreshing.value)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando usuarios...',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1F08),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega el primer usuario para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.showCreateUserDialog,
            icon: Icon(Icons.person_add),
            label: Text('Agregar Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1F08),
            ),
          ),
          SizedBox(height: 8),
          Obx(() => Text(
            controller.searchQuery.value.isNotEmpty 
              ? 'Intenta con otros términos de búsqueda'
              : 'Prueba cambiando los filtros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          )),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: controller.clearSearch,
                icon: Icon(Icons.clear_all),
                label: Text('Limpiar Búsqueda'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF8B4513),
                ),
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => controller.changeFilter(UserFilter.todos),
                icon: Icon(Icons.refresh),
                label: Text('Mostrar Todos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF8B4513),
                  side: BorderSide(color: Color(0xFF8B4513)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<Usuario> users) {
    return RefreshIndicator(
      onRefresh: controller.refreshUsers,
      color: Color(0xFF8B4513),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Usuario user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: user.roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: user.roleColor,
                  width: 2,
                ),
              ),
              child: Icon(
                user.roleIcon,
                color: user.roleColor,
                size: 30,
              ),
            ),
            
            SizedBox(width: 16),
            
            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.roleText,
                      style: TextStyle(
                        color: user.roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (user.fechaCreacion != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Creado: ${_formatDate(user.fechaCreacion!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Acciones
            Column(
              children: [
                IconButton(
                  onPressed: () => controller.startEditUser(user),
                  icon: Icon(Icons.edit, color: Color(0xFF8B4513)),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () => controller.deleteUser(user),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.tune, color: Color(0xFF8B4513)),
                  SizedBox(width: 12),
                  Text(
                    'Filtrar Usuarios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      controller.changeFilter(UserFilter.todos);
                      Get.back();
                    },
                    child: Text('Limpiar'),
                  ),
                ],
              ),
            ),
            
            // Filtros
            ...UserFilter.values.map((filter) {
              return Obx(() => ListTile(
                leading: Icon(
                  filter.icon,
                  color: controller.selectedFilter.value == filter 
                    ? Color(0xFF8B4513) 
                    : Colors.grey,
                ),
                title: Text(
                  filter.displayName,
                  style: TextStyle(
                    fontWeight: controller.selectedFilter.value == filter 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                    color: controller.selectedFilter.value == filter 
                      ? Color(0xFF8B4513) 
                      : Colors.black,
                  ),
                ),
                trailing: controller.selectedFilter.value == filter 
                  ? Icon(Icons.check, color: Color(0xFF8B4513))
                  : null,
                onTap: () {
                  controller.changeFilter(filter);
                  Get.back();
                },
              ));
            }).toList(),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semana${weeks != 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
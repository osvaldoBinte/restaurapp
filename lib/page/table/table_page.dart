import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/table/table_controller.dart';

class TablesScreen extends StatelessWidget {
  final TablesController controller = Get.put(TablesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        return Column(
          children: [
            
            // Filtros y búsqueda
            _buildFiltersAndSearch(),
            
            // Lista de mesas
            Expanded(
              child: _buildMesasList(),
            ),
          ],
        );
      }),
     
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
            'Cargando mesas...',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
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
      child: Column(
        children: [
          // Título y estadísticas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Mesas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 4),
                    Obx(() => Text(
                      '${controller.totalMesas} mesas • ${controller.mesasActivas} activas • ${controller.mesasInactivas} inactivas',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    )),
                  ],
                ),
              ),
              
              // Estadísticas visuales
              Obx(() => Row(
                children: [
                  _buildStatChip('Total', controller.totalMesas.toString(), Color(0xFF8B4513)),
                  SizedBox(width: 8),
                  _buildStatChip('Activas', controller.mesasActivas.toString(), Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  _buildStatChip('Inactivas', controller.mesasInactivas.toString(), Color(0xFFFF9800)),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildFiltersAndSearch() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            child: TextField(
              onChanged: (value) => controller.buscarMesas(value),
              decoration: InputDecoration(
                hintText: 'Buscar por número de mesa...',
                prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF8B4513)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF8B4513)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                fillColor: Color(0xFFF5F2F0),
                filled: true,
              ),
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Botón crear compacto
        GestureDetector(
          onTap: () => controller.mostrarModalCrearMesa(),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
        SizedBox(width: 8),
        // Contador de mesas (opcional - puedes usar el observable que tengas)
        Obx(() => Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Color(0xFF3498DB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${controller.mesas.length}', // Ajusta según tu observable
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        )),
      ],
    ),
  );
}

  Widget _buildMesasList() {
    return Obx(() {
      if (controller.filteredMesas.isEmpty) {
        return _buildEmptyState();
      }

      // Lista simple sin RefreshIndicator y sin GridView
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.filteredMesas.length,
        itemBuilder: (context, index) {
          final mesa = controller.filteredMesas[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: buildMesaCard(mesa),
          );
        },
      );
    });
  }
Widget buildMesaCard(Mesa mesa) {
  return Container(
    margin: EdgeInsets.only(bottom: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Row(
      children: [
        // Icono de mesa
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFF8B4513).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.table_restaurant,
            size: 24,
            color: Color(0xFF8B4513),
          ),
        ),
        SizedBox(width: 12),
        
        // Información de la mesa
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mesa ${mesa.numeroMesa}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF3E1F08),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'ID: ${mesa.id}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mesa.status ? Color(0xFF4CAF50).withOpacity(0.1) : Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mesa.status ? 'ACTIVA' : 'INACTIVA',
                  style: TextStyle(
                    color: mesa.status ? Color(0xFF4CAF50) : Color(0xFFFF9800),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Botones de acción
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón activar/desactivar
            GestureDetector(
              onTap: () => controller.confirmarCambioStatus(mesa),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mesa.status ? Color(0xFFFF9800).withOpacity(0.1) : Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  mesa.status ? Icons.visibility_off : Icons.visibility,
                  color: mesa.status ? Color(0xFFFF9800) : Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
            ),
            SizedBox(width: 8),
            // Botón eliminar
            GestureDetector(
              onTap: () => controller.confirmarEliminarMesa(mesa),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 16,
                ),
              ),
            ),
          ],
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
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF8B4513).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.table_restaurant,
              size: 64,
              color: Color(0xFF8B4513),
            ),
          ),
          SizedBox(height: 24),
          Text(
            controller.searchText.value.isNotEmpty || controller.selectedFilter.value != 'Todas'
                ? 'No se encontraron mesas'
                : 'No hay mesas registradas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1F08),
            ),
          ),
          SizedBox(height: 8),
          Text(
            controller.searchText.value.isNotEmpty || controller.selectedFilter.value != 'Todas'
                ? 'Intenta cambiar los filtros de búsqueda'
                : 'Crea tu primera mesa para comenzar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (controller.searchText.value.isEmpty && controller.selectedFilter.value == 'Todas')
            ElevatedButton.icon(
              onPressed: () => controller.mostrarModalCrearMesa(),
              icon: Icon(Icons.add),
              label: Text('Crear Primera Mesa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
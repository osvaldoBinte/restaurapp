import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurapp/common/services/BluetoothPrinterService.dart';

class PrinterConfigWidget extends StatelessWidget {
  final BluetoothPrinterService printerService = Get.find<BluetoothPrinterService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración de Impresión',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8B4513),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(0xFFF5F2F0),
      body: Obx(() => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de conexión
            _buildConnectionStatusCard(),
            
            SizedBox(height: 20),
            
            // Configuración de impresión
            _buildPrintingSettingsCard(),
            
            SizedBox(height: 20),
            
            // Botones de acción
            _buildActionButtons(),
            
            SizedBox(height: 20),
            
            // Lista de dispositivos
            _buildDevicesList(),
          ],
        ),
      )),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: printerService.isConnected.value 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  printerService.isConnected.value 
                    ? Icons.bluetooth_connected 
                    : Icons.bluetooth,
                  color: printerService.isConnected.value 
                    ? Colors.green 
                    : Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Sistema',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    Text(
                      printerService.connectionStatus.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (printerService.selectedDevice.value != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispositivo: ${printerService.selectedDevice.value!['name']}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Dirección: ${printerService.selectedDevice.value!['address']}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrintingSettingsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Configuración de Impresión',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E1F08),
            ),
          ),
          SizedBox(height: 16),
          
          // Toggle para habilitar/deshabilitar impresión
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: printerService.isPrintingEnabled.value
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: printerService.isPrintingEnabled.value
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  printerService.isPrintingEnabled.value
                    ? Icons.print
                    : Icons.print_disabled,
                  color: printerService.isPrintingEnabled.value
                    ? Colors.green
                    : Colors.grey[600],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printerService.isPrintingEnabled.value
                          ? 'Impresión Habilitada'
                          : 'Impresión Deshabilitada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: printerService.isPrintingEnabled.value
                            ? Colors.green[700]
                            : Colors.grey[700],
                        ),
                      ),
                      Text(
                        printerService.isPrintingEnabled.value
                          ? 'Los tickets se generarán automáticamente al procesar pagos'
                          : 'Los tickets no se generarán al procesar pagos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: printerService.isPrintingEnabled.value,
                  onChanged: (value) => printerService.togglePrinting(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Fila 1: Buscar y desconectar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: printerService.isSearching.value 
                  ? null 
                  : () => printerService.searchDevices(),
                icon: printerService.isSearching.value
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.bluetooth_searching, color: Colors.white),
                label: Text(
                  printerService.isSearching.value ? 'Buscando...' : 'Buscar Impresoras',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B4513),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            if (printerService.isConnected.value) ...[
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => printerService.disconnect(),
                  icon: Icon(Icons.bluetooth_disabled, color: Colors.white),
                  label: Text(
                    'Desconectar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Fila 2: Ticket de prueba
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => printerService.imprimirTicketPrueba(),
            icon: Icon(Icons.receipt_long, color: Colors.white),
            label: Text(
              'GENERAR TICKET DE PRUEBA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF27AE60),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dispositivos Bluetooth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E1F08),
                ),
              ),
              SizedBox(width: 8),
              if (printerService.availableDevices.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${printerService.availableDevices.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          
          Expanded(
            child: printerService.availableDevices.isEmpty
              ? _buildEmptyDevicesList()
              : ListView.builder(
                  itemCount: printerService.availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = printerService.availableDevices[index];
                    final isSelected = printerService.selectedDevice.value?['address'] == device['address'];
                    final deviceName = device['name'] ?? 'Dispositivo desconocido';
                    final deviceAddress = device['address'] ?? 'Sin dirección';
                    final deviceType = device['type'] ?? 'Bluetooth';
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? Color(0xFF8B4513) 
                            : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isSelected ? Color(0xFF8B4513) : 
                                   (deviceType == 'Bluetooth' ? Colors.blue : Colors.grey[400]))?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            deviceType == 'Bluetooth' ? Icons.print : Icons.print_outlined,
                            color: isSelected ? Color(0xFF8B4513) : 
                                   (deviceType == 'Bluetooth' ? Colors.blue : Colors.grey[600]),
                          ),
                        ),
                        title: Text(
                          deviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deviceAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: deviceType == 'Bluetooth' 
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    deviceType,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: deviceType == 'Bluetooth' 
                                        ? Colors.blue[700]
                                        : Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: isSelected 
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Conectado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => printerService.connectToDevice(device),
                              child: Text(
                                'Conectar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: deviceType == 'Bluetooth' 
                                  ? Colors.blue 
                                  : Color(0xFF8B4513),
                                minimumSize: Size(80, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDevicesList() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No se encontraron dispositivos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Asegúrese de que su impresora Bluetooth esté:\n• Encendida\n• En modo de emparejamiento\n• Emparejada con este dispositivo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => printerService.searchDevices(),
            icon: Icon(Icons.refresh, color: Colors.white, size: 18),
            label: Text(
              'Buscar de nuevo',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B4513),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
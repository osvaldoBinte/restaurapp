import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPrinterService extends GetxController {
  var isConnected = false.obs;
  var availableDevices = <Map<String, String>>[].obs;
  var selectedDevice = Rxn<Map<String, String>>();
  var isSearching = false.obs;
  var connectionStatus = ''.obs;
  var isPrintingEnabled = true.obs;
  var isConnecting = false.obs;

  // Platform channel para comunicarse con código nativo
  static const platform = MethodChannel('bluetooth_printer_channel');

  @override
  void onInit() {
    super.onInit();
    _initializePrinter();
  }

  /// Verificar y solicitar permisos Bluetooth
  Future<bool> _checkBluetoothPermissions() async {
    try {
      // Verificar permisos según la versión de Android
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Necesario para descubrimiento en Android < 12
      ].request();

      bool allGranted = statuses.values.every(
        (status) => status == PermissionStatus.granted || status == PermissionStatus.limited
      );

      if (!allGranted) {
        Get.snackbar(
          'Permisos Requeridos',
          'Se necesitan permisos de Bluetooth para conectar a la impresora',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
      return true;
    } catch (e) {
      print('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Inicializar el servicio de impresora
  Future<void> _initializePrinter() async {
    try {
      connectionStatus.value = 'Inicializando...';
      
      // Verificar permisos primero
      final hasPermissions = await _checkBluetoothPermissions();
      if (!hasPermissions) {
        connectionStatus.value = 'Sin permisos de Bluetooth';
        return;
      }
      
      // Cargar configuración guardada
      final prefs = await SharedPreferences.getInstance();
      isPrintingEnabled.value = prefs.getBool('printing_enabled') ?? true;
      
      // Cargar dispositivo conectado previamente si existe
      final savedDevice = prefs.getString('selected_printer');
      if (savedDevice != null) {
        try {
          final deviceMap = Map<String, String>.from(jsonDecode(savedDevice));
          selectedDevice.value = deviceMap;
          connectionStatus.value = 'Reconectando a ${deviceMap['name']}...';
          
          // Intentar reconectar al dispositivo guardado
          await _reconnectToSavedDevice(deviceMap);
        } catch (e) {
          print('❌ Error al cargar dispositivo guardado: $e');
        }
      }
      
      if (!isConnected.value) {
        connectionStatus.value = 'Listo para buscar dispositivos';
        // Buscar dispositivos automáticamente
        await searchDevices();
      }
      
    } catch (e) {
      print('❌ Error al inicializar impresora: $e');
      connectionStatus.value = 'Error de inicialización';
    }
  }

  /// Reconectar a dispositivo guardado
  Future<void> _reconnectToSavedDevice(Map<String, String> device) async {
    try {
      final result = await _connectViaPlatform(device['address']!);
      if (result) {
        isConnected.value = true;
        connectionStatus.value = 'Reconectado a ${device['name']}';
        print('✅ Reconectado exitosamente a: ${device['name']}');
      } else {
        isConnected.value = false;
        connectionStatus.value = 'No se pudo reconectar';
        // Limpiar dispositivo que no se puede reconectar
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('selected_printer');
        selectedDevice.value = null;
      }
    } catch (e) {
      isConnected.value = false;
      connectionStatus.value = 'Error en reconexión';
      print('❌ Error al reconectar: $e');
    }
  }

  /// Buscar dispositivos Bluetooth emparejados
  Future<void> searchDevices() async {
    if (isSearching.value) return;
    
    try {
      isSearching.value = true;
      connectionStatus.value = 'Buscando dispositivos Bluetooth...';
      
      // Verificar permisos antes de buscar
      final hasPermissions = await _checkBluetoothPermissions();
      if (!hasPermissions) {
        connectionStatus.value = 'Sin permisos de Bluetooth';
        return;
      }

      // Verificar si Bluetooth está habilitado
      final isBluetoothEnabled = await platform.invokeMethod('isBluetoothEnabled');
      if (!isBluetoothEnabled) {
        connectionStatus.value = 'Bluetooth deshabilitado';
        Get.snackbar(
          'Bluetooth Deshabilitado',
          'Por favor habilite Bluetooth en la configuración del dispositivo',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
      
      // Llamar al código nativo para obtener dispositivos emparejados
      final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
      
      // Convertir a formato esperado
      final List<Map<String, String>> formattedDevices = devices.map((device) {
        return Map<String, String>.from({
          'name': device['name'] ?? 'Dispositivo desconocido',
          'address': device['address'] ?? '',
          'type': 'Bluetooth',
          'bondState': device['bondState'] ?? 'unknown',
        });
      }).toList();
      
      // Filtrar solo dispositivos emparejados correctamente
      final pairedDevices = formattedDevices.where((device) {
        return device['address']!.isNotEmpty && 
               device['bondState'] == 'bonded';
      }).toList();
      
      availableDevices.value = pairedDevices;
      
      if (pairedDevices.isNotEmpty) {
        connectionStatus.value = '${pairedDevices.length} dispositivos encontrados';
        print('✅ Dispositivos encontrados: ${pairedDevices.map((d) => '${d['name']} (${d['address']})').join(', ')}');
      } else {
        connectionStatus.value = 'No se encontraron dispositivos emparejados';
        print('⚠️ No se encontraron dispositivos Bluetooth emparejados');
        
        Get.snackbar(
          'Sin Dispositivos',
          'No se encontraron dispositivos Bluetooth emparejados.\n\nPor favor empareje su impresora desde Configuración > Bluetooth',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('❌ Error al buscar dispositivos: $e');
      connectionStatus.value = 'Error: $e';
      
      Get.snackbar(
        'Error de Búsqueda',
        'Error al buscar dispositivos: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Conectar via platform channel con mejor manejo de errores
  Future<bool> _connectViaPlatform(String address) async {
    try {
      connectionStatus.value = 'Estableciendo conexión...';
      
      // Llamar al método nativo con timeout
      final result = await platform.invokeMethod('connectToDevice', {
        'address': address,
        'timeout': 10000, // 10 segundos timeout
      }).timeout(Duration(seconds: 15));
      
      return result == true;
    } catch (e) {
      print('❌ Error en conexión platform: $e');
      connectionStatus.value = 'Error de conexión: $e';
      return false;
    }
  }

  /// Conectar a un dispositivo específico
  Future<bool> connectToDevice(Map<String, String> device) async {
    if (isConnecting.value) return false;
    
    try {
      isConnecting.value = true;
      connectionStatus.value = 'Conectando a ${device['name']}...';
      
      // Desconectar dispositivo actual si existe
      if (isConnected.value) {
        await disconnect();
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      bool connected = false;
      
      if (device['type'] == 'Bluetooth' && device['address']!.isNotEmpty) {
        // Intentar conexión real
        connected = await _connectViaPlatform(device['address']!);
        
        if (connected) {
          // Verificar conexión con un comando de prueba
          final testResult = await _testConnection();
          if (!testResult) {
            print('⚠️ Conexión establecida pero no responde a comandos');
            await platform.invokeMethod('disconnect');
            connected = false;
          }
        }
      }
      
      if (connected) {
        selectedDevice.value = device;
        isConnected.value = true;
        connectionStatus.value = 'Conectado a ${device['name']}';
        
        // Guardar dispositivo seleccionado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_printer', jsonEncode(device));
        
        Get.snackbar(
          'Conexión Exitosa',
          'Conectado a ${device['name']}\nDirección: ${device['address']}',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        
        print('✅ Conectado exitosamente a: ${device['name']} (${device['address']})');
        return true;
      } else {
        connectionStatus.value = 'Error al conectar con ${device['name']}';
        
        Get.snackbar(
          'Error de Conexión',
          'No se pudo conectar a ${device['name']}\n\nVerifique que:\n- La impresora esté encendida\n- Esté en rango de alcance\n- No esté conectada a otro dispositivo',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al conectar: $e');
      connectionStatus.value = 'Error al conectar: $e';
      
      Get.snackbar(
        'Error de Conexión',
        'Error inesperado al conectar: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Probar conexión con la impresora
  Future<bool> _testConnection() async {
    try {
      // Enviar comando de estado ESC/POS
      final testResult = await platform.invokeMethod('sendTestCommand');
      return testResult == true;
    } catch (e) {
      print('❌ Error en test de conexión: $e');
      return false;
    }
  }

  /// Desconectar dispositivo
  Future<void> disconnect() async {
    try {
      if (selectedDevice.value != null && selectedDevice.value!['type'] == 'Bluetooth') {
        // Desconectar dispositivo real
        await platform.invokeMethod('disconnect');
      }
      
      selectedDevice.value = null;
      isConnected.value = false;
      connectionStatus.value = 'Desconectado';
      
      print('✅ Desconectado exitosamente');
    } catch (e) {
      print('❌ Error al desconectar: $e');
      connectionStatus.value = 'Error al desconectar: $e';
    }
  }

  /// Generar comandos ESC/POS para impresora térmica
  List<int> _generateESCPOSCommands(String content) {
    List<int> commands = [];
    
    // Inicializar impresora
    commands.addAll([0x1B, 0x40]); // ESC @
    
    // Configurar caracteres
    commands.addAll([0x1B, 0x52, 0x00]); // Seleccionar tabla de caracteres internacional
    commands.addAll([0x1B, 0x74, 0x13]); // Seleccionar página de códigos CP850
    
    // Alineación centrada para encabezado
    commands.addAll([0x1B, 0x61, 0x01]); // ESC a 1 (centrado)
    
    // Texto en negrita para encabezado
    commands.addAll([0x1B, 0x45, 0x01]); // ESC E 1 (negrita on)
    
    // Procesar contenido línea por línea
    final lines = content.split('\n');
    bool isHeader = true;
    
    for (String line in lines) {
      if (line.trim().isEmpty) {
        commands.addAll([0x0A]); // Línea vacía
        continue;
      }
      
      // Detectar cambio de sección (del encabezado al contenido)
      if (line.contains('PRODUCTOS') || line.contains('--------------------------------')) {
        isHeader = false;
        // Cambiar a alineación izquierda
        commands.addAll([0x1B, 0x61, 0x00]); // ESC a 0 (izquierda)
        // Quitar negrita
        commands.addAll([0x1B, 0x45, 0x00]); // ESC E 0 (negrita off)
      }
      
      // Aplicar negrita a líneas de total
      if (line.contains('TOTAL:') || line.contains('Subtotal:')) {
        commands.addAll([0x1B, 0x45, 0x01]); // ESC E 1 (negrita on)
      }
      
      // Convertir texto a bytes
      try {
        // Intentar UTF-8 primero, luego latin1 como fallback
        List<int> textBytes;
        try {
          textBytes = utf8.encode(line);
        } catch (e) {
          textBytes = latin1.encode(line);
        }
        
        commands.addAll(textBytes);
        commands.addAll([0x0A]); // Nueva línea
        
        // Quitar negrita después de líneas de total
        if (line.contains('TOTAL:') || line.contains('Subtotal:')) {
          commands.addAll([0x1B, 0x45, 0x00]); // ESC E 0 (negrita off)
        }
      } catch (e) {
        print('❌ Error codificando línea: $line - $e');
        // Como fallback, usar ASCII básico
        commands.addAll(line.codeUnits.where((c) => c < 128).toList());
        commands.addAll([0x0A]);
      }
    }
    
    // Avanzar papel y cortar
    commands.addAll([0x0A, 0x0A, 0x0A]); // 3 líneas vacías
    commands.addAll([0x1D, 0x56, 0x42, 0x00]); // Corte parcial del papel
    
    return commands;
  }

  /// Enviar datos a impresora real con formato ESC/POS
  Future<bool> _sendToPrinter(String content) async {
    try {
      if (selectedDevice.value != null && selectedDevice.value!['type'] == 'Bluetooth' && isConnected.value) {
        // Generar comandos ESC/POS
        final commands = _generateESCPOSCommands(content);
        
        // Enviar a impresora real usando bytes
        final result = await platform.invokeMethod('printBytes', {
          'data': commands,
        });
        
        if (result == true) {
          print('✅ Datos enviados a impresora: ${commands.length} bytes');
          return true;
        } else {
          print('❌ Error enviando datos a impresora');
          return false;
        }
      } else {
        // Modo simulado
        print('📄 IMPRESIÓN SIMULADA:\n$content');
        return true;
      }
    } catch (e) {
      print('❌ Error al enviar a impresora: $e');
      
      // Intentar reconectar si hay error de conexión
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        isConnected.value = false;
        connectionStatus.value = 'Conexión perdida';
        
        Get.snackbar(
          'Conexión Perdida',
          'Se perdió la conexión con la impresora. Intentando reconectar...',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        
        // Intentar reconectar automáticamente
        if (selectedDevice.value != null) {
          await Future.delayed(Duration(seconds: 2));
          await connectToDevice(selectedDevice.value!);
        }
      }
      
      return false;
    }
  }

  /// Generar contenido del ticket optimizado para impresoras térmicas
  String _generateTicketContent({
    required int numeroMesa,
    required List<Map<String, dynamic>> pedidos,
    required double totalMesa,
    String metodoPago = 'Efectivo',
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final fechaFormat = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Encabezado optimizado para impresora térmica (32 caracteres max)
    buffer.writeln('================================');
    buffer.writeln('        RESTAURANTE EJ');
    buffer.writeln('      Comedor El Jobo');
    buffer.writeln('================================');
    buffer.writeln('');
    buffer.writeln('Fecha: $fechaFormat');
    buffer.writeln('Mesa: $numeroMesa');
    buffer.writeln('Metodo: $metodoPago');
    buffer.writeln('');
    buffer.writeln('--------------------------------');
    buffer.writeln('          PRODUCTOS');
    buffer.writeln('--------------------------------');

    double subtotal = 0.0;
    int totalItems = 0;

    for (var pedido in pedidos) {
      final detalles = pedido['detalles'] as List;
      final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
      
      // Nombre del pedido (truncado si es muy largo)
      final nombreTruncado = nombreOrden.length > 30 
        ? nombreOrden.substring(0, 30) + '...'
        : nombreOrden;
      
      buffer.writeln('');
      buffer.writeln('Pedido: $nombreTruncado');
      buffer.writeln('- - - - - - - - - - - - - - - -');

      for (var detalle in detalles) {
        final status = detalle['statusDetalle'] ?? 'proceso';
        
        if (status != 'cancelado') {
          final nombre = detalle['nombreProducto'] ?? 'Producto';
          final cantidad = (detalle['cantidad'] as num?)?.toInt() ?? 1;
          final precio = (detalle['precioUnitario'] as num?)?.toDouble() ?? 0.0;
          final lineTotal = precio * cantidad;
          
          subtotal += lineTotal;
          totalItems += cantidad;

          // Formatear línea de producto (máximo 32 caracteres)
          final nombreTruncado = nombre.length > 25 
            ? nombre.substring(0, 25) + '...'
            : nombre;
          
          buffer.writeln('$cantidad x $nombreTruncado');
          buffer.writeln('  \$${precio.toStringAsFixed(2)} c/u = \$${lineTotal.toStringAsFixed(2)}');
          
          // Observaciones si existen (truncadas)
          final observaciones = detalle['observaciones'];
          if (observaciones != null && observaciones.isNotEmpty) {
            final obsTruncadas = observaciones.length > 28
              ? observaciones.substring(0, 28) + '...'
              : observaciones;
            buffer.writeln('  * $obsTruncadas');
          }
        }
      }
    }

    // Totales
    buffer.writeln('');
    buffer.writeln('================================');
    buffer.writeln('Items totales: $totalItems');
    buffer.writeln('');
    buffer.writeln('       TOTAL: \$${totalMesa.toStringAsFixed(2)}');
    buffer.writeln('================================');
    buffer.writeln('');
    buffer.writeln('     Gracias por su visita');
    buffer.writeln('        Vuelva pronto');
    buffer.writeln('');
    buffer.writeln('${fechaFormat}');
    buffer.writeln('================================');

    return buffer.toString();
  }

  /// Imprimir ticket de pedido específico
  Future<bool> imprimirTicketPedido({
    required int numeroMesa,
    required Map<String, dynamic> pedido,
    required double totalPedido,
    String metodoPago = 'Efectivo',
  }) async {
    if (!isPrintingEnabled.value) {
      Get.snackbar(
        'Impresión deshabilitada', 
        'La impresión está deshabilitada en configuración',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    try {
      // Verificar conexión antes de imprimir
      if (isConnected.value && selectedDevice.value != null) {
        final connectionTest = await _testConnection();
        if (!connectionTest) {
          isConnected.value = false;
          connectionStatus.value = 'Conexión perdida';
          
          Get.snackbar(
            'Sin Conexión',
            'La impresora no responde. Verifique la conexión.',
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
          return false;
        }
      }

      // Generar contenido del ticket para pedido específico
      final ticketContent = _generateTicketContent(
        numeroMesa: numeroMesa,
        pedidos: [pedido], // Solo este pedido
        totalMesa: totalPedido,
        metodoPago: metodoPago,
      );

      // Mostrar indicador de impresión
      Get.dialog(
        Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text('Enviando a impresora...'),
                if (selectedDevice.value != null)
                  Text(
                    selectedDevice.value!['name']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Intentar enviar a impresora
      final printed = await _sendToPrinter(ticketContent);
      
      // Cerrar indicador de carga
      Get.back();
      
      if (printed) {
        // Mostrar vista previa del ticket
        await _showTicketPreview(
          title: 'Ticket Pedido #${pedido['pedidoId']}',
          content: ticketContent,
          mesa: numeroMesa,
          total: totalPedido,
          pedidoId: pedido['pedidoId'],
          success: true,
        );
        
        print('✅ Ticket impreso para Pedido #${pedido['pedidoId']} - Total: \$${totalPedido.toStringAsFixed(2)}');
        return true;
      } else {
        throw Exception('Error al enviar datos a la impresora');
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al imprimir ticket: $e');
      Get.snackbar(
        'Error de Impresión', 
        'Error al imprimir: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      return false;
    }
  }

  /// Mostrar vista previa del ticket
  Future<void> _showTicketPreview({
    required String title,
    required String content,
    required int mesa,
    required double total,
    int? pedidoId,
    bool success = false,
  }) async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.85,
          height: Get.height * 0.75,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: success ? Colors.green : Color(0xFF8B4513),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      success ? Icons.check_circle : (isConnected.value ? Icons.print : Icons.receipt_long),
                      color: Colors.white
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            success ? 'Ticket Impreso' : title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isConnected.value && selectedDevice.value?['type'] == 'Bluetooth'
                              ? 'Enviado a ${selectedDevice.value!['name']}'
                              : 'Generado en modo demo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Contenido del ticket
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        content,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF3E1F08),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Footer con información de estado
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesa $mesa ${pedidoId != null ? '- Pedido #$pedidoId' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E1F08),
                              ),
                            ),
                            Text(
                              'Total: \$${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => Get.back(),
                          child: Text('Cerrar', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                    
                    // Estado de conexión
                    if (isConnected.value && selectedDevice.value != null) ...[
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bluetooth_connected, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Conectado a ${selectedDevice.value!['name']}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bluetooth_disabled, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Modo demo - Sin impresora conectada',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Imprimir ticket de prueba mejorado
  Future<bool> imprimirTicketPrueba() async {
    try {
      final now = DateTime.now();
      final fechaFormat = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
      
      final testContent = '''
================================
      TICKET DE PRUEBA
================================

Fecha: $fechaFormat
Estado: Servicio funcionando
${isConnected.value && selectedDevice.value != null ? 'Dispositivo: ${selectedDevice.value!['name']}' : 'Modo: Demostración'}

--------------------------------
        ¡Conexión exitosa!
--------------------------------

Este es un ticket de prueba para
verificar que el sistema de
impresión está funcionando 
correctamente.

Datos de conexión:
${isConnected.value ? '✓ Impresora conectada' : '✗ Sin conexión'}
${selectedDevice.value != null ? '✓ Dispositivo: ${selectedDevice.value!['address']}' : '✗ Sin dispositivo'}

${isConnected.value && selectedDevice.value?['type'] == 'Bluetooth' ? '🖨️ Enviado via Bluetooth' : '📱 Generado en modo demo'}

================================
''';

      // Mostrar indicador de impresión
      Get.dialog(
        Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                ),
                SizedBox(height: 16),
                Text('Enviando ticket de prueba...'),
                if (selectedDevice.value != null)
                  Text(
                    selectedDevice.value!['name']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final printed = await _sendToPrinter(testContent);
      
      // Cerrar indicador
      Get.back();
      
      if (printed) {
        await _showTicketPreview(
          title: 'Ticket de Prueba',
          content: testContent,
          mesa: 0,
          total: 0.0,
          success: true,
        );
        
        Get.snackbar(
          'Prueba Exitosa', 
          isConnected.value && selectedDevice.value?['type'] == 'Bluetooth'
            ? 'Ticket enviado a la impresora correctamente'
            : 'El sistema de tickets está funcionando en modo demo',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        
        return true;
      } else {
        throw Exception('Error al enviar ticket de prueba');
      }
    } catch (e) {
      // Cerrar indicador si está abierto
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('❌ Error al imprimir ticket de prueba: $e');
      Get.snackbar(
        'Error', 
        'Error al imprimir ticket de prueba: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Alternar estado de impresión
  Future<void> togglePrinting() async {
    isPrintingEnabled.value = !isPrintingEnabled.value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('printing_enabled', isPrintingEnabled.value);
    
    Get.snackbar(
      isPrintingEnabled.value ? 'Impresión Habilitada' : 'Impresión Deshabilitada',
      isPrintingEnabled.value 
        ? 'Los tickets se generarán automáticamente'
        : 'Los tickets no se generarán',
      backgroundColor: isPrintingEnabled.value 
        ? Colors.green.withOpacity(0.8)
        : Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  /// Obtener información detallada del dispositivo conectado
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected.value,
      'selectedDevice': selectedDevice.value,
      'connectionStatus': connectionStatus.value,
      'isPrintingEnabled': isPrintingEnabled.value,
      'availableDevicesCount': availableDevices.length,
    };
  }

  /// Forzar reconexión
  Future<void> forceReconnect() async {
    if (selectedDevice.value != null) {
      await disconnect();
      await Future.delayed(Duration(seconds: 1));
      await connectToDevice(selectedDevice.value!);
    } else {
      Get.snackbar(
        'Sin Dispositivo',
        'No hay ningún dispositivo seleccionado para reconectar',
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
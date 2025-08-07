// pubspec.yaml - Agregar estas dependencias:
/*
dependencies:
  flutter_bluetooth_serial: ^0.4.0
  esc_pos_utils: ^1.1.0
  image: ^3.0.2
*/

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'dart:convert';
import 'dart:typed_data';

class BluetoothPrinter extends StatefulWidget {
  @override
  _BluetoothPrinterState createState() => _BluetoothPrinterState();
}

class _BluetoothPrinterState extends State<BluetoothPrinter> {
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  // Obtener dispositivos emparejados
  void _getBondedDevices() async {
    List<BluetoothDevice> bondedDevices = 
        await FlutterBluetoothSerial.instance.getBondedDevices();
    
    setState(() {
      devices = bondedDevices.where((device) => 
        device.name?.toLowerCase().contains('printer') == true ||
        device.name?.toLowerCase().contains('bluetooth') == true
      ).toList();
    });
  }

  // Conectar a impresora
  void _connectToPrinter(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        isConnected = true;
        selectedDevice = device;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a ${device.name}')),
      );
    } catch (e) {
      print('Error conectando: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar: $e')),
      );
    }
  }

  // Desconectar impresora
  void _disconnect() async {
    if (connection != null) {
      await connection!.close();
      setState(() {
        isConnected = false;
        selectedDevice = null;
        connection = null;
      });
    }
  }

  // Imprimir texto simple
  void _printHello() async {
    if (connection == null || !isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay conexión con la impresora')),
      );
      return;
    }

    try {
      // Crear comandos ESC/POS
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = [];
      
      // Texto centrado y grande
      bytes += generator.text('HOLA MUNDO!',
          styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      
      bytes += generator.text('Impreso desde Flutter',
          styles: PosStyles(align: PosAlign.center));
      
      bytes += generator.text('-------------------------',
          styles: PosStyles(align: PosAlign.center));
      
      bytes += generator.text('Fecha: ${DateTime.now().toString().substring(0, 19)}',
          styles: PosStyles(align: PosAlign.left));
      
      // Salto de líneas y corte de papel
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Enviar a impresora
      connection!.output.add(Uint8List.fromList(bytes));
      await connection!.output.allSent;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Impreso exitosamente!')),
      );
      
    } catch (e) {
      print('Error imprimiendo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir: $e')),
      );
    }
  }

  // Imprimir ticket más completo
  void _printTicket() async {
    if (connection == null || !isConnected) return;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = [];
      
      // Header del ticket
      bytes += generator.text('MI NEGOCIO',
          styles: PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
          ));
      
      bytes += generator.text('Dirección: Calle 123',
          styles: PosStyles(align: PosAlign.center));
      
      bytes += generator.text('Tel: +52 123 456 7890',
          styles: PosStyles(align: PosAlign.center));
      
      bytes += generator.text('================================',
          styles: PosStyles(align: PosAlign.center));
      
      // Productos
      bytes += generator.text('TICKET DE VENTA');
      bytes += generator.text('--------------------------------');
      
      bytes += generator.row([
        PosColumn(text: 'Producto 1', width: 8),
        PosColumn(text: '\$10.00', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Producto 2', width: 8),
        PosColumn(text: '\$25.50', width: 4, styles: PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.text('--------------------------------');
      
      bytes += generator.row([
        PosColumn(text: 'TOTAL:', width: 8, styles: PosStyles(bold: true)),
        PosColumn(text: '\$35.50', width: 4, 
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);
      
      bytes += generator.text('');
      bytes += generator.text('¡Gracias por su compra!',
          styles: PosStyles(align: PosAlign.center));
      
      bytes += generator.feed(2);
      bytes += generator.cut();

      connection!.output.add(Uint8List.fromList(bytes));
      await connection!.output.allSent;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket impreso!')),
      );
      
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Impresora Bluetooth'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Estado de conexión
            Card(
              child: ListTile(
                leading: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                title: Text(isConnected 
                    ? 'Conectado: ${selectedDevice?.name}' 
                    : 'No conectado'),
                subtitle: Text(isConnected 
                    ? selectedDevice?.address ?? '' 
                    : 'Selecciona una impresora'),
                trailing: isConnected 
                    ? ElevatedButton(
                        onPressed: _disconnect,
                        child: Text('Desconectar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ) 
                    : null,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Lista de dispositivos disponibles
            if (!isConnected) ...[
              Text('Impresoras disponibles:', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.print),
                        title: Text(device.name ?? 'Dispositivo desconocido'),
                        subtitle: Text(device.address),
                        onTap: () => _connectToPrinter(device),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Botones de impresión
            if (isConnected) ...[
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _printHello,
                icon: Icon(Icons.print),
                label: Text('Imprimir "HOLA"'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              
              SizedBox(height: 10),
              
              ElevatedButton.icon(
                onPressed: _printTicket,
                icon: Icon(Icons.receipt),
                label: Text('Imprimir Ticket Completo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (connection != null) {
      connection!.close();
    }
    super.dispose();
  }
}

// Para usar en main.dart:
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impresora Bluetooth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothPrinter(),
    );
  }
}

void main() async{ 
  WidgetsFlutterBinding.ensureInitialized();
 

  runApp( MyApp());
}

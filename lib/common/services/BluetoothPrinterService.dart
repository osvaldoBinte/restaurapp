// pubspec.yaml - Agregar estas dependencias:
/*
dependencies:
  flutter:
    sdk: flutter
  
  # Para móvil (Android/iOS)
  flutter_bluetooth_serial: ^0.4.0
  esc_pos_utils: ^1.1.0
  image: ^3.0.2
  
  # Para desktop (Windows/Mac/Linux)
  win32: ^5.0.0  # Solo Windows
  ffi: ^2.0.1
  path: ^1.8.0
  
  # Detección de plataforma
  universal_io: ^2.2.0
  
  # Para impresión por red (IP)
  ping_discover_network: ^0.1.1
*/

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// Imports para móvil
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' 
    if (dart.library.html) 'package:restaurapp/stubs/bluetooth_stub.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

// Imports para desktop
import 'package:ffi/ffi.dart' if (dart.library.html) 'package:restaurapp/stubs/ffi_stub.dart';
import 'package:win32/win32.dart' if (dart.library.html) 'package:restaurapp/stubs/win32_stub.dart';

class UniversalPrinterService {
  // Variables para móvil
  BluetoothConnection? bluetoothConnection;
  bool isBluetoothConnected = false;
  
  // Variables para desktop
  String? selectedPrinterName;
  bool isDesktopPrinterConnected = false;
  
  // Detectar plataforma
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  // ===== FUNCIONES PÚBLICAS =====
  
  /// Conectar automáticamente a impresora según plataforma
  Future<bool> conectarImpresoraAutomaticamente() async {
    try {
      if (isMobile) {
        return await _conectarBluetoothAutomatico();
      } else if (isDesktop) {
        return await _conectarImpresoraDesktop();
      }
      return false;
    } catch (e) {
      print('❌ Error conectando impresora: $e');
      return false;
    }
  }
  
  /// Imprimir ticket universal
  Future<void> imprimirTicket(Map<String, dynamic> pedido, double total) async {
    try {
      if (isMobile && isBluetoothConnected) {
        await _imprimirTicketBluetooth(pedido, total);
      } else if (isDesktop && isDesktopPrinterConnected) {
        await _imprimirTicketDesktop(pedido, total);
      } else {
        throw Exception('No hay impresora conectada');
      }
    } catch (e) {
      print('❌ Error imprimiendo ticket: $e');
      rethrow;
    }
  }
  
  /// Desconectar impresora
  Future<void> desconectar() async {
    try {
      if (isMobile && bluetoothConnection != null) {
        await bluetoothConnection!.close();
        bluetoothConnection = null;
        isBluetoothConnected = false;
      }
      
      if (isDesktop) {
        selectedPrinterName = null;
        isDesktopPrinterConnected = false;
      }
    } catch (e) {
      print('❌ Error desconectando: $e');
    }
  }
  
  /// Obtener impresoras disponibles según plataforma
  Future<List<String>> obtenerImpresorasDisponibles() async {
    try {
      if (isMobile) {
        return await _obtenerImpresorasBluetooth();
      } else if (isDesktop) {
        return await _obtenerImpresorasDesktop();
      }
      return [];
    } catch (e) {
      print('❌ Error obteniendo impresoras: $e');
      return [];
    }
  }
  
  // ===== FUNCIONES MÓVIL (BLUETOOTH) =====
  
  Future<bool> _conectarBluetoothAutomatico() async {
    try {
      List<BluetoothDevice> bondedDevices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      BluetoothDevice? impresora;
      for (var device in bondedDevices) {
        final deviceName = device.name?.toLowerCase() ?? '';
        if (deviceName.contains('printer') || 
            deviceName.contains('bluetooth') ||
            deviceName.contains('pos') ||
            deviceName.contains('receipt')) {
          impresora = device;
          break;
        }
      }
      
      if (impresora == null) {
        print('❌ No se encontró impresora Bluetooth');
        return false;
      }
      
      bluetoothConnection = await BluetoothConnection.toAddress(impresora.address);
      isBluetoothConnected = true;
      
      print('✅ Conectado a impresora Bluetooth: ${impresora.name}');
      return true;
      
    } catch (e) {
      print('❌ Error Bluetooth: $e');
      return false;
    }
  }
  
  Future<List<String>> _obtenerImpresorasBluetooth() async {
    try {
      List<BluetoothDevice> bondedDevices = 
          await FlutterBluetoothSerial.instance.getBondedDevices();
      
      return bondedDevices
          .where((device) {
            final name = device.name?.toLowerCase() ?? '';
            return name.contains('printer') || 
                   name.contains('bluetooth') ||
                   name.contains('pos');
          })
          .map((device) => device.name ?? 'Dispositivo desconocido')
          .toList();
    } catch (e) {
      print('❌ Error obteniendo Bluetooth: $e');
      return [];
    }
  }
  
  Future<void> _imprimirTicketBluetooth(Map<String, dynamic> pedido, double total) async {
    if (!isBluetoothConnected || bluetoothConnection == null) {
      throw Exception('No hay conexión Bluetooth');
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = _generarComandosESCPOS(generator, pedido, total);
      
      bluetoothConnection!.output.add(Uint8List.fromList(bytes));
      await bluetoothConnection!.output.allSent;
      
      print('✅ Ticket Bluetooth impreso correctamente');
      
    } catch (e) {
      print('❌ Error imprimiendo Bluetooth: $e');
      rethrow;
    }
  }
  
  // ===== FUNCIONES DESKTOP (USB/SERIAL/RED) =====
  
  Future<bool> _conectarImpresoraDesktop() async {
    try {
      List<String> impresoras = await _obtenerImpresorasDesktop();
      
      if (impresoras.isEmpty) {
        print('❌ No se encontraron impresoras en desktop');
        return false;
      }
      
      // Buscar impresora POS o térmica
      String? impresoraPOS;
      for (String impresora in impresoras) {
        final nombreLower = impresora.toLowerCase();
        if (nombreLower.contains('pos') || 
            nombreLower.contains('thermal') ||
            nombreLower.contains('receipt') ||
            nombreLower.contains('ticket')) {
          impresoraPOS = impresora;
          break;
        }
      }
      
      // Si no encuentra específica, usar la primera disponible
      selectedPrinterName = impresoraPOS ?? impresoras.first;
      isDesktopPrinterConnected = true;
      
      print('✅ Impresora desktop seleccionada: $selectedPrinterName');
      return true;
      
    } catch (e) {
      print('❌ Error desktop: $e');
      return false;
    }
  }
  
  Future<List<String>> _obtenerImpresorasDesktop() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isWindows) {
        impresoras = await _obtenerImpresorasWindows();
      } else if (Platform.isMacOS) {
        impresoras = await _obtenerImpresorasMac();
      } else if (Platform.isLinux) {
        impresoras = await _obtenerImpresorasLinux();
      }
    } catch (e) {
      print('❌ Error obteniendo impresoras desktop: $e');
    }
    
    return impresoras;
  }
  
  // WINDOWS - Usando Win32 API
  Future<List<String>> _obtenerImpresorasWindows() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isWindows) {
        // Usar comando PowerShell para obtener impresoras
        ProcessResult result = await Process.run(
          'powershell',
          ['-Command', 'Get-Printer | Select-Object -ExpandProperty Name'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          String output = result.stdout.toString();
          impresoras = output.split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error Windows impresoras: $e');
    }
    
    return impresoras;
  }
  
  // MAC - Usando comando system
  Future<List<String>> _obtenerImpresorasMac() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isMacOS) {
        ProcessResult result = await Process.run(
          'lpstat',
          ['-p'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          String output = result.stdout.toString();
          RegExp regex = RegExp(r'printer (.+) ');
          Iterable<RegExpMatch> matches = regex.allMatches(output);
          
          impresoras = matches
              .map((match) => match.group(1)!)
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error Mac impresoras: $e');
    }
    
    return impresoras;
  }
  
  // LINUX - Usando CUPS
  Future<List<String>> _obtenerImpresorasLinux() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isLinux) {
        ProcessResult result = await Process.run(
          'lpstat',
          ['-p'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          String output = result.stdout.toString();
          RegExp regex = RegExp(r'printer (.+) ');
          Iterable<RegExpMatch> matches = regex.allMatches(output);
          
          impresoras = matches
              .map((match) => match.group(1)!)
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error Linux impresoras: $e');
    }
    
    return impresoras;
  }
  
  Future<void> _imprimirTicketDesktop(Map<String, dynamic> pedido, double total) async {
    if (!isDesktopPrinterConnected || selectedPrinterName == null) {
      throw Exception('No hay impresora desktop conectada');
    }

    try {
      // Generar contenido del ticket en texto plano para desktop
      String contenidoTicket = _generarTicketTextoPlano(pedido, total);
      
      if (Platform.isWindows) {
        await _imprimirWindows(contenidoTicket);
      } else if (Platform.isMacOS) {
        await _imprimirMac(contenidoTicket);
      } else if (Platform.isLinux) {
        await _imprimirLinux(contenidoTicket);
      }
      
      print('✅ Ticket desktop impreso correctamente');
      
    } catch (e) {
      print('❌ Error imprimiendo desktop: $e');
      rethrow;
    }
  }
  
  Future<void> _imprimirWindows(String contenido) async {
    try {
      // Crear archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(contenido, encoding: utf8);
      
      // Imprimir usando comando print de Windows
      ProcessResult result = await Process.run(
        'print',
        ['/D:$selectedPrinterName', tempFile.path],
        runInShell: true,
      );
      
      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (result.exitCode != 0) {
        throw Exception('Error imprimiendo en Windows: ${result.stderr}');
      }
      
    } catch (e) {
      print('❌ Error Windows print: $e');
      rethrow;
    }
  }
  
  Future<void> _imprimirMac(String contenido) async {
    try {
      // Crear archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(contenido, encoding: utf8);
      
      // Imprimir usando lpr
      ProcessResult result = await Process.run(
        'lpr',
        ['-P', selectedPrinterName!, tempFile.path],
        runInShell: true,
      );
      
      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (result.exitCode != 0) {
        throw Exception('Error imprimiendo en Mac: ${result.stderr}');
      }
      
    } catch (e) {
      print('❌ Error Mac print: $e');
      rethrow;
    }
  }
  
  Future<void> _imprimirLinux(String contenido) async {
    try {
      // Crear archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(contenido, encoding: utf8);
      
      // Imprimir usando lpr
      ProcessResult result = await Process.run(
        'lpr',
        ['-P', selectedPrinterName!, tempFile.path],
        runInShell: true,
      );
      
      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (result.exitCode != 0) {
        throw Exception('Error imprimiendo en Linux: ${result.stderr}');
      }
      
    } catch (e) {
      print('❌ Error Linux print: $e');
      rethrow;
    }
  }
  
  // ===== FUNCIONES AUXILIARES =====
  
  /// Generar comandos ESC/POS para impresoras térmicas móviles
  List<int> _generarComandosESCPOS(Generator generator, Map<String, dynamic> pedido, double total) {
    List<int> bytes = [];
    
    // Header
    bytes += generator.text('COMEDOR "EL JOBO"',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    
    bytes += generator.text('================================',
        styles: PosStyles(align: PosAlign.center));
    
    // Información del pedido
    final numeroMesa = pedido['numeroMesa'] ?? 'S/N';
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final pedidoId = pedido['pedidoId'] ?? 'S/N';
    final fecha = DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final horaStr = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    bytes += generator.row([
      PosColumn(text: 'Mesa:', width: 4),
      PosColumn(text: '$numeroMesa', width: 8, styles: PosStyles(bold: true)),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Pedido:', width: 4),
      PosColumn(text: '#$pedidoId', width: 8),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'Cliente:', width: 4),
      PosColumn(text: '$nombreOrden', width: 8),
    ]);
    
    // Productos
    bytes += generator.text('--------------------------------');
    final detalles = pedido['detalles'] as List;
    double subtotal = 0.0;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'cancelado') continue;
      
      final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
      final cantidad = detalle['cantidad'] ?? 1;
      final precioUnitario = (detalle['precioUnitario'] ?? 0.0).toDouble();
      final totalItem = precioUnitario * cantidad;
      
      subtotal += totalItem;
      
      bytes += generator.row([
        PosColumn(text: nombreProducto, width: 6),
        PosColumn(text: '$cantidad', width: 3, styles: PosStyles(align: PosAlign.center)),
        PosColumn(text: '\$${totalItem.toStringAsFixed(2)}', width: 3, 
            styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    
    // Total
    bytes += generator.text('--------------------------------');
    bytes += generator.row([
      PosColumn(text: 'SUBTOTAL:', width: 8, 
          styles: PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: '\$${subtotal.toStringAsFixed(2)}', width: 4, 
          styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);
    
    bytes += generator.text('');
    bytes += generator.text('¡Gracias por su visita!',
        styles: PosStyles(align: PosAlign.center, bold: true));
    
    bytes += generator.feed(3);
    bytes += generator.cut();
    
    return bytes;
  }
  
  /// Generar ticket en texto plano para impresoras desktop
  String _generarTicketTextoPlano(Map<String, dynamic> pedido, double total) {
    StringBuffer ticket = StringBuffer();
    
    // Header
    ticket.writeln(''.padLeft(32, '='));
    ticket.writeln('       COMEDOR "EL JOBO"');
    ticket.writeln('        Órdenes de Comida');
    ticket.writeln(''.padLeft(32, '='));
    
    // Información del pedido
    final numeroMesa = pedido['numeroMesa'] ?? 'S/N';
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final pedidoId = pedido['pedidoId'] ?? 'S/N';
    final fecha = DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final horaStr = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    ticket.writeln('TICKET DE VENTA');
    ticket.writeln(''.padLeft(32, '-'));
    ticket.writeln('Mesa: $numeroMesa');
    ticket.writeln('Pedido: #$pedidoId');
    ticket.writeln('Cliente: $nombreOrden');
    ticket.writeln('Fecha: $fechaStr');
    ticket.writeln('Hora: $horaStr');
    ticket.writeln(''.padLeft(32, '='));
    
    // Productos
    ticket.writeln('PRODUCTO         CANT   TOTAL');
    ticket.writeln(''.padLeft(32, '-'));
    
    final detalles = pedido['detalles'] as List;
    double subtotal = 0.0;
    
    for (var detalle in detalles) {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'cancelado') continue;
      
      final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
      final cantidad = detalle['cantidad'] ?? 1;
      final precioUnitario = (detalle['precioUnitario'] ?? 0.0).toDouble();
      final totalItem = precioUnitario * cantidad;
      
      subtotal += totalItem;
      
      // Formatear línea del producto
      String nombre = nombreProducto.length > 16 ? nombreProducto.substring(0, 16) : nombreProducto;
      String linea = '${nombre.padRight(16)} ${cantidad.toString().padLeft(4)} \$${totalItem.toStringAsFixed(2).padLeft(6)}';
      ticket.writeln(linea);
      
      // Observaciones si existen
      final observaciones = detalle['observaciones'];
      if (observaciones != null && observaciones.toString().trim().isNotEmpty) {
        ticket.writeln('  * $observaciones');
      }
    }
    
    // Total
    ticket.writeln(''.padLeft(32, '-'));
    ticket.writeln('SUBTOTAL:               \$${subtotal.toStringAsFixed(2)}');
    ticket.writeln(''.padLeft(32, '='));
    ticket.writeln('');
    ticket.writeln('      ¡Gracias por su visita!');
    ticket.writeln('');
    ticket.writeln('     Sistema de Restaurante');
    ticket.writeln('   ${DateTime.now().toString().substring(0, 19)}');
    ticket.writeln('');
    ticket.writeln('');
    ticket.writeln('');
    
    return ticket.toString();
  }
}
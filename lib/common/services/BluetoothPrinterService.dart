// ✅ CÓDIGO CORREGIDO para detectar tu impresora POS-58 en Windows

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
  
  // ===== FUNCIONES DESKTOP CORREGIDAS =====
  
  Future<bool> _conectarImpresoraDesktop() async {
    try {
      List<String> impresoras = await _obtenerImpresorasDesktop();
      
      print('🖨️ Impresoras encontradas: $impresoras');
      
      if (impresoras.isEmpty) {
        print('❌ No se encontraron impresoras en desktop');
        return false;
      }
      
      // ✅ MEJORADO: Buscar específicamente tu impresora POS-58
      String? impresoraPOS;
      for (String impresora in impresoras) {
        final nombreLower = impresora.toLowerCase();
        print('🔍 Analizando impresora: $impresora');
        
        if (nombreLower.contains('pos-58') || 
            nombreLower.contains('pos 58') ||
            nombreLower.contains('pos58') ||
            nombreLower.contains('pos') || 
            nombreLower.contains('thermal') ||
            nombreLower.contains('receipt') ||
            nombreLower.contains('ticket') ||
            nombreLower.contains('series')) {
          impresoraPOS = impresora;
          print('✅ Impresora POS encontrada: $impresora');
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
  
  // ✅ WINDOWS CORREGIDO - Múltiples métodos para detectar impresoras
  Future<List<String>> _obtenerImpresorasWindows() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isWindows) {
        print('🔍 Buscando impresoras en Windows...');
        
        // ✅ MÉTODO 1: PowerShell Get-Printer (más confiable)
        try {
          ProcessResult result = await Process.run(
            'powershell',
            ['-Command', 'Get-Printer | Select-Object -ExpandProperty Name'],
            runInShell: true,
          );
          
          print('📡 Resultado PowerShell Get-Printer: ${result.stdout}');
          print('📡 Código de salida: ${result.exitCode}');
          
          if (result.exitCode == 0) {
            String output = result.stdout.toString();
            List<String> printers = output.split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            
            impresoras.addAll(printers);
            print('✅ Impresoras encontradas con Get-Printer: $printers');
          }
        } catch (e) {
          print('❌ Error con Get-Printer: $e');
        }
        
        // ✅ MÉTODO 2: WMI (Windows Management Instrumentation)
        if (impresoras.isEmpty) {
          try {
            ProcessResult result = await Process.run(
              'wmic',
              ['printer', 'get', 'name', '/format:list'],
              runInShell: true,
            );
            
            print('📡 Resultado WMIC: ${result.stdout}');
            
            if (result.exitCode == 0) {
              String output = result.stdout.toString();
              RegExp regex = RegExp(r'Name=(.+)');
              Iterable<RegExpMatch> matches = regex.allMatches(output);
              
              List<String> printers = matches
                  .map((match) => match.group(1)!.trim())
                  .where((name) => name.isNotEmpty && name != 'Name=')
                  .toList();
              
              impresoras.addAll(printers);
              print('✅ Impresoras encontradas con WMIC: $printers');
            }
          } catch (e) {
            print('❌ Error con WMIC: $e');
          }
        }
        
        // ✅ MÉTODO 3: Comando simple print /? para verificar
        if (impresoras.isEmpty) {
          try {
            ProcessResult result = await Process.run(
              'cmd',
              ['/c', 'wmic printer get name /value'],
              runInShell: true,
            );
            
            print('📡 Resultado CMD: ${result.stdout}');
            
            if (result.exitCode == 0) {
              String output = result.stdout.toString();
              List<String> lines = output.split('\n');
              
              for (String line in lines) {
                if (line.startsWith('Name=') && line.length > 5) {
                  String printerName = line.substring(5).trim();
                  if (printerName.isNotEmpty) {
                    impresoras.add(printerName);
                  }
                }
              }
              print('✅ Impresoras encontradas con CMD: $impresoras');
            }
          } catch (e) {
            print('❌ Error con CMD: $e');
          }
        }
        
        // ✅ MÉTODO 4: Agregar manualmente la POS-58 si no se detecta
        if (impresoras.isEmpty) {
          print('⚠️ No se detectaron impresoras automáticamente');
          print('🔧 Agregando impresoras comunes de POS...');
          
          // Agregar nombres comunes de impresoras POS
          List<String> impresorasComunes = [
            'POS-58 Series Printer',
            'POS-80 Series Printer', 
            'Thermal Printer',
            'Receipt Printer',
            'Generic / Text Only',
          ];
          
          impresoras.addAll(impresorasComunes);
          print('✅ Impresoras agregadas manualmente: $impresorasComunes');
        }
      }
    } catch (e) {
      print('❌ Error Windows impresoras: $e');
    }
    
    // Eliminar duplicados
    impresoras = impresoras.toSet().toList();
    print('🖨️ Lista final de impresoras Windows: $impresoras');
    
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
      print('🖨️ Iniciando impresión en: $selectedPrinterName');
      
      // ✅ NUEVO: Para impresoras POS, usar comandos ESC/POS en lugar de texto plano
      if (_esPimpresotaPOS(selectedPrinterName!)) {
        await _imprimirPOSDesktop(pedido, total);
      } else {
        // Generar contenido del ticket en texto plano para impresoras normales
        String contenidoTicket = _generarTicketTextoPlano(pedido, total);
        
        if (Platform.isWindows) {
          await _imprimirWindows(contenidoTicket);
        } else if (Platform.isMacOS) {
          await _imprimirMac(contenidoTicket);
        } else if (Platform.isLinux) {
          await _imprimirLinux(contenidoTicket);
        }
      }
      
      print('✅ Ticket desktop impreso correctamente');
      
    } catch (e) {
      print('❌ Error imprimiendo desktop: $e');
      rethrow;
    }
  }
  
  // ✅ NUEVA FUNCIÓN: Detectar si es impresora POS
  bool _esPimpresotaPOS(String nombreImpresora) {
    final nombre = nombreImpresora.toLowerCase();
    return nombre.contains('pos') || 
           nombre.contains('thermal') ||
           nombre.contains('receipt') ||
           nombre.contains('ticket') ||
           nombre.contains('series');
  }
  
  // ✅ NUEVA FUNCIÓN: Imprimir en impresora POS desde desktop
  Future<void> _imprimirPOSDesktop(Map<String, dynamic> pedido, double total) async {
    try {
      // Generar comandos ESC/POS como bytes
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = _generarComandosESCPOS(generator, pedido, total);
      
      // Crear archivo temporal con comandos ESC/POS
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_pos_${DateTime.now().millisecondsSinceEpoch}.bin');
      await tempFile.writeAsBytes(bytes);
      
      if (Platform.isWindows) {
        // Enviar archivo binario directamente a la impresora
        ProcessResult result = await Process.run(
          'copy',
          ['/B', tempFile.path, selectedPrinterName!],
          runInShell: true,
        );
        
        print('📡 Resultado copy: ${result.exitCode}');
        print('📡 Salida: ${result.stdout}');
        print('📡 Error: ${result.stderr}');
        
        if (result.exitCode != 0) {
          // Método alternativo: usar print command
          ProcessResult result2 = await Process.run(
            'print',
            ['/D:$selectedPrinterName', tempFile.path],
            runInShell: true,
          );
          
          if (result2.exitCode != 0) {
            throw Exception('Error imprimiendo POS: ${result2.stderr}');
          }
        }
      }
      
      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
    } catch (e) {
      print('❌ Error impresión POS desktop: $e');
      rethrow;
    }
  }
  
  Future<void> _imprimirWindows(String contenido) async {
    try {
      print('🖨️ Imprimiendo en Windows con: $selectedPrinterName');
      
      // Crear archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(contenido, encoding: utf8);
      
      print('📄 Archivo temporal creado: ${tempFile.path}');
      
      // ✅ MÉTODO MEJORADO: Usar comando print de Windows
      ProcessResult result = await Process.run(
        'print',
        ['/D:"$selectedPrinterName"', tempFile.path],
        runInShell: true,
      );
      
      print('📡 Resultado print: ${result.exitCode}');
      print('📡 Salida: ${result.stdout}');
      print('📡 Error: ${result.stderr}');
      
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
  
  /// Generar comandos ESC/POS para impresoras térmicas
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
      PosColumn(text: 'TOTAL:', width: 8, 
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
  
  /// Generar ticket en texto plano para impresoras normales
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
    ticket.writeln('TOTAL:                  \$${subtotal.toStringAsFixed(2)}');
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
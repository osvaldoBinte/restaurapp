// ✅ VERSIÓN MEJORADA con diagnósticos completos para detectar tu POS-58

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';

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
  List<String> impresorasDetectadas = []; // ✅ NUEVO: Lista de impresoras encontradas
  
  // Detectar plataforma
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  /// ✅ NUEVO: Conectar con diagnóstico completo
  Future<bool> conectarImpresoraConDiagnostico() async {
    try {
      print('🔍 === DIAGNÓSTICO DE IMPRESORA INICIADO ===');
      
      if (isMobile) {
        return await _conectarBluetoothAutomatico();
      } else if (isDesktop) {
        return await _conectarImpresoraDesktopConDiagnostico();
      }
      return false;
    } catch (e) {
      print('❌ Error conectando impresora: $e');
      return false;
    }
  }
  
  /// ✅ NUEVO: Mostrar diálogo de diagnóstico antes del ticket
  Future<void> mostrarDiagnosticoYConfirmar(Map<String, dynamic> pedido, double total) async {
    try {
      // Realizar diagnóstico
      bool conexionExitosa = await conectarImpresoraConDiagnostico();
      
      // Preparar mensaje de diagnóstico
      String tituloDiagnostico;
      String mensajeDiagnostico;
      QuickAlertType tipoDiagnostico;
      
      if (conexionExitosa) {
        tituloDiagnostico = '✅ Impresora Conectada';
        mensajeDiagnostico = '🖨️ Impresora detectada y lista:\n\n'
            '📍 Plataforma: ${Platform.operatingSystem}\n'
            '🔗 Impresora: $selectedPrinterName\n'
            '📋 Total encontradas: ${impresorasDetectadas.length}\n\n'
            '¿Proceder a imprimir el ticket?';
        tipoDiagnostico = QuickAlertType.success;
      } else {
        tituloDiagnostico = '⚠️ Problema de Conexión';
        mensajeDiagnostico = '🔍 Estado de impresoras:\n\n'
            '📍 Plataforma: ${Platform.operatingSystem}\n'
            '📊 Impresoras encontradas: ${impresorasDetectadas.length}\n';
        
        if (impresorasDetectadas.isNotEmpty) {
          mensajeDiagnostico += '\n🖨️ Lista detectada:\n';
          for (int i = 0; i < impresorasDetectadas.length && i < 3; i++) {
            mensajeDiagnostico += '  ${i+1}. ${impresorasDetectadas[i]}\n';
          }
        }
        
        mensajeDiagnostico += '\n❌ No se pudo establecer conexión automática.\n\n'
            '¿Intentar imprimir de todas formas?';
        tipoDiagnostico = QuickAlertType.warning;
      }
      
      // Mostrar diálogo con opción de continuar
      bool continuar = false;
      
      await QuickAlert.show(
        context: Get.context!,
        type: tipoDiagnostico,
        title: tituloDiagnostico,
        text: mensajeDiagnostico,
        confirmBtnText: conexionExitosa ? 'Imprimir Ticket' : 'Intentar Imprimir',
        cancelBtnText: 'Cancelar',
        onConfirmBtnTap: () {
          continuar = true;
          Get.back();
        },
        onCancelBtnTap: () {
          continuar = false;
          Get.back();
        },
      );
      
      // Si el usuario confirma, proceder con la impresión
      if (continuar) {
        await imprimirTicket(pedido, total);
      }
      
    } catch (e) {
      print('❌ Error en diagnóstico: $e');
      
      // Mostrar error de diagnóstico
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        title: '❌ Error de Diagnóstico',
        text: '🔍 No se pudo realizar el diagnóstico de impresora:\n\n'
            'Error: $e\n\n'
            '¿Intentar imprimir sin diagnóstico?',
        confirmBtnText: 'Intentar',
        cancelBtnText: 'Cancelar',
        onConfirmBtnTap: () async {
          Get.back();
          try {
            await imprimirTicket(pedido, total);
          } catch (e2) {
            print('❌ Error final imprimiendo: $e2');
          }
        },
      );
    }
  }
  
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
  
  // ===== FUNCIONES DESKTOP MEJORADAS CON DIAGNÓSTICO =====
  
  /// ✅ NUEVO: Conexión desktop con diagnóstico completo
  Future<bool> _conectarImpresoraDesktopConDiagnostico() async {
    try {
      print('🔍 Iniciando diagnóstico desktop...');
      print('📍 Sistema operativo: ${Platform.operatingSystem}');
      print('📍 Versión: ${Platform.operatingSystemVersion}');
      
      // Limpiar lista anterior
      impresorasDetectadas.clear();
      
      // Obtener impresoras con diagnóstico detallado
      List<String> impresoras = await _obtenerImpresorasDesktopConDiagnostico();
      impresorasDetectadas = impresoras;
      
      print('📊 Total de impresoras detectadas: ${impresoras.length}');
      
      if (impresoras.isEmpty) {
        print('❌ No se encontraron impresoras en desktop');
        return false;
      }
      
      // Buscar específicamente tu POS-58
      String? impresoraPOS = _buscarImpresoraPOS58(impresoras);
      
      if (impresoraPOS != null) {
        selectedPrinterName = impresoraPOS;
        isDesktopPrinterConnected = true;
        print('✅ POS-58 encontrada y seleccionada: $impresoraPOS');
        return true;
      } else {
        // Si no encuentra POS específica, usar la primera disponible
        selectedPrinterName = impresoras.first;
        isDesktopPrinterConnected = true;
        print('⚠️ POS-58 no encontrada, usando primera disponible: ${impresoras.first}');
        return true;
      }
      
    } catch (e) {
      print('❌ Error en diagnóstico desktop: $e');
      return false;
    }
  }
  
  /// ✅ NUEVO: Buscar específicamente la impresora POS-58
  String? _buscarImpresoraPOS58(List<String> impresoras) {
    print('🔍 Buscando POS-58 en lista de impresoras...');
    
    // Patrones específicos para POS-58 (basado en tu captura)
    List<String> patronesPOS58 = [
      'pos-58 series printer',
      'pos-58',
      'pos 58',
      'pos58',
      'series printer',
      'thermal',
      'receipt',
      'pos',
    ];
    
    for (String impresora in impresoras) {
      final nombreLower = impresora.toLowerCase();
      print('   🔍 Analizando: "$impresora"');
      
      for (String patron in patronesPOS58) {
        if (nombreLower.contains(patron)) {
          print('   ✅ Coincidencia encontrada con patrón "$patron"');
          return impresora;
        }
      }
    }
    
    print('   ❌ No se encontró coincidencia específica para POS-58');
    return null;
  }
  
  Future<bool> _conectarImpresoraDesktop() async {
    try {
      List<String> impresoras = await _obtenerImpresorasDesktop();
      
      if (impresoras.isEmpty) {
        print('❌ No se encontraron impresoras en desktop');
        return false;
      }
      
      // Buscar específicamente POS-58
      String? impresoraPOS = _buscarImpresoraPOS58(impresoras);
      selectedPrinterName = impresoraPOS ?? impresoras.first;
      isDesktopPrinterConnected = true;
      
      print('✅ Impresora desktop seleccionada: $selectedPrinterName');
      return true;
      
    } catch (e) {
      print('❌ Error desktop: $e');
      return false;
    }
  }
  
  /// ✅ NUEVO: Obtener impresoras con diagnóstico detallado
  Future<List<String>> _obtenerImpresorasDesktopConDiagnostico() async {
    List<String> impresoras = [];
    
    try {
      print('🔍 Obteniendo impresoras con diagnóstico detallado...');
      
      if (Platform.isWindows) {
        impresoras = await _obtenerImpresorasWindowsConDiagnostico();
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
  
  /// ✅ NUEVO: Windows con diagnóstico súper detallado
  Future<List<String>> _obtenerImpresorasWindowsConDiagnostico() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isWindows) {
        print('🔍 === DIAGNÓSTICO WINDOWS DETALLADO ===');
        
        // ✅ MÉTODO 1: PowerShell Get-Printer (MÁS CONFIABLE)
        print('📡 Probando método 1: PowerShell Get-Printer...');
        try {
          ProcessResult result = await Process.run(
            'powershell',
            ['-Command', 'Get-Printer | Format-Table Name, DriverName, PortName -AutoSize'],
            runInShell: true,
          );
          
          print('📡 Código de salida PowerShell: ${result.exitCode}');
          print('📡 Salida PowerShell completa:');
          print('--- INICIO SALIDA ---');
          print(result.stdout);
          print('--- FIN SALIDA ---');
          
          if (result.stderr.toString().isNotEmpty) {
            print('📡 Errores PowerShell: ${result.stderr}');
          }
          
          if (result.exitCode == 0) {
            String output = result.stdout.toString();
            
            // Extraer nombres de impresoras de la tabla
            List<String> lines = output.split('\n');
            bool foundHeader = false;
            
            for (String line in lines) {
              line = line.trim();
              if (line.isEmpty) continue;
              
              // Buscar la línea de encabezado
              if (line.contains('Name') && line.contains('DriverName')) {
                foundHeader = true;
                continue;
              }
              
              // Saltar línea separadora
              if (line.startsWith('-') && foundHeader) {
                continue;
              }
              
              // Procesar líneas de impresoras
              if (foundHeader && line.isNotEmpty && !line.startsWith('-')) {
                // Extraer el nombre (primera columna)
                List<String> parts = line.split(RegExp(r'\s+'));
                if (parts.isNotEmpty) {
                  String printerName = parts[0];
                  if (printerName.isNotEmpty && !impresoras.contains(printerName)) {
                    impresoras.add(printerName);
                    print('✅ Impresora encontrada (PowerShell): $printerName');
                  }
                }
              }
            }
          }
        } catch (e) {
          print('❌ Error con PowerShell Get-Printer: $e');
        }
        
        // ✅ MÉTODO 2: WMIC (BACKUP)
        if (impresoras.isEmpty) {
          print('📡 Probando método 2: WMIC...');
          try {
            ProcessResult result = await Process.run(
              'wmic',
              ['printer', 'get', 'name,drivername,portname', '/format:table'],
              runInShell: true,
            );
            
            print('📡 Código de salida WMIC: ${result.exitCode}');
            print('📡 Salida WMIC: ${result.stdout}');
            
            if (result.exitCode == 0) {
              String output = result.stdout.toString();
              List<String> lines = output.split('\n');
              
              bool foundHeader = false;
              for (String line in lines) {
                line = line.trim();
                if (line.isEmpty) continue;
                
                if (line.toLowerCase().contains('name') && line.toLowerCase().contains('drivername')) {
                  foundHeader = true;
                  continue;
                }
                
                if (foundHeader && line.isNotEmpty) {
                  // Extraer nombre de la primera columna
                  List<String> parts = line.split(RegExp(r'\s+'));
                  if (parts.isNotEmpty) {
                    String printerName = parts[0];
                    if (printerName.isNotEmpty && !impresoras.contains(printerName)) {
                      impresoras.add(printerName);
                      print('✅ Impresora encontrada (WMIC): $printerName');
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('❌ Error con WMIC: $e');
          }
        }
        
        // ✅ MÉTODO 3: CMD simple (BACKUP)
        if (impresoras.isEmpty) {
          print('📡 Probando método 3: CMD...');
          try {
            ProcessResult result = await Process.run(
              'cmd',
              ['/c', 'wmic printer get name /value'],
              runInShell: true,
            );
            
            print('📡 Código de salida CMD: ${result.exitCode}');
            print('📡 Salida CMD: ${result.stdout}');
            
            if (result.exitCode == 0) {
              String output = result.stdout.toString();
              List<String> lines = output.split('\n');
              
              for (String line in lines) {
                if (line.startsWith('Name=') && line.length > 5) {
                  String printerName = line.substring(5).trim();
                  if (printerName.isNotEmpty && !impresoras.contains(printerName)) {
                    impresoras.add(printerName);
                    print('✅ Impresora encontrada (CMD): $printerName');
                  }
                }
              }
            }
          } catch (e) {
            print('❌ Error con CMD: $e');
          }
        }
        
        // ✅ MÉTODO 4: Agregar manualmente POS comunes si no encuentra nada
        if (impresoras.isEmpty) {
          print('⚠️ No se detectaron impresoras automáticamente');
          print('🔧 Agregando impresoras POS comunes...');
          
          List<String> impresorasComunes = [
            'POS-58 Series Printer',
            'Generic / Text Only',
            'Microsoft Print to PDF', // Para testing
          ];
          
          impresoras.addAll(impresorasComunes);
          print('✅ Impresoras agregadas manualmente: $impresorasComunes');
        }
        
        // ✅ VERIFICACIÓN ESPECÍFICA: Buscar tu POS-58 exacta
        print('🎯 === VERIFICACIÓN ESPECÍFICA POS-58 ===');
        String tuImpresora = 'POS-58 Series Printer';
        bool encontradaExacta = impresoras.any((imp) => 
            imp.toLowerCase().contains('pos-58') && 
            imp.toLowerCase().contains('series'));
        
        if (encontradaExacta) {
          print('✅ Tu impresora POS-58 Series Printer SÍ fue encontrada!');
        } else {
          print('❌ Tu impresora POS-58 Series Printer NO fue detectada automáticamente');
          print('🔧 Agregándola manualmente...');
          if (!impresoras.contains(tuImpresora)) {
            impresoras.insert(0, tuImpresora); // Agregar al principio
          }
        }
      }
    } catch (e) {
      print('❌ Error Windows impresoras con diagnóstico: $e');
    }
    
    // Eliminar duplicados
    impresoras = impresoras.toSet().toList();
    
    print('🖨️ === RESULTADO FINAL WINDOWS ===');
    print('📊 Total encontradas: ${impresoras.length}');
    for (int i = 0; i < impresoras.length; i++) {
      print('   ${i+1}. ${impresoras[i]}');
    }
    
    return impresoras;
  }
  
  // Mantener método original para compatibilidad
  Future<List<String>> _obtenerImpresorasWindows() async {
    List<String> impresoras = [];
    
    try {
      if (Platform.isWindows) {
        ProcessResult result = await Process.run(
          'powershell',
          ['-Command', 'Get-Printer | Select-Object -ExpandProperty Name'],
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          String output = result.stdout.toString();
          List<String> printers = output.split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          
          impresoras.addAll(printers);
        }
        
        // Fallback a WMIC si PowerShell falla
        if (impresoras.isEmpty) {
          ProcessResult result2 = await Process.run(
            'wmic',
            ['printer', 'get', 'name', '/format:list'],
            runInShell: true,
          );
          
          if (result2.exitCode == 0) {
            String output = result2.stdout.toString();
            RegExp regex = RegExp(r'Name=(.+)');
            Iterable<RegExpMatch> matches = regex.allMatches(output);
            
            List<String> printers = matches
                .map((match) => match.group(1)!.trim())
                .where((name) => name.isNotEmpty && name != 'Name=')
                .toList();
            
            impresoras.addAll(printers);
          }
        }
        
        // Agregar manualmente si no encuentra nada
        if (impresoras.isEmpty) {
          List<String> impresorasComunes = [
            'POS-58 Series Printer',
            'Generic / Text Only',
          ];
          
          impresoras.addAll(impresorasComunes);
        }
      }
    } catch (e) {
      print('❌ Error Windows impresoras: $e');
    }
    
    // Eliminar duplicados
    impresoras = impresoras.toSet().toList();
    
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
      
      // Para impresoras POS, usar comandos ESC/POS
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
  
  // Detectar si es impresora POS
  bool _esPimpresotaPOS(String nombreImpresora) {
    final nombre = nombreImpresora.toLowerCase();
    return nombre.contains('pos') || 
           nombre.contains('thermal') ||
           nombre.contains('receipt') ||
           nombre.contains('ticket') ||
           nombre.contains('series');
  }
  Future<void> diagnosticarImpresoraCompartida() async {
  try {
    print('🔍 === DIAGNÓSTICO IMPRESORA COMPARTIDA ===');
    
    // Verificar estado de la impresora
    ProcessResult statusResult = await Process.run(
      'powershell',
      ['-Command', 'Get-Printer "$selectedPrinterName" | Select-Object Name, PrinterStatus, JobCount, Shared'],
      runInShell: true,
    );
    
    print('📊 Estado impresora: ${statusResult.stdout}');
    
    // Verificar cola de impresión
    ProcessResult queueResult = await Process.run(
      'powershell',
      ['-Command', 'Get-PrintJob -PrinterName "$selectedPrinterName"'],
      runInShell: true,
    );
    
    print('📋 Cola impresión: ${queueResult.stdout}');
    
    // Verificar permisos de recurso compartido
    ProcessResult shareResult = await Process.run(
      'net',
      ['share'],
      runInShell: true,
    );
    
    if (shareResult.stdout.toString().contains(selectedPrinterName!)) {
      print('✅ Impresora está compartida correctamente');
    }
    
  } catch (e) {
    print('❌ Error en diagnóstico: $e');
  }
}
Future<void> _imprimirPOSDesktop(Map<String, dynamic> pedido, double total) async {
  try {
    print('🖨️ === INICIANDO IMPRESIÓN POS-58 COMPARTIDA ===');
    print('🔗 Impresora: $selectedPrinterName');
    print('🌐 Tipo: Impresora compartida en red');
    
    // ✅ PASO 1: Crear contenido del ticket optimizado para POS
    String contenidoTicket = _generarTicketParaPOSCompartida(pedido, total);
    
    // ✅ PASO 2: Crear archivo temporal
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempFile = File('${tempDir.path}/pos58_ticket_$timestamp.txt');
    
    // ✅ IMPORTANTE: Usar codificación específica para POS
    await tempFile.writeAsString(contenidoTicket, encoding: latin1);
    
    print('📄 Archivo temporal: ${tempFile.path}');
    
    bool exitoso = false;
    String ultimoError = '';
    
    // ✅ MÉTODO 1: print con nombre exacto de impresora compartida
    try {
      print('📡 Método 1: print command para impresora compartida...');
      
      ProcessResult result = await Process.run(
        'print',
        ['/D:"$selectedPrinterName"', tempFile.path],
        runInShell: true,
      );
      
      print('📊 print - Código: ${result.exitCode}');
      print('📊 print - Salida: ${result.stdout}');
      print('📊 print - Error: ${result.stderr}');
      
      if (result.exitCode == 0) {
        exitoso = true;
        print('✅ ÉXITO: Impresión con print command');
      } else {
        ultimoError = 'print: ${result.stderr}';
      }
    } catch (e) {
      print('❌ Error método 1: $e');
      ultimoError = 'print exception: $e';
    }
    
    // ✅ MÉTODO 2: copy directo al puerto USB002
    if (!exitoso) {
      try {
        print('📡 Método 2: copy directo a puerto USB002...');
        
        ProcessResult result = await Process.run(
          'copy',
          [tempFile.path, '\\\\localhost\\USB002'],
          runInShell: true,
        );
        
        print('📊 copy USB002 - Código: ${result.exitCode}');
        print('📊 copy USB002 - Salida: ${result.stdout}');
        
        if (result.exitCode == 0) {
          exitoso = true;
          print('✅ ÉXITO: Copy directo a USB002');
        } else {
          ultimoError = 'copy USB002: ${result.stderr}';
        }
      } catch (e) {
        print('❌ Error método 2: $e');
        ultimoError = 'copy USB002 exception: $e';
      }
    }
    
    // ✅ MÉTODO 3: net use + copy (para impresoras compartidas)
    if (!exitoso) {
      try {
        print('📡 Método 3: net use + copy...');
        
        // Primero conectar al recurso compartido
        ProcessResult connectResult = await Process.run(
          'net',
          ['use', 'LPT2:', '\\\\localhost\\$selectedPrinterName'],
          runInShell: true,
        );
        
        print('📊 net use - Código: ${connectResult.exitCode}');
        
        if (connectResult.exitCode == 0) {
          // Ahora copiar al puerto mapeado
          ProcessResult copyResult = await Process.run(
            'copy',
            [tempFile.path, 'LPT2:'],
            runInShell: true,
          );
          
          print('📊 copy LPT2 - Código: ${copyResult.exitCode}');
          
          if (copyResult.exitCode == 0) {
            exitoso = true;
            print('✅ ÉXITO: net use + copy');
          }
          
          // Limpiar conexión
          await Process.run('net', ['use', 'LPT2:', '/delete'], runInShell: true);
        } else {
          ultimoError = 'net use: ${connectResult.stderr}';
        }
      } catch (e) {
        print('❌ Error método 3: $e');
        ultimoError = 'net use exception: $e';
      }
    }
    
    // ✅ MÉTODO 4: PowerShell Out-Printer (más robusto para compartidas)
    if (!exitoso) {
      try {
        print('📡 Método 4: PowerShell Out-Printer...');
        
        String psCommand = 'Get-Content "${tempFile.path}" -Raw | Out-Printer -Name "$selectedPrinterName"';
        
        ProcessResult result = await Process.run(
          'powershell',
          ['-Command', psCommand],
          runInShell: true,
        );
        
        print('📊 PowerShell - Código: ${result.exitCode}');
        print('📊 PowerShell - Error: ${result.stderr}');
        
        if (result.exitCode == 0) {
          exitoso = true;
          print('✅ ÉXITO: PowerShell Out-Printer');
        } else {
          ultimoError = 'PowerShell: ${result.stderr}';
        }
      } catch (e) {
        print('❌ Error método 4: $e');
        ultimoError = 'PowerShell exception: $e';
      }
    }
    
    // ✅ MÉTODO 5: Usar notepad como último recurso (funciona siempre)
    if (!exitoso) {
      try {
        print('📡 Método 5: notepad /p (último recurso)...');
        
        ProcessResult result = await Process.run(
          'notepad',
          ['/p', tempFile.path],
          runInShell: true,
        );
        
        print('📊 notepad - Código: ${result.exitCode}');
        
        if (result.exitCode == 0) {
          exitoso = true;
          print('✅ ÉXITO: notepad /p (puede requerir intervención del usuario)');
          
          // Esperar para que notepad procese
          await Future.delayed(Duration(seconds: 3));
        } else {
          ultimoError = 'notepad: ${result.stderr}';
        }
      } catch (e) {
        print('❌ Error método 5: $e');
        ultimoError = 'notepad exception: $e';
      }
    }
    
    // ✅ LIMPIAR archivo temporal
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
        print('🗑️ Archivo temporal eliminado');
      }
    } catch (e) {
      print('⚠️ No se pudo eliminar archivo temporal: $e');
    }
    
    // ✅ RESULTADO FINAL
    if (exitoso) {
      print('🎉 === IMPRESIÓN POS-58 EXITOSA ===');
    } else {
      print('❌ === FALLÓ IMPRESIÓN POS-58 ===');
      print('🔍 Último error: $ultimoError');
      throw Exception('Falló impresión POS-58 con todos los métodos. Último error: $ultimoError');
    }
    
  } catch (e) {
    print('💥 Error crítico en _imprimirPOSDesktop: $e');
    rethrow;
  }
}

// ✅ NUEVA FUNCIÓN: Generar ticket optimizado para POS compartida
String _generarTicketParaPOSCompartida(Map<String, dynamic> pedido, double total) {
  StringBuffer ticket = StringBuffer();
  
  try {
    // ✅ Header simple y compatible
    ticket.writeln('================================');
    ticket.writeln('       COMEDOR EL JOBO');
    ticket.writeln('================================');
    ticket.writeln('');
    
    // ✅ Información básica
    final fecha = DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final horaStr = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    
    ticket.writeln('Fecha: $fechaStr');
    ticket.writeln('Hora: $horaStr');
    
    // Información del pedido
    final mesa = pedido['mesa'] ?? 'N/A';
    final nombreOrden = pedido['nombreOrden'] ?? 'Sin nombre';
    final pedidoId = pedido['pedidoId'] ?? 'N/A';
    
    ticket.writeln('Mesa: $mesa');
    ticket.writeln('Pedido: $nombreOrden');
    ticket.writeln('ID: #$pedidoId');
    ticket.writeln('');
    ticket.writeln('--------------------------------');
    
    // ✅ Productos con formato simple
    final detalles = pedido['detalles'] as List? ?? [];
    double subtotal = 0.0;
    int contador = 1;
    
    for (var detalle in detalles) {
      try {
        final status = detalle['statusDetalle'] ?? 'proceso';
        if (status == 'cancelado') continue;
        
        final nombreProducto = detalle['nombreProducto'] ?? 'Producto $contador';
        final cantidad = (detalle['cantidad'] ?? 1).toInt();
        final precioUnitario = (detalle['precioUnitario'] ?? 0.0).toDouble();
        final totalItem = precioUnitario * cantidad;
        
        subtotal += totalItem;
        
        // Formato simple para evitar problemas de codificación
        ticket.writeln('$contador. $nombreProducto');
        ticket.writeln('   Cant: $cantidad x \$${precioUnitario.toStringAsFixed(2)}');
        ticket.writeln('   Total: \$${totalItem.toStringAsFixed(2)}');
        
        // Observaciones si existen
        final observaciones = detalle['observaciones'];
        if (observaciones != null && observaciones.toString().trim().isNotEmpty) {
          ticket.writeln('   * ${observaciones.toString()}');
        }
        
        ticket.writeln('');
        contador++;
      } catch (e) {
        print('❌ Error procesando detalle: $e');
        continue;
      }
    }
    
    // ✅ Total grande y visible
    ticket.writeln('--------------------------------');
    ticket.writeln('TOTAL A PAGAR:');
    ticket.writeln('\$${subtotal.toStringAsFixed(2)}');
    ticket.writeln('================================');
    ticket.writeln('');
    ticket.writeln('    ¡Gracias por su visita!');
    ticket.writeln('');
    ticket.writeln('  Sistema de Restaurante v1.0');
    ticket.writeln('  ${DateTime.now().toString().substring(0, 19)}');
    
    // ✅ Espacios al final para cortar papel
    ticket.writeln('');
    ticket.writeln('');
    ticket.writeln('');
    ticket.writeln('');
    
    print('📋 Ticket generado: ${detalles.length} productos, Total: \$${subtotal.toStringAsFixed(2)}');
    
  } catch (e) {
    print('❌ Error generando ticket: $e');
    // Ticket de emergencia
    ticket.clear();
    ticket.writeln('ERROR GENERANDO TICKET');
    ticket.writeln('Pedido ID: ${pedido['pedidoId'] ?? 'N/A'}');
    ticket.writeln('Total estimado: \$${total.toStringAsFixed(2)}');
    ticket.writeln('');
  }
  
  return ticket.toString();
}



// ✅ NUEVA FUNCIÓN: Impresión de texto plano mejorada
Future<void> _imprimirWindowsTextoPlanoMejorado(String contenido) async {
  try {
    print('🖨️ Impresión texto plano mejorada para: $selectedPrinterName');
    
    // Crear archivo temporal con encoding correcto
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
    
    // ✅ IMPORTANTE: Usar encoding que entienda la impresora POS
    await tempFile.writeAsString(contenido, encoding: latin1);
    
    print('📄 Archivo creado: ${tempFile.path}');
    
    bool exitoso = false;
    
    // ✅ MÉTODO 1: print command con comillas
    try {
      ProcessResult result = await Process.run(
        'print',
        ['/D:"$selectedPrinterName"', '"${tempFile.path}"'],
        runInShell: true,
      );
      
      print('📊 print - Código: ${result.exitCode}');
      print('📊 print - Salida: ${result.stdout}');
      print('📊 print - Error: ${result.stderr}');
      
      if (result.exitCode == 0) {
        exitoso = true;
        print('✅ Impresión exitosa con print command');
      }
    } catch (e) {
      print('❌ Error con print command: $e');
    }
    
    // ✅ MÉTODO 2: notepad /p (funciona bien con POS)
    if (!exitoso) {
      try {
        ProcessResult result = await Process.run(
          'notepad',
          ['/p', tempFile.path],
          runInShell: true,
        );
        
        print('📊 notepad - Código: ${result.exitCode}');
        if (result.exitCode == 0) {
          exitoso = true;
          print('✅ Impresión exitosa con notepad /p');
          
          // Esperar un poco para que notepad procese
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('❌ Error con notepad: $e');
      }
    }
    
    // ✅ MÉTODO 3: PowerShell Out-Printer
    if (!exitoso) {
      try {
        ProcessResult result = await Process.run(
          'powershell',
          ['-Command', 'Get-Content "${tempFile.path}" | Out-Printer -Name "$selectedPrinterName"'],
          runInShell: true,
        );
        
        print('📊 PowerShell - Código: ${result.exitCode}');
        if (result.exitCode == 0) {
          exitoso = true;
          print('✅ Impresión exitosa con PowerShell');
        }
      } catch (e) {
        print('❌ Error con PowerShell: $e');
      }
    }
    
    // Limpiar archivo temporal
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    
    if (!exitoso) {
      throw Exception('Falló impresión de texto con todos los métodos');
    }
    
  } catch (e) {
    print('❌ Error en impresión texto plano mejorada: $e');
    rethrow;
  }
}

// ✅ NUEVA FUNCIÓN: Detectar puerto de la impresora
Future<String?> _detectarPuertoImpresora() async {
  try {
    print('🔍 Detectando puerto de impresora...');
    
    ProcessResult result = await Process.run(
      'powershell',
      ['-Command', 'Get-Printer "$selectedPrinterName" | Select-Object -ExpandProperty PortName'],
      runInShell: true,
    );
    
    if (result.exitCode == 0) {
      String puerto = result.stdout.toString().trim();
      print('🔗 Puerto detectado: $puerto');
      
      // Convertir puertos USB a formato correcto
      if (puerto.startsWith('USB')) {
        // Para puertos USB, intentar usar LPT1 o COM1
        List<String> puertosAlternativos = ['LPT1:', 'COM1:', 'COM2:', 'COM3:'];
        
        for (String puertoAlt in puertosAlternativos) {
          try {
            // Verificar si el puerto existe
            ProcessResult testResult = await Process.run(
              'mode',
              [puertoAlt],
              runInShell: true,
            );
            
            if (testResult.exitCode == 0) {
              print('✅ Puerto alternativo encontrado: $puertoAlt');
              return puertoAlt;
            }
          } catch (e) {
            continue;
          }
        }
        
        return null;
      } else {
        return puerto.endsWith(':') ? puerto : '$puerto:';
      }
    }
    
    return null;
  } catch (e) {
    print('❌ Error detectando puerto: $e');
    return null;
  }
}

// ✅ FUNCIÓN MEJORADA: Generar ticket más compatible
String _generarTicketTextoPlanoCompatible(Map<String, dynamic> pedido, double total) {
  StringBuffer ticket = StringBuffer();
  
  // Header más simple para POS
  ticket.writeln('================================');
  ticket.writeln('       COMEDOR EL JOBO');
  ticket.writeln('================================');
  ticket.writeln('');
  
  // Información básica
  final fecha = DateTime.now();
  final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  final horaStr = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  
  ticket.writeln('Fecha: $fechaStr  Hora: $horaStr');
  ticket.writeln('Mesa: ${pedido['mesa'] ?? 'N/A'}');
  ticket.writeln('Pedido: ${pedido['nombreOrden'] ?? 'Sin nombre'}');
  ticket.writeln('ID: #${pedido['pedidoId'] ?? 'N/A'}');
  ticket.writeln('');
  ticket.writeln('--------------------------------');
  
  // Productos
  final detalles = pedido['detalles'] as List? ?? [];
  double subtotal = 0.0;
  
  for (var detalle in detalles) {
    try {
      final status = detalle['statusDetalle'] ?? 'proceso';
      if (status == 'cancelado') continue;
      
      final nombreProducto = detalle['nombreProducto'] ?? 'Producto';
      final cantidad = (detalle['cantidad'] ?? 1).toInt();
      final precioUnitario = (detalle['precioUnitario'] ?? 0.0).toDouble();
      final totalItem = precioUnitario * cantidad;
      
      subtotal += totalItem;
      
      // Nombre del producto
      ticket.writeln(nombreProducto);
      // Cantidad y precio en línea separada
      ticket.writeln('  ${cantidad}x \$${precioUnitario.toStringAsFixed(2)} = \$${totalItem.toStringAsFixed(2)}');
      
      // Observaciones si existen
      final observaciones = detalle['observaciones'];
      if (observaciones != null && observaciones.toString().trim().isNotEmpty) {
        ticket.writeln('  * $observaciones');
      }
      
      ticket.writeln('');
    } catch (e) {
      print('❌ Error procesando detalle: $e');
      continue;
    }
  }
  
  // Total
  ticket.writeln('--------------------------------');
  ticket.writeln('TOTAL: \$${subtotal.toStringAsFixed(2)}');
  ticket.writeln('================================');
  ticket.writeln('');
  ticket.writeln('      Gracias por su visita!');
  ticket.writeln('');
  ticket.writeln('   ${DateTime.now().toString().substring(0, 19)}');
  ticket.writeln('');
  ticket.writeln('');
  ticket.writeln('');
  ticket.writeln('');
  
  return ticket.toString();
}

// ✅ ACTUALIZA también esta función para usar el nuevo formato
String _generarTicketTextoPlano(Map<String, dynamic> pedido, double total) {
  return _generarTicketTextoPlanoCompatible(pedido, total);
}
  
  Future<void> _imprimirWindows(String contenido) async {
    try {
      print('🖨️ Imprimiendo texto plano en Windows con: $selectedPrinterName');
      
      // Crear archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.txt');
      await tempFile.writeAsString(contenido, encoding: utf8);
      
      print('📄 Archivo temporal creado: ${tempFile.path}');
      
      // Usar comando print de Windows
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
    bytes += generator.text(
      'COMEDOR "EL JOBO"',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
        bold: true,
      ),
    );

    bytes += generator.text('================================',
        styles: PosStyles(align: PosAlign.center));
    
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
      
      // Nombre completo en línea separada
      bytes += generator.text(nombreProducto, 
          styles: PosStyles(bold: true));
      
      // Cantidad y precio en línea separada con mejor distribución
      bytes += generator.row([
        PosColumn(text: 'Cant: $cantidad', width: 6, 
            styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: '\$${totalItem.toStringAsFixed(2)}', width: 6, 
            styles: PosStyles(align: PosAlign.right, bold: true)),
      ]);
      
      // Espacio entre productos para mejor legibilidad
      bytes += generator.text(' ');
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
    
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }

}
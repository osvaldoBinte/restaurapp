import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionController extends GetxController {
  // Observable para el tamaño de fuente personalizado
  final RxDouble tamanoFuentePersonalizado = 0.0.obs;
  
  // Observable para saber si está usando tamaño personalizado
  final RxBool usarTamanoPersonalizado = false.obs;
  
  // Observable para tamaño de texto secundario (Cant, observaciones, etc.)
  final RxDouble tamanoFuenteSecundario = 0.0.obs;
  
  // Observable para saber si está usando tamaño personalizado para texto secundario
  final RxBool usarTamanoSecundarioPersonalizado = false.obs;
  
  // Observable para el ancho personalizado de las cards
  final RxDouble anchoCardPersonalizado = 0.0.obs;
  
  // Observable para saber si está usando ancho personalizado
  final RxBool usarAnchoPersonalizado = false.obs;
  
  // Observable para el color personalizado
  final Rx<Color> colorTextoPersonalizado = Colors.white.obs;
  
  // Observable para saber si está usando color personalizado
  final RxBool usarColorPersonalizado = false.obs;
  
  // Colores predefinidos
  final List<Color> coloresPredefinidos = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.teal,
  ];
  
  // Clave para SharedPreferences
  static const String _keyTamanoFuente = 'tamano_fuente_personalizado';
  static const String _keyUsarPersonalizado = 'usar_tamano_personalizado';
  static const String _keyTamanoSecundario = 'tamano_fuente_secundario';
  static const String _keyUsarSecundarioPersonalizado = 'usar_tamano_secundario_personalizado';
  static const String _keyAnchoCard = 'ancho_card_personalizado';
  static const String _keyUsarAnchoPersonalizado = 'usar_ancho_personalizado';
  static const String _keyColorTexto = 'color_texto_personalizado';
  static const String _keyUsarColorPersonalizado = 'usar_color_personalizado';
  
  @override
  void onInit() {
    super.onInit();
    _cargarConfiguracion();
  }
  
  // Cargar configuración guardada
  Future<void> _cargarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      tamanoFuentePersonalizado.value = prefs.getDouble(_keyTamanoFuente) ?? 14.0;
      usarTamanoPersonalizado.value = prefs.getBool(_keyUsarPersonalizado) ?? false;
      
      // Cargar configuración texto secundario
      tamanoFuenteSecundario.value = prefs.getDouble(_keyTamanoSecundario) ?? 12.0;
      usarTamanoSecundarioPersonalizado.value = prefs.getBool(_keyUsarSecundarioPersonalizado) ?? false;
      
      // Cargar configuración ancho de card
      anchoCardPersonalizado.value = prefs.getDouble(_keyAnchoCard) ?? 190.0;
      usarAnchoPersonalizado.value = prefs.getBool(_keyUsarAnchoPersonalizado) ?? false;
      
      // Cargar color personalizado
      final colorValue = prefs.getInt(_keyColorTexto) ?? Colors.white.value;
      colorTextoPersonalizado.value = Color(colorValue);
      usarColorPersonalizado.value = prefs.getBool(_keyUsarColorPersonalizado) ?? false;
    } catch (e) {
      print('Error cargando configuración: $e');
    }
  }
  
  // Guardar configuración
  Future<void> _guardarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTamanoFuente, tamanoFuentePersonalizado.value);
      await prefs.setBool(_keyUsarPersonalizado, usarTamanoPersonalizado.value);
      await prefs.setDouble(_keyTamanoSecundario, tamanoFuenteSecundario.value);
      await prefs.setBool(_keyUsarSecundarioPersonalizado, usarTamanoSecundarioPersonalizado.value);
      await prefs.setDouble(_keyAnchoCard, anchoCardPersonalizado.value);
      await prefs.setBool(_keyUsarAnchoPersonalizado, usarAnchoPersonalizado.value);
      await prefs.setInt(_keyColorTexto, colorTextoPersonalizado.value.value);
      await prefs.setBool(_keyUsarColorPersonalizado, usarColorPersonalizado.value);
    } catch (e) {
      print('Error guardando configuración: $e');
    }
  }
  
  // Obtener el tamaño de fuente basado en la configuración
  double obtenerTamanoFuente(bool isSmallWidth, bool isSmallScreen) {
    if (usarTamanoPersonalizado.value) {
      return tamanoFuentePersonalizado.value;
    }
    
    // Tamaño automático basado en el tamaño de pantalla
    return isSmallWidth ? 12 : (isSmallScreen ? 13 : 14);
  }
  
  // Obtener el tamaño de fuente para texto secundario (Cant, observaciones, etc.)
  double obtenerTamanoFuenteSecundario(bool isSmallWidth, bool isSmallScreen) {
    if (usarTamanoSecundarioPersonalizado.value) {
      return tamanoFuenteSecundario.value;
    }
    
    // Tamaño automático basado en el tamaño de pantalla para texto secundario
    return isSmallWidth ? 10 : (isSmallScreen ? 11 : 12);
  }
  
  // Obtener el ancho de la card basado en la configuración
  double obtenerAnchoCard(bool isSmallWidth, bool isSmallScreen) {
    if (usarAnchoPersonalizado.value) {
      return anchoCardPersonalizado.value;
    }
    
    // Ancho automático basado en el tamaño de pantalla
    if (isSmallWidth) {
      return 150;
    } else if (isSmallScreen) {
      return 170;
    } else {
      return 190;
    }
  }
  
  // Obtener el ancho mínimo permitido basado en pantalla
  double obtenerAnchoMinimo(bool isSmallWidth, bool isSmallScreen) {
    if (isSmallWidth) {
      return 150;
    } else if (isSmallScreen) {
      return 170;
    } else {
      return 190;
    }
  }
  
  // Obtener la altura mínima del carousel basada en la configuración
  double obtenerAlturaMinCarousel(bool isVerySmallScreen, bool isSmallScreen) {
    // Factor de escalado basado en el ancho de las cards
    double factorEscala = 1.0;
    
    if (usarAnchoPersonalizado.value) {
      // Calcular factor de escala basado en el ancho personalizado
      double anchoBase = isVerySmallScreen ? 150 : (isSmallScreen ? 170 : 190);
      factorEscala = anchoCardPersonalizado.value / anchoBase;
      
      // Limitar el factor de escala para evitar valores extremos
      factorEscala = factorEscala.clamp(1.0, 2.0);
    }
    
    // Altura base según el tamaño de pantalla
    double alturaBase;
    if (isVerySmallScreen) {
      alturaBase = 140;
    } else if (isSmallScreen) {
      alturaBase = 160;
    } else {
      alturaBase = 180;
    }
    
    return alturaBase * factorEscala;
  }
  
  // Obtener la altura máxima del carousel basada en la configuración
  double obtenerAlturaMaxCarousel(bool isVerySmallScreen, bool isSmallScreen) {
    // Factor de escalado basado en el ancho de las cards
    double factorEscala = 1.0;
    
    if (usarAnchoPersonalizado.value) {
      // Calcular factor de escala basado en el ancho personalizado
      double anchoBase = isVerySmallScreen ? 150 : (isSmallScreen ? 170 : 190);
      factorEscala = anchoCardPersonalizado.value / anchoBase;
      
      // Limitar el factor de escala para evitar valores extremos
      factorEscala = factorEscala.clamp(1.0, 2.0);
    }
    
    // Altura base según el tamaño de pantalla
    double alturaBase;
    if (isVerySmallScreen) {
      alturaBase = 180;
    } else if (isSmallScreen) {
      alturaBase = 200;
    } else {
      alturaBase = 240;
    }
    
    return alturaBase * factorEscala;
  }
  
  // Obtener el color del texto basado en la configuración
  Color obtenerColorTexto() {
    if (usarColorPersonalizado.value) {
      return colorTextoPersonalizado.value;
    }
    
    // Color por defecto
    return Colors.white;
  }
  
  // Cambiar color personalizado
  void cambiarColorTexto(Color nuevoColor) {
    colorTextoPersonalizado.value = nuevoColor;
    _guardarConfiguracion();
  }
  
  // Alternar entre color automático y personalizado
  void alternarModoColorPersonalizado() {
    usarColorPersonalizado.value = !usarColorPersonalizado.value;
    _guardarConfiguracion();
  }
  
  // Cambiar tamaño de fuente personalizado
  void cambiarTamanoFuente(double nuevoTamano) {
    tamanoFuentePersonalizado.value = nuevoTamano;
    _guardarConfiguracion();
  }
  
  // Cambiar tamaño de fuente secundario
  void cambiarTamanoFuenteSecundario(double nuevoTamano) {
    tamanoFuenteSecundario.value = nuevoTamano;
    _guardarConfiguracion();
  }
  
  // Alternar entre automático y personalizado
  void alternarModoPersonalizado() {
    usarTamanoPersonalizado.value = !usarTamanoPersonalizado.value;
    _guardarConfiguracion();
  }
  
  // Alternar modo personalizado para texto secundario
  void alternarModoSecundarioPersonalizado() {
    usarTamanoSecundarioPersonalizado.value = !usarTamanoSecundarioPersonalizado.value;
    _guardarConfiguracion();
  }
  
  // Cambiar ancho de card personalizado
  void cambiarAnchoCard(double nuevoAncho) {
    anchoCardPersonalizado.value = nuevoAncho;
    _guardarConfiguracion();
  }
  
  // Alternar modo personalizado para ancho de card
  void alternarModoAnchoPersonalizado() {
    usarAnchoPersonalizado.value = !usarAnchoPersonalizado.value;
    _guardarConfiguracion();
  }
  
  // Resetear a valores por defecto
  void resetearConfiguracion() {
    usarTamanoPersonalizado.value = false;
    tamanoFuentePersonalizado.value = 14.0;
    usarTamanoSecundarioPersonalizado.value = false;
    tamanoFuenteSecundario.value = 12.0;
    usarAnchoPersonalizado.value = false;
    anchoCardPersonalizado.value = 190.0;
    usarColorPersonalizado.value = false;
    colorTextoPersonalizado.value = Colors.white;
    _guardarConfiguracion();
  }
  
  // Mostrar modal de configuración
  void mostrarModalConfiguracion() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: 600), // Limitar altura
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Personalizar Texto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // SECCIÓN TAMAÑO DE FUENTE PRINCIPAL
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Toggle para tamaño personalizado
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tamaño personalizado (Título)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          usarTamanoPersonalizado.value 
                            ? 'Usando tamaño personalizado para títulos'
                            : 'Usando tamaño automático para títulos',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: usarTamanoPersonalizado.value,
                        onChanged: (value) => alternarModoPersonalizado(),
                        activeColor: Color(0xFF8B4513),
                      )),
                      
                      // Slider para tamaño (solo si está en modo personalizado)
                      Obx(() {
                        if (!usarTamanoPersonalizado.value) {
                          return SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tamaño título: ${tamanoFuentePersonalizado.value.toInt()}px',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            Slider(
                              value: tamanoFuentePersonalizado.value,
                              min: 10.0,
                              max: 24.0,
                              divisions: 14,
                              activeColor: Color(0xFF8B4513),
                              onChanged: (value) {
                                cambiarTamanoFuente(value);
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                // SECCIÓN TAMAÑO DE FUENTE SECUNDARIO (Cantidad, observaciones)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Toggle para tamaño secundario personalizado
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tamaño personalizado (Detalles)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          usarTamanoSecundarioPersonalizado.value 
                            ? 'Usando tamaño personalizado para detalles'
                            : 'Usando tamaño automático para detalles',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: usarTamanoSecundarioPersonalizado.value,
                        onChanged: (value) => alternarModoSecundarioPersonalizado(),
                        activeColor: Color(0xFF8B4513),
                      )),
                      
                      // Slider para tamaño secundario (solo si está en modo personalizado)
                      Obx(() {
                        if (!usarTamanoSecundarioPersonalizado.value) {
                          return SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tamaño detalles: ${tamanoFuenteSecundario.value.toInt()}px',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            Slider(
                              value: tamanoFuenteSecundario.value,
                              min: 8.0,
                              max: 20.0,
                              divisions: 12,
                              activeColor: Color(0xFF8B4513),
                              onChanged: (value) {
                                cambiarTamanoFuenteSecundario(value);
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                // SECCIÓN ANCHO DE TARJETAS
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Toggle para ancho personalizado
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Ancho personalizado (Tarjetas)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          usarAnchoPersonalizado.value 
                            ? 'Usando ancho personalizado para tarjetas'
                            : 'Usando ancho automático para tarjetas',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: usarAnchoPersonalizado.value,
                        onChanged: (value) => alternarModoAnchoPersonalizado(),
                        activeColor: Color(0xFF8B4513),
                      )),
                      
                      // Slider para ancho (solo si está en modo personalizado)
                      Obx(() {
                        if (!usarAnchoPersonalizado.value) {
                          return SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ancho tarjetas: ${anchoCardPersonalizado.value.toInt()}px',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            Text(
                              'Mínimo: ${obtenerAnchoMinimo(false, false).toInt()}px',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            Slider(
                              value: anchoCardPersonalizado.value,
                              min: obtenerAnchoMinimo(false, false), // Ancho mínimo basado en pantalla
                              max: 300.0, // Ancho máximo
                              divisions: ((300 - obtenerAnchoMinimo(false, false)) / 10).round(),
                              activeColor: Color(0xFF8B4513),
                              onChanged: (value) {
                                cambiarAnchoCard(value);
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // SECCIÓN COLOR
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Toggle para color personalizado
                      Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Color personalizado',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          usarColorPersonalizado.value 
                            ? 'Usando color personalizado'
                            : 'Usando color automático (blanco)',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: usarColorPersonalizado.value,
                        onChanged: (value) => alternarModoColorPersonalizado(),
                        activeColor: Color(0xFF8B4513),
                      )),
                      
                      // Selector de colores (solo si está en modo personalizado)
                      Obx(() {
                        if (!usarColorPersonalizado.value) {
                          return SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccionar color:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: coloresPredefinidos.map((color) {
                                return Obx(() => GestureDetector(
                                  onTap: () => cambiarColorTexto(color),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorTextoPersonalizado.value == color
                                          ? Color(0xFF8B4513)
                                          : Colors.grey[400]!,
                                        width: colorTextoPersonalizado.value == color ? 3 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: colorTextoPersonalizado.value == color
                                      ? Icon(
                                          Icons.check,
                                          color: color == Colors.white || color == Colors.yellow
                                            ? Colors.black
                                            : Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                  ),
                                ));
                              }).toList(),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // VISTA PREVIA
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vista Previa',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Título del producto
                      Obx(() => Text(
                        'Tacos al Pastor',
                        style: TextStyle(
                          color: obtenerColorTexto(),
                          fontSize: obtenerTamanoFuente(false, false),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      )),
                      
                      SizedBox(height: 4),
                      
                      // Cantidad con tamaño secundario
                      Obx(() => Text(
                        'Cant: 3',
                        style: TextStyle(
                          color: obtenerColorTexto().withOpacity(0.9),
                          fontSize: obtenerTamanoFuenteSecundario(false, false),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      )),
                      
                      SizedBox(height: 8),
                      
                      // Badge de mesa (mantiene estilo original)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'MESA 5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 6),
                      
                      // Observaciones con tamaño secundario
                      Obx(() => Text(
                        'Sin cebolla, extra salsa',
                        style: TextStyle(
                          color: obtenerColorTexto().withOpacity(0.7),
                          fontSize: obtenerTamanoFuenteSecundario(false, false),
                          height: 1.2,
                        ),
                      )),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Resetear
                    TextButton(
                      onPressed: () {
                        resetearConfiguracion();
                      },
                      child: Text(
                        'Resetear',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    // Botón Cerrar
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Aplicar',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
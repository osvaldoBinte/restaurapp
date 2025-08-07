import 'package:flutter/material.dart';

class AdminColors {
  // Colores principales - Versión más clara
  static const Color primaryColor = Color(0xFF3F72AF); // Azul más claro
  static const Color secondaryColor = Color(0xFF5195CE); // Azul secundario más claro
  static const Color accentColor = Color(0xFF2E9CCA);    // Azul acento más claro
  
  // Colores de fondo y superficie - Versión más clara
  static const Color backgroundColor = Color(0xFFF5F7FA); // Fondo gris muy claro
  static const Color surfaceColor = Color(0xFFFFFFFF);   // Superficie blanca
  static const Color cardColor = Color(0xFFF0F2F5);      // Tarjeta gris muy claro
  
  // Colores de texto - Versión más clara
  static const Color textPrimaryColor = Color(0xFF2C3E50); // Texto casi negro pero más suave
  static const Color textSecondaryColor = Color(0xFF546E7A); // Texto gris oscuro
  static const Color textSecondaryColoralert = Color(0xFF455A64);
  static const Color textLightColor = Colors.white;
  
  // Colores de estado - Versión más clara pero vibrante
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);
static final Color loaddingwithOpacity1 = const Color.fromARGB(255, 48, 44, 44).withOpacity(0.1);
static final Color loaddingwithOpacity3 = const Color.fromARGB(255, 41, 38, 38).withOpacity(0.3);
static final Color loadding = const Color.fromARGB(255, 65, 60, 60);



  // Colores específicos para la aplicación - Actualizados
  static const Color colorFondo = backgroundColor;
  static const Color colornavbar = Color(0xFFECEFF1);    // Barra de navegación muy clara
  static const Color colorTexto = textPrimaryColor;
  static const Color colorCabezeraTabla = Color(0xFFE1E5EB); // Cabecera de tabla clara
  static const Color colorRowPar = Color(0xFFF7F9FC);    // Fila par muy clara
  static const Color colorRowNoPar = Color(0xFFEDF1F7);  // Fila impar clara
  static const Color colordCard = cardColor;
  static const Color colorAccionButtons = accentColor;
  static const Color colorCancelar = errorColor;
  static const Color colorBotonNavbar = textPrimaryColor;
  static const Color colorHoverRow = accentColor;
  
  // Colores para la card de suscripciones - Actualizados
  static const Color colorSubsCardBackground = Color(0xFFF8F9FA);
  static const Color colorSubsCardTitle = textPrimaryColor;
  static const Color colorSubsCardPrice = Color(0xFF43A047);
  static const Color colorSubsCardDuration = Color(0xFF78909C);
  
  // Utilidades con valores computados - Actualizados
  static final Color shadoCard = Colors.black.withOpacity(0.1);
  static final Color dividerColor = Colors.grey.withOpacity(0.3);
  static final Color shadowColor = Colors.black.withOpacity(0.1);
  static final Color disabledColor = Color(0xFFBDBDBD);
  static final Color colorSubsCardBorder = Colors.grey[300]!;
  static final Color colorSubsCardSecondaryText = Colors.grey[600]!;
  
  // Lista de colores para el degradado - Versión clara
  static final List<Color> lightGradientColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF5F7FA), 
    Color(0xFFECEFF1),
  ];
  
  // Gradientes - Actualizados para tema claro
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get blueGradient => LinearGradient(
    colors: [Color(0xFF2E9CCA), Color(0xFF4CB5E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get purpleGradient => LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: lightGradientColors,
  );
  
  // Valores constantes para dimensiones
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 20.0;
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double elevationSmall = 1.0;  // Reducida para tema claro
  static const double elevationMedium = 2.0; // Reducida para tema claro
  static const double elevationLarge = 4.0;  // Reducida para tema claro
  
  // Objetos BorderRadius
  static BorderRadius get smallBorderRadius => BorderRadius.circular(smallRadius);
  static BorderRadius get mediumBorderRadius => BorderRadius.circular(mediumRadius);
  static BorderRadius get largeBorderRadius => BorderRadius.circular(largeRadius);
  
  // Sombras - Más sutiles para tema claro
  static BoxShadow get lightShadow => BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 6,
    offset: const Offset(0, 1),
  );
  
  static BoxShadow get mediumShadow => BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  // Decoraciones - Actualizadas para tema claro
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: mediumBorderRadius,
    border: Border.all(color: Colors.grey[300]!),
    boxShadow: [lightShadow],
  );
  
  static BoxDecoration get statusCardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: mediumBorderRadius,
    border: Border.all(color: Colors.grey[300]!),
    boxShadow: [lightShadow],
  );
  
  // Estilos de texto - Actualizados para tema claro
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static TextStyle get headingMedium => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: cardColor,
  );
  
  static TextStyle get headingSmall => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static TextStyle get subtitleLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );
  
  static TextStyle get subtitleMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    color: textSecondaryColor,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
  );
  
  static TextStyle get buttonText => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textLightColor,
  );
  
  static TextStyle get statusText => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: accentColor,
  );
  
  static TextStyle get bannerTextStyle => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textLightColor,
  );
  
  // ThemeData - Actualizado para tema claro
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: textLightColor,
      secondary: secondaryColor,
      onSecondary: textLightColor,
      tertiary: accentColor,
      error: errorColor,
      onError: textLightColor,
      background: backgroundColor,
      onBackground: textPrimaryColor,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
    ),
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: colornavbar,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      titleTextStyle: headingSmall,
    ),
    
    // Card
    cardTheme: CardThemeData(
      color: colorSubsCardBackground,
      elevation: elevationSmall,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: mediumBorderRadius,
        side: BorderSide(color: colorSubsCardBorder, width: 1),
      ),
    ),
    
    // Botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorAccionButtons,
        foregroundColor: textLightColor,
        shape: RoundedRectangleBorder(
          borderRadius: smallBorderRadius,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: buttonText,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorAccionButtons,
        shape: RoundedRectangleBorder(
          borderRadius: smallBorderRadius,
        ),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // DataTable
    dataTableTheme: DataTableThemeData(
      headingRowColor: MaterialStateProperty.all(colorCabezeraTabla),
      dataRowColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return colorHoverRow.withOpacity(0.1);
          }
          return Colors.transparent;
        },
      ),
      dividerThickness: 1,
      headingTextStyle: TextStyle(
        color: textPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Estilos de texto
    textTheme: TextTheme(
      bodyMedium: bodyMedium,
      bodyLarge: bodyLarge,
      titleMedium: subtitleMedium,
      titleLarge: headingSmall,
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: smallBorderRadius,
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: smallBorderRadius,
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: smallBorderRadius,
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      labelStyle: TextStyle(color: textSecondaryColor),
      hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7)),
    ),
    
    // Bottom navigation bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colornavbar,
      selectedItemColor: accentColor,
      unselectedItemColor: disabledColor,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      elevation: 4,
    ),
    
    // Divider
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: primaryColor,
      size: 24,
    ),
  );
  
  // Helper methods para widgets comunes
  
  // Botón primario
  static Widget createPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isFullWidth = true,
    double? height, 
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
  
  // Tarjeta de estado
  static Widget createStatusCard(String title, String status) {
    return Container(
      width: 200,
      decoration: statusCardDecoration,
      padding: const EdgeInsets.all(paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: subtitleMedium,
          ),
          const SizedBox(height: paddingSmall),
          Text(
            status,
            style: statusText,
          ),
        ],
      ),
    );
  }
  
  // Tarjeta de evento
  static Widget createEventCard({
    required String bannerText,
    required String title,
    required String date,
    required String location,
    List<Color>? gradientColors,
    IconData icon = Icons.medical_services,
  }) {
    final colors = gradientColors ?? [primaryColor, secondaryColor];
    
    return Container(
      width: double.infinity,
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner con degradado
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(paddingMedium),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: textLightColor,
                      size: 32,
                    ),
                    SizedBox(width: paddingSmall),
                    Text(
                      bannerText,
                      style: bannerTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Detalles del evento
          Padding(
            padding: const EdgeInsets.all(paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: headingSmall,
                ),
                SizedBox(height: paddingSmall),
                Text(
                  date,
                  style: subtitleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  location,
                  style: subtitleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
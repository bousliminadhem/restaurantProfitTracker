import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
    
  static const Color bordeauxRed = Color(0xFFAF1224);
  static const Color offWhite = Color(0xFFFDFCFC);
  static const Color warmGray = Color(0xFFB5AAA5);
  static const Color goldenOrange = Color(0xFFC8813B);
  static const Color darkBrown = Color(0xFF6B2007);
  static const Color caramel = Color(0xFF97531F);
  static const Color freshGreen = Color(0xFF2E7D32);
  static const Color successGreen = Color(0xFF4CAF50);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bordeauxRed, Color(0xFF8A0E1C)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldenOrange, caramel],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [freshGreen, successGreen],
  );

  // Text Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: offWhite,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
    color: offWhite,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: darkBrown,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: darkBrown,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: darkBrown,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: darkBrown,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: offWhite,
  );

  // Shadow Styles
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: darkBrown.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: darkBrown.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;

  // Material 3 Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: bordeauxRed,
        onPrimary: offWhite,
        secondary: goldenOrange,
        onSecondary: offWhite,
        tertiary: freshGreen,
        error: const Color(0xFFD32F2F),
        surface: offWhite,
        onSurface: darkBrown,
        surfaceContainerHighest: warmGray.withOpacity(0.1),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: bordeauxRed,
        foregroundColor: offWhite,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: offWhite,
        ),
        iconTheme: const IconThemeData(color: offWhite),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: darkBrown.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        color: offWhite,
        surfaceTintColor: Colors.transparent,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bordeauxRed,
          foregroundColor: offWhite,
          elevation: 4,
          shadowColor: bordeauxRed.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLarge,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: labelLarge,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: bordeauxRed,
          side: const BorderSide(color: bordeauxRed, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLarge,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: bordeauxRed,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMedium,
            vertical: 12,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: offWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: warmGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: warmGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: bordeauxRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: offWhite,
        elevation: 8,
        shadowColor: darkBrown.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: headlineMedium,
        contentTextStyle: bodyLarge,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: goldenOrange,
        foregroundColor: offWhite,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: warmGray.withOpacity(0.2),
        labelStyle: bodyMedium.copyWith(color: darkBrown),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: warmGray.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
      ),
    );
  }

  // Set status bar and navigation bar colors
  static void setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: bordeauxRed,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Enable edge-to-edge mode
  static void enableEdgeToEdge() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MochiTheme {
  // Minimal Color Palettes
  static const Map<String, Color> pastelColors = {
    'slate': Color(0xFF64748B),
    'gray': Color(0xFF6B7280),
    'neutral': Color(0xFF737373),
    'stone': Color(0xFF78716C),
    'blue': Color(0xFF3B82F6),
    'indigo': Color(0xFF6366F1),
    'violet': Color(0xFF8B5CF6),
    'purple': Color(0xFFA855F7),
  };

  // Theme variations
  static const Map<String, Map<String, Color>> themes = {
    'default': {
      'primary': Color(0xFF2C3E50),
      'secondary': Color(0xFF34495E),
      'accent': Color(0xFF3498DB),
      'background': Color(0xFFFAFAFA),
      'surface': Colors.white,
      'cardBackground': Color(0xFFFFFFFF),
    },
    'minimal': {
      'primary': Color(0xFF2C3E50),
      'secondary': Color(0xFF7F8C8D),
      'accent': Color(0xFF3498DB),
      'background': Color(0xFFF8F9FA),
      'surface': Colors.white,
      'cardBackground': Color(0xFFFFFFFF),
    },
    'festival': {
      'primary': Color(0xFFE1C6FF),
      'secondary': Color(0xFFFFB8D6),
      'accent': Color(0xFFFFF2B8),
      'background': Color(0xFFFFF8E1),
      'surface': Color(0xFFFFFFF0),
      'cardBackground': Color(0xFFF5F0FF),
    },
    'night': {
      'primary': Color(0xFF4A5568),
      'secondary': Color(0xFF718096),
      'accent': Color(0xFF9F7AEA),
      'background': Color(0xFF1A202C),
      'surface': Color(0xFF2D3748),
      'cardBackground': Color(0xFF4A5568),
    },
  };

  // Mochi expressions and emotions
  static const Map<String, String> mochiExpressions = {
    'happy': '😄',
    'sleepy': '😴',
    'shocked': '😳',
    'laughing': '🤭',
    'sad': '😢',
    'crazy': '🤪',
    'love': '😍',
    'thinking': '🤔',
    'winking': '😉',
    'confused': '😕',
  };

  // Get theme colors
  static Map<String, Color> getThemeColors(String themeName) {
    return themes[themeName] ?? themes['default']!;
  }

  // Build Material Theme
  static ThemeData buildTheme(String themeName) {
    final colors = getThemeColors(themeName);
    final isDark = themeName == 'night';

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: _createMaterialColor(colors['primary']!),
      primaryColor: colors['primary'],
      scaffoldBackgroundColor: colors['background'],
      cardColor: colors['cardBackground'],
      
      // Typography
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),

      // Component Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: isDark ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 4,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors['cardBackground'],
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: colors['primary']!.withValues(alpha: 0.3),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors['primary'],
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors['surface'],
        selectedItemColor: colors['primary'],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors['secondary'],
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 8,
        shape: const CircleBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['surface'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors['primary']!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Additional theme properties
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors['primary']!,
        secondary: colors['secondary']!,
        surface: colors['surface']!,
      ),
    );
  }

  // Create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

// Animation Durations
class MochiAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration extraSlow = Duration(milliseconds: 1000);
}

// Common sizes and spacing
class MochiSizes {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  
  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Quick access to current theme colors (default theme)
  static Color get primaryColor => MochiTheme.themes['default']!['primary']!;
  static Color get backgroundColor => MochiTheme.themes['default']!['background']!;
  static Color get cardColor => MochiTheme.themes['default']!['cardBackground']!;
  static Color get textColor => const Color(0xFF2D3748);
  static Color get shadowColor => const Color(0xFF000000).withOpacity(0.1);
}
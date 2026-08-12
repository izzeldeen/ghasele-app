import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // Cleanyjo Brand Colors
  // Sampled directly from the Cleanyjo logo:
  //   slate  #414953 - wordmark "Cleany", hanger/shirt mark
  //   green  #43AD82 - leaf, bubbles, "jo" and the crescent sweep
  // ---------------------------------------------------------------------------
  static const brandGreen = Color(0xFF43AD82);
  static const brandGreenLight = Color(0xFF5EC79B);
  static const brandGreenDark = Color(0xFF2F8C66);
  static const brandGreenSurface = Color(0xFFEAF7F1);

  static const brandSlate = Color(0xFF414953);
  static const brandSlateLight = Color(0xFF5A6472);
  static const brandSlateDark = Color(0xFF2C333C);

  /// Primary action colour across the app (buttons, active states, links).
  static const primary = brandGreen;
  static const primaryLight = brandGreenLight;
  static const primaryDark = brandGreenDark;

  /// Secondary/contrast colour - headlines, dark surfaces, icons.
  static const secondary = brandSlate;
  static const secondaryLight = brandSlateLight;
  static const secondaryDark = brandSlateDark;

  /// The signature Cleanyjo gradient (used on hero cards and the splash).
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreen, brandGreenDark],
  );

  // Neutral Colors - subtly tinted toward the brand slate so greys sit
  // naturally next to the logo instead of reading as flat cold grey.
  static const neutral50 = Color(0xFFF8FAF9);
  static const neutral100 = Color(0xFFF1F4F3);
  static const neutral200 = Color(0xFFE3E7E9);
  static const neutral300 = Color(0xFFCBD2D6);
  static const neutral400 = Color(0xFF9AA3AC);
  static const neutral500 = Color(0xFF6E7781);
  static const neutral600 = Color(0xFF565F69);
  static const neutral700 = Color(0xFF414953);
  static const neutral800 = Color(0xFF2C333C);
  static const neutral900 = Color(0xFF1B2027);

  // Semantic Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // Background
  static const scaffoldBackground = neutral50;
  static const cardBackground = Colors.white;
  
  // Text Styles
  static TextTheme get textTheme => GoogleFonts.interTextTheme(
    TextTheme(
      // Display styles
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: neutral900,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: neutral900,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: neutral900,
        height: 1.3,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: neutral900,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.4,
      ),
      
      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.4,
      ),
      
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: neutral700,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: neutral700,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: neutral600,
        height: 1.5,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: neutral700,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neutral600,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: neutral500,
        height: 1.4,
      ),
    ),
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppTheme.primary,
        primaryContainer: brandGreenSurface,
        secondary: AppTheme.secondary,
        secondaryContainer: neutral100,
        surface: cardBackground,
        background: scaffoldBackground,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: neutral900,
        onBackground: neutral900,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: neutral900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
        iconTheme: const IconThemeData(color: neutral900),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: neutral200, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutral200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neutral200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neutral600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: neutral400,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: error,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: neutral400,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: neutral100,
        selectedColor: AppTheme.primary.withOpacity(0.1),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

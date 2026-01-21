import 'package:flutter/material.dart';

class AppTheme {
  // ============ COLOR PALETTE ============
  // Primary Colors (Hijau Gunung)
  static const Color primaryColor = Color(0xFF2E7D32);    // Hijau utama
  static const Color primaryLight = Color(0xFF4CAF50);    // Hijau muda
  static const Color primaryDark = Color(0xFF1B5E20);     // Hijau gelap
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFFFF9800);  // Orange aksen
  static const Color secondaryLight = Color(0xFFFFB74D);  // Orange muda
  static const Color secondaryDark = Color(0xFFF57C00);   // Orange gelap
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF8F9FA); // Background utama
  static const Color surfaceColor = Color(0xFFFFFFFF);    // Card/Sheet background
  static const Color borderColor = Color(0xFFE0E0E0);     // Border lines
  
  // Semantic Colors
  static const Color successColor = Color(0xFF4CAF50);    // Hijau sukses
  static const Color warningColor = Color(0xFFFF9800);    // Orange peringatan
  static const Color errorColor = Color(0xFFF44336);      // Merah error
  static const Color infoColor = Color(0xFF2196F3);       // Biru info
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);     // Teks utama
  static const Color textSecondary = Color(0xFF757575);   // Teks sekunder
  static const Color textDisabled = Color(0xFF9E9E9E);    // Teks disabled
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // Teks di atas primary
  static const Color textOnSecondary = Color(0xFF212121); // Teks di atas secondary

  // ============ TEXT STYLES ============
  // Heading Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Title Styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  // Label/Caption Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textDisabled,
  );

  // Button Text
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    letterSpacing: 0.5,
  );

  // ============ SHADOWS ============
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color.fromRGBO(76, 175, 80, 0.3),
      blurRadius: 8,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ============ BORDER RADIUS ============
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadiusExtraLarge = BorderRadius.all(Radius.circular(24));

  // ============ SPACING ============
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============ APP THEME ============
  static ThemeData get lightTheme {
    return ThemeData(
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: textOnPrimary,
        onSecondary: textOnSecondary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textOnPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),
      

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: headlineLarge,
        displayMedium: headlineMedium,
        displaySmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: textDisabled,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          textStyle: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.3),
          minimumSize: const Size(64, 48),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          textStyle: labelLarge,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          textStyle: buttonText.copyWith(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusMedium,
          ),
          minimumSize: const Size(64, 48),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(spacingM),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textDisabled),
        errorStyle: bodySmall.copyWith(color: errorColor),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Card Theme - FIXED VERSION
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(spacingS),
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),

      // Dialog Theme - FIXED VERSION
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
        ),
        titleTextStyle: titleLarge,
        contentTextStyle: bodyMedium,
      ),

      // Chip Theme - FIXED VERSION
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        disabledColor: textDisabled.withOpacity(0.1),
        labelStyle: labelMedium.copyWith(color: primaryColor),
        secondaryLabelStyle: labelMedium.copyWith(color: Colors.white),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingS,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusSmall,
          side: BorderSide.none,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Visual Density
      visualDensity: VisualDensity.standard,

      // Use Material 3 - DISABLED untuk compatibility
      useMaterial3: false, // ⚠️ Changed from true to false
    );
  }

  // ============ CUSTOM STYLES ============
  // Custom Card Style
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: borderRadiusMedium,
      boxShadow: cardShadow,
    );
  }

  // Primary Button Style
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: textOnPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingM,
      ),
      textStyle: buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.3),
    );
  }

  // Secondary Button Style
  static ButtonStyle get secondaryButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingM,
      ),
      textStyle: buttonText.copyWith(color: primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
    );
  }

  // Success Button Style
  static ButtonStyle get successButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: successColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingM,
      ),
      textStyle: buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
    );
  }

  // Warning Button Style
  static ButtonStyle get warningButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: warningColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingM,
      ),
      textStyle: buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
    );
  }

  // Error Button Style
  static ButtonStyle get errorButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: errorColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingM,
      ),
      textStyle: buttonText,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
    );
  }
}
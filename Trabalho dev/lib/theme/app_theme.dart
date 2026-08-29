
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==============================
  // PALETA LILÁS CLARA
  // ==============================

  static const Color primary = Color(0xFF8B5CF6); // lilás principal
  static const Color primaryDark = Color(0xFF6D28D9); // lilás escuro

  static const Color background = Color(0xFFF5F3FF); // fundo lilás bem claro
  static const Color surface = Color(0xFFFFFFFF); // branco

  static const Color textPrimary = Color(0xFF2E2545); // texto principal
  static const Color textSecondary = Color(0xFF756E83); // texto secundário

  static const Color border = Color(0xFFE9E3F5); // bordas suaves

  static const Color success = Color(0xFF22C55E); // verde sucesso
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double button = 12;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),

      // Fundo geral do aplicativo
      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Roboto',
    );

    return base.copyWith(

      // ==============================
      // APP BAR
      // ==============================

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,

        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ==============================
      // TEXTOS
      // ==============================

      textTheme: base.textTheme.copyWith(

        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),

        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // ==============================
      // BOTÃO PRINCIPAL
      // ==============================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
          ),

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ==============================
      // BOTÃO CONTORNADO
      // ==============================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,

          side: const BorderSide(
            color: AppColors.border,
          ),

          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppRadius.button,
            ),
          ),
        ),
      ),

      // ==============================
      // CARDS
      // ==============================

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.card,
          ),

          side: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
    );
  }
}

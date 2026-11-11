import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NEXUS DESIGN SYSTEM · Studio Professional
/// Preto e branco · detalhes em laranja · medidores digitais.
class NX {
  // Paleta oficial
  static const white = Color(0xFFFFFFFF);
  static const silver = Color(0xFFE5E7EB);
  static const metal = Color(0xFF9CA3AF);
  static const graphite = Color(0xFF111216);

  // Apoio
  static const bg = Color(0xFF060607);
  static const card = Color(0xFF141518);
  static const cardHi = Color(0xFF1D1F24);
  static const border = Color(0xFF2B2D33);
  static const dim = Color(0xFF61656F);

  // Estados
  static const ok = Color(0xFF3DDC5A);
  static const warn = Color(0xFFFFC233);
  static const bad = Color(0xFFFF4D4D);

  /// Cores de destaque disponíveis (Ajustes › Cor de Destaque).
  static const accents = [
    Color(0xFFFF7A1A), // laranja Nexus (padrão)
    Color(0xFF3DDC5A),
    Color(0xFF22C3E6),
    Color(0xFF2F7BFF),
    Color(0xFF9B5CFF),
    Color(0xFFFF2D9A),
  ];

  /// Destaque atual. NÃO usar em expressões `const`.
  static Color accent = accents[0];
  static bool glow = true;
  static bool animations = true;

  static TextStyle sora(double size,
          {FontWeight w = FontWeight.w600, Color c = white, double ls = 0}) =>
      GoogleFonts.getFont('Sora',
          fontSize: size, fontWeight: w, color: c, letterSpacing: ls);

  static TextStyle inter(double size,
          {FontWeight w = FontWeight.w400, Color c = silver, double ls = 0}) =>
      GoogleFonts.getFont('Inter',
          fontSize: size, fontWeight: w, color: c, letterSpacing: ls);

  /// Fonte digital para valores.
  static TextStyle mono(double size, {Color c = white, double ls = 0}) =>
      GoogleFonts.getFont('Share Tech Mono',
          fontSize: size, color: c, letterSpacing: ls);

  static List<BoxShadow>? glowShadow({double blur = 16, double opacity = 0.45}) =>
      glow
          ? [BoxShadow(color: accent.withOpacity(opacity), blurRadius: blur)]
          : null;

  /// Card grafite com borda metálica (ou laranja, se ativo).
  static BoxDecoration cardDeco({
    bool active = false,
    double radius = 14,
    Color? borderColor,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1C21), Color(0xFF0F1013)],
        ),
        border: Border.all(
          color: borderColor ?? (active ? accent : border),
          width: active ? 1.6 : 1,
        ),
        boxShadow: active ? glowShadow(blur: 12, opacity: 0.35) : null,
      );

  static Color statusColor(double absCents) {
    if (absCents <= 10) return ok;
    if (absCents <= 30) return warn;
    return bad;
  }

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: white,
        secondary: silver,
        surface: card,
        onSurface: silver,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: silver, displayColor: white),
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(white),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : cardHi),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: border,
        thumbColor: white,
        overlayColor: accent.withOpacity(0.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
        labelStyle: const TextStyle(color: metal),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: accent.withOpacity(0.25),
        side: const BorderSide(color: border),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardHi,
        contentTextStyle: TextStyle(color: white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

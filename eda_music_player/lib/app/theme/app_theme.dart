import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Paleta atmosférica derivada de la portada de cada canción.
/// Diseñada para alimentar tanto la vista inmersiva *Now Playing* (con
/// difuminado continuo sobre el color de la portada, estilo Apple Music)
/// como el Light Mode sofisticado de las vistas de listas.
class SongVisualPalette {
  const SongVisualPalette({
    required this.name,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.ambientSurface,
    required this.artworkTopColor,
    required this.artworkMidColor,
    required this.artworkBottomColor,
    required this.playerAtmosphereTop,
    required this.playerAtmosphereBottom,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final String name;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color ambientSurface;
  final Color artworkTopColor;
  final Color artworkMidColor;
  final Color artworkBottomColor;
  /// Tonos atmosféricos donde se funde el borde inferior de la portada en Now Playing
  final Color playerAtmosphereTop;
  final Color playerAtmosphereBottom;
  final Color badgeBackground;
  final Color badgeForeground;
}

class AppTheme {
  AppTheme._();

  // --- Base Tokens (Light Mode Sofisticado & Liquid Glass) ---
  static const Color alabasterMist = Color(0xFFF3F5F9);
  static const Color warmPaper = Color(0xFFF9FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // --- Ink & Text Hierarchy ---
  static const Color obsidianInk = Color(0xFF10141E);
  static const Color slatePrimary = Color(0xFF252C3E);
  static const Color slateSecondary = Color(0xFF566077);
  static const Color mutedInk = Color(0xFF737D94);

  // --- Glass & Specular Borders ---
  static const Color glassFillStrong = Color(0xCCFFFFFF);
  static const Color glassFillMedium = Color(0xA6FFFFFF);
  static const Color glassFillSoft = Color(0x78FFFFFF);
  static const Color glassBorderHighlight = Color(0xF2FFFFFF);
  static const Color hairlineBorder = Color(0x1410141E);

  // --- Semantic Colors ---
  static const Color defaultAccent = Color(0xFF345E85);
  static const Color successEmerald = Color(0xFF198754);
  static const Color warningAmber = Color(0xFFB4690E);
  static const Color dangerRose = Color(0xFFC93B4B);

  static String get fontFamily => 'Plus Jakarta Sans';

  /// Paletas atmosféricas inspiradas en las referencias de Apple Music:
  /// - Colores de portada profundos arriba que se funden en una neblina
  ///   difuminada continua abajo sin cortes ni líneas divisorias.
  static SongVisualPalette paletteForSong({
    required int id,
    required String genero,
  }) {
    switch (id) {
      case 1: // Bohemian Rhapsody - Queen (Azul noche profundo y ámbar cálido)
        return const SongVisualPalette(
          name: 'Midnight Opera Slate',
          primaryAccent: Color(0xFF2D536C),
          secondaryAccent: Color(0xFF1B3548),
          ambientSurface: Color(0xFFEDF2F6),
          artworkTopColor: Color(0xFF0E263D),
          artworkMidColor: Color(0xFF274A63),
          artworkBottomColor: Color(0xFF557182),
          playerAtmosphereTop: Color(0xFF4C687A),
          playerAtmosphereBottom: Color(0xFF2C3E4A),
          badgeBackground: Color(0x1F2D536C),
          badgeForeground: Color(0xFF1D3B50),
        );
      case 2: // De Música Ligera - Soda Stereo (Azul cerúleo brumoso como ref Heartfirst)
        return const SongVisualPalette(
          name: 'Cerulean Mist',
          primaryAccent: Color(0xFF2B679B),
          secondaryAccent: Color(0xFF194269),
          ambientSurface: Color(0xFFEAF1F8),
          artworkTopColor: Color(0xFF1B4D7A),
          artworkMidColor: Color(0xFF427AA1),
          artworkBottomColor: Color(0xFF6B98B8),
          playerAtmosphereTop: Color(0xFF5C89A8),
          playerAtmosphereBottom: Color(0xFF395D78),
          badgeBackground: Color(0x1F2B679B),
          badgeForeground: Color(0xFF1A4678),
        );
      case 3: // Billie Jean - Michael Jackson (Carmesí aterciopelado como ref Girl Like Me)
        return const SongVisualPalette(
          name: 'Velvet Crimson Glass',
          primaryAccent: Color(0xFF8C263E),
          secondaryAccent: Color(0xFF541323),
          ambientSurface: Color(0xFFF6ECF0),
          artworkTopColor: Color(0xFF3B0A18),
          artworkMidColor: Color(0xFF6E1D31),
          artworkBottomColor: Color(0xFF8F384D),
          playerAtmosphereTop: Color(0xFF702134),
          playerAtmosphereBottom: Color(0xFF3D101B),
          badgeBackground: Color(0x1F8C263E),
          badgeForeground: Color(0xFF6E182D),
        );
      case 4: // Tren al Sur - Los Prisioneros (Oliva cálido / tierra como ref Hurry Up Tomorrow)
        return const SongVisualPalette(
          name: 'Warm Olive Dusk',
          primaryAccent: Color(0xFF6E563A),
          secondaryAccent: Color(0xFF443320),
          ambientSurface: Color(0xFFF3EFEA),
          artworkTopColor: Color(0xFF2E2318),
          artworkMidColor: Color(0xFF5C4733),
          artworkBottomColor: Color(0xFF876F58),
          playerAtmosphereTop: Color(0xFF6B5642),
          playerAtmosphereBottom: Color(0xFF3A2D21),
          badgeBackground: Color(0x1F6E563A),
          badgeForeground: Color(0xFF523E26),
        );
      case 5: // Clocks - Coldplay (Pizarra azul-grisáceo como ref Cruel World)
        return const SongVisualPalette(
          name: 'Nordic Slate Fog',
          primaryAccent: Color(0xFF2E5A6B),
          secondaryAccent: Color(0xFF1B3A47),
          ambientSurface: Color(0xFFEBF2F5),
          artworkTopColor: Color(0xFF0B2338),
          artworkMidColor: Color(0xFF2D4F63),
          artworkBottomColor: Color(0xFF577280),
          playerAtmosphereTop: Color(0xFF4E6775),
          playerAtmosphereBottom: Color(0xFF2F3F47),
          badgeBackground: Color(0x1F2E5A6B),
          badgeForeground: Color(0xFF1B4352),
        );
      default:
        return const SongVisualPalette(
          name: 'Rose Cloud Glass',
          primaryAccent: Color(0xFF9C3564),
          secondaryAccent: Color(0xFF631D3E),
          ambientSurface: Color(0xFFF7EDF2),
          artworkTopColor: Color(0xFF5E1B3B),
          artworkMidColor: Color(0xFF8F345E),
          artworkBottomColor: Color(0xFFB55B83),
          playerAtmosphereTop: Color(0xFF8C355D),
          playerAtmosphereBottom: Color(0xFF521A34),
          badgeBackground: Color(0x1F9C3564),
          badgeForeground: Color(0xFF78224A),
        );
    }
  }

  /// Sombras suaves teñidas con el color de acento (nunca gris/negro duro).
  static List<BoxShadow> softTintedShadows(
    Color accent, {
    double intensity = 1.0,
  }) {
    return [
      BoxShadow(
        color: accent.withValues(alpha: 0.12 * intensity),
        blurRadius: 28,
        spreadRadius: 0,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: obsidianInk.withValues(alpha: 0.04 * intensity),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 3),
      ),
    ];
  }

  /// Decoración Liquid Glass con reflejo especular superior y borde de 0.9 px.
  static BoxDecoration glassDecoration({
    Color? fillColor,
    Color? borderColor,
    Color? shadowAccent,
    double borderRadius = 24,
    double borderWidth = 0.9,
    double shadowIntensity = 0.85,
  }) {
    return BoxDecoration(
      color: fillColor ?? glassFillStrong,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? glassBorderHighlight,
        width: borderWidth,
      ),
      boxShadow: softTintedShadows(
        shadowAccent ?? defaultAccent,
        intensity: shadowIntensity,
      ),
    );
  }

  /// Estilo numérico con `FontFeature.tabularFigures()` para que los tiempos
  /// (1:21 / -2:06) y contadores nunca vibren al cambiar cada segundo.
  static TextStyle tabularNumberStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = slateSecondary,
    double letterSpacing = 0.1,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle _jakarta({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    final base = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
    try {
      if (GoogleFonts.config.allowRuntimeFetching) {
        return GoogleFonts.plusJakartaSans(textStyle: base);
      }
    } catch (_) {
      return base;
    }
    return base;
  }

  static ThemeData buildLightTheme(SongVisualPalette activePalette) {
    final colorScheme = ColorScheme.light(
      primary: activePalette.primaryAccent,
      onPrimary: pureWhite,
      secondary: activePalette.secondaryAccent,
      onSecondary: pureWhite,
      surface: warmPaper,
      onSurface: obsidianInk,
      error: dangerRose,
      onError: pureWhite,
    );

    final resolvedTextTheme = TextTheme(
      headlineLarge: _jakarta(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: obsidianInk,
        letterSpacing: -0.5,
        height: 1.18,
      ),
      headlineMedium: _jakarta(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: obsidianInk,
        letterSpacing: -0.45,
        height: 1.2,
      ),
      titleLarge: _jakarta(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: obsidianInk,
        letterSpacing: -0.3,
      ),
      titleMedium: _jakarta(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: obsidianInk,
        letterSpacing: -0.15,
      ),
      bodyLarge: _jakarta(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: slatePrimary,
        height: 1.42,
      ),
      bodyMedium: _jakarta(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: slateSecondary,
        height: 1.38,
      ),
      labelLarge: _jakarta(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: obsidianInk,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: activePalette.ambientSurface,
      splashFactory: NoSplash.splashFactory,
      dividerColor: hairlineBorder,
      textTheme: resolvedTextTheme,
    );
  }
}

import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../models/cancion.dart';

/// Lienzo de portada a **pantalla completa** (`Positioned.fill`) para el
/// reproductor principal (*Now Playing*).
///
/// Corrección clave solicitada por el usuario:
/// - **La portada NO se queda cortada a la mitad ni arriba**: ocupa toda la
///   pantalla del reproductor de extremo a extremo.
/// - En la mitad superior se aprecia la portada nítida y despejada, y conforme
///   baja hacia el título, la barra de duración y los controles inferiores,
///   se aplica un **difuminado progresivo suave (`ShaderMask` + `BackdropFilter`)**
///   sin ninguna línea divisoria ni espacio vacío intermedio.
class FullScreenPlayerArtwork extends StatelessWidget {
  const FullScreenPlayerArtwork({
    super.key,
    required this.cancion,
    required this.palette,
    required this.isPlaying,
  });

  final CancionModel? cancion;
  final SongVisualPalette palette;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Portada ocupando el 100% de la pantalla del reproductor
        _buildFullScreenCover(),

        // 2. Capa de difuminado progresivo en la mitad inferior donde viven
        //    el título, la barra de duración, los controles y el volumen.
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.36, 0.56, 0.76, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x88000000),
                  Colors.black,
                  Colors.black,
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.42, 0.72, 1.0],
                      colors: [
                        Colors.transparent,
                        palette.playerAtmosphereTop.withValues(alpha: 0.35),
                        palette.playerAtmosphereTop.withValues(alpha: 0.82),
                        palette.playerAtmosphereBottom.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenCover() {
    // Si el backend C++ extrajo la portada embebida desde la metadata del audio:
    if (cancion?.portadaBytes != null && cancion!.portadaBytes!.isNotEmpty) {
      return Image.memory(
        cancion!.portadaBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Lienzo de portada a pantalla completa mientras proviene del CSV sin portada extraída:
    return CustomPaint(
      painter: _FullScreenAtmosphericCoverPainter(
        palette: palette,
        songId: cancion?.id ?? 0,
      ),
      child: Align(
        alignment: const Alignment(0, -0.34),
        child: AnimatedScale(
          scale: isPlaying ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.pureWhite.withValues(alpha: 0.20),
                      AppTheme.pureWhite.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.pureWhite.withValues(alpha: 0.30),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.pureWhite.withValues(alpha: 0.09),
                        border: Border.all(
                          color: AppTheme.pureWhite.withValues(alpha: 0.20),
                          width: 0.9,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.music_note_2,
                      size: 52,
                      color: AppTheme.pureWhite.withValues(alpha: 0.86),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alias compatible para previsualizaciones o cabeceras puntuales.
class ArtworkHeader extends StatelessWidget {
  const ArtworkHeader({
    super.key,
    required this.cancion,
    required this.palette,
    required this.isPlaying,
    this.height = 420,
  });

  final CancionModel? cancion;
  final SongVisualPalette palette;
  final bool isPlaying;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FullScreenPlayerArtwork(
        cancion: cancion,
        palette: palette,
        isPlaying: isPlaying,
      ),
    );
  }
}

/// Miniatura de portada para listas (Biblioteca, Playlists, Historial) y Mini-Player.
class SongArtworkThumbnail extends StatelessWidget {
  const SongArtworkThumbnail({
    super.key,
    required this.cancion,
    this.size = 48,
    this.borderRadius = 14,
    this.isCurrent = false,
    this.isPlaying = false,
  });

  final CancionModel cancion;
  final double size;
  final double borderRadius;
  final bool isCurrent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteForSong(
      id: cancion.id,
      genero: cancion.genero,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.pureWhite.withValues(alpha: isCurrent ? 0.55 : 0.22),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cancion.portadaBytes != null &&
                cancion.portadaBytes!.isNotEmpty)
              Image.memory(
                cancion.portadaBytes!,
                fit: BoxFit.cover,
              )
            else
              CustomPaint(
                painter: _FullScreenAtmosphericCoverPainter(
                  palette: palette,
                  songId: cancion.id,
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.music_note,
                    size: size * 0.42,
                    color: AppTheme.pureWhite.withValues(alpha: 0.85),
                  ),
                ),
              ),
            if (isCurrent)
              Container(
                color: Colors.black.withValues(alpha: 0.34),
                alignment: Alignment.center,
                child: Icon(
                  isPlaying
                      ? CupertinoIcons.waveform
                      : CupertinoIcons.pause_fill,
                  color: AppTheme.pureWhite,
                  size: size * 0.44,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenAtmosphericCoverPainter extends CustomPainter {
  const _FullScreenAtmosphericCoverPainter({
    required this.palette,
    required this.songId,
  });

  final SongVisualPalette palette;
  final int songId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Lienzo continuo vertical desde la cima hasta el pie de la pantalla
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.42, 0.75, 1.0],
        colors: [
          palette.artworkTopColor,
          palette.artworkMidColor,
          palette.playerAtmosphereTop,
          palette.playerAtmosphereBottom,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Luces volumétricas suaves en la mitad superior (donde brilla la portada)
    final focalA = Offset(
      size.width * (0.28 + (songId % 3) * 0.18),
      size.height * 0.26,
    );
    final radiusA = size.shortestSide * 0.78;
    final paintA = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.artworkBottomColor.withValues(alpha: 0.65),
          palette.artworkMidColor.withValues(alpha: 0.24),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: focalA, radius: radiusA));
    canvas.drawCircle(focalA, radiusA, paintA);

    final focalB = Offset(
      size.width * 0.75,
      size.height * 0.44,
    );
    final radiusB = size.shortestSide * 0.64;
    final paintB = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.pureWhite.withValues(alpha: 0.16),
          palette.primaryAccent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: focalB, radius: radiusB));
    canvas.drawCircle(focalB, radiusB, paintB);
  }

  @override
  bool shouldRepaint(
    covariant _FullScreenAtmosphericCoverPainter oldDelegate,
  ) {
    return oldDelegate.songId != songId ||
        oldDelegate.palette.name != palette.name;
  }
}

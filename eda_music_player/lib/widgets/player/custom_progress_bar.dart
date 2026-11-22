import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// Barra de progreso en cápsula continua estilo Apple Music / iOS 26 Liquid Glass.
///
/// Corrección clave solicitada por el usuario:
/// - **SIN bolita (`thumb` circular)**: es una barra cápsula continua de extremo
///   a extremo (`BorderRadius.circular(999)`), idéntica a las referencias de
///   `Cruel World`, `Girl Like Me` y `Heartfirst`.
/// - **Micro-interacción Liquid Glass**: en reposo mide `6.5 px` de altura; al
///   tocarla o arrastrarla, **toda la cápsula se expande verticalmente a `12 px`**
///   con curva `Curves.easeOutCubic` y aumenta su brillo.
/// - Tiempos debajo (`1:21` y `-2:06`) con `FontFeature.tabularFigures()`.
class CustomProgressBar extends StatefulWidget {
  const CustomProgressBar({
    super.key,
    required this.progress,
    required this.elapsedText,
    required this.remainingText,
    required this.totalDurationText,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.onSeekNormalized,
    this.centerLabel,
    this.isAtmospheric = true,
  });

  final double progress;
  final String elapsedText;
  final String remainingText;
  final String totalDurationText;
  final Color accentColor;
  final Color secondaryAccentColor;
  final ValueChanged<double> onSeekNormalized;
  final String? centerLabel;
  final bool isAtmospheric;

  @override
  State<CustomProgressBar> createState() => _CustomProgressBarState();
}

class _CustomProgressBarState extends State<CustomProgressBar> {
  double? _dragValue;
  bool _isInteracting = false;
  bool _showRemaining = true;

  void _updateFromLocalDx(double dx, double maxWidth) {
    if (maxWidth <= 0) {
      return;
    }
    final ratio = (dx / maxWidth).clamp(0.0, 1.0);
    setState(() {
      _isInteracting = true;
      _dragValue = ratio;
    });
    widget.onSeekNormalized(ratio);
  }

  void _endInteraction() {
    if (_isInteracting || _dragValue != null) {
      setState(() {
        _isInteracting = false;
        _dragValue = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress =
        (_isInteracting ? (_dragValue ?? widget.progress) : widget.progress)
            .clamp(0.0, 1.0);

    // En reposo 6.5 px; al arrastrar/tocar se infla toda la barra a 12 px (sin bolita)
    final barHeight = _isInteracting ? 12.0 : 6.5;

    final trackColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: 0.24)
        : AppTheme.obsidianInk.withValues(alpha: 0.12);

    final fillColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: _isInteracting ? 0.98 : 0.86)
        : widget.accentColor;

    final timeColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: _isInteracting ? 0.92 : 0.62)
        : AppTheme.slateSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zona táctil amplia (34 px) para arrastrar con comodidad
        SizedBox(
          height: 30,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final filledWidth = (maxWidth * effectiveProgress).clamp(
                0.0,
                maxWidth,
              );

              return Semantics(
                slider: true,
                label: 'Duración de la canción',
                value: '${(effectiveProgress * 100).round()}%',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) =>
                      _updateFromLocalDx(d.localPosition.dx, maxWidth),
                  onTapUp: (_) => _endInteraction(),
                  onTapCancel: _endInteraction,
                  onHorizontalDragStart: (d) =>
                      _updateFromLocalDx(d.localPosition.dx, maxWidth),
                  onHorizontalDragUpdate: (d) =>
                      _updateFromLocalDx(d.localPosition.dx, maxWidth),
                  onHorizontalDragEnd: (_) => _endInteraction(),
                  onHorizontalDragCancel: _endInteraction,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: maxWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: _isInteracting
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: filledWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _isInteracting
                                ? [
                                    BoxShadow(
                                      color: fillColor.withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      spreadRadius: 0.5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Fila de tiempos: 1:21 a la izquierda, etiqueta central opcional, -2:06 a la derecha
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.elapsedText,
              style: AppTheme.tabularNumberStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: timeColor,
              ),
            ),
            if (widget.centerLabel != null &&
                widget.centerLabel!.isNotEmpty)
              Text(
                widget.centerLabel!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: timeColor,
                ),
              ),
            GestureDetector(
              onTap: () => setState(() => _showRemaining = !_showRemaining),
              behavior: HitTestBehavior.opaque,
              child: Text(
                _showRemaining
                    ? widget.remainingText
                    : widget.totalDurationText,
                style: AppTheme.tabularNumberStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timeColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barra de volumen en cápsula continua estilo Apple Music (sin bolita/thumb),
/// con iconos `CupertinoIcons.speaker_fill` y `CupertinoIcons.speaker_3_fill`
/// en los extremos y expansión vertical suave al deslizar.
class CustomVolumeBar extends StatefulWidget {
  const CustomVolumeBar({
    super.key,
    required this.volume,
    required this.accentColor,
    required this.onVolumeChanged,
    this.isAtmospheric = true,
  });

  final double volume;
  final Color accentColor;
  final ValueChanged<double> onVolumeChanged;
  final bool isAtmospheric;

  @override
  State<CustomVolumeBar> createState() => _CustomVolumeBarState();
}

class _CustomVolumeBarState extends State<CustomVolumeBar> {
  bool _isDragging = false;

  void _updateVolume(double dx, double width) {
    if (width <= 0) {
      return;
    }
    setState(() => _isDragging = true);
    widget.onVolumeChanged((dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.volume.clamp(0.0, 1.0);
    final barHeight = _isDragging ? 10.5 : 5.5;

    final iconColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: 0.62)
        : AppTheme.mutedInk;
    final trackColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: 0.22)
        : AppTheme.obsidianInk.withValues(alpha: 0.11);
    final fillColor = widget.isAtmospheric
        ? AppTheme.pureWhite.withValues(alpha: _isDragging ? 0.96 : 0.84)
        : widget.accentColor;

    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.onVolumeChanged(0.0),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              CupertinoIcons.speaker_fill,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _updateVolume(d.localPosition.dx, width),
                  onTapUp: (_) => setState(() => _isDragging = false),
                  onTapCancel: () => setState(() => _isDragging = false),
                  onHorizontalDragStart: (d) =>
                      _updateVolume(d.localPosition.dx, width),
                  onHorizontalDragUpdate: (d) =>
                      _updateVolume(d.localPosition.dx, width),
                  onHorizontalDragEnd: (_) =>
                      setState(() => _isDragging = false),
                  onHorizontalDragCancel: () =>
                      setState(() => _isDragging = false),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      width: width,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 140),
                          width: width * clamped,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => widget.onVolumeChanged(1.0),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              CupertinoIcons.speaker_3_fill,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

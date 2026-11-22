import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../models/modo_repeticion.dart';

/// Controles centrales de transporte con identidad propia *Liquid Glass*:
/// - No copia 1:1 los iconos sueltos de Apple Music ni usa círculos sólidos de
///   Material Design: el botón central Play/Pause vive dentro de una **lente
///   circular de cristal líquido refractante (`BackdropFilter` transparente con
///   borde especular diagonal)**, mientras que Anterior y Siguiente tienen
///   cápsulas suaves de vidrio al presionarlos.
class TransportControls extends StatelessWidget {
  const TransportControls({
    super.key,
    required this.isPlaying,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    this.isAtmospheric = true,
  });

  final bool isPlaying;
  final Color accentColor;
  final Color secondaryAccentColor;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final bool isAtmospheric;

  @override
  Widget build(BuildContext context) {
    final fgColor =
        isAtmospheric ? AppTheme.pureWhite : AppTheme.obsidianInk;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Anterior (NodoDoble->anterior)
        _FloatingTransportIcon(
          icon: CupertinoIcons.backward_fill,
          tooltip: 'Canción anterior (actual->anterior)',
          iconSize: 34,
          hitSize: 58,
          color: fgColor,
          onPressed: onPrevious,
        ),

        // Play / Pause central dentro de una lente Liquid Glass transparente
        _LiquidGlassCenterPlayButton(
          isPlaying: isPlaying,
          color: fgColor,
          onPressed: onPlayPause,
        ),

        // Siguiente (NodoDoble->siguiente)
        _FloatingTransportIcon(
          icon: CupertinoIcons.forward_fill,
          tooltip: 'Siguiente canción (actual->siguiente)',
          iconSize: 34,
          hitSize: 58,
          color: fgColor,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _LiquidGlassCenterPlayButton extends StatefulWidget {
  const _LiquidGlassCenterPlayButton({
    required this.isPlaying,
    required this.color,
    required this.onPressed,
  });

  final bool isPlaying;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_LiquidGlassCenterPlayButton> createState() =>
      _LiquidGlassCenterPlayButtonState();
}

class _LiquidGlassCenterPlayButtonState
    extends State<_LiquidGlassCenterPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label =
        widget.isPlaying ? 'Pausar reproducción' : 'Iniciar reproducción';

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.pureWhite
                            .withValues(alpha: _pressed ? 0.28 : 0.18),
                        AppTheme.pureWhite
                            .withValues(alpha: _pressed ? 0.14 : 0.07),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.pureWhite
                          .withValues(alpha: _pressed ? 0.52 : 0.34),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_arrow_solid,
                      key: ValueKey<bool>(widget.isPlaying),
                      size: 36,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTransportIcon extends StatefulWidget {
  const _FloatingTransportIcon({
    required this.icon,
    required this.tooltip,
    required this.iconSize,
    required this.hitSize,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double iconSize;
  final double hitSize;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_FloatingTransportIcon> createState() => _FloatingTransportIconState();
}

class _FloatingTransportIconState extends State<_FloatingTransportIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 115),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: widget.hitSize,
              height: widget.hitSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed
                    ? AppTheme.pureWhite.withValues(alpha: 0.16)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila inferior de utilidades en píldoras suaves *Liquid Glass* con identidad
/// propia del proyecto EDA:
/// 1. Inspector TAD / CSV
/// 2. Modo de Repetición (`SIN_REPETICION`, `REPETIR_UNA`, `REPETIR_TODAS`)
/// 3. Mezcla Fisher-Yates
/// 4. Cola Circular (`ListaDobleCircular`)
class BottomPlayerUtilityRow extends StatelessWidget {
  const BottomPlayerUtilityRow({
    super.key,
    required this.modoRepeticion,
    required this.accentColor,
    required this.activeQueueCount,
    required this.onInspectTad,
    required this.onToggleRepeatMode,
    required this.onShuffleFisherYates,
    required this.onOpenQueueSheet,
    this.isAtmospheric = true,
  });

  final ModoRepeticion modoRepeticion;
  final Color accentColor;
  final int activeQueueCount;
  final VoidCallback onInspectTad;
  final VoidCallback onToggleRepeatMode;
  final VoidCallback onShuffleFisherYates;
  final VoidCallback onOpenQueueSheet;
  final bool isAtmospheric;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _LiquidUtilityPill(
            icon: CupertinoIcons.quote_bubble,
            label: 'TAD',
            tooltip: 'Inspeccionar Nodo TAD Cancion y CSV',
            onTap: onInspectTad,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: _LiquidUtilityPill(
            icon: modoRepeticion == ModoRepeticion.repetirUna
                ? CupertinoIcons.repeat_1
                : CupertinoIcons.repeat,
            label: modoRepeticion.etiquetaCorta,
            tooltip: 'Modo: ${modoRepeticion.etiqueta}',
            isActive: modoRepeticion != ModoRepeticion.sinRepeticion,
            onTap: onToggleRepeatMode,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: _LiquidUtilityPill(
            icon: CupertinoIcons.shuffle,
            label: 'Shuffle',
            tooltip: 'Mezclar con Algoritmo Fisher-Yates',
            onTap: onShuffleFisherYates,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: _LiquidUtilityPill(
            icon: CupertinoIcons.list_bullet,
            label: 'Cola ($activeQueueCount)',
            tooltip: 'Ver Cola Circular Activa (ListaDobleCircular)',
            isActive: true,
            onTap: onOpenQueueSheet,
          ),
        ),
      ],
    );
  }
}

class _LiquidUtilityPill extends StatefulWidget {
  const _LiquidUtilityPill({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<_LiquidUtilityPill> createState() => _LiquidUtilityPillState();
}

class _LiquidUtilityPillState extends State<_LiquidUtilityPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withValues(
                alpha: widget.isActive ? 0.18 : 0.09,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppTheme.pureWhite.withValues(
                  alpha: widget.isActive ? 0.34 : 0.16,
                ),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: AppTheme.pureWhite.withValues(
                    alpha: widget.isActive ? 0.96 : 0.72,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.tabularNumberStyle(
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.pureWhite.withValues(
                        alpha: widget.isActive ? 0.96 : 0.72,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// Superficie **Liquid Glass** unificada para toda la aplicación (Reproductor,
/// Biblioteca, Playlists, Historial y Modales).
///
/// Utiliza `BackdropFilter` con relleno de cristal translúcido esmerilado,
/// borde especular refractante de `0.9 px` y respuesta táctil con `scale-down`.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.blurSigma = 26,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 0.9,
    this.accentColor,
    this.shadowIntensity = 0.75,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? accentColor;
  final double shadowIntensity;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapEnd([dynamic _]) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;

    final defaultFill = widget.isHighlighted
        ? AppTheme.pureWhite.withValues(alpha: _isPressed ? 0.28 : 0.22)
        : AppTheme.pureWhite.withValues(alpha: _isPressed ? 0.18 : 0.11);

    final defaultBorder = widget.isHighlighted
        ? AppTheme.pureWhite.withValues(alpha: 0.46)
        : AppTheme.pureWhite.withValues(alpha: 0.22);

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.fillColor ?? defaultFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor ?? defaultBorder,
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (!interactive) {
      return cardContent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapEnd,
      onTapCancel: _handleTapEnd,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.982 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: cardContent,
      ),
    );
  }
}

/// Botón circular Liquid Glass translúcido para toda la aplicación.
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
    this.iconSize = 18,
    this.accentColor,
    this.isActive = false,
    this.isAtmospheric = true,
    this.fillColor,
    this.iconColor,
    this.badgeText,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? accentColor;
  final bool isActive;
  final bool isAtmospheric;
  final Color? fillColor;
  final Color? iconColor;
  final String? badgeText;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hitSize = widget.size < 44 ? 44.0 : widget.size;
    final disabled = widget.onPressed == null;

    final bgColor = widget.fillColor ??
        (widget.isActive
            ? AppTheme.pureWhite.withValues(alpha: 0.28)
            : AppTheme.pureWhite.withValues(alpha: 0.13));
    final borderColor = AppTheme.pureWhite.withValues(
      alpha: widget.isActive ? 0.48 : 0.24,
    );
    final fgColor = disabled
        ? AppTheme.pureWhite.withValues(alpha: 0.35)
        : (widget.iconColor ?? AppTheme.pureWhite);

    Widget buttonBody = Semantics(
      button: true,
      enabled: !disabled,
      label: widget.tooltip,
      selected: widget.isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderColor,
                          width: 0.85,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: widget.iconSize,
                        color: fgColor,
                      ),
                    ),
                  ),
                ),
                if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.pureWhite.withValues(alpha: 0.7),
                          width: 0.9,
                        ),
                      ),
                      child: Text(
                        widget.badgeText!,
                        style: AppTheme.tabularNumberStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
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

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        child: buttonBody,
      );
    }
    return buttonBody;
  }
}

/// Notificación flotante tipo cápsula Liquid Glass.
void showEdaToast(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData icon = CupertinoIcons.check_mark_circled_solid,
  Color? accentColor,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  final accent = accentColor ?? AppTheme.defaultAccent;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      duration: const Duration(milliseconds: 2400),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.obsidianInk.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.pureWhite.withValues(alpha: 0.22),
                width: 0.9,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: AppTheme.pureWhite),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.pureWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppTheme.pureWhite.withValues(alpha: 0.72),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

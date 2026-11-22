import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';

/// Dock de navegación inferior en cápsula flotante **Liquid Glass**.
///
/// Correcciones aplicadas según feedback del usuario:
/// - **Eliminada por completo la lupa lateral** que redirigía a Biblioteca.
/// - Cápsula única centrada (`borderRadius: 999`) con lente de vidrio líquido
///   translúcida sobre la pestaña activa (*Suena*, *Biblioteca*, *Playlists*, *Historial*).
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.accentColor,
    required this.onSelect,
    this.isAtmospheric = true,
  });

  final int currentIndex;
  final Color accentColor;
  final ValueChanged<int> onSelect;
  final bool isAtmospheric;

  static const _items = [
    (
      icon: CupertinoIcons.play_circle,
      activeIcon: CupertinoIcons.play_circle_fill,
      label: 'Suena',
    ),
    (
      icon: CupertinoIcons.music_albums,
      activeIcon: CupertinoIcons.music_albums_fill,
      label: 'Biblioteca',
    ),
    (
      icon: CupertinoIcons.music_note_list,
      activeIcon: CupertinoIcons.music_note_list,
      label: 'Playlists',
    ),
    (
      icon: CupertinoIcons.clock,
      activeIcon: CupertinoIcons.clock_fill,
      label: 'Historial',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pillFill = AppTheme.pureWhite.withValues(alpha: 0.13);
    final pillBorder = AppTheme.pureWhite.withValues(alpha: 0.26);
    final activeLensFill = AppTheme.pureWhite.withValues(alpha: 0.22);
    const activeFg = AppTheme.pureWhite;
    final inactiveFg = AppTheme.pureWhite.withValues(alpha: 0.64);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: pillFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: pillBorder,
                    width: 0.95,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final selected = index == currentIndex;

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: item.label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: selected
                                  ? activeLensFill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: selected
                                  ? Border.all(
                                      color: AppTheme.pureWhite
                                          .withValues(alpha: 0.34),
                                      width: 0.85,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected ? item.activeIcon : item.icon,
                                  size: 20,
                                  color: selected ? activeFg : inactiveFg,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected ? activeFg : inactiveFg,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

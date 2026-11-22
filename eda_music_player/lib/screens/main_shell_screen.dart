import 'package:material_ui/material_ui.dart';

import '../services/music_player_controller.dart';
import '../widgets/layout/glass_bottom_nav.dart';
import '../widgets/layout/mini_player_bar.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'now_playing_screen.dart';
import 'playlists_screen.dart';

/// Contenedor móvil principal (`MainShellScreen`).
///
/// Unifica el lienzo atmosférico **Liquid Glass** en todas las pestañas
/// (*Suena*, *Biblioteca*, *Playlists* e *Historial*) para que no exista
/// ningún salto a fondos blancos planos de Material Design al cambiar de vista.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    super.key,
    required this.controller,
  });

  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final palette = controller.activePalette;
        final state = controller.playbackState;
        final currentIndex = controller.selectedNavIndex;
        final isNowPlayingTab = currentIndex == 0;
        final showMiniPlayer =
            !isNowPlayingTab && state.cancionActual != null;

        return Scaffold(
          backgroundColor: palette.playerAtmosphereBottom,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  palette.artworkTopColor,
                  palette.playerAtmosphereTop,
                  palette.playerAtmosphereBottom,
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Vista activa
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildCurrentScreen(currentIndex),
                ),

                // 2. Mini-Player en cápsula + Dock Flotante Liquid Glass (sin lupa)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          child: showMiniPlayer
                              ? Padding(
                                  key: const ValueKey<String>('mini_player'),
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: MiniPlayerBar(
                                    cancion: state.cancionActual!,
                                    contextName: state.nombreContexto,
                                    isPlaying: state.isPlaying,
                                    progress: state.progreso,
                                    accentColor: palette.primaryAccent,
                                    onTapExpand: () =>
                                        controller.selectNavIndex(0),
                                    onPlayPause: controller.togglePlayPause,
                                    onNext: controller.siguienteCancion,
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey<String>('no_mini_player'),
                                ),
                        ),
                        GlassBottomNav(
                          currentIndex: currentIndex,
                          accentColor: palette.primaryAccent,
                          isAtmospheric: true,
                          onSelect: controller.selectNavIndex,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen(int index) {
    switch (index) {
      case 0:
        return NowPlayingScreen(
          key: const ValueKey<int>(0),
          controller: controller,
        );
      case 1:
        return LibraryScreen(
          key: const ValueKey<int>(1),
          controller: controller,
        );
      case 2:
        return PlaylistsScreen(
          key: const ValueKey<int>(2),
          controller: controller,
        );
      case 3:
        return HistoryScreen(
          key: const ValueKey<int>(3),
          controller: controller,
        );
      default:
        return NowPlayingScreen(
          key: const ValueKey<int>(0),
          controller: controller,
        );
    }
  }
}

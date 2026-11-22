import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../models/cancion.dart';
import '../player/artwork_header.dart';

/// Mini Reproductor flotante en cápsula **Liquid Glass** que se suspende sobre
/// el dock inferior en las vistas de Biblioteca, Playlists e Historial.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.cancion,
    required this.contextName,
    required this.isPlaying,
    required this.progress,
    required this.accentColor,
    required this.onTapExpand,
    required this.onPlayPause,
    required this.onNext,
  });

  final CancionModel cancion;
  final String contextName;
  final bool isPlaying;
  final double progress;
  final Color accentColor;
  final VoidCallback onTapExpand;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GestureDetector(
            onTap: onTapExpand,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.pureWhite.withValues(alpha: 0.30),
                      width: 0.95,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SongArtworkThumbnail(
                              cancion: cancion,
                              size: 40,
                              borderRadius: 20,
                              isCurrent: false,
                              isPlaying: isPlaying,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cancion.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.pureWhite,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${cancion.artista} · $contextName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.pureWhite
                                          .withValues(alpha: 0.68),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: onPlayPause,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Icon(
                                  isPlaying
                                      ? CupertinoIcons.pause_fill
                                      : CupertinoIcons.play_arrow_solid,
                                  color: AppTheme.pureWhite,
                                  size: 22,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: onNext,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(4, 8, 10, 8),
                                child: Icon(
                                  CupertinoIcons.forward_fill,
                                  color: AppTheme.pureWhite,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Línea de progreso en cápsula integrada en la base del Mini-Player
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 2.2,
                            backgroundColor:
                                AppTheme.pureWhite.withValues(alpha: 0.16),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
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

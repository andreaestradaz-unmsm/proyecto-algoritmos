import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../app/theme/app_theme.dart';
import '../models/playlist.dart';
import '../services/music_player_controller.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/song_dialogs.dart';
import '../widgets/player/artwork_header.dart';

/// Vista del Historial de Reproducción (`ListaSimple historial` de Andrea y
/// `GestorReproduccion::registrarEnHistorial` de Juan Pablo), rediseñada 100%
/// en estilo **Liquid Glass**.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
  });

  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final palette = controller.activePalette;
    final accent = palette.primaryAccent;
    final items = controller.historial;
    final duracionTotal = PlaylistModel.formatearDuracionTotal(
      controller.duracionTotalHistorialSegundos,
    );

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera Liquid Glass del Historial LIFO
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.pureWhite.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppTheme.pureWhite.withValues(alpha: 0.24),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'ListaSimple · agregarAlInicio (LIFO)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureWhite,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Historial de Reproducción',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.pureWhite,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items.length} reproducciones · Tiempo acumulado: $duracionTotal',
                            style: AppTheme.tabularNumberStyle(
                              fontSize: 12.5,
                              color:
                                  AppTheme.pureWhite.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      GestureDetector(
                        onTap: () => _confirmClearHistory(context),
                        behavior: HitTestBehavior.opaque,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerRose
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFF7A88)
                                      .withValues(alpha: 0.45),
                                  width: 0.9,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.trash,
                                    size: 15,
                                    color: AppTheme.pureWhite,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.pureWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Lista de nodos del Historial en Tarjetas Liquid Glass
              Expanded(
                child: items.isEmpty
                    ? EmptyStateView(
                        icon: CupertinoIcons.clock,
                        structureBadge:
                            'ListaSimple historial · cabeza == nullptr',
                        title: 'Aún no hay canciones en el historial',
                        description:
                            'Cada vez que reproduzcas o avances de pista, GestorReproduccion::registrarEnHistorial insertará un nuevo NodoSimple en la cabeza de la lista.',
                        actionLabel: 'Reproducir canción actual',
                        accentColor: accent,
                        onAction: () {
                          controller.play();
                          controller.selectNavIndex(0);
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 165),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          final cancion = item.cancion;
                          final esMasReciente = index == 0;
                          final songPalette = AppTheme.paletteForSong(
                            id: cancion.id,
                            genero: cancion.genero,
                          );

                          return GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 22,
                            isHighlighted: esMasReciente,
                            onTap: () {
                              controller.reproducirCancionDirecta(cancion);
                              showEdaToast(
                                context,
                                title: 'Reproduciendo desde Historial',
                                subtitle:
                                    '${cancion.titulo} — Se insertó un nuevo nodo en cabeza.',
                                accentColor: songPalette.primaryAccent,
                              );
                            },
                            child: Row(
                              children: [
                                SongArtworkThumbnail(
                                  cancion: cancion,
                                  size: 48,
                                  borderRadius: 13,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (esMasReciente) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.pureWhite
                                                    .withValues(alpha: 0.24),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'CABEZA (Más reciente)',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.pureWhite,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                          ],
                                          Expanded(
                                            child: Text(
                                              cancion.titulo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${cancion.artista} · Origen: ${item.origenNombre}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.pureWhite
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'NodoSimple #${index + 1} · Hora: ${item.horaFormateada} · Duración: ${cancion.obtenerDuracionFormateada()}',
                                        style: AppTheme.tabularNumberStyle(
                                          fontSize: 11,
                                          color: AppTheme.pureWhite
                                              .withValues(alpha: 0.60),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GlassIconButton(
                                  icon: CupertinoIcons.info_circle,
                                  tooltip: 'Ver detalles del nodo TAD',
                                  size: 34,
                                  iconSize: 16,
                                  onPressed: () => showSongNodeInspectorSheet(
                                    context,
                                    cancion: cancion,
                                    palette: songPalette,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GlassIconButton(
                                  icon: CupertinoIcons.play_arrow_solid,
                                  tooltip: 'Volver a reproducir',
                                  size: 34,
                                  iconSize: 15,
                                  isActive: true,
                                  onPressed: () {
                                    controller
                                        .reproducirCancionDirecta(cancion);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: AppTheme.dangerRose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Limpiar Historial (ListaSimple::limpiar)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se recorrerán todos los nodos de ListaSimple historial liberando su memoria y dejando cabeza = cola = nullptr.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppTheme.pureWhite.withValues(alpha: 0.76),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.pureWhite,
                        side: BorderSide(
                          color: AppTheme.pureWhite.withValues(alpha: 0.26),
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: AppTheme.pureWhite,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        controller.limpiarHistorial();
                        Navigator.of(ctx).pop();
                        showEdaToast(
                          context,
                          title: 'Historial vaciado',
                          subtitle: 'ListaSimple::limpiar() ejecutado.',
                          icon: CupertinoIcons.trash,
                          accentColor: AppTheme.dangerRose,
                        );
                      },
                      child: const Text('Vaciar historial'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

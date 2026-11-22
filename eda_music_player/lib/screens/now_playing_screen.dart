import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../app/theme/app_theme.dart';
import '../models/cancion.dart';
import '../services/music_player_controller.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/song_dialogs.dart';
import '../widgets/player/artwork_header.dart';
import '../widgets/player/custom_progress_bar.dart';
import '../widgets/player/transport_controls.dart';

/// Vista principal del Reproductor (*Now Playing*):
/// - **La portada ocupa el 100% de la pantalla (`Positioned.fill`)**, y cuando
///   baja hacia el título y la barra de duración se va difuminando de forma
///   continua (`FullScreenPlayerArtwork`).
/// - **Eliminado el espacio vacío intermedio**: el bloque de Título, Artista y
///   botones `☆` / `•••` está unido directamente encima de la barra de duración
///   (separado por apenas `16 px`), dejando libre la mitad superior para lucir
///   la portada completa.
/// - **Identidad propia Liquid Glass**: incluye píldora de contexto del nodo
///   activo de la `ListaDobleCircular` sobre el título, lente refractante en
///   el botón Play/Pause y barra inferior de píldoras de vidrio líquido.
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({
    super.key,
    required this.controller,
  });

  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.playbackState;
    final cancion = state.cancionActual;
    final palette = controller.activePalette;
    final playlistActiva = controller.playlistActiva;

    if (cancion == null) {
      return EmptyStateView(
        icon: CupertinoIcons.music_note_2,
        structureBadge: 'ListaDobleCircular · Sin nodo actual',
        title: 'Ninguna pista en el cursor actual',
        description:
            'Selecciona una canción desde la Biblioteca o activa una playlist con canciones para iniciar el recorrido de nodos.',
        actionLabel: 'Ir a la Biblioteca',
        accentColor: palette.primaryAccent,
        onAction: () => controller.selectNavIndex(1),
      );
    }

    final posHumana = playlistActiva?.indiceActual != null
        ? (playlistActiva!.indiceActual! + 1)
        : 1;
    final totalNodos = playlistActiva?.tamano ?? 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Portada a pantalla completa con difuminado progresivo al llegar a los controles
        FullScreenPlayerArtwork(
          cancion: cancion,
          palette: palette,
          isPlaying: state.isPlaying,
        ),

        // 2. Grabber pill superior
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppTheme.pureWhite.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // 3. Panel Inferior Unificado (Título + Barra de Duración + Controles + Volumen + Utilidades)
        //    Todo agrupado abajo sobre la zona difuminada de la portada -> CERO espacio vacío intermedio.
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Píldora de identidad EDA: Nodo actual en ListaDobleCircular
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _showCircularQueueSheet(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.pureWhite.withValues(alpha: 0.24),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 13,
                              color: AppTheme.pureWhite.withValues(alpha: 0.90),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                playlistActiva != null
                                    ? '${playlistActiva.nombre} · Nodo $posHumana/$totalNodos'
                                    : state.nombreContexto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.tabularNumberStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.pureWhite
                                      .withValues(alpha: 0.90),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Título + Artista a la izquierda y botones ☆ / ••• a la derecha
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cancion.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.pureWhite,
                                letterSpacing: -0.5,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              cancion.artista,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color:
                                    AppTheme.pureWhite.withValues(alpha: 0.74),
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Botón Estrella (Favorito) en círculo Liquid Glass
                      GlassIconButton(
                        icon: cancion.esFavorita
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        tooltip: cancion.esFavorita
                            ? 'Quitar de favoritas'
                            : 'Marcar como favorita',
                        size: 36,
                        iconSize: 18,
                        isAtmospheric: true,
                        isActive: cancion.esFavorita,
                        onPressed: () {
                          controller.toggleFavorito(cancion.id);
                        },
                      ),
                      const SizedBox(width: 6),

                      // Botón ••• (Más opciones) en círculo Liquid Glass
                      GlassIconButton(
                        icon: CupertinoIcons.ellipsis,
                        tooltip: 'Opciones de la canción',
                        size: 36,
                        iconSize: 18,
                        isAtmospheric: true,
                        onPressed: () => _showTrackOptionsMenu(
                          context,
                          cancion,
                          palette,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Aviso sutil si llegó a la cola en modo SIN_REPETICION
                  if (state.mensajeEstado != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.pureWhite.withValues(alpha: 0.24),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        state.mensajeEstado!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureWhite.withValues(alpha: 0.90),
                        ),
                      ),
                    ),
                  ],

                  // Barra de duración en cápsula continua (SIN bolita/thumb)
                  CustomProgressBar(
                    progress: state.progreso,
                    elapsedText: state.tiempoTranscurridoTexto,
                    remainingText: state.tiempoRestanteTexto,
                    totalDurationText: state.duracionTotalTexto,
                    centerLabel:
                        '${cancion.genero} · ${state.modoRepeticion.etiquetaCorta}',
                    accentColor: palette.primaryAccent,
                    secondaryAccentColor: palette.secondaryAccent,
                    isAtmospheric: true,
                    onSeekNormalized: controller.seekToNormalized,
                  ),

                  const SizedBox(height: 22),

                  // Controles centrales con lente Liquid Glass en Play/Pause
                  TransportControls(
                    isPlaying: state.isPlaying,
                    accentColor: palette.primaryAccent,
                    secondaryAccentColor: palette.secondaryAccent,
                    isAtmospheric: true,
                    onPrevious: () {
                      controller.anteriorCancion();
                    },
                    onPlayPause: controller.togglePlayPause,
                    onNext: () {
                      final sig = controller.siguienteCancion();
                      if (sig == null && context.mounted) {
                        showEdaToast(
                          context,
                          title: 'Fin de la playlist (Sin repetición)',
                          subtitle:
                              'actual == cola. Cambia el modo a Repetir todas o retrocede.',
                          icon: CupertinoIcons.forward_end_fill,
                          accentColor: palette.primaryAccent,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 22),

                  // Barra de volumen en cápsula continua (SIN bolita/thumb)
                  CustomVolumeBar(
                    volume: state.volumen,
                    accentColor: palette.primaryAccent,
                    isAtmospheric: true,
                    onVolumeChanged: controller.setVolumen,
                  ),

                  const SizedBox(height: 16),

                  // Fila inferior de píldoras Liquid Glass
                  BottomPlayerUtilityRow(
                    modoRepeticion: state.modoRepeticion,
                    accentColor: palette.primaryAccent,
                    activeQueueCount: playlistActiva?.tamano ?? 0,
                    isAtmospheric: true,
                    onInspectTad: () => showSongNodeInspectorSheet(
                      context,
                      cancion: cancion,
                      palette: palette,
                    ),
                    onToggleRepeatMode: () {
                      controller.ciclarModoRepeticion();
                      final nuevo = controller.playbackState.modoRepeticion;
                      showEdaToast(
                        context,
                        title: 'Modo: ${nuevo.etiqueta}',
                        subtitle: nuevo.explicacionEda,
                        icon: CupertinoIcons.repeat,
                        accentColor: palette.primaryAccent,
                      );
                    },
                    onShuffleFisherYates: () {
                      final pl = controller.playlistActiva;
                      if (pl == null || pl.tamano < 2) {
                        showEdaToast(
                          context,
                          title: 'Se necesitan al menos 2 canciones',
                          subtitle:
                              'Agrega más nodos a la playlist activa para aplicar Fisher-Yates.',
                          icon: CupertinoIcons.info,
                          accentColor: AppTheme.warningAmber,
                        );
                        return;
                      }
                      controller.aplicarShuffleFisherYates(pl.id);
                      final semilla =
                          controller.playbackState.ultimoShuffleSemilla;
                      showEdaToast(
                        context,
                        title: 'Mezcla Fisher-Yates aplicada',
                        subtitle:
                            'Playlist "${pl.nombre}" reordenada in-place (semilla: $semilla).',
                        icon: CupertinoIcons.shuffle,
                        accentColor: palette.primaryAccent,
                      );
                    },
                    onOpenQueueSheet: () => _showCircularQueueSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTrackOptionsMenu(
    BuildContext context,
    CancionModel cancion,
    SongVisualPalette palette,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: palette.primaryAccent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SongArtworkThumbnail(cancion: cancion, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cancion.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                        Text(
                          '${cancion.artista} · ${cancion.obtenerDuracionFormateada()} · ${cancion.genero}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.pureWhite.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: AppTheme.pureWhite.withValues(alpha: 0.14)),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.plus_square_on_square,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Insertar en una playlist...',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Elegir Al inicio (cabeza), Al final (cola) o En posición',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showAddToPlaylistPositionSheet(
                    context,
                    controller: controller,
                    cancion: cancion,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.info_circle,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Inspeccionar nodo TAD Cancion y CSV',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'ID #${cancion.id} · ${cancion.aCSV()}',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showSongNodeInspectorSheet(
                    context,
                    cancion: cancion,
                    palette: palette,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.list_bullet,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Ver Cola Circular Activa',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  controller.playbackState.nombreContexto,
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showCircularQueueSheet(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCircularQueueSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: controller,
          builder: (ctx, _) {
            final activa = controller.playlistActiva;
            final palette = controller.activePalette;

            return buildLiquidGlassModalContainer(
              context: ctx,
              accentColor: palette.primaryAccent,
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activa != null
                                    ? 'Cola Circular: ${activa.nombre}'
                                    : 'Sin playlist activa',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.pureWhite,
                                ),
                              ),
                              if (activa != null)
                                Text(
                                  '${activa.tamano} nodos · Duración total: ${activa.duracionTotalFormateada} · ${activa.modoRepeticion.etiqueta}',
                                  style: AppTheme.tabularNumberStyle(
                                    fontSize: 12,
                                    color: AppTheme.pureWhite
                                        .withValues(alpha: 0.70),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (activa != null && activa.tamano >= 2)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppTheme.pureWhite.withValues(alpha: 0.18),
                              foregroundColor: AppTheme.pureWhite,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              controller.aplicarShuffleFisherYates(activa.id);
                              showEdaToast(
                                context,
                                title: 'Fisher-Yates aplicado',
                                subtitle: 'Nodos mezclados aleatoriamente.',
                                icon: CupertinoIcons.shuffle,
                                accentColor: palette.primaryAccent,
                              );
                            },
                            icon:
                                const Icon(CupertinoIcons.shuffle, size: 15),
                            label: const Text('Fisher-Yates'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: AppTheme.pureWhite.withValues(alpha: 0.14),
                    ),
                    Expanded(
                      child: activa == null || activa.estaVacia
                          ? Center(
                              child: Text(
                                'La playlist activa está vacía.',
                                style: TextStyle(
                                  color: AppTheme.pureWhite
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              itemCount: activa.tamano,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, index) {
                                final c = activa.canciones[index];
                                final esActual = activa.indiceActual == index;
                                final esCabeza = index == 0;
                                final esCola = index == activa.tamano - 1;

                                return GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  borderRadius: 16,
                                  isHighlighted: esActual,
                                  onTap: () {
                                    controller.reproducirCancionEnPlaylist(
                                      activa.id,
                                      index,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          esActual
                                              ? '> ${index + 1}'
                                              : '${index + 1}.',
                                          style: AppTheme.tabularNumberStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: esActual
                                                ? AppTheme.pureWhite
                                                : AppTheme.pureWhite
                                                    .withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ),
                                      SongArtworkThumbnail(
                                        cancion: c,
                                        size: 40,
                                        borderRadius: 10,
                                        isCurrent: esActual,
                                        isPlaying: esActual &&
                                            controller.playbackState.isPlaying,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.titulo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    c.artista,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.pureWhite
                                                          .withValues(
                                                              alpha: 0.68),
                                                    ),
                                                  ),
                                                ),
                                                if (esCabeza) ...[
                                                  const SizedBox(width: 6),
                                                  const _NodePointerChip(
                                                    label: 'cabeza',
                                                  ),
                                                ],
                                                if (esCola) ...[
                                                  const SizedBox(width: 6),
                                                  const _NodePointerChip(
                                                    label: 'cola ↺',
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        c.obtenerDuracionFormateada(),
                                        style: AppTheme.tabularNumberStyle(
                                          fontSize: 12,
                                          color: AppTheme.pureWhite
                                              .withValues(alpha: 0.72),
                                        ),
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
            );
          },
        );
      },
    );
  }
}

class _NodePointerChip extends StatelessWidget {
  const _NodePointerChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.pureWhite,
        ),
      ),
    );
  }
}

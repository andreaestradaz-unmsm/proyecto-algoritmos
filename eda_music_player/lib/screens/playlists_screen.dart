import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../app/theme/app_theme.dart';
import '../models/cancion.dart';
import '../models/playlist.dart';
import '../services/music_player_controller.dart';
import '../services/music_repository.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/song_dialogs.dart';
import '../widgets/player/artwork_header.dart';

/// Vista de Gestión y Edición de Playlists (`ListaDobleCircular` de Jeick,
/// `GestorReproduccion` de Juan Pablo y menús de Jeremy con `MAX_PLAYLISTS = 20`),
/// rediseñada 100% en estética **Liquid Glass**.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({
    super.key,
    required this.controller,
  });

  final MusicPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final palette = controller.activePalette;
    final accent = palette.primaryAccent;
    final playlists = controller.playlists;
    final activa = controller.playlistActiva;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: CustomScrollView(
            slivers: [
              // 1. Cabecera Liquid Glass y Acciones Globales de Playlists
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                    color: AppTheme.pureWhite
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppTheme.pureWhite
                                          .withValues(alpha: 0.24),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'ListaDobleCircular · ${controller.cantidadPlaylists}/${MusicRepository.maxPlaylists} Playlists',
                                    style: AppTheme.tabularNumberStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.pureWhite,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Playlists Circulares',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.pureWhite,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Cargar Playlist desde CSV
                          GlassIconButton(
                            icon: CupertinoIcons.tray_arrow_down,
                            tooltip: 'Cargar playlist desde CSV',
                            size: 40,
                            iconSize: 18,
                            onPressed: () => _openLoadPlaylistCsvSheet(context),
                          ),
                          const SizedBox(width: 8),
                          // Fusionar dos Playlists
                          GlassIconButton(
                            icon: CupertinoIcons.arrow_merge,
                            tooltip: 'Fusionar dos playlists',
                            size: 40,
                            iconSize: 18,
                            onPressed: () => _openMergePlaylistsDialog(context),
                          ),
                          const SizedBox(width: 8),
                          // Crear Nueva Playlist en cápsula Liquid Glass
                          GestureDetector(
                            onTap: () => _openCreatePlaylistDialog(context),
                            behavior: HitTestBehavior.opaque,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pureWhite
                                        .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppTheme.pureWhite
                                          .withValues(alpha: 0.42),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.add,
                                        size: 17,
                                        color: AppTheme.pureWhite,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Crear',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
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
                      const SizedBox(height: 14),

                      // 2. Carrusel horizontal de Playlists en Cristal Líquido
                      if (playlists.isNotEmpty)
                        SizedBox(
                          height: 118,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: playlists.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (ctx, index) {
                              final pl = playlists[index];
                              final isSelected = pl.esActiva;

                              return SizedBox(
                                width: 230,
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  borderRadius: 22,
                                  isHighlighted: isSelected,
                                  onTap: () {
                                    controller.seleccionarPlaylistActiva(pl.id);
                                    showEdaToast(
                                      context,
                                      title: 'Playlist activa: ${pl.nombre}',
                                      subtitle:
                                          '${pl.tamano} canciones · ${pl.duracionTotalFormateada}',
                                      accentColor: accent,
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.pureWhite
                                                  .withValues(
                                                    alpha: isSelected
                                                        ? 0.28
                                                        : 0.12,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              isSelected
                                                  ? '* ACTIVA'
                                                  : 'Playlist #${index + 1}',
                                              style:
                                                  AppTheme.tabularNumberStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () =>
                                                _openPlaylistActionsSheet(
                                              context,
                                              pl,
                                            ),
                                            child: Icon(
                                              CupertinoIcons.ellipsis,
                                              size: 18,
                                              color: AppTheme.pureWhite
                                                  .withValues(alpha: 0.78),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        pl.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.pureWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${pl.tamano} canciones · ${pl.duracionTotalFormateada}',
                                        style: AppTheme.tabularNumberStyle(
                                          fontSize: 11.5,
                                          color: AppTheme.pureWhite
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Panel Editor Liquid Glass de la Playlist Activa
              if (playlists.isEmpty || activa == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: CupertinoIcons.music_note_list,
                    structureBadge: 'cantidadPlaylists == 0',
                    title: 'No hay playlists creadas',
                    description:
                        'Crea tu primera ListaDobleCircular o carga un archivo CSV para empezar a enlazar nodos dobles circulares.',
                    actionLabel: 'Crear primera playlist',
                    accentColor: accent,
                    onAction: () => _openCreatePlaylistDialog(context),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EDITAR PLAYLIST ACTIVA: ${activa.nombre}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${activa.tamano} nodos · Duración total: ${activa.duracionTotalFormateada} (${activa.duracionTotalLegible})',
                                      style: AppTheme.tabularNumberStyle(
                                        fontSize: 12,
                                        color: AppTheme.pureWhite
                                            .withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GlassIconButton(
                                icon: CupertinoIcons.floppy_disk,
                                tooltip: 'Guardar playlist en CSV',
                                size: 34,
                                iconSize: 16,
                                onPressed: () => _openExportPlaylistCsvSheet(
                                  context,
                                  activa,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GlassIconButton(
                                icon: CupertinoIcons.pencil,
                                tooltip: 'Renombrar playlist',
                                size: 34,
                                iconSize: 16,
                                onPressed: () =>
                                    _openRenamePlaylistDialog(context, activa),
                              ),
                              const SizedBox(width: 4),
                              GlassIconButton(
                                icon: CupertinoIcons.trash,
                                tooltip: 'Eliminar playlist',
                                size: 34,
                                iconSize: 16,
                                iconColor: const Color(0xFFFF7A88),
                                onPressed: () =>
                                    _confirmDeletePlaylist(context, activa),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Cabecera Editorial Liquid Glass: Shuffle + Play + Agregar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassIconButton(
                                icon: CupertinoIcons.shuffle,
                                tooltip: 'Mezclar con Algoritmo Fisher-Yates',
                                size: 42,
                                iconSize: 18,
                                onPressed: () {
                                  if (activa.tamano < 2) {
                                    showEdaToast(
                                      context,
                                      title:
                                          'Se necesitan al menos 2 canciones para mezclar',
                                      accentColor: AppTheme.warningAmber,
                                    );
                                    return;
                                  }
                                  controller.aplicarShuffleFisherYates(
                                    activa.id,
                                  );
                                  showEdaToast(
                                    context,
                                    title:
                                        'Playlist "${activa.nombre}" mezclada con Fisher-Yates',
                                    subtitle:
                                        'Intercambio uniforme in-place sobre nodos dobles.',
                                    icon: CupertinoIcons.shuffle,
                                    accentColor: accent,
                                  );
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (activa.estaVacia) {
                                      _openAddSongFromLibraryModal(
                                        context,
                                        activa,
                                      );
                                      return;
                                    }
                                    controller.reproducirCancionEnPlaylist(
                                      activa.id,
                                      activa.indiceActual ?? 0,
                                    );
                                    controller.selectNavIndex(0);
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.pureWhite
                                          .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppTheme.pureWhite
                                            .withValues(alpha: 0.44),
                                        width: 0.95,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.play_arrow_solid,
                                          size: 18,
                                          color: AppTheme.pureWhite,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Play',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppTheme.pureWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              GlassIconButton(
                                icon: CupertinoIcons.add,
                                tooltip: 'Agregar canción desde la Biblioteca',
                                size: 42,
                                iconSize: 20,
                                onPressed: () => _openAddSongFromLibraryModal(
                                  context,
                                  activa,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Píldoras de operaciones sobre ListaDobleCircular
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _OperationActionChip(
                                icon: CupertinoIcons.add_circled,
                                label: 'Agregar canción',
                                isPrimary: true,
                                onTap: () => _openAddSongFromLibraryModal(
                                  context,
                                  activa,
                                ),
                              ),
                              _OperationActionChip(
                                icon: CupertinoIcons.minus_circle,
                                label: 'Quitar (1ª / Última / Pos)',
                                onTap: () => _openRemoveFromPlaylistModal(
                                  context,
                                  activa,
                                ),
                              ),
                              _OperationActionChip(
                                icon: CupertinoIcons.arrow_up_arrow_down,
                                label: 'Mover posición',
                                onTap: () => _openMoveSongPositionDialog(
                                  context,
                                  activa,
                                ),
                              ),
                              _OperationActionChip(
                                icon: CupertinoIcons.shuffle,
                                label: 'Fisher-Yates',
                                onTap: () {
                                  if (activa.tamano < 2) {
                                    showEdaToast(
                                      context,
                                      title:
                                          'Se necesitan al menos 2 canciones para mezclar',
                                      accentColor: AppTheme.warningAmber,
                                    );
                                    return;
                                  }
                                  controller.aplicarShuffleFisherYates(
                                    activa.id,
                                  );
                                  showEdaToast(
                                    context,
                                    title:
                                        'Playlist "${activa.nombre}" mezclada con Fisher-Yates',
                                    subtitle:
                                        'Intercambio uniforme in-place sobre nodos dobles.',
                                    icon: CupertinoIcons.shuffle,
                                    accentColor: accent,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Listado numerado de Nodos Dobles de la Playlist Activa
                if (activa.estaVacia)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 165),
                      child: EmptyStateView(
                        icon: CupertinoIcons.music_note_list,
                        structureBadge: 'cabeza == nullptr · Playlist vacía',
                        title: 'La playlist "${activa.nombre}" está vacía',
                        description:
                            'Inserta canciones desde la Biblioteca al inicio, al final o en una posición específica.',
                        actionLabel: 'Agregar canción de la Biblioteca',
                        accentColor: accent,
                        onAction: () =>
                            _openAddSongFromLibraryModal(context, activa),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 165),
                    sliver: SliverList.separated(
                      itemCount: activa.tamano,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (ctx, index) {
                        final cancion = activa.canciones[index];
                        final esActual = activa.indiceActual == index;
                        final esCabeza = index == 0;
                        final esCola = index == activa.tamano - 1;
                        final posHumana = index + 1;

                        return GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          borderRadius: 20,
                          isHighlighted: esActual,
                          onTap: () {
                            controller.reproducirCancionEnPlaylist(
                              activa.id,
                              index,
                            );
                            showEdaToast(
                              context,
                              title: 'Cursor actual movido al nodo #$posHumana',
                              subtitle:
                                  '${cancion.titulo} — ${cancion.artista}',
                              accentColor: accent,
                            );
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  esActual ? '> $posHumana' : '  $posHumana.',
                                  style: AppTheme.tabularNumberStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: esActual
                                        ? AppTheme.pureWhite
                                        : AppTheme.pureWhite
                                            .withValues(alpha: 0.66),
                                  ),
                                ),
                              ),
                              SongArtworkThumbnail(
                                cancion: cancion,
                                size: 46,
                                borderRadius: 12,
                                isCurrent: esActual,
                                isPlaying: esActual &&
                                    controller.playbackState.isPlaying,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cancion.titulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${cancion.artista} · ${cancion.genero}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.pureWhite
                                            .withValues(alpha: 0.70),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        if (esActual)
                                          const _PointerBadge(
                                            text: 'actual (sonando)',
                                            isActive: true,
                                          ),
                                        if (esCabeza)
                                          const _PointerBadge(text: 'cabeza'),
                                        if (esCola)
                                          const _PointerBadge(
                                            text: 'cola -> cabeza',
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                cancion.obtenerDuracionFormateada(),
                                style: AppTheme.tabularNumberStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.pureWhite
                                      .withValues(alpha: 0.78),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GlassIconButton(
                                icon: CupertinoIcons.xmark,
                                tooltip: 'Quitar nodo en posición $posHumana',
                                size: 32,
                                iconSize: 14,
                                onPressed: () {
                                  final quitada = controller
                                      .eliminarDePlaylistEnPosicionUnoBased(
                                    activa.id,
                                    posHumana,
                                  );
                                  if (quitada != null) {
                                    showEdaToast(
                                      context,
                                      title:
                                          'Se quitó "${quitada.titulo}" (pos $posHumana)',
                                      subtitle:
                                          'ListaDobleCircular::eliminarEnPosicion(${posHumana - 1})',
                                      icon: CupertinoIcons.minus_circle,
                                      accentColor: AppTheme.dangerRose,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Modales Liquid Glass de Gestión de Playlists ---

  void _openCreatePlaylistDialog(BuildContext context) {
    if (!controller.puedeCrearMasPlaylists) {
      showEdaToast(
        context,
        title: 'Límite de ${MusicRepository.maxPlaylists} playlists alcanzado',
        subtitle: 'Elimina o fusiona una playlist antes de crear otra.',
        accentColor: AppTheme.dangerRose,
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final accent = controller.activePalette.primaryAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear nueva Playlist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 12),
              buildLiquidTextField(
                controller: nameCtrl,
                label: 'Nombre de la playlist',
                helperText:
                    'Se creará una nueva ListaDobleCircular y quedará activa.',
                autofocus: true,
              ),
              const SizedBox(height: 18),
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
                        backgroundColor:
                            AppTheme.pureWhite.withValues(alpha: 0.22),
                        foregroundColor: AppTheme.pureWhite,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        final nombre = nameCtrl.text.trim();
                        if (nombre.isEmpty) {
                          return;
                        }
                        if (controller.existeNombrePlaylist(nombre)) {
                          showEdaToast(
                            context,
                            title: 'Ya existe una playlist con ese nombre',
                            accentColor: AppTheme.dangerRose,
                          );
                          return;
                        }
                        final creada = controller.crearPlaylist(nombre);
                        Navigator.of(ctx).pop();
                        if (creada != null) {
                          showEdaToast(
                            context,
                            title:
                                'Playlist "${creada.nombre}" creada y activada',
                            accentColor: accent,
                          );
                        }
                      },
                      child: const Text('Crear playlist'),
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

  void _openRenamePlaylistDialog(BuildContext context, PlaylistModel pl) {
    final nameCtrl = TextEditingController(text: pl.nombre);
    final accent = controller.activePalette.primaryAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Renombrar "${pl.nombre}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 12),
              buildLiquidTextField(
                controller: nameCtrl,
                label: 'Nuevo nombre',
                autofocus: true,
              ),
              const SizedBox(height: 18),
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
                        backgroundColor:
                            AppTheme.pureWhite.withValues(alpha: 0.22),
                        foregroundColor: AppTheme.pureWhite,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        final nuevo = nameCtrl.text.trim();
                        if (nuevo.isEmpty) {
                          return;
                        }
                        if (controller.existeNombrePlaylist(
                          nuevo,
                          ignorarId: pl.id,
                        )) {
                          showEdaToast(
                            context,
                            title: 'Ya existe otra playlist con ese nombre',
                            accentColor: AppTheme.dangerRose,
                          );
                          return;
                        }
                        controller.renombrarPlaylist(pl.id, nuevo);
                        Navigator.of(ctx).pop();
                        showEdaToast(
                          context,
                          title: 'Playlist renombrada a "$nuevo"',
                          accentColor: accent,
                        );
                      },
                      child: const Text('Guardar nombre'),
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

  void _confirmDeletePlaylist(BuildContext context, PlaylistModel pl) {
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
                'Eliminar Playlist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se eliminará "${pl.nombre}" con sus ${pl.tamano} canciones y se liberarán todos sus nodos dobles (~ListaDobleCircular). ¿Confirmas?',
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
                        controller.eliminarPlaylist(pl.id);
                        Navigator.of(ctx).pop();
                        showEdaToast(
                          context,
                          title: 'Playlist "${pl.nombre}" eliminada',
                          icon: CupertinoIcons.trash,
                          accentColor: AppTheme.dangerRose,
                        );
                      },
                      child: const Text('Eliminar'),
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

  void _openMergePlaylistsDialog(BuildContext context) {
    final playlists = controller.playlists;
    if (playlists.length < 2) {
      showEdaToast(
        context,
        title: 'Necesitas al menos 2 playlists para fusionar',
        subtitle: 'Crea una segunda playlist primero.',
        accentColor: AppTheme.warningAmber,
      );
      return;
    }

    String principalId = playlists.first.id;
    String secundariaId = playlists[1].id;
    bool vaciarSecundaria = false;
    final accent = controller.activePalette.primaryAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return buildLiquidGlassModalContainer(
              context: ctx,
              accentColor: accent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Fusionar dos Playlists (fusionarListas)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Copia todos los nodos de la Playlist Secundaria al final de la Playlist Principal.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.pureWhite.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '1. Playlist PRINCIPAL (recibe las canciones):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: playlists.map((p) {
                      final selected = p.id == principalId;
                      return GestureDetector(
                        onTap: () => setModalState(() => principalId = p.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(
                              alpha: selected ? 0.26 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.pureWhite.withValues(
                                alpha: selected ? 0.55 : 0.18,
                              ),
                            ),
                          ),
                          child: Text(
                            '${p.nombre} (${p.tamano})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '2. Playlist SECUNDARIA (se copian sus canciones):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: playlists.map((p) {
                      final selected = p.id == secundariaId;
                      return GestureDetector(
                        onTap: () => setModalState(() => secundariaId = p.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(
                              alpha: selected ? 0.26 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.pureWhite.withValues(
                                alpha: selected ? 0.55 : 0.18,
                              ),
                            ),
                          ),
                          child: Text(
                            '${p.nombre} (${p.tamano})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.pureWhite,
                    title: const Text(
                      'Vaciar la playlist secundaria después de fusionar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                    subtitle: Text(
                      vaciarSecundaria
                          ? 'La secundaria ejecutará limpiar() y quedará con 0 canciones.'
                          : 'La secundaria conservará sus canciones originales.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.pureWhite.withValues(alpha: 0.65),
                      ),
                    ),
                    value: vaciarSecundaria,
                    onChanged: (v) =>
                        setModalState(() => vaciarSecundaria = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppTheme.pureWhite.withValues(alpha: 0.22),
                        foregroundColor: AppTheme.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (principalId == secundariaId) {
                          showEdaToast(
                            context,
                            title: 'Elige dos playlists distintas',
                            subtitle:
                                'No se puede fusionar una playlist consigo misma.',
                            accentColor: AppTheme.dangerRose,
                          );
                          return;
                        }
                        final ok = controller.fusionarPlaylists(
                          playlistPrincipalId: principalId,
                          playlistSecundariaId: secundariaId,
                          vaciarSecundaria: vaciarSecundaria,
                        );
                        Navigator.of(ctx).pop();
                        if (ok) {
                          showEdaToast(
                            context,
                            title: 'Fusión completada exitosamente',
                            subtitle: vaciarSecundaria
                                ? 'La playlist secundaria quedó vacía.'
                                : 'Canciones anexadas al final de la principal.',
                            icon: CupertinoIcons.arrow_merge,
                            accentColor: accent,
                          );
                        } else {
                          showEdaToast(
                            context,
                            title: 'La playlist secundaria estaba vacía',
                            accentColor: AppTheme.warningAmber,
                          );
                        }
                      },
                      icon: const Icon(CupertinoIcons.arrow_merge, size: 17),
                      label: const Text('Ejecutar Fusión de Listas'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddSongFromLibraryModal(
    BuildContext context,
    PlaylistModel activa,
  ) {
    final bib = controller.biblioteca;
    if (bib.isEmpty) {
      showEdaToast(
        context,
        title: 'La biblioteca está vacía',
        subtitle: 'Agrega canciones primero en la pestaña Biblioteca.',
        accentColor: AppTheme.warningAmber,
      );
      return;
    }

    CancionModel selectedSong = bib.first;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return buildLiquidGlassModalContainer(
              context: ctx,
              accentColor: controller.activePalette.primaryAccent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elegir canción de Biblioteca para "${activa.nombre}"',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: bib.length,
                      itemBuilder: (ctx, i) {
                        final c = bib[i];
                        final selected = c.id == selectedSong.id;
                        return ListTile(
                          dense: true,
                          leading: SongArtworkThumbnail(cancion: c, size: 38),
                          title: Text(
                            '[#${c.id}] ${c.titulo}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                          subtitle: Text(
                            '${c.artista} · ${c.obtenerDuracionFormateada()}',
                            style: TextStyle(
                              color:
                                  AppTheme.pureWhite.withValues(alpha: 0.68),
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  CupertinoIcons.check_mark_circled_solid,
                                  color: AppTheme.pureWhite,
                                )
                              : null,
                          onTap: () => setModalState(() => selectedSong = c),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppTheme.pureWhite.withValues(alpha: 0.22),
                        foregroundColor: AppTheme.pureWhite,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showAddToPlaylistPositionSheet(
                          context,
                          controller: controller,
                          cancion: selectedSong,
                          preselectedPlaylistId: activa.id,
                        );
                      },
                      icon: const Icon(CupertinoIcons.arrow_right, size: 17),
                      label: const Text(
                        'Elegir modo (Inicio / Final / Posición)',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openRemoveFromPlaylistModal(
    BuildContext context,
    PlaylistModel activa,
  ) {
    if (activa.estaVacia) {
      showEdaToast(
        context,
        title: 'La playlist está vacía',
        accentColor: AppTheme.warningAmber,
      );
      return;
    }

    int modo = 0; // 0 = primera, 1 = última, 2 = de una posición
    final posCtrl = TextEditingController(text: '1');
    final accent = controller.activePalette.primaryAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return buildLiquidGlassModalContainer(
              context: ctx,
              accentColor: accent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quitar canción de "${activa.nombre}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RemoveModeOption(
                          label: 'La primera (1)',
                          selected: modo == 0,
                          onTap: () => setModalState(() => modo = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RemoveModeOption(
                          label: 'La última (${activa.tamano})',
                          selected: modo == 1,
                          onTap: () => setModalState(() => modo = 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RemoveModeOption(
                          label: 'Por posición',
                          selected: modo == 2,
                          onTap: () => setModalState(() => modo = 2),
                        ),
                      ),
                    ],
                  ),
                  if (modo == 2) ...[
                    const SizedBox(height: 14),
                    buildLiquidTextField(
                      controller: posCtrl,
                      label: 'Posición a quitar (1 a ${activa.tamano})',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: AppTheme.pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        CancionModel? quitada;
                        if (modo == 0) {
                          quitada = controller.eliminarDePlaylistAlInicio(
                            activa.id,
                          );
                        } else if (modo == 1) {
                          quitada = controller.eliminarDePlaylistAlFinal(
                            activa.id,
                          );
                        } else {
                          final p = int.tryParse(posCtrl.text.trim());
                          if (p == null || p < 1 || p > activa.tamano) {
                            showEdaToast(
                              context,
                              title: 'Posición fuera de rango',
                              subtitle: 'Elige entre 1 y ${activa.tamano}.',
                              accentColor: AppTheme.dangerRose,
                            );
                            return;
                          }
                          quitada =
                              controller.eliminarDePlaylistEnPosicionUnoBased(
                            activa.id,
                            p,
                          );
                        }
                        Navigator.of(ctx).pop();
                        if (quitada != null) {
                          showEdaToast(
                            context,
                            title: 'Se quitó: ${quitada.titulo}',
                            subtitle: 'Nodo liberado con delete.',
                            accentColor: accent,
                          );
                        }
                      },
                      icon: const Icon(CupertinoIcons.trash, size: 17),
                      label: const Text('Quitar de la playlist'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openMoveSongPositionDialog(
    BuildContext context,
    PlaylistModel activa,
  ) {
    if (activa.tamano < 2) {
      showEdaToast(
        context,
        title: 'Se necesitan al menos 2 canciones para mover una',
        accentColor: AppTheme.warningAmber,
      );
      return;
    }

    final origenCtrl = TextEditingController(text: '1');
    final destinoCtrl = TextEditingController(text: '${activa.tamano}');
    final accent = controller.activePalette.primaryAccent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mover canción en "${activa.nombre}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ejecuta GestorReproduccion::moverCancion(lista, origen - 1, destino - 1). Rango: 1 a ${activa.tamano}.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.pureWhite.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 14),
              buildLiquidTextField(
                controller: origenCtrl,
                label: 'Posición de la canción a mover (1 a ${activa.tamano})',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              buildLiquidTextField(
                controller: destinoCtrl,
                label: 'Nueva posición destino (1 a ${activa.tamano})',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
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
                        backgroundColor:
                            AppTheme.pureWhite.withValues(alpha: 0.22),
                        foregroundColor: AppTheme.pureWhite,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        final origen = int.tryParse(origenCtrl.text.trim());
                        final destino = int.tryParse(destinoCtrl.text.trim());
                        if (origen == null ||
                            destino == null ||
                            origen < 1 ||
                            origen > activa.tamano ||
                            destino < 1 ||
                            destino > activa.tamano) {
                          showEdaToast(
                            context,
                            title:
                                'Posición fuera de rango (1..${activa.tamano})',
                            accentColor: AppTheme.dangerRose,
                          );
                          return;
                        }
                        controller.moverCancionEnPlaylistUnoBased(
                          activa.id,
                          origen,
                          destino,
                        );
                        Navigator.of(ctx).pop();
                        showEdaToast(
                          context,
                          title:
                              'Canción movida de la posición $origen a la $destino',
                          accentColor: accent,
                        );
                      },
                      child: const Text('Mover nodo'),
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

  void _openExportPlaylistCsvSheet(
    BuildContext context,
    PlaylistModel pl,
  ) {
    final safeName = pl.nombre
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .toLowerCase();
    showCsvSheet(
      context,
      title: 'CSV de Playlist "${pl.nombre}"',
      suggestedFileName: 'playlist_$safeName.csv',
      initialCsvContent: controller.exportarPlaylistCSV(pl.id),
      accentColor: controller.activePalette.primaryAccent,
      askForPlaylistNameOnImport: true,
      onImportCsv: (csv, targetName) {
        final name = (targetName != null && targetName.isNotEmpty)
            ? targetName
            : '${pl.nombre} (CSV)';
        controller.importarPlaylistCSV(
          nombrePlaylist: name,
          contenidoCSV: csv,
        );
      },
    );
  }

  void _openLoadPlaylistCsvSheet(BuildContext context) {
    const samplePlaylistCsv = '''
id;titulo;artista;duracion_segundos;genero
1;Bohemian Rhapsody;Queen;354;Rock
3;Billie Jean;Michael Jackson;294;Pop
5;Clocks;Coldplay;307;Alternative
''';
    showCsvSheet(
      context,
      title: 'Cargar Playlist desde CSV',
      suggestedFileName: 'playlist_favoritas.csv',
      initialCsvContent: samplePlaylistCsv,
      accentColor: controller.activePalette.primaryAccent,
      askForPlaylistNameOnImport: true,
      onImportCsv: (csv, targetName) {
        final nombre = (targetName != null && targetName.isNotEmpty)
            ? targetName
            : 'Importada CSV ${controller.cantidadPlaylists + 1}';
        final creada = controller.importarPlaylistCSV(
          nombrePlaylist: nombre,
          contenidoCSV: csv,
        );
        if (creada != null) {
          showEdaToast(
            context,
            title:
                'Playlist "${creada.nombre}" cargada (${creada.tamano} canciones)',
            accentColor: controller.activePalette.primaryAccent,
          );
        }
      },
    );
  }

  void _openPlaylistActionsSheet(BuildContext context, PlaylistModel pl) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: controller.activePalette.primaryAccent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  CupertinoIcons.check_mark_circled,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Activar esta playlist',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.seleccionarPlaylistActiva(pl.id);
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.pencil,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Renombrar playlist',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openRenamePlaylistDialog(context, pl);
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.floppy_disk,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Guardar / Ver CSV de esta playlist',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openExportPlaylistCsvSheet(context, pl);
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xFFFF6B7A),
                ),
                title: const Text(
                  'Eliminar playlist',
                  style: TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeletePlaylist(context, pl);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OperationActionChip extends StatelessWidget {
  const _OperationActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite.withValues(alpha: isPrimary ? 0.24 : 0.11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                AppTheme.pureWhite.withValues(alpha: isPrimary ? 0.46 : 0.20),
            width: 0.85,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: AppTheme.pureWhite,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerBadge extends StatelessWidget {
  const _PointerBadge({
    required this.text,
    this.isActive = false,
  });

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite.withValues(alpha: isActive ? 0.26 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.pureWhite,
        ),
      ),
    );
  }
}

class _RemoveModeOption extends StatelessWidget {
  const _RemoveModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite.withValues(alpha: selected ? 0.24 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.pureWhite.withValues(alpha: selected ? 0.55 : 0.18),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.pureWhite,
          ),
        ),
      ),
    );
  }
}

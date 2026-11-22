import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../app/theme/app_theme.dart';
import '../models/cancion.dart';
import '../services/music_player_controller.dart';
import '../widgets/common/empty_state_view.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/song_dialogs.dart';
import '../widgets/player/artwork_header.dart';

/// Vista de la Biblioteca General (`ListaSimple biblioteca` de Andrea y
/// persistencia en `biblioteca.csv`), rediseñada 100% en estilo **Liquid Glass**
/// sobre el lienzo atmosférico difuminado.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.controller,
  });

  final MusicPlayerController controller;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final palette = controller.activePalette;
    final accent = palette.primaryAccent;
    final totalCanciones = controller.biblioteca.length;
    final filtradas = controller.bibliotecaFiltrada;
    final generos = controller.generosDisponibles;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera Hero Liquid Glass de Biblioteca General (ListaSimple)
              Padding(
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
                                child: const Text(
                                  'ListaSimple · biblioteca.csv',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Biblioteca General',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.pureWhite,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalCanciones canciones · Duración total: ${controller.duracionTotalBibliotecaFormateada}',
                                style: AppTheme.tabularNumberStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.pureWhite
                                      .withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón CSV en círculo Liquid Glass
                        GlassIconButton(
                          icon: CupertinoIcons.doc_text,
                          tooltip: 'Exportar o cargar biblioteca.csv',
                          size: 40,
                          iconSize: 18,
                          onPressed: () => _openLibraryCsvSheet(context),
                        ),
                        const SizedBox(width: 8),
                        // Botón + Importar en cápsula Liquid Glass
                        GestureDetector(
                          onTap: () => _openAddOrImportSongSheet(context),
                          behavior: HitTestBehavior.opaque,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                                      'Importar',
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

                    // 2. Buscador en cápsula Liquid Glass
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.pureWhite.withValues(alpha: 0.22),
                              width: 0.85,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: controller.setSearchQuery,
                            style: const TextStyle(
                              color: AppTheme.pureWhite,
                              fontSize: 13.5,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por título, artista, género o ID...',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color:
                                    AppTheme.pureWhite.withValues(alpha: 0.52),
                              ),
                              prefixIcon: Icon(
                                CupertinoIcons.search,
                                color:
                                    AppTheme.pureWhite.withValues(alpha: 0.76),
                                size: 18,
                              ),
                              suffixIcon: controller.searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        controller.setSearchQuery('');
                                      },
                                      icon: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 17,
                                        color: AppTheme.pureWhite
                                            .withValues(alpha: 0.70),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Píldoras de filtro por género en Liquid Glass
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: generos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx, index) {
                          final genero = generos[index];
                          final selected =
                              controller.selectedGenreFilter == genero;
                          return GestureDetector(
                            onTap: () => controller.setGenreFilter(genero),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.pureWhite.withValues(
                                  alpha: selected ? 0.26 : 0.09,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.pureWhite.withValues(
                                    alpha: selected ? 0.52 : 0.18,
                                  ),
                                  width: 0.85,
                                ),
                              ),
                              child: Text(
                                genero,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppTheme.pureWhite.withValues(
                                    alpha: selected ? 1.0 : 0.74,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Listado de Nodos de ListaSimple en Tarjetas Liquid Glass
              Expanded(
                child: filtradas.isEmpty
                    ? EmptyStateView(
                        icon: CupertinoIcons.music_albums,
                        structureBadge: 'ListaSimple · cabeza == nullptr',
                        title: totalCanciones == 0
                            ? 'La biblioteca está vacía'
                            : 'Sin coincidencias para tu filtro',
                        description: totalCanciones == 0
                            ? 'Importa archivos de audio desde tu dispositivo con el botón + o restaura las canciones semilla de biblioteca.csv.'
                            : 'Prueba con otro término de búsqueda o selecciona la categoría "Todos".',
                        actionLabel: totalCanciones == 0
                            ? 'Importar canción'
                            : 'Limpiar filtros',
                        accentColor: accent,
                        onAction: () {
                          if (totalCanciones == 0) {
                            _openAddOrImportSongSheet(context);
                          } else {
                            _searchController.clear();
                            controller.setSearchQuery('');
                            controller.setGenreFilter('Todos');
                          }
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 165),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final cancion = filtradas[index];
                          final esActual =
                              controller.cancionActual?.id == cancion.id;
                          final songPalette = AppTheme.paletteForSong(
                            id: cancion.id,
                            genero: cancion.genero,
                          );

                          return GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 22,
                            isHighlighted: esActual,
                            onTap: () {
                              controller.reproducirCancionDirecta(cancion);
                              showEdaToast(
                                context,
                                title: 'Reproduciendo: ${cancion.titulo}',
                                subtitle:
                                    '${cancion.artista} (${cancion.obtenerDuracionFormateada()})',
                                icon: CupertinoIcons.play_circle_fill,
                                accentColor: songPalette.primaryAccent,
                              );
                            },
                            child: Row(
                              children: [
                                SongArtworkThumbnail(
                                  cancion: cancion,
                                  size: 50,
                                  borderRadius: 14,
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.pureWhite
                                                  .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '#${cancion.id}',
                                              style:
                                                  AppTheme.tabularNumberStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 7),
                                          Expanded(
                                            child: Text(
                                              cancion.titulo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.pureWhite,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cancion.artista,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.pureWhite
                                              .withValues(alpha: 0.72),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.pureWhite
                                                  .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              cancion.genero,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.pureWhite
                                                    .withValues(alpha: 0.88),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            CupertinoIcons.clock,
                                            size: 12,
                                            color: AppTheme.pureWhite
                                                .withValues(alpha: 0.62),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cancion.obtenerDuracionFormateada(),
                                            style: AppTheme.tabularNumberStyle(
                                              fontSize: 12,
                                              color: AppTheme.pureWhite
                                                  .withValues(alpha: 0.76),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GlassIconButton(
                                  icon: CupertinoIcons.plus,
                                  tooltip: 'Agregar a una playlist',
                                  size: 34,
                                  iconSize: 16,
                                  onPressed: () =>
                                      showAddToPlaylistPositionSheet(
                                    context,
                                    controller: controller,
                                    cancion: cancion,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GlassIconButton(
                                  icon: CupertinoIcons.ellipsis,
                                  tooltip: 'Acciones del nodo',
                                  size: 34,
                                  iconSize: 16,
                                  onPressed: () => _showSongActionsModal(
                                    context,
                                    cancion,
                                    songPalette,
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
      ),
    );
  }

  void _showSongActionsModal(
    BuildContext context,
    CancionModel cancion,
    SongVisualPalette songPalette,
  ) {
    final controller = widget.controller;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return buildLiquidGlassModalContainer(
          context: ctx,
          accentColor: songPalette.primaryAccent,
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
              ListTile(
                leading: const Icon(
                  CupertinoIcons.play_arrow_solid,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Reproducir ahora',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.reproducirCancionDirecta(cancion);
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.plus_square_on_square,
                  color: AppTheme.pureWhite,
                ),
                title: const Text(
                  'Insertar en una playlist (Inicio / Final / Posición)...',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
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
                onTap: () {
                  Navigator.of(ctx).pop();
                  showSongNodeInspectorSheet(
                    context,
                    cancion: cancion,
                    palette: songPalette,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xFFFF6B7A),
                ),
                title: const Text(
                  'Eliminar de la Biblioteca por ID',
                  style: TextStyle(
                    color: Color(0xFFFF6B7A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteFromLibrary(context, cancion);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteFromLibrary(BuildContext context, CancionModel cancion) {
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
                'Eliminar canción de la Biblioteca',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Se ejecutará ListaSimple::eliminarPorId(${cancion.id}) para "${cancion.titulo}" (${cancion.artista}).\n\nLas playlists que ya contenían esta canción conservarán su copia del nodo (comportamiento exacto de ui.cpp).',
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
                        widget.controller
                            .eliminarCancionDeBiblioteca(cancion.id);
                        Navigator.of(ctx).pop();
                        showEdaToast(
                          context,
                          title:
                              'Nodo #${cancion.id} eliminado de la Biblioteca',
                          subtitle: cancion.titulo,
                          icon: CupertinoIcons.trash,
                          accentColor: AppTheme.dangerRose,
                        );
                      },
                      child: const Text('Confirmar eliminación'),
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

  void _openLibraryCsvSheet(BuildContext context) {
    final controller = widget.controller;
    showCsvSheet(
      context,
      title: 'Persistencia biblioteca.csv',
      suggestedFileName: 'biblioteca.csv',
      initialCsvContent: controller.exportarBibliotecaCSV(),
      accentColor: controller.activePalette.primaryAccent,
      onImportCsv: (csvText, _) {
        final count = controller.importarBibliotecaCSV(csvText);
        showEdaToast(
          context,
          title: 'Se cargaron $count canciones desde CSV',
          subtitle: 'ListaSimple::cargarDesdeCSV ejecutado con éxito.',
          accentColor: controller.activePalette.primaryAccent,
        );
      },
    );
  }

  void _openAddOrImportSongSheet(BuildContext context) {
    final controller = widget.controller;
    final accent = controller.activePalette.primaryAccent;

    bool tabImportFile = true;
    final idController = TextEditingController(
      text: controller.siguienteIdLibre.toString(),
    );
    final pathController = TextEditingController(
      text: '/storage/emulated/0/Music/Gustavo Cerati - Puente.flac',
    );
    final titleController = TextEditingController(text: 'Puente');
    final artistController = TextEditingController(text: 'Gustavo Cerati');
    final durationController = TextEditingController(text: '4:03');
    final genreController = TextEditingController(text: 'Rock Alternativo');

    const deviceAudioFiles = [
      (
        path: '/storage/emulated/0/Music/Gustavo Cerati - Puente.flac',
        title: 'Puente',
        artist: 'Gustavo Cerati',
        duration: '4:03',
        genre: 'Rock Alternativo',
      ),
      (
        path: '/storage/emulated/0/Music/The Strokes - Reptilia.mp3',
        title: 'Reptilia',
        artist: 'The Strokes',
        duration: '3:41',
        genre: 'Indie Rock',
      ),
      (
        path: '/storage/emulated/0/Music/Daft Punk - Instant Crush.flac',
        title: 'Instant Crush',
        artist: 'Daft Punk',
        duration: '5:37',
        genre: 'Synth Pop',
      ),
      (
        path:
            '/storage/emulated/0/Music/Charly Garcia - Nos Siguen Pegando Abajo.mp3',
        title: 'Nos Siguen Pegando Abajo',
        artist: 'Charly García',
        duration: '3:25',
        genre: 'Rock Argentino',
      ),
    ];

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
              child: SingleChildScrollView(
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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Agregar a Biblioteca',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.pureWhite.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ModeTabPill(
                                label: 'Archivo Audio',
                                selected: tabImportFile,
                                onTap: () =>
                                    setModalState(() => tabImportFile = true),
                              ),
                              _ModeTabPill(
                                label: 'Manual TAD',
                                selected: !tabImportFile,
                                onTap: () =>
                                    setModalState(() => tabImportFile = false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (tabImportFile) ...[
                      Text(
                        'Archivos detectados en almacenamiento local (toca para extraer metadata):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureWhite.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: deviceAudioFiles.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final preset = deviceAudioFiles[i];
                            final isSelected =
                                pathController.text == preset.path;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  pathController.text = preset.path;
                                  titleController.text = preset.title;
                                  artistController.text = preset.artist;
                                  durationController.text = preset.duration;
                                  genreController.text = preset.genre;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.pureWhite.withValues(
                                    alpha: isSelected ? 0.26 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppTheme.pureWhite.withValues(
                                      alpha: isSelected ? 0.52 : 0.18,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${preset.artist} - ${preset.title}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildLiquidTextField(
                        controller: pathController,
                        label: 'Ruta del archivo local (rutaArchivo)',
                        prefixIcon: CupertinoIcons.folder,
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      buildLiquidTextField(
                        controller: idController,
                        label:
                            'ID numérico único (sugerido: ${controller.siguienteIdLibre})',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: buildLiquidTextField(
                            controller: titleController,
                            label: 'Título',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildLiquidTextField(
                            controller: artistController,
                            label: 'Artista',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: buildLiquidTextField(
                            controller: durationController,
                            label: 'Duración (seg o m:ss)',
                            helperText: 'Ej: 225 o 3:45 (ui.cpp)',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildLiquidTextField(
                            controller: genreController,
                            label: 'Género',
                            helperText: 'Enter = Sin genero',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                          final durSeg = _parsearDuracionComoUiCpp(
                            durationController.text.trim(),
                          );
                          if (durSeg == null || durSeg <= 0) {
                            showEdaToast(
                              context,
                              title: 'Duración no válida',
                              subtitle:
                                  'Usa segundos (ej. 225) o m:ss (ej. 3:45).',
                              icon: CupertinoIcons.exclamationmark_triangle,
                              accentColor: AppTheme.dangerRose,
                            );
                            return;
                          }

                          final titulo = titleController.text.trim();
                          final artista = artistController.text.trim();
                          if (titulo.isEmpty || artista.isEmpty) {
                            showEdaToast(
                              context,
                              title: 'Completa Título y Artista',
                              icon: CupertinoIcons.exclamationmark_triangle,
                              accentColor: AppTheme.dangerRose,
                            );
                            return;
                          }

                          CancionModel creada;
                          if (tabImportFile) {
                            creada = controller.importarArchivoAudio(
                              rutaArchivo: pathController.text.trim(),
                              tituloOverride: titulo,
                              artistaOverride: artista,
                              duracionSegundosOverride: durSeg,
                              generoOverride: genreController.text.trim(),
                            );
                          } else {
                            final id = int.tryParse(idController.text.trim());
                            if (id == null || id <= 0) {
                              showEdaToast(
                                context,
                                title: 'ID inválido',
                                subtitle: 'Escribe un entero mayor a 0.',
                                accentColor: AppTheme.dangerRose,
                              );
                              return;
                            }
                            final existente = controller.buscarPorId(id);
                            if (existente != null) {
                              showEdaToast(
                                context,
                                title: 'El ID #$id ya está ocupado',
                                subtitle:
                                    'Usado por: ${existente.titulo} (${existente.artista})',
                                accentColor: AppTheme.dangerRose,
                              );
                              return;
                            }
                            creada = controller.agregarCancion(
                              id: id,
                              titulo: titulo,
                              artista: artista,
                              duracionSegundos: durSeg,
                              genero: genreController.text.trim().isEmpty
                                  ? 'Sin genero'
                                  : genreController.text.trim(),
                            );
                          }

                          Navigator.of(ctx).pop();
                          showEdaToast(
                            context,
                            title: 'Canción agregada al final de ListaSimple',
                            subtitle:
                                '[#${creada.id}] ${creada.titulo} - ${creada.artista} (${creada.obtenerDuracionFormateada()})',
                            accentColor: accent,
                          );
                        },
                        icon: const Icon(CupertinoIcons.add_circled, size: 18),
                        label: Text(
                          tabImportFile
                              ? 'Importar archivo y agregar nodo'
                              : 'Agregar nodo a Biblioteca',
                        ),
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

  int? _parsearDuracionComoUiCpp(String texto) {
    if (texto.isEmpty) {
      return null;
    }
    if (!texto.contains(':')) {
      return int.tryParse(texto);
    }
    final partes = texto.split(':');
    if (partes.length != 2) {
      return null;
    }
    final min = int.tryParse(partes[0].trim());
    final seg = int.tryParse(partes[1].trim());
    if (min == null || seg == null || min < 0 || seg < 0 || seg >= 60) {
      return null;
    }
    return min * 60 + seg;
  }
}

class _ModeTabPill extends StatelessWidget {
  const _ModeTabPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.pureWhite.withValues(alpha: 0.24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.pureWhite
                .withValues(alpha: selected ? 1.0 : 0.68),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../models/cancion.dart';
import '../../services/music_player_controller.dart';
import '../player/artwork_header.dart';
import 'glass_card.dart';

/// Contenedor base para hojas modales en **Liquid Glass** (reemplaza los
/// diálogos y bottom sheets blancos de Material Design en toda la app).
Widget buildLiquidGlassModalContainer({
  required BuildContext context,
  required Widget child,
  Color? accentColor,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(22, 14, 22, 24),
}) {
  final accent = accentColor ?? AppTheme.defaultAccent;
  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Center(
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF141B28).withValues(alpha: 0.90),
                      const Color(0xFF0D121C).withValues(alpha: 0.94),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.pureWhite.withValues(alpha: 0.24),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Campo de texto estilizado en **Liquid Glass** (sin `OutlineInputBorder` de Material).
Widget buildLiquidTextField({
  required TextEditingController controller,
  required String label,
  String? helperText,
  IconData? prefixIcon,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool readOnly = false,
  bool autofocus = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.pureWhite.withValues(alpha: 0.78),
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.pureWhite.withValues(alpha: 0.22),
            width: 0.85,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          autofocus: autofocus,
          style: AppTheme.tabularNumberStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.pureWhite,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 18,
                    color: AppTheme.pureWhite.withValues(alpha: 0.70),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ),
      if (helperText != null && helperText.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          helperText,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.pureWhite.withValues(alpha: 0.54),
          ),
        ),
      ],
    ],
  );
}

/// Inspector del Nodo TAD `Cancion` en Liquid Glass.
void showSongNodeInspectorSheet(
  BuildContext context, {
  required CancionModel cancion,
  required SongVisualPalette palette,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return buildLiquidGlassModalContainer(
        context: ctx,
        accentColor: palette.primaryAccent,
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
            const SizedBox(height: 18),
            Row(
              children: [
                SongArtworkThumbnail(
                  cancion: cancion,
                  size: 56,
                  borderRadius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.pureWhite.withValues(alpha: 0.24),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'TAD Cancion · Nodo ID #${cancion.id}',
                          style: AppTheme.tabularNumberStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cancion.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                      Text(
                        cancion.artista,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.pureWhite.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(
              height: 1,
              color: AppTheme.pureWhite.withValues(alpha: 0.14),
            ),
            const SizedBox(height: 14),
            _InspectorDetailRow(
              label: 'Duración (duracionSegundos)',
              value:
                  '${cancion.duracionSegundos} s (${cancion.obtenerDuracionFormateada()})',
              isTabular: true,
            ),
            _InspectorDetailRow(
              label: 'Género (genero)',
              value: cancion.genero,
            ),
            _InspectorDetailRow(
              label: 'Ruta de archivo (backend)',
              value: cancion.rutaArchivo ?? 'Pendiente de enlace local',
            ),
            _InspectorDetailRow(
              label: 'Portada desde metadata',
              value: cancion.tienePortadaMetadata
                  ? 'Extraída del archivo de audio'
                  : 'Pendiente de extracción ID3/APIC',
            ),
            const SizedBox(height: 10),
            Text(
              'Serialización Cancion::aCSV(\';\')',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.pureWhite.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.pureWhite.withValues(alpha: 0.18),
                ),
              ),
              child: SelectableText(
                cancion.aCSV(),
                style: AppTheme.tabularNumberStyle(
                  fontSize: 12.5,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.pureWhite.withValues(alpha: 0.20),
                  foregroundColor: AppTheme.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(CupertinoIcons.check_mark, size: 17),
                label: const Text('Cerrar inspector'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _InspectorDetailRow extends StatelessWidget {
  const _InspectorDetailRow({
    required this.label,
    required this.value,
    this.isTabular = false,
  });

  final String label;
  final String value;
  final bool isTabular;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.pureWhite.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isTabular
                  ? AppTheme.tabularNumberStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    )
                  : const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.pureWhite,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja modal en Liquid Glass para insertar una canción en una `ListaDobleCircular`
/// (Al inicio, Al final o En una posición `1..N+1`).
void showAddToPlaylistPositionSheet(
  BuildContext context, {
  required MusicPlayerController controller,
  required CancionModel cancion,
  String? preselectedPlaylistId,
}) {
  final playlists = controller.playlists;
  if (playlists.isEmpty) {
    showEdaToast(
      context,
      title: 'No hay playlists creadas',
      subtitle: 'Crea una playlist primero en la pestaña Playlists.',
      icon: CupertinoIcons.info,
      accentColor: AppTheme.warningAmber,
    );
    return;
  }

  String selectedPlaylistId = preselectedPlaylistId ??
      controller.playlistActiva?.id ??
      playlists.first.id;
  int modoInsercion = 1; // 0 = inicio, 1 = final, 2 = en posición
  final posController = TextEditingController(text: '1');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final targetPlaylist = playlists.firstWhere(
            (p) => p.id == selectedPlaylistId,
            orElse: () => playlists.first,
          );
          final maxPos = targetPlaylist.tamano + 1;
          final accent = controller.activePalette.primaryAccent;

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
                const SizedBox(height: 16),
                const Text(
                  'Insertar Nodo en ListaDobleCircular',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cancion.titulo} — ${cancion.artista}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.pureWhite.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Playlist destino',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: playlists.map((pl) {
                    final selected = pl.id == selectedPlaylistId;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedPlaylistId = pl.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withValues(
                            alpha: selected ? 0.26 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.pureWhite.withValues(
                              alpha: selected ? 0.55 : 0.20,
                            ),
                          ),
                        ),
                        child: Text(
                          '${pl.nombre} (${pl.tamano})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Operación de punteros (NodoDoble*)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InsertionModeTile(
                        title: 'Al inicio',
                        subtitle: 'Nueva cabeza (1)',
                        icon: CupertinoIcons.arrow_up_to_line,
                        selected: modoInsercion == 0,
                        onTap: () => setModalState(() => modoInsercion = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InsertionModeTile(
                        title: 'Al final',
                        subtitle: 'Nueva cola ($maxPos)',
                        icon: CupertinoIcons.arrow_down_to_line,
                        selected: modoInsercion == 1,
                        onTap: () => setModalState(() => modoInsercion = 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InsertionModeTile(
                        title: 'En posición',
                        subtitle: 'Rango 1..$maxPos',
                        icon: CupertinoIcons.number,
                        selected: modoInsercion == 2,
                        onTap: () => setModalState(() => modoInsercion = 2),
                      ),
                    ),
                  ],
                ),
                if (modoInsercion == 2) ...[
                  const SizedBox(height: 14),
                  buildLiquidTextField(
                    controller: posController,
                    label: 'Posición donde quedará (1 a $maxPos)',
                    helperText:
                        'En ui.cpp se pide 1..$maxPos y se invoca insertarEnPosicion(pos - 1)',
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 20),
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
                      bool ok = false;
                      String detalle = '';
                      if (modoInsercion == 0) {
                        ok = controller.insertarEnPlaylistAlInicio(
                          targetPlaylist.id,
                          cancion,
                        );
                        detalle =
                            'Insertada al inicio (cabeza) de ${targetPlaylist.nombre}';
                      } else if (modoInsercion == 1) {
                        ok = controller.insertarEnPlaylistAlFinal(
                          targetPlaylist.id,
                          cancion,
                        );
                        detalle =
                            'Insertada al final (cola) de ${targetPlaylist.nombre}';
                      } else {
                        final pos = int.tryParse(posController.text.trim());
                        if (pos == null || pos < 1 || pos > maxPos) {
                          showEdaToast(
                            context,
                            title: 'Posición fuera de rango',
                            subtitle: 'Escribe un número entre 1 y $maxPos.',
                            icon: CupertinoIcons.exclamationmark_triangle,
                            accentColor: AppTheme.dangerRose,
                          );
                          return;
                        }
                        ok = controller.insertarEnPlaylistEnPosicionUnoBased(
                          targetPlaylist.id,
                          cancion,
                          pos,
                        );
                        detalle =
                            'Insertada en la posición $pos de ${targetPlaylist.nombre}';
                      }

                      Navigator.of(ctx).pop();
                      if (ok) {
                        showEdaToast(
                          context,
                          title: cancion.titulo,
                          subtitle: detalle,
                          accentColor: accent,
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.add_circled, size: 18),
                    label: const Text('Confirmar inserción en lista'),
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

class _InsertionModeTile extends StatelessWidget {
  const _InsertionModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite.withValues(alpha: selected ? 0.24 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.pureWhite.withValues(alpha: selected ? 0.55 : 0.18),
            width: selected ? 1.2 : 0.85,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 19,
              color: AppTheme.pureWhite
                  .withValues(alpha: selected ? 1.0 : 0.68),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.pureWhite
                    .withValues(alpha: selected ? 1.0 : 0.85),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: AppTheme.pureWhite.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Liquid Glass para exportar o importar archivos CSV (`id;titulo;artista;duracion_segundos;genero`).
void showCsvSheet(
  BuildContext context, {
  required String title,
  required String suggestedFileName,
  required String initialCsvContent,
  required Color accentColor,
  required void Function(String csvContent, String? targetName) onImportCsv,
  bool askForPlaylistNameOnImport = false,
}) {
  final csvController = TextEditingController(text: initialCsvContent);
  final nameController = TextEditingController(
    text: suggestedFileName.replaceAll('.csv', ''),
  );
  bool isImportMode = false;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return buildLiquidGlassModalContainer(
            context: ctx,
            accentColor: accentColor,
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ),
                    // Selector tipo cápsula Liquid Glass
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
                          _LiquidSegmentTab(
                            label: 'Exportar',
                            selected: !isImportMode,
                            onTap: () =>
                                setModalState(() => isImportMode = false),
                          ),
                          _LiquidSegmentTab(
                            label: 'Cargar CSV',
                            selected: isImportMode,
                            onTap: () =>
                                setModalState(() => isImportMode = true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Archivo: $suggestedFileName · Delimitador estricto ";"',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.pureWhite.withValues(alpha: 0.68),
                  ),
                ),
                if (isImportMode && askForPlaylistNameOnImport) ...[
                  const SizedBox(height: 12),
                  buildLiquidTextField(
                    controller: nameController,
                    label: 'Nombre para la playlist cargada',
                  ),
                ],
                const SizedBox(height: 12),
                buildLiquidTextField(
                  controller: csvController,
                  label: isImportMode
                      ? 'Pega o edita las líneas CSV (id;titulo;artista;duracion_segundos;genero)'
                      : 'Contenido generado por Cancion::aCSV(\';\')',
                  maxLines: 6,
                  readOnly: !isImportMode,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.pureWhite,
                          side: BorderSide(
                            color: AppTheme.pureWhite.withValues(alpha: 0.28),
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: csvController.text),
                          );
                          showEdaToast(
                            context,
                            title: 'CSV copiado al portapapeles',
                            subtitle: suggestedFileName,
                            accentColor: accentColor,
                          );
                        },
                        icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
                        label: const Text('Copiar CSV'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppTheme.pureWhite.withValues(alpha: 0.22),
                          foregroundColor: AppTheme.pureWhite,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (isImportMode) {
                            onImportCsv(
                              csvController.text,
                              nameController.text.trim(),
                            );
                          } else {
                            showEdaToast(
                              context,
                              title: 'CSV sincronizado ($suggestedFileName)',
                              subtitle:
                                  'Formato compatible con ListaSimple::guardarEnCSV',
                              accentColor: accentColor,
                            );
                          }
                          Navigator.of(ctx).pop();
                        },
                        icon: Icon(
                          isImportMode
                              ? CupertinoIcons.tray_arrow_down
                              : CupertinoIcons.floppy_disk,
                          size: 16,
                        ),
                        label: Text(
                          isImportMode
                              ? 'Cargar nodos CSV'
                              : 'Guardar $suggestedFileName',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _LiquidSegmentTab extends StatelessWidget {
  const _LiquidSegmentTab({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.pureWhite.withValues(alpha: 0.24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.pureWhite
                .withValues(alpha: selected ? 1.0 : 0.68),
          ),
        ),
      ),
    );
  }
}

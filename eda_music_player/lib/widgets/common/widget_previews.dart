import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import '../../models/cancion.dart';
import '../layout/mini_player_bar.dart';
import '../player/custom_progress_bar.dart';
import 'empty_state_view.dart';

/// Previsualizaciones interactivas de widgets usando la skill
/// `flutter-add-widget-preview` (`package:flutter/widget_previews.dart`).
@Preview(
  name: 'Custom Progress Bar - Bohemian Rhapsody',
  group: 'Player Controls',
  size: Size(360, 80),
)
Widget previewCustomProgressBar() {
  final palette = AppTheme.paletteForSong(id: 1, genero: 'Rock');
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: palette.ambientSurface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomProgressBar(
            progress: 0.38,
            elapsedText: '1:21',
            remainingText: '-2:06',
            totalDurationText: '5:54',
            accentColor: palette.primaryAccent,
            secondaryAccentColor: palette.secondaryAccent,
            onSeekNormalized: (_) {},
          ),
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Mini Player Glass Bar',
  group: 'Navigation & Layout',
  size: Size(375, 100),
)
Widget previewMiniPlayerBar() {
  final palette = AppTheme.paletteForSong(id: 2, genero: 'Rock Latino');
  const song = CancionModel(
    id: 2,
    titulo: 'De Música Ligera',
    artista: 'Soda Stereo',
    duracionSegundos: 212,
    genero: 'Rock Latino',
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: palette.ambientSurface,
      body: Center(
        child: MiniPlayerBar(
          cancion: song,
          contextName: 'Esenciales EDA',
          isPlaying: true,
          progress: 0.45,
          accentColor: palette.primaryAccent,
          onTapExpand: () {},
          onPlayPause: () {},
          onNext: () {},
        ),
      ),
    ),
  );
}

@Preview(
  name: 'Empty State - ListaSimple',
  group: 'Common States',
  size: Size(375, 380),
)
Widget previewEmptyState() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: EmptyStateView(
        icon: Icons.library_music_outlined,
        structureBadge: 'ListaSimple · cabeza == nullptr',
        title: 'La biblioteca está vacía',
        description:
            'Importa archivos de audio o carga biblioteca.csv para enlazar nodos.',
      ),
    ),
  );
}

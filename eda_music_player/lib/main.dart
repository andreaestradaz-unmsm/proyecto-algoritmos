import 'package:material_ui/material_ui.dart';

import 'app/theme/app_theme.dart';
import 'screens/main_shell_screen.dart';
import 'services/cpp_music_repository.dart';
import 'services/mock_music_repository.dart';
import 'services/music_player_controller.dart';
import 'services/music_repository.dart';

void main() {
  runApp(EdaMusicPlayerApp(
    repository: CppMusicRepository(), // Reemplaza a MockMusicRepository()
  ));
}

/// Aplicación principal del Reproductor de Música con Listas de Reproducción
/// (UNMSM - Algoritmos y Estructuras de Datos CC0401).
///
/// Recibe un [MusicRepository] desacoplado. Por defecto utiliza
/// [MockMusicRepository] (implementación funcional completa en memoria),
/// permitiendo al equipo de backend inyectar su futuro `CppMusicRepository`
/// en una sola línea sin modificar ninguna pantalla ni widget.
class EdaMusicPlayerApp extends StatefulWidget {
  const EdaMusicPlayerApp({
    super.key,
    this.repository,
    this.enableAutoTicker = true,
  });

  final MusicRepository? repository;
  final bool enableAutoTicker;

  @override
  State<EdaMusicPlayerApp> createState() => _EdaMusicPlayerAppState();
}

class _EdaMusicPlayerAppState extends State<EdaMusicPlayerApp> {
  late final MusicPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MusicPlayerController(
      repository: widget.repository ?? MockMusicRepository(),
      enableAutoTicker: widget.enableAutoTicker,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    final repo = widget.repository;
    if (repo is CppMusicRepository) {
      repo.dispose(); // bridge_shutdown(): libera TADs y motor de audio
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final palette = _controller.activePalette;
        return MaterialApp(
          title: 'EDA Music Player · UNMSM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(palette),
          home: MainShellScreen(controller: _controller),
        );
      },
    );
  }
}
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app/theme/app_theme.dart';
import '../models/cancion.dart';
import '../models/historial_item.dart';
import '../models/modo_repeticion.dart';
import '../models/playback_state.dart';
import '../models/playlist.dart';
import 'music_repository.dart';

/// Controlador central reactivo de la aplicación Flutter (`ChangeNotifier`).
///
/// Se comunica exclusivamente con la interfaz `MusicRepository` para que las
/// pantallas y widgets jamás dependan de si los datos provienen del mock en
/// memoria o del adaptador C++ real.
class MusicPlayerController extends ChangeNotifier {
  MusicPlayerController({
    required this.repository,
    this.enableAutoTicker = true,
  }) {
    if (enableAutoTicker) {
      _iniciarTickerProgreso();
    }
  }

  final MusicRepository repository;
  final bool enableAutoTicker;

  MusicRepository get _repository => repository;

  Timer? _ticker;
  int _selectedNavIndex = 0;
  String _searchQuery = '';
  String _selectedGenreFilter = 'Todos';

  // --- Navegación principal ---
  int get selectedNavIndex => _selectedNavIndex;

  void selectNavIndex(int index) {
    if (_selectedNavIndex == index) {
      return;
    }
    _selectedNavIndex = index;
    notifyListeners();
  }

  // --- Estado de Reproducción y Paleta Visual Dinámica ---
  PlaybackStateModel get playbackState =>
      _repository.obtenerEstadoReproduccion();

  CancionModel? get cancionActual => playbackState.cancionActual;

  SongVisualPalette get activePalette {
    final actual = cancionActual;
    if (actual == null) {
      return AppTheme.paletteForSong(id: 1, genero: 'Rock');
    }
    return AppTheme.paletteForSong(id: actual.id, genero: actual.genero);
  }

  // --- Biblioteca General (ListaSimple) ---
  List<CancionModel> get biblioteca => _repository.obtenerBiblioteca();

  int get duracionTotalBibliotecaSegundos =>
      _repository.calcularDuracionTotalBibliotecaSegundos();

  String get duracionTotalBibliotecaFormateada =>
      PlaylistModel.formatearDuracionTotal(duracionTotalBibliotecaSegundos);

  int get siguienteIdLibre => _repository.siguienteIdLibreBiblioteca();

  String get searchQuery => _searchQuery;

  String get selectedGenreFilter => _selectedGenreFilter;

  List<String> get generosDisponibles {
    final setGeneros = <String>{'Todos'};
    for (final c in biblioteca) {
      if (c.genero.trim().isNotEmpty) {
        setGeneros.add(c.genero.trim());
      }
    }
    return setGeneros.toList();
  }

  List<CancionModel> get bibliotecaFiltrada {
    final q = _searchQuery.trim().toLowerCase();
    return biblioteca.where((c) {
      final coincideGenero = _selectedGenreFilter == 'Todos' ||
          c.genero.toLowerCase() == _selectedGenreFilter.toLowerCase();
      if (!coincideGenero) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      return c.titulo.toLowerCase().contains(q) ||
          c.artista.toLowerCase().contains(q) ||
          c.genero.toLowerCase().contains(q) ||
          c.id.toString() == q;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setGenreFilter(String genre) {
    _selectedGenreFilter = genre;
    notifyListeners();
  }

  CancionModel? buscarPorId(int id) => _repository.buscarCancionPorId(id);

  CancionModel agregarCancion({
    required int id,
    required String titulo,
    required String artista,
    required int duracionSegundos,
    required String genero,
    String? rutaArchivo,
    bool esArchivoLocal = false,
  }) {
    final creada = _repository.agregarCancionABiblioteca(
      id: id,
      titulo: titulo,
      artista: artista,
      duracionSegundos: duracionSegundos,
      genero: genero,
      rutaArchivo: rutaArchivo,
      esArchivoLocal: esArchivoLocal,
      metadataExtraida: rutaArchivo != null,
    );
    notifyListeners();
    return creada;
  }

  CancionModel importarArchivoAudio({
    required String rutaArchivo,
    String? tituloOverride,
    String? artistaOverride,
    int? duracionSegundosOverride,
    String? generoOverride,
    int? tamanoBytes,
  }) {
    final importada = _repository.importarArchivoAudio(
      rutaArchivo: rutaArchivo,
      tituloOverride: tituloOverride,
      artistaOverride: artistaOverride,
      duracionSegundosOverride: duracionSegundosOverride,
      generoOverride: generoOverride,
      tamanoBytes: tamanoBytes,
    );
    notifyListeners();
    return importada;
  }

  bool eliminarCancionDeBiblioteca(int id) {
    final ok = _repository.eliminarCancionDeBibliotecaPorId(id);
    if (ok) {
      if (!generosDisponibles.contains(_selectedGenreFilter)) {
        _selectedGenreFilter = 'Todos';
      }
      notifyListeners();
    }
    return ok;
  }

  void toggleFavorito(int cancionId) {
    _repository.toggleFavoritoCancion(cancionId);
    notifyListeners();
  }

  String exportarBibliotecaCSV({bool incluirExtendidos = false}) =>
      _repository.exportarBibliotecaCSV(
        incluirCamposExtendidos: incluirExtendidos,
      );

  int importarBibliotecaCSV(
    String contenidoCSV, {
    bool reemplazarExistente = false,
  }) {
    final cargadas = _repository.importarBibliotecaDesdeCSV(
      contenidoCSV,
      reemplazarExistente: reemplazarExistente,
    );
    notifyListeners();
    return cargadas;
  }

  // --- Playlists (ListaDobleCircular & GestorReproduccion) ---
  List<PlaylistModel> get playlists => _repository.obtenerPlaylists();

  PlaylistModel? get playlistActiva => _repository.obtenerPlaylistActiva();

  int get cantidadPlaylists => playlists.length;

  bool get puedeCrearMasPlaylists =>
      cantidadPlaylists < MusicRepository.maxPlaylists;

  bool existeNombrePlaylist(String nombre, {String? ignorarId}) =>
      _repository.existeNombrePlaylist(nombre, ignorarPlaylistId: ignorarId);

  PlaylistModel? crearPlaylist(String nombre, {bool activarAlCrear = true}) {
    final creada = _repository.crearPlaylist(
      nombre,
      activarAlCrear: activarAlCrear,
    );
    if (creada != null) {
      notifyListeners();
    }
    return creada;
  }

  bool renombrarPlaylist(String playlistId, String nuevoNombre) {
    final ok = _repository.renombrarPlaylist(playlistId, nuevoNombre);
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool eliminarPlaylist(String playlistId) {
    final ok = _repository.eliminarPlaylist(playlistId);
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool seleccionarPlaylistActiva(String playlistId) {
    final ok = _repository.seleccionarPlaylistActiva(playlistId);
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool insertarEnPlaylistAlInicio(String playlistId, CancionModel cancion) {
    final ok = _repository.insertarCancionAlInicio(playlistId, cancion);
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool insertarEnPlaylistAlFinal(String playlistId, CancionModel cancion) {
    final ok = _repository.insertarCancionAlFinal(playlistId, cancion);
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  /// Recibe posición 1-based (`1 .. tamano + 1`) tal como pide la interfaz de Jeremy (`ui.cpp`)
  /// y la convierte a 0-based para `ListaDobleCircular::insertarEnPosicion`.
  bool insertarEnPlaylistEnPosicionUnoBased(
    String playlistId,
    CancionModel cancion,
    int posicionUnoBased,
  ) {
    final ok = _repository.insertarCancionEnPosicion(
      playlistId,
      cancion,
      posicionUnoBased - 1,
    );
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  CancionModel? eliminarDePlaylistAlInicio(String playlistId) {
    final quitada = _repository.eliminarCancionAlInicio(playlistId);
    if (quitada != null) {
      notifyListeners();
    }
    return quitada;
  }

  CancionModel? eliminarDePlaylistAlFinal(String playlistId) {
    final quitada = _repository.eliminarCancionAlFinal(playlistId);
    if (quitada != null) {
      notifyListeners();
    }
    return quitada;
  }

  /// Recibe posición 1-based (`1 .. tamano`) y la convierte a 0-based.
  CancionModel? eliminarDePlaylistEnPosicionUnoBased(
    String playlistId,
    int posicionUnoBased,
  ) {
    final quitada = _repository.eliminarCancionEnPosicion(
      playlistId,
      posicionUnoBased - 1,
    );
    if (quitada != null) {
      notifyListeners();
    }
    return quitada;
  }

  /// Recibe posiciones 1-based (`1 .. tamano`) y las convierte a 0-based.
  bool moverCancionEnPlaylistUnoBased(
    String playlistId,
    int posOrigenUnoBased,
    int posDestinoUnoBased,
  ) {
    final ok = _repository.moverCancionEnPlaylist(
      playlistId,
      posOrigenUnoBased - 1,
      posDestinoUnoBased - 1,
    );
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool aplicarShuffleFisherYates(String playlistId, {int? semilla}) {
    final ok = _repository.aplicarShuffleFisherYates(
      playlistId,
      semilla: semilla,
    );
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  bool fusionarPlaylists({
    required String playlistPrincipalId,
    required String playlistSecundariaId,
    required bool vaciarSecundaria,
  }) {
    final ok = _repository.fusionarPlaylists(
      playlistPrincipalId: playlistPrincipalId,
      playlistSecundariaId: playlistSecundariaId,
      vaciarSecundaria: vaciarSecundaria,
    );
    if (ok) {
      notifyListeners();
    }
    return ok;
  }

  String exportarPlaylistCSV(String playlistId) =>
      _repository.exportarPlaylistCSV(playlistId);

  PlaylistModel? importarPlaylistCSV({
    required String nombrePlaylist,
    required String contenidoCSV,
  }) {
    final cargada = _repository.importarPlaylistDesdeCSV(
      nombrePlaylist: nombrePlaylist,
      contenidoCSV: contenidoCSV,
    );
    if (cargada != null) {
      notifyListeners();
    }
    return cargada;
  }

  // --- Controles de Reproducción ---
  void togglePlayPause() {
    _repository.setPlaying(!playbackState.isPlaying);
    notifyListeners();
  }

  void play() {
    _repository.setPlaying(true);
    notifyListeners();
  }

  void pause() {
    _repository.setPlaying(false);
    notifyListeners();
  }

  CancionModel? siguienteCancion() {
    final sig = _repository.siguienteCancion();
    notifyListeners();
    return sig;
  }

  CancionModel? anteriorCancion() {
    // Si lleva más de 4 segundos en la pista, reinicia a 00:00; si no, va al nodo anterior
    if (playbackState.posicionActualSegundos > 4) {
      _repository.seekTo(0);
      notifyListeners();
      return cancionActual;
    }
    final ant = _repository.anteriorCancion();
    notifyListeners();
    return ant;
  }

  CancionModel? irANodoAnteriorDirecto() {
    final ant = _repository.anteriorCancion();
    notifyListeners();
    return ant;
  }

  void seekToSeconds(int segundos) {
    _repository.seekTo(segundos);
    notifyListeners();
  }

  void seekToNormalized(double ratio) {
    final dur = playbackState.duracionTotalSegundos;
    if (dur <= 0) {
      return;
    }
    final target = (ratio.clamp(0.0, 1.0) * dur).round();
    _repository.seekTo(target);
    notifyListeners();
  }

  void setVolumen(double volumen) {
    _repository.setVolumen(volumen);
    notifyListeners();
  }

  void ciclarModoRepeticion() {
    final siguiente = playbackState.modoRepeticion.siguienteModo;
    _repository.setModoRepeticion(siguiente);
    notifyListeners();
  }

  void setModoRepeticion(ModoRepeticion modo) {
    _repository.setModoRepeticion(modo);
    notifyListeners();
  }

  void reproducirCancionEnPlaylist(String playlistId, int indiceNodo) {
    _repository.reproducirCancionEnPlaylist(
      playlistId: playlistId,
      indiceNodo: indiceNodo,
    );
    notifyListeners();
  }

  void reproducirCancionDirecta(CancionModel cancion) {
    _repository.reproducirCancionDirecta(cancion);
    notifyListeners();
  }

  // --- Historial (ListaSimple LIFO) ---
  List<HistorialItemModel> get historial => _repository.obtenerHistorial();

  int get duracionTotalHistorialSegundos =>
      _repository.calcularDuracionTotalHistorialSegundos();

  void limpiarHistorial() {
    _repository.limpiarHistorial();
    notifyListeners();
  }

  // --- Temporizador de Progreso en Tiempo Real ---
  bool _finDePistaProcesado = false;

  void _iniciarTickerProgreso() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final st = playbackState;
      if (st.cancionActual == null) {
        return;
      }

      // Motor nativo (C++ / miniaudio): el audio avanza solo. Dart únicamente
      // refresca la UI y detecta el fin de pista para pedir el siguiente nodo.
      if (_repository.motorNativoGestionaProgreso) {
        final terminada = st.duracionTotalSegundos > 0 &&
            st.posicionActualSegundos >= st.duracionTotalSegundos;
        if (terminada && !_finDePistaProcesado) {
          _finDePistaProcesado = true;
          final sig = _repository.siguienteCancion();
          if (sig == null) {
            // SIN_REPETICION al llegar a cola: se detiene.
            _repository.setPlaying(false);
          }
        } else if (!terminada) {
          _finDePistaProcesado = false;
        }
        notifyListeners();
        return;
      }

      // Mock en memoria: simula el avance segundo a segundo.
      if (!st.isPlaying) {
        return;
      }
      if (st.posicionActualSegundos + 1 < st.duracionTotalSegundos) {
        _repository.seekTo(st.posicionActualSegundos + 1);
        notifyListeners();
      } else {
        // Fin de la pista actual -> avanza según ModoRepeticion de ListaDobleCircular
        _repository.siguienteCancion();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
import '../models/cancion.dart';
import '../models/historial_item.dart';
import '../models/modo_repeticion.dart';
import '../models/playback_state.dart';
import '../models/playlist.dart';

/// Contrato desacoplado entre el Frontend Flutter y el Backend C++.
///
/// Refleja 1 a 1 las estructuras del curso **Algoritmos y Estructuras de Datos (CC0401)**:
/// - `ListaSimple` para Biblioteca General (`lista_simple.h` - Andrea)
/// - `ListaSimple` para Historial LIFO (`lista_simple.h` - Andrea)
/// - `ListaDobleCircular` para Playlists Circulares (`lista_doble_circular.h` - Jeick)
/// - `GestorReproduccion` para algoritmos de listas (`reproduccion.h` - Juan Pablo)
/// - `MAX_PLAYLISTS = 20` (`ui.h` - Jeremy)
/// - Extensión completa de Audio Real, Metadatos y Rutas Locales (Integrantes 1, 2 y 3).
abstract class MusicRepository {
  static const int maxPlaylists = 20;

  // ===========================================================================
  // 1. BIBLIOTECA GENERAL (ListaSimple)
  // ===========================================================================
  List<CancionModel> obtenerBiblioteca();

  int calcularDuracionTotalBibliotecaSegundos();

  int siguienteIdLibreBiblioteca();

  CancionModel? buscarCancionPorId(int id);

  CancionModel agregarCancionABiblioteca({
    required int id,
    required String titulo,
    required String artista,
    required int duracionSegundos,
    required String genero,
    String? rutaArchivo,
    String? portadaUrl,
    bool esArchivoLocal = false,
    bool metadataExtraida = false,
    int? tamanoBytes,
  });

  /// Importa un archivo de audio del dispositivo (extrayendo o estimando
  /// metadatos desde la ruta/nombre del archivo y registrando el nodo al final
  /// de `ListaSimple biblioteca`).
  CancionModel importarArchivoAudio({
    required String rutaArchivo,
    String? tituloOverride,
    String? artistaOverride,
    int? duracionSegundosOverride,
    String? generoOverride,
    int? tamanoBytes,
  });

  bool eliminarCancionDeBibliotecaPorId(int id);

  CancionModel? toggleFavoritoCancion(int id);

  String exportarBibliotecaCSV({
    String delimitador = ';',
    bool incluirCamposExtendidos = false,
  });

  int importarBibliotecaDesdeCSV(
    String contenidoCSV, {
    String delimitador = ';',
    bool reemplazarExistente = false,
  });

  // ===========================================================================
  // 2. GESTIÓN DE PLAYLISTS (Arreglo de punteros ListaDobleCircular* [MAX=20])
  // ===========================================================================
  List<PlaylistModel> obtenerPlaylists();

  PlaylistModel? obtenerPlaylistActiva();

  PlaylistModel? obtenerPlaylistPorId(String playlistId);

  bool existeNombrePlaylist(String nombre, {String? ignorarPlaylistId});

  PlaylistModel? crearPlaylist(String nombre, {bool activarAlCrear = true});

  bool renombrarPlaylist(String playlistId, String nuevoNombre);

  bool eliminarPlaylist(String playlistId);

  bool seleccionarPlaylistActiva(String playlistId);

  // ===========================================================================
  // 3. OPERACIONES DE NODOS EN PLAYLIST (ListaDobleCircular - Jeick)
  // ===========================================================================
  bool insertarCancionAlInicio(String playlistId, CancionModel cancion);

  bool insertarCancionAlFinal(String playlistId, CancionModel cancion);

  /// `posicionCeroBased` sigue la firma C++ `insertarEnPosicion(cancion, posicion)`
  /// donde `0 <= posicion <= tamano`. En la UI se pide `1..tamano+1` y se resta 1.
  bool insertarCancionEnPosicion(
    String playlistId,
    CancionModel cancion,
    int posicionCeroBased,
  );

  CancionModel? eliminarCancionAlInicio(String playlistId);

  CancionModel? eliminarCancionAlFinal(String playlistId);

  /// `posicionCeroBased` sigue `eliminarEnPosicion(posicion)` (`0 <= posicion < tamano`).
  CancionModel? eliminarCancionEnPosicion(
    String playlistId,
    int posicionCeroBased,
  );

  // ===========================================================================
  // 4. ALGORITMOS DE REPRODUCCIÓN Y LISTAS (GestorReproduccion - Juan Pablo)
  // ===========================================================================
  bool moverCancionEnPlaylist(
    String playlistId,
    int posOrigenCeroBased,
    int posDestinoCeroBased,
  );

  bool aplicarShuffleFisherYates(
    String playlistId, {
    int? semilla,
  });

  bool fusionarPlaylists({
    required String playlistPrincipalId,
    required String playlistSecundariaId,
    required bool vaciarSecundaria,
  });

  String exportarPlaylistCSV(
    String playlistId, {
    String delimitador = ';',
  });

  PlaylistModel? importarPlaylistDesdeCSV({
    required String nombrePlaylist,
    required String contenidoCSV,
    String delimitador = ';',
  });

  // ===========================================================================
  // 5. MOTOR DE REPRODUCCIÓN, CURSOR CIRCULAR Y AUDIO
  // ===========================================================================
  PlaybackStateModel obtenerEstadoReproduccion();

  CancionModel? reproducirCancionEnPlaylist({
    required String playlistId,
    required int indiceNodo,
  });

  CancionModel? reproducirCancionDirecta(CancionModel cancion);

  CancionModel? siguienteCancion();

  CancionModel? anteriorCancion();

  void setPlaying(bool isPlaying);

  void seekTo(int posicionSegundos);

  void setVolumen(double volumen);

  void setModoRepeticion(ModoRepeticion nuevoModo);

  // ===========================================================================
  // 6. HISTORIAL DE REPRODUCCIÓN (ListaSimple LIFO - Andrea & Juan Pablo)
  // ===========================================================================
  List<HistorialItemModel> obtenerHistorial();

  int calcularDuracionTotalHistorialSegundos();

  void registrarEnHistorial(CancionModel cancion, {String? origenNombre});

  void limpiarHistorial();
}

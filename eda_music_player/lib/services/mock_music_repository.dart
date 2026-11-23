import 'dart:math' as math;

import '../models/cancion.dart';
import '../models/historial_item.dart';
import '../models/modo_repeticion.dart';
import '../models/playback_state.dart';
import '../models/playlist.dart';
import 'music_repository.dart';

/// Implementación en memoria 100% funcional de `MusicRepository`.
///
/// Replica con exactitud matemática el comportamiento de los TADs en C++:
/// - `ListaSimple` para `biblioteca` (inserción por cola `agregarAlFinal`)
/// - `ListaSimple` para `historial` (inserción por cabeza `agregarAlInicio` - LIFO)
/// - `ListaDobleCircular` para cada playlist (punteros `cabeza`, `cola` y cursor `actual`)
/// - `GestorReproduccion::aplicarShuffleFisherYates`, `moverCancion`, `fusionarListas`
/// - Serialización y parser CSV con delimitador `;` compatible con `biblioteca.csv`.
class MockMusicRepository implements MusicRepository {
  @override
  bool get motorNativoGestionaProgreso => false;

  MockMusicRepository() {
    _inicializarDatosSemilla();
  }

  final List<CancionModel> _biblioteca = [];
  final List<PlaylistModel> _playlists = [];
  final List<HistorialItemModel> _historial = [];

  String? _playlistActivaId;
  PlaybackStateModel _playbackState = const PlaybackStateModel();
  int _contadorPlaylists = 0;
  int _contadorHistorial = 0;

  /// Carga exactamente las 5 canciones de `biblioteca.csv` y configura
  /// playlists iniciales para demostrar todas las operaciones de `ListaDobleCircular`.
  void _inicializarDatosSemilla() {
    const csvInicial = '''
id;titulo;artista;duracion_segundos;genero
1;Bohemian Rhapsody;Queen;354;Rock
2;De Musica Ligera;Soda Stereo;212;Rock Latino
3;Billie Jean;Michael Jackson;294;Pop
4;Tren al Sur;Los Prisioneros;336;New Wave
5;Clocks;Coldplay;307;Alternative
''';

    importarBibliotecaDesdeCSV(csvInicial, reemplazarExistente: true);

    // Marcamos algunas canciones con rutas simuladas y favoritas para riqueza visual
    if (_biblioteca.length >= 5) {
      _biblioteca[0] = _biblioteca[0].copyWith(
        esFavorita: true,
        rutaArchivo: 'storage/music/queen_bohemian_rhapsody.flac',
        metadataExtraida: true,
      );
      _biblioteca[1] = _biblioteca[1].copyWith(
        titulo: 'De Música Ligera',
        esFavorita: true,
        rutaArchivo: 'storage/music/soda_stereo_de_musica_ligera.mp3',
        metadataExtraida: true,
      );
      _biblioteca[2] = _biblioteca[2].copyWith(
        rutaArchivo: 'storage/music/michael_jackson_billie_jean.mp3',
        metadataExtraida: true,
      );
      _biblioteca[3] = _biblioteca[3].copyWith(
        rutaArchivo: 'storage/music/los_prisioneros_tren_al_sur.mp3',
        metadataExtraida: true,
      );
      _biblioteca[4] = _biblioteca[4].copyWith(
        esFavorita: true,
        rutaArchivo: 'storage/music/coldplay_clocks.flac',
        metadataExtraida: true,
      );
    }

    // Playlist 1 (Activa): Esenciales EDA con las 5 canciones de biblioteca.csv
    final principal = crearPlaylist('Esenciales EDA', activarAlCrear: true);
    if (principal != null) {
      for (final cancion in _biblioteca) {
        insertarCancionAlFinal(principal.id, cancion);
      }
    }

    // Playlist 2 (Secundaria): Rock & New Wave (lista para probar Fusión de Listas)
    final secundaria = crearPlaylist(
      'Ruta Latinoamericana',
      activarAlCrear: false,
    );
    if (secundaria != null && _biblioteca.length >= 4) {
      insertarCancionAlFinal(secundaria.id, _biblioteca[1]); // De Música Ligera
      insertarCancionAlFinal(secundaria.id, _biblioteca[3]); // Tren al Sur
    }

    // Rehidratamos la playlist Principal como activa en la pista 1 (Bohemian Rhapsody)
    if (principal != null) {
      seleccionarPlaylistActiva(principal.id);
      final activa = obtenerPlaylistActiva();
      final actual = activa?.cancionActual;
      if (actual != null) {
        _playbackState = _playbackState.copyWith(
          cancionActual: actual,
          playlistActivaId: activa!.id,
          nombreContexto: activa.nombre,
          isPlaying: false,
          posicionActualSegundos: 81, // 1:21 como en la imagen de referencia
          duracionTotalSegundos: actual.duracionSegundos,
          modoRepeticion: activa.modoRepeticion,
        );
        registrarEnHistorial(actual, origenNombre: activa.nombre);
      }
    }
  }

  // ===========================================================================
  // 1. BIBLIOTECA GENERAL (ListaSimple)
  // ===========================================================================

  @override
  List<CancionModel> obtenerBiblioteca() => List.unmodifiable(_biblioteca);

  @override
  int calcularDuracionTotalBibliotecaSegundos() {
    var suma = 0;
    for (final c in _biblioteca) {
      suma += c.duracionSegundos;
    }
    return suma;
  }

  @override
  int siguienteIdLibreBiblioteca() {
    var maximo = 0;
    for (final c in _biblioteca) {
      if (c.id > maximo) {
        maximo = c.id;
      }
    }
    return maximo + 1;
  }

  @override
  CancionModel? buscarCancionPorId(int id) {
    for (final c in _biblioteca) {
      if (c.id == id) {
        return c;
      }
    }
    return null;
  }

  @override
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
  }) {
    final limpioTitulo = titulo.replaceAll(';', ',').trim();
    final limpioArtista = artista.replaceAll(';', ',').trim();
    final limpioGenero = genero.replaceAll(';', ',').trim();

    final nueva = CancionModel(
      id: id,
      titulo: limpioTitulo.isEmpty ? 'Sin titulo' : limpioTitulo,
      artista: limpioArtista.isEmpty ? 'Desconocido' : limpioArtista,
      duracionSegundos: duracionSegundos <= 0 ? 180 : duracionSegundos,
      genero: limpioGenero.isEmpty ? 'Sin genero' : limpioGenero,
      rutaArchivo: rutaArchivo,
      portadaUrl: portadaUrl,
      esArchivoLocal: esArchivoLocal,
      metadataExtraida: metadataExtraida,
      tamanoBytes: tamanoBytes,
    );

    // ListaSimple::agregarAlFinal
    _biblioteca.add(nueva);
    return nueva;
  }

  @override
  CancionModel importarArchivoAudio({
    required String rutaArchivo,
    String? tituloOverride,
    String? artistaOverride,
    int? duracionSegundosOverride,
    String? generoOverride,
    int? tamanoBytes,
  }) {
    final nombreArchivo = rutaArchivo.split(RegExp(r'[/\\]')).last;
    final sinExtension = nombreArchivo.replaceAll(
      RegExp(r'\.(mp3|flac|wav|ogg|m4a|aac)$', caseSensitive: false),
      '',
    );

    String artistaInferido = 'Artista Local';
    String tituloInferido = sinExtension.replaceAll('_', ' ').trim();

    if (sinExtension.contains('-')) {
      final partes = sinExtension.split('-');
      if (partes.length >= 2) {
        artistaInferido = partes.first.replaceAll('_', ' ').trim();
        tituloInferido = partes.sublist(1).join('-').replaceAll('_', ' ').trim();
      }
    }

    // Estimación determinística de duración si no se provee override (basada en tamaño o hash)
    final duracionEstimada = duracionSegundosOverride ??
        (tamanoBytes != null && tamanoBytes > 0
            ? (tamanoBytes ~/ 24000).clamp(95, 480)
            : 185 + (nombreArchivo.hashCode.abs() % 140));

    return agregarCancionABiblioteca(
      id: siguienteIdLibreBiblioteca(),
      titulo: (tituloOverride != null && tituloOverride.trim().isNotEmpty)
          ? tituloOverride.trim()
          : (tituloInferido.isEmpty ? 'Audio Importado' : tituloInferido),
      artista: (artistaOverride != null && artistaOverride.trim().isNotEmpty)
          ? artistaOverride.trim()
          : (artistaInferido.isEmpty ? 'Artista Local' : artistaInferido),
      duracionSegundos: duracionEstimada,
      genero: (generoOverride != null && generoOverride.trim().isNotEmpty)
          ? generoOverride.trim()
          : 'Audio Local',
      rutaArchivo: rutaArchivo,
      esArchivoLocal: true,
      metadataExtraida: true,
      tamanoBytes: tamanoBytes,
    );
  }

  @override
  bool eliminarCancionDeBibliotecaPorId(int id) {
    // ListaSimple::eliminarPorId (las playlists conservan su copia del nodo, igual que en ui.cpp)
    final index = _biblioteca.indexWhere((c) => c.id == id);
    if (index == -1) {
      return false;
    }
    _biblioteca.removeAt(index);
    return true;
  }

  @override
  CancionModel? toggleFavoritoCancion(int id) {
    CancionModel? actualizada;
    for (var i = 0; i < _biblioteca.length; i++) {
      if (_biblioteca[i].id == id) {
        _biblioteca[i] = _biblioteca[i].copyWith(
          esFavorita: !_biblioteca[i].esFavorita,
        );
        actualizada = _biblioteca[i];
      }
    }

    for (var p = 0; p < _playlists.length; p++) {
      final pl = _playlists[p];
      final nuevasCanciones = pl.canciones.map((c) {
        if (c.id == id) {
          final toggled = c.copyWith(esFavorita: actualizada?.esFavorita ?? !c.esFavorita);
          actualizada ??= toggled;
          return toggled;
        }
        return c;
      }).toList();
      _playlists[p] = pl.copyWith(canciones: nuevasCanciones);
    }

    if (_playbackState.cancionActual?.id == id && actualizada != null) {
      _playbackState = _playbackState.copyWith(cancionActual: actualizada);
    }
    return actualizada;
  }

  @override
  String exportarBibliotecaCSV({
    String delimitador = ';',
    bool incluirCamposExtendidos = false,
  }) {
    final buffer = StringBuffer();
    if (incluirCamposExtendidos) {
      buffer.writeln(
        'id${delimitador}titulo${delimitador}artista${delimitador}duracion_segundos${delimitador}genero${delimitador}ruta_archivo${delimitador}portada',
      );
    } else {
      buffer.writeln(
        'id${delimitador}titulo${delimitador}artista${delimitador}duracion_segundos${delimitador}genero',
      );
    }
    for (final cancion in _biblioteca) {
      buffer.writeln(
        cancion.aCSV(
          delimitador: delimitador,
          incluirCamposExtendidos: incluirCamposExtendidos,
        ),
      );
    }
    return buffer.toString();
  }

  @override
  int importarBibliotecaDesdeCSV(
    String contenidoCSV, {
    String delimitador = ';',
    bool reemplazarExistente = false,
  }) {
    if (reemplazarExistente) {
      _biblioteca.clear();
    }
    final lineas = contenidoCSV.split(RegExp(r'\r?\n'));
    var cargadas = 0;
    for (final linea in lineas) {
      final cancion = CancionModel.desdeCSV(linea, delimitador: delimitador);
      if (cancion != null) {
        // Si el ID ya existe y no estamos reemplazando, asignamos siguiente ID libre
        final idFinal = buscarCancionPorId(cancion.id) != null
            ? siguienteIdLibreBiblioteca()
            : cancion.id;
        _biblioteca.add(cancion.copyWith(id: idFinal));
        cargadas++;
      }
    }
    return cargadas;
  }

  // ===========================================================================
  // 2. GESTIÓN DE PLAYLISTS (ListaDobleCircular* [MAX=20])
  // ===========================================================================

  @override
  List<PlaylistModel> obtenerPlaylists() {
    return List.unmodifiable(
      _playlists.map((p) => p.copyWith(esActiva: p.id == _playlistActivaId)),
    );
  }

  @override
  PlaylistModel? obtenerPlaylistActiva() {
    if (_playlistActivaId == null) {
      return null;
    }
    return obtenerPlaylistPorId(_playlistActivaId!);
  }

  @override
  PlaylistModel? obtenerPlaylistPorId(String playlistId) {
    for (final p in _playlists) {
      if (p.id == playlistId) {
        return p.copyWith(esActiva: p.id == _playlistActivaId);
      }
    }
    return null;
  }

  int _indexPlaylist(String playlistId) =>
      _playlists.indexWhere((p) => p.id == playlistId);

  @override
  bool existeNombrePlaylist(String nombre, {String? ignorarPlaylistId}) {
    final buscado = nombre.trim().toLowerCase();
    return _playlists.any(
      (p) =>
          p.id != ignorarPlaylistId && p.nombre.trim().toLowerCase() == buscado,
    );
  }

  @override
  PlaylistModel? crearPlaylist(String nombre, {bool activarAlCrear = true}) {
    // Validación de MAX_PLAYLISTS = 20 de InterfazConsola::crearPlaylist (ui.cpp)
    if (_playlists.length >= MusicRepository.maxPlaylists) {
      return null;
    }
    final limpio = nombre.replaceAll(';', ',').trim();
    if (limpio.isEmpty || existeNombrePlaylist(limpio)) {
      return null;
    }

    _contadorPlaylists++;
    final nueva = PlaylistModel(
      id: 'pl_$_contadorPlaylists',
      nombre: limpio,
      canciones: const [],
      indiceActual: null,
      modoRepeticion: ModoRepeticion.repetirTodas,
      esActiva: activarAlCrear,
    );
    _playlists.add(nueva);

    if (activarAlCrear || _playlistActivaId == null) {
      _playlistActivaId = nueva.id;
      _sincronizarPlaybackConPlaylistActiva();
    }
    return obtenerPlaylistPorId(nueva.id);
  }

  @override
  bool renombrarPlaylist(String playlistId, String nuevoNombre) {
    final idx = _indexPlaylist(playlistId);
    final limpio = nuevoNombre.replaceAll(';', ',').trim();
    if (idx == -1 ||
        limpio.isEmpty ||
        existeNombrePlaylist(limpio, ignorarPlaylistId: playlistId)) {
      return false;
    }
    _playlists[idx] = _playlists[idx].copyWith(nombre: limpio);
    if (_playlistActivaId == playlistId) {
      _playbackState = _playbackState.copyWith(nombreContexto: limpio);
    }
    return true;
  }

  @override
  bool eliminarPlaylist(String playlistId) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final eraActiva = _playlistActivaId == playlistId;
    _playlists.removeAt(idx);

    if (_playlists.isEmpty) {
      _playlistActivaId = null;
      _playbackState = _playbackState.copyWith(
        clearCancionActual: true,
        nombreContexto: 'Sin playlist activa',
        isPlaying: false,
        posicionActualSegundos: 0,
        duracionTotalSegundos: 0,
      );
    } else if (eraActiva) {
      // Igual que en ui.cpp: si se borra la activa, pasa a la primera disponible
      _playlistActivaId = _playlists.first.id;
      _sincronizarPlaybackConPlaylistActiva();
    }
    return true;
  }

  @override
  bool seleccionarPlaylistActiva(String playlistId) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    _playlistActivaId = playlistId;
    _sincronizarPlaybackConPlaylistActiva();
    return true;
  }

  void _sincronizarPlaybackConPlaylistActiva() {
    final activa = obtenerPlaylistActiva();
    if (activa == null) {
      return;
    }
    final actual = activa.cancionActual;
    _playbackState = _playbackState.copyWith(
      playlistActivaId: activa.id,
      nombreContexto: activa.nombre,
      modoRepeticion: activa.modoRepeticion,
      cancionActual: actual,
      clearCancionActual: actual == null,
      posicionActualSegundos: 0,
      duracionTotalSegundos: actual?.duracionSegundos ?? 0,
    );
  }

  // ===========================================================================
  // 3. OPERACIONES DE NODOS EN PLAYLIST (ListaDobleCircular - Jeick)
  // ===========================================================================

  @override
  bool insertarCancionAlInicio(String playlistId, CancionModel cancion) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final pl = _playlists[idx];
    final nuevas = [cancion, ...pl.canciones];
    // Si estaba vacía: cabeza = cola = actual = nuevo (índice 0).
    // Si no estaba vacía: el nuevo nodo entra en 0 y el puntero `actual` se desplaza +1.
    final nuevoIndiceActual =
        pl.estaVacia ? 0 : ((pl.indiceActual ?? 0) + 1);

    _playlists[idx] = pl.copyWith(
      canciones: nuevas,
      indiceActual: nuevoIndiceActual,
    );
    if (_playlistActivaId == playlistId && pl.estaVacia) {
      _sincronizarPlaybackConPlaylistActiva();
    }
    return true;
  }

  @override
  bool insertarCancionAlFinal(String playlistId, CancionModel cancion) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final pl = _playlists[idx];
    final nuevas = [...pl.canciones, cancion];
    final nuevoIndiceActual = pl.estaVacia ? 0 : (pl.indiceActual ?? 0);

    _playlists[idx] = pl.copyWith(
      canciones: nuevas,
      indiceActual: nuevoIndiceActual,
    );
    if (_playlistActivaId == playlistId && pl.estaVacia) {
      _sincronizarPlaybackConPlaylistActiva();
    }
    return true;
  }

  @override
  bool insertarCancionEnPosicion(
    String playlistId,
    CancionModel cancion,
    int posicionCeroBased,
  ) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final pl = _playlists[idx];
    if (posicionCeroBased < 0 || posicionCeroBased > pl.tamano) {
      return false;
    }
    if (posicionCeroBased == 0) {
      return insertarCancionAlInicio(playlistId, cancion);
    }
    if (posicionCeroBased == pl.tamano) {
      return insertarCancionAlFinal(playlistId, cancion);
    }

    final nuevas = List<CancionModel>.from(pl.canciones)
      ..insert(posicionCeroBased, cancion);
    var actualIdx = pl.indiceActual ?? 0;
    if (posicionCeroBased <= actualIdx) {
      actualIdx++;
    }

    _playlists[idx] = pl.copyWith(
      canciones: nuevas,
      indiceActual: actualIdx,
    );
    return true;
  }

  @override
  CancionModel? eliminarCancionAlInicio(String playlistId) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1 || _playlists[idx].estaVacia) {
      return null;
    }
    return eliminarCancionEnPosicion(playlistId, 0);
  }

  @override
  CancionModel? eliminarCancionAlFinal(String playlistId) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1 || _playlists[idx].estaVacia) {
      return null;
    }
    return eliminarCancionEnPosicion(
      playlistId,
      _playlists[idx].tamano - 1,
    );
  }

  @override
  CancionModel? eliminarCancionEnPosicion(
    String playlistId,
    int posicionCeroBased,
  ) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return null;
    }
    final pl = _playlists[idx];
    if (posicionCeroBased < 0 || posicionCeroBased >= pl.tamano) {
      return null;
    }

    final nuevas = List<CancionModel>.from(pl.canciones);
    final eliminada = nuevas.removeAt(posicionCeroBased);

    // Regla exacta de ListaDobleCircular::eliminar* (lista_doble_circular.cpp):
    // - Si queda vacía: cabeza = cola = actual = nullptr
    // - Si actual == borrar: actual = borrar->siguiente (que en circular si era cola pasa a cabeza = 0)
    int? nuevoActual;
    if (nuevas.isEmpty) {
      nuevoActual = null;
    } else {
      final actualPrevio = pl.indiceActual ?? 0;
      if (posicionCeroBased < actualPrevio) {
        nuevoActual = actualPrevio - 1;
      } else if (posicionCeroBased == actualPrevio) {
        // Si borramos la cola, actual pasa a cabeza (0); si no, queda en el mismo índice (que ahora es siguiente)
        nuevoActual = actualPrevio >= nuevas.length ? 0 : actualPrevio;
      } else {
        nuevoActual = actualPrevio;
      }
    }

    _playlists[idx] = pl.copyWith(
      canciones: nuevas,
      indiceActual: nuevoActual,
      clearIndiceActual: nuevas.isEmpty,
    );

    if (_playlistActivaId == playlistId) {
      _sincronizarPlaybackConPlaylistActiva();
    }
    return eliminada;
  }

  // ===========================================================================
  // 4. ALGORITMOS DE REPRODUCCIÓN (GestorReproduccion - Juan Pablo)
  // ===========================================================================

  @override
  bool moverCancionEnPlaylist(
    String playlistId,
    int posOrigenCeroBased,
    int posDestinoCeroBased,
  ) {
    // Espejo de GestorReproduccion::moverCancion (reproduccion.cpp)
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final pl = _playlists[idx];
    final limite = pl.tamano - 1;
    if (posOrigenCeroBased < 0 ||
        posOrigenCeroBased > limite ||
        posDestinoCeroBased < 0 ||
        posDestinoCeroBased > limite) {
      return false;
    }
    if (posOrigenCeroBased == posDestinoCeroBased) {
      return true;
    }

    final cancionMovida = pl.canciones[posOrigenCeroBased];
    eliminarCancionEnPosicion(playlistId, posOrigenCeroBased);
    insertarCancionEnPosicion(playlistId, cancionMovida, posDestinoCeroBased);
    return true;
  }

  @override
  bool aplicarShuffleFisherYates(
    String playlistId, {
    int? semilla,
  }) {
    // Espejo de GestorReproduccion::aplicarShuffleFisherYates (reproduccion.cpp):
    // for (int i = n - 1; i >= 1; --i) { swap(nodoI->dato, nodoJ->dato); }
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return false;
    }
    final pl = _playlists[idx];
    final n = pl.tamano;
    if (n <= 1) {
      return false;
    }

    final seedUsada =
        semilla ?? DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    final random = math.Random(seedUsada);
    final copia = List<CancionModel>.from(pl.canciones);

    for (var i = n - 1; i >= 1; --i) {
      final j = random.nextInt(i + 1); // distribución uniforme [0, i]
      final temp = copia[i];
      copia[i] = copia[j];
      copia[j] = temp;
    }

    _playlists[idx] = pl.copyWith(canciones: copia);

    if (_playlistActivaId == playlistId) {
      final actual = _playlists[idx].cancionActual;
      _playbackState = _playbackState.copyWith(
        cancionActual: actual,
        duracionTotalSegundos: actual?.duracionSegundos ?? 0,
        posicionActualSegundos: 0,
        ultimoShuffleSemilla: seedUsada,
      );
    }
    return true;
  }

  @override
  bool fusionarPlaylists({
    required String playlistPrincipalId,
    required String playlistSecundariaId,
    required bool vaciarSecundaria,
  }) {
    // Espejo de GestorReproduccion::fusionarListas (reproduccion.cpp)
    if (playlistPrincipalId == playlistSecundariaId) {
      return false;
    }
    final idxPrincipal = _indexPlaylist(playlistPrincipalId);
    final idxSecundaria = _indexPlaylist(playlistSecundariaId);
    if (idxPrincipal == -1 || idxSecundaria == -1) {
      return false;
    }

    final secundaria = _playlists[idxSecundaria];
    if (secundaria.estaVacia) {
      return false;
    }

    for (final cancion in secundaria.canciones) {
      insertarCancionAlFinal(playlistPrincipalId, cancion);
    }

    if (vaciarSecundaria) {
      _playlists[idxSecundaria] = secundaria.copyWith(
        canciones: const [],
        clearIndiceActual: true,
      );
      if (_playlistActivaId == playlistSecundariaId) {
        _sincronizarPlaybackConPlaylistActiva();
      }
    }
    return true;
  }

  @override
  String exportarPlaylistCSV(
    String playlistId, {
    String delimitador = ';',
  }) {
    // Espejo de GestorReproduccion::guardarPlaylistCSV (reproduccion.cpp)
    final pl = obtenerPlaylistPorId(playlistId);
    if (pl == null) {
      return '';
    }
    final buffer = StringBuffer();
    buffer.writeln('id;titulo;artista;duracion_segundos;genero');
    for (final c in pl.canciones) {
      buffer.writeln(c.aCSV(delimitador: delimitador));
    }
    return buffer.toString();
  }

  @override
  PlaylistModel? importarPlaylistDesdeCSV({
    required String nombrePlaylist,
    required String contenidoCSV,
    String delimitador = ';',
  }) {
    // Espejo de GestorReproduccion::cargarPlaylistCSV (reproduccion.cpp)
    final creada = crearPlaylist(nombrePlaylist, activarAlCrear: true);
    if (creada == null) {
      return null;
    }

    final lineas = contenidoCSV.split(RegExp(r'\r?\n'));
    for (final linea in lineas) {
      final cancion = CancionModel.desdeCSV(linea, delimitador: delimitador);
      if (cancion != null) {
        insertarCancionAlFinal(creada.id, cancion);
      }
    }
    _sincronizarPlaybackConPlaylistActiva();
    return obtenerPlaylistPorId(creada.id);
  }

  // ===========================================================================
  // 5. MOTOR DE REPRODUCCIÓN Y NAVEGACIÓN CIRCULAR
  // ===========================================================================

  @override
  PlaybackStateModel obtenerEstadoReproduccion() => _playbackState;

  @override
  CancionModel? reproducirCancionEnPlaylist({
    required String playlistId,
    required int indiceNodo,
  }) {
    final idx = _indexPlaylist(playlistId);
    if (idx == -1) {
      return null;
    }
    final pl = _playlists[idx];
    if (indiceNodo < 0 || indiceNodo >= pl.tamano) {
      return null;
    }

    _playlistActivaId = playlistId;
    _playlists[idx] = pl.copyWith(indiceActual: indiceNodo);
    final cancion = _playlists[idx].cancionActual!;

    _playbackState = _playbackState.copyWith(
      cancionActual: cancion,
      playlistActivaId: playlistId,
      nombreContexto: pl.nombre,
      isPlaying: true,
      posicionActualSegundos: 0,
      duracionTotalSegundos: cancion.duracionSegundos,
      modoRepeticion: pl.modoRepeticion,
      clearMensajeEstado: true,
    );

    registrarEnHistorial(cancion, origenNombre: pl.nombre);
    return cancion;
  }

  @override
  CancionModel? reproducirCancionDirecta(CancionModel cancion) {
    final activa = obtenerPlaylistActiva();
    if (activa != null) {
      final idxEnActiva =
          activa.canciones.indexWhere((c) => c.id == cancion.id);
      if (idxEnActiva != -1) {
        return reproducirCancionEnPlaylist(
          playlistId: activa.id,
          indiceNodo: idxEnActiva,
        );
      }
    }

    _playbackState = _playbackState.copyWith(
      cancionActual: cancion,
      nombreContexto: 'Biblioteca General (ListaSimple)',
      isPlaying: true,
      posicionActualSegundos: 0,
      duracionTotalSegundos: cancion.duracionSegundos,
      clearMensajeEstado: true,
    );
    registrarEnHistorial(cancion, origenNombre: 'Biblioteca General');
    return cancion;
  }

  @override
  CancionModel? siguienteCancion() {
    // Espejo exacto de ListaDobleCircular::siguienteCancion() (lista_doble_circular.cpp)
    final activa = obtenerPlaylistActiva();
    if (activa == null || activa.estaVacia) {
      return null;
    }

    final idxPl = _indexPlaylist(activa.id);
    final actualIdx = activa.indiceActual ?? 0;
    final modo = activa.modoRepeticion;

    int nuevoIndice = actualIdx;
    if (modo == ModoRepeticion.repetirTodas) {
      // Circular: cola->siguiente == cabeza
      nuevoIndice = (actualIdx + 1) % activa.tamano;
    } else if (modo == ModoRepeticion.sinRepeticion) {
      // Si actual == cola, retorna nullptr y detiene la reproducción
      if (actualIdx >= activa.tamano - 1) {
        _playbackState = _playbackState.copyWith(
          isPlaying: false,
          posicionActualSegundos: activa.cancionActual?.duracionSegundos ?? 0,
          mensajeEstado:
              'Fin de la playlist (modo Sin repetición). Cambia el modo o retrocede.',
        );
        return null;
      }
      nuevoIndice = actualIdx + 1;
    } else if (modo == ModoRepeticion.repetirUna) {
      // actual permanece en el mismo nodo
      nuevoIndice = actualIdx;
    }

    _playlists[idxPl] = activa.copyWith(indiceActual: nuevoIndice);
    final siguiente = _playlists[idxPl].cancionActual!;

    _playbackState = _playbackState.copyWith(
      cancionActual: siguiente,
      posicionActualSegundos: 0,
      duracionTotalSegundos: siguiente.duracionSegundos,
      isPlaying: true,
      clearMensajeEstado: true,
    );

    registrarEnHistorial(siguiente, origenNombre: activa.nombre);
    return siguiente;
  }

  @override
  CancionModel? anteriorCancion() {
    // Espejo exacto de ListaDobleCircular::anteriorCancion() (lista_doble_circular.cpp):
    // actual = actual->anterior; (circular: cabeza->anterior == cola)
    final activa = obtenerPlaylistActiva();
    if (activa == null || activa.estaVacia) {
      return null;
    }

    final idxPl = _indexPlaylist(activa.id);
    final actualIdx = activa.indiceActual ?? 0;
    final nuevoIndice = (actualIdx - 1 + activa.tamano) % activa.tamano;

    _playlists[idxPl] = activa.copyWith(indiceActual: nuevoIndice);
    final anterior = _playlists[idxPl].cancionActual!;

    _playbackState = _playbackState.copyWith(
      cancionActual: anterior,
      posicionActualSegundos: 0,
      duracionTotalSegundos: anterior.duracionSegundos,
      isPlaying: true,
      clearMensajeEstado: true,
    );

    registrarEnHistorial(anterior, origenNombre: activa.nombre);
    return anterior;
  }

  @override
  void setPlaying(bool isPlaying) {
    if (_playbackState.cancionActual == null) {
      final activa = obtenerPlaylistActiva();
      if (activa != null && !activa.estaVacia) {
        reproducirCancionEnPlaylist(
          playlistId: activa.id,
          indiceNodo: activa.indiceActual ?? 0,
        );
        return;
      }
      if (_biblioteca.isNotEmpty) {
        reproducirCancionDirecta(_biblioteca.first);
        return;
      }
      return;
    }
    _playbackState = _playbackState.copyWith(
      isPlaying: isPlaying,
      clearMensajeEstado: true,
    );
  }

  @override
  void seekTo(int posicionSegundos) {
    final maxDur = _playbackState.duracionTotalSegundos;
    final clamped = posicionSegundos.clamp(0, maxDur > 0 ? maxDur : 0);
    _playbackState = _playbackState.copyWith(
      posicionActualSegundos: clamped,
      clearMensajeEstado: true,
    );
  }

  @override
  void setVolumen(double volumen) {
    _playbackState = _playbackState.copyWith(
      volumen: volumen.clamp(0.0, 1.0),
    );
  }

  @override
  void setModoRepeticion(ModoRepeticion nuevoModo) {
    final activa = obtenerPlaylistActiva();
    if (activa != null) {
      final idx = _indexPlaylist(activa.id);
      if (idx != -1) {
        _playlists[idx] = _playlists[idx].copyWith(modoRepeticion: nuevoModo);
      }
    }
    _playbackState = _playbackState.copyWith(
      modoRepeticion: nuevoModo,
      clearMensajeEstado: true,
    );
  }

  // ===========================================================================
  // 6. HISTORIAL DE REPRODUCCIÓN (ListaSimple LIFO - Andrea & Juan Pablo)
  // ===========================================================================

  @override
  List<HistorialItemModel> obtenerHistorial() => List.unmodifiable(_historial);

  @override
  int calcularDuracionTotalHistorialSegundos() {
    var suma = 0;
    for (final item in _historial) {
      suma += item.cancion.duracionSegundos;
    }
    return suma;
  }

  @override
  void registrarEnHistorial(CancionModel cancion, {String? origenNombre}) {
    // Espejo de GestorReproduccion::registrarEnHistorial -> historial.agregarAlInicio(*actual)
    _contadorHistorial++;
    final item = HistorialItemModel(
      idRegistro: 'hist_$_contadorHistorial',
      cancion: cancion,
      fechaReproduccion: DateTime.now(),
      origenNombre: origenNombre ?? _playbackState.nombreContexto,
    );
    _historial.insert(0, item); // agregarAlInicio (LIFO)
  }

  @override
  void limpiarHistorial() {
    // Espejo de ListaSimple::limpiar()
    _historial.clear();
  }
}
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../models/cancion.dart';
import '../models/historial_item.dart';
import '../models/modo_repeticion.dart';
import '../models/playback_state.dart';
import '../models/playlist.dart';
import 'music_repository.dart';
import 'package:flutter/foundation.dart';

typedef _P = Pointer<Utf8>;

/// Pequeño "arena" para reservar cadenas nativas (UTF-8) y liberarlas todas
/// en un único `finally`, evitando fugas de memoria al llamar al puente C++.
class _Arena {
  final List<Pointer<Utf8>> _ptrs = [];

  Pointer<Utf8> str(String? s) {
    if (s == null) {
      return nullptr;
    }
    final p = s.toNativeUtf8();
    _ptrs.add(p);
    return p;
  }

  void liberar() {
    for (final p in _ptrs) {
      malloc.free(p);
    }
    _ptrs.clear();
  }
}

/// Implementación real de [MusicRepository] sobre la biblioteca nativa C++
/// (`eda_music_bridge.dll` / `libeda_music_bridge.so`) usando `dart:ffi`.
///
/// Toda operación se ejecuta sobre los TADs del curso en C++
/// (`ListaSimple`, `ListaDobleCircular`, `GestorReproduccion`, `MotorAudio`).
/// Dart solo serializa/deserializa JSON y muestra el resultado.
class CppMusicRepository implements MusicRepository {
  CppMusicRepository({
    String? rutaLibreria,
    String? rutaBibliotecaCsv,
    }) : _lib = _abrirLibreria(rutaLibreria) {
    debugPrint('PASO 1b: DLL abierta');
    _fnInit = _lib.lookupFunction<Int32 Function(_P), int Function(_P)>(
      'bridge_init',
    );
    final arena = _Arena();
    try {
      debugPrint('PASO 1c: llamando bridge_init...');
      _fnInit(arena.str(_resolverCsv(rutaBibliotecaCsv)));
      debugPrint('PASO 1d: bridge_init terminó');
    } finally {
      arena.liberar();
    }
  }

  final DynamicLibrary _lib;
  late final int Function(_P) _fnInit;

  /// El motor de audio de C++ avanza solo; el controlador NO debe hacer seek +1.
  @override
  bool get motorNativoGestionaProgreso => true;

  // ===========================================================================
  // Carga de la biblioteca nativa
  // ===========================================================================
  static DynamicLibrary _abrirLibreria(String? rutaExplicita) {
    final nombre = Platform.isWindows
        ? 'eda_music_bridge.dll'
        : (Platform.isMacOS
            ? 'libeda_music_bridge.dylib'
            : 'libeda_music_bridge.so');
    final cwd = Directory.current.path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final sep = Platform.pathSeparator;

    final candidatos = <String>[
      if (rutaExplicita != null && rutaExplicita.isNotEmpty) rutaExplicita,
      if ((Platform.environment['EDA_BRIDGE_PATH'] ?? '').isNotEmpty)
        Platform.environment['EDA_BRIDGE_PATH']!,
      '$exeDir$sep$nombre',
      '$cwd$sep$nombre',
      '$cwd$sep..$sep$nombre',
    ];

    for (final ruta in candidatos) {
      final f = File(ruta);
      if (f.existsSync()) {
        return DynamicLibrary.open(f.absolute.path);
      }
    }
    try {
      return DynamicLibrary.open(nombre);
    } catch (_) {
      throw StateError(
        'No se encontró $nombre. Compílala con "make bridge" (o '
        '"mingw32-make bridge") y colócala junto al ejecutable, en la carpeta '
        'del proyecto Flutter o define EDA_BRIDGE_PATH. Rutas probadas: '
        '${candidatos.join(' | ')}',
      );
    }
  }

  static String? _resolverCsv(String? explicita) {
    final sep = Platform.pathSeparator;
    final cwd = Directory.current.path;
    final candidatos = <String>[
      if (explicita != null && explicita.isNotEmpty) explicita,
      '$cwd$sep..${sep}biblioteca.csv',
      '$cwd${sep}biblioteca.csv',
    ];
    for (final ruta in candidatos) {
      if (File(ruta).existsSync()) {
        return File(ruta).absolute.path;
      }
    }
    return null; // el puente arranca igualmente con biblioteca vacía
  }

  // ===========================================================================
  // Enlaces a funciones extern "C" (bridge_ffi.h)
  // ===========================================================================
  late final void Function() _shutdown =
      _lib.lookupFunction<Void Function(), void Function()>('bridge_shutdown');
  late final void Function(_P) _freeString =
      _lib.lookupFunction<Void Function(_P), void Function(_P)>(
    'bridge_free_string',
  );
  late final void Function(Pointer<Uint8>) _freeBytes = _lib.lookupFunction<
      Void Function(Pointer<Uint8>), void Function(Pointer<Uint8>)>(
    'bridge_free_bytes',
  );

  // --- Biblioteca ---
  late final _P Function() _biblioteca = _lib
      .lookupFunction<_P Function(), _P Function()>('bridge_obtener_biblioteca_json');
  late final int Function() _durBiblioteca =
      _lib.lookupFunction<Int32 Function(), int Function()>(
    'bridge_calcular_duracion_total_biblioteca',
  );
  late final int Function() _siguienteId =
      _lib.lookupFunction<Int32 Function(), int Function()>(
    'bridge_siguiente_id_libre_biblioteca',
  );
  late final _P Function(int) _buscarPorId =
      _lib.lookupFunction<_P Function(Int32), _P Function(int)>(
    'bridge_buscar_cancion_por_id_json',
  );
  late final _P Function(int, _P, _P, int, _P, _P, _P, int, int, int)
      _agregarCancion = _lib.lookupFunction<
          _P Function(Int32, _P, _P, Int32, _P, _P, _P, Int32, Int32, Int32),
          _P Function(int, _P, _P, int, _P, _P, _P, int, int, int)>(
    'bridge_agregar_cancion_biblioteca_json',
  );
  late final _P Function(_P, _P, _P, int, _P, int) _importarAudio =
      _lib.lookupFunction<_P Function(_P, _P, _P, Int32, _P, Int32),
          _P Function(_P, _P, _P, int, _P, int)>(
    'bridge_importar_archivo_audio_json',
  );
  late final int Function(int) _eliminarCancion =
      _lib.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'bridge_eliminar_cancion_biblioteca',
  );
  late final _P Function(int) _toggleFavorito =
      _lib.lookupFunction<_P Function(Int32), _P Function(int)>(
    'bridge_toggle_favorito_cancion_json',
  );
  late final _P Function(int, int) _exportarBiblioteca =
      _lib.lookupFunction<_P Function(Int8, Int32), _P Function(int, int)>(
    'bridge_exportar_biblioteca_csv',
  );
  late final int Function(_P, int, int) _importarBiblioteca =
      _lib.lookupFunction<Int32 Function(_P, Int8, Int32),
          int Function(_P, int, int)>('bridge_importar_biblioteca_csv');
  late final Pointer<Uint8> Function(int, Pointer<Int32>) _portadaBytes =
      _lib.lookupFunction<Pointer<Uint8> Function(Int32, Pointer<Int32>),
          Pointer<Uint8> Function(int, Pointer<Int32>)>(
    'bridge_obtener_portada_bytes',
  );

  // --- Playlists ---
  late final _P Function() _playlists = _lib
      .lookupFunction<_P Function(), _P Function()>('bridge_obtener_playlists_json');
  late final _P Function() _playlistActiva = _lib.lookupFunction<
      _P Function(), _P Function()>('bridge_obtener_playlist_activa_json');
  late final _P Function(_P) _playlistPorId =
      _lib.lookupFunction<_P Function(_P), _P Function(_P)>(
    'bridge_obtener_playlist_por_id_json',
  );
  late final int Function(_P, _P) _existeNombre =
      _lib.lookupFunction<Int32 Function(_P, _P), int Function(_P, _P)>(
    'bridge_existe_nombre_playlist',
  );
  late final _P Function(_P, int) _crearPlaylist =
      _lib.lookupFunction<_P Function(_P, Int32), _P Function(_P, int)>(
    'bridge_crear_playlist_json',
  );
  late final int Function(_P, _P) _renombrar =
      _lib.lookupFunction<Int32 Function(_P, _P), int Function(_P, _P)>(
    'bridge_renombrar_playlist',
  );
  late final int Function(_P) _eliminarPlaylist =
      _lib.lookupFunction<Int32 Function(_P), int Function(_P)>(
    'bridge_eliminar_playlist',
  );
  late final int Function(_P) _seleccionarPlaylist =
      _lib.lookupFunction<Int32 Function(_P), int Function(_P)>(
    'bridge_seleccionar_playlist_activa',
  );

  // --- Nodos dobles ---
  late final int Function(_P, int) _insIniPorId =
      _lib.lookupFunction<Int32 Function(_P, Int32), int Function(_P, int)>(
    'bridge_playlist_insertar_inicio_por_id',
  );
  late final int Function(_P, int) _insFinPorId =
      _lib.lookupFunction<Int32 Function(_P, Int32), int Function(_P, int)>(
    'bridge_playlist_insertar_final_por_id',
  );
  late final int Function(_P, int, int) _insPosPorId = _lib.lookupFunction<
      Int32 Function(_P, Int32, Int32), int Function(_P, int, int)>(
    'bridge_playlist_insertar_posicion_por_id',
  );
  late final int Function(_P, int, _P, _P, int, _P) _insIni =
      _lib.lookupFunction<Int32 Function(_P, Int32, _P, _P, Int32, _P),
          int Function(_P, int, _P, _P, int, _P)>(
    'bridge_playlist_insertar_inicio',
  );
  late final int Function(_P, int, _P, _P, int, _P) _insFin =
      _lib.lookupFunction<Int32 Function(_P, Int32, _P, _P, Int32, _P),
          int Function(_P, int, _P, _P, int, _P)>(
    'bridge_playlist_insertar_final',
  );
  late final int Function(_P, int, _P, _P, int, _P, int) _insPos =
      _lib.lookupFunction<Int32 Function(_P, Int32, _P, _P, Int32, _P, Int32),
          int Function(_P, int, _P, _P, int, _P, int)>(
    'bridge_playlist_insertar_posicion',
  );
  late final _P Function(_P) _elimIni =
      _lib.lookupFunction<_P Function(_P), _P Function(_P)>(
    'bridge_playlist_eliminar_inicio_json',
  );
  late final _P Function(_P) _elimFin =
      _lib.lookupFunction<_P Function(_P), _P Function(_P)>(
    'bridge_playlist_eliminar_final_json',
  );
  late final _P Function(_P, int) _elimPos =
      _lib.lookupFunction<_P Function(_P, Int32), _P Function(_P, int)>(
    'bridge_playlist_eliminar_posicion_json',
  );

  // --- Algoritmos (GestorReproduccion) ---
  late final int Function(_P, int, int) _mover = _lib.lookupFunction<
      Int32 Function(_P, Int32, Int32), int Function(_P, int, int)>(
    'bridge_mover_cancion_playlist',
  );
  late final int Function(_P, int, int) _shuffle = _lib.lookupFunction<
      Int32 Function(_P, Int32, Uint32), int Function(_P, int, int)>(
    'bridge_aplicar_shuffle_fisher_yates',
  );
  late final int Function(_P, _P, int) _fusionar = _lib.lookupFunction<
      Int32 Function(_P, _P, Int32), int Function(_P, _P, int)>(
    'bridge_fusionar_playlists',
  );
  late final _P Function(_P, int) _exportarPlaylist =
      _lib.lookupFunction<_P Function(_P, Int8), _P Function(_P, int)>(
    'bridge_exportar_playlist_csv',
  );
  late final _P Function(_P, _P, int) _importarPlaylist = _lib.lookupFunction<
      _P Function(_P, _P, Int8), _P Function(_P, _P, int)>(
    'bridge_importar_playlist_csv_json',
  );

  // --- Motor de reproducción ---
  late final _P Function() _estado = _lib.lookupFunction<_P Function(),
      _P Function()>('bridge_obtener_estado_reproduccion_json');
  late final _P Function(_P, int) _reproducirEnPlaylist =
      _lib.lookupFunction<_P Function(_P, Int32), _P Function(_P, int)>(
    'bridge_reproducir_cancion_en_playlist_json',
  );
  late final _P Function(int, _P, _P, int, _P) _reproducirDirecta =
      _lib.lookupFunction<_P Function(Int32, _P, _P, Int32, _P),
          _P Function(int, _P, _P, int, _P)>(
    'bridge_reproducir_cancion_directa_json',
  );
  late final _P Function() _siguiente = _lib
      .lookupFunction<_P Function(), _P Function()>('bridge_siguiente_cancion_json');
  late final _P Function() _anterior = _lib
      .lookupFunction<_P Function(), _P Function()>('bridge_anterior_cancion_json');
  late final void Function(int) _setPlaying =
      _lib.lookupFunction<Void Function(Int32), void Function(int)>(
    'bridge_set_playing',
  );
  late final void Function(int) _seekTo =
      _lib.lookupFunction<Void Function(Int32), void Function(int)>(
    'bridge_seek_to',
  );
  late final void Function(double) _setVolumen =
      _lib.lookupFunction<Void Function(Double), void Function(double)>(
    'bridge_set_volumen',
  );
  late final void Function(int) _setModo =
      _lib.lookupFunction<Void Function(Int32), void Function(int)>(
    'bridge_set_modo_repeticion',
  );

  // --- Historial LIFO ---
  late final _P Function() _historial = _lib
      .lookupFunction<_P Function(), _P Function()>('bridge_obtener_historial_json');
  late final int Function() _durHistorial =
      _lib.lookupFunction<Int32 Function(), int Function()>(
    'bridge_calcular_duracion_total_historial',
  );
  late final void Function(int, _P, _P, int, _P, _P) _registrarHistorial =
      _lib.lookupFunction<Void Function(Int32, _P, _P, Int32, _P, _P),
          void Function(int, _P, _P, int, _P, _P)>(
    'bridge_registrar_en_historial',
  );
  late final void Function() _limpiarHistorial =
      _lib.lookupFunction<Void Function(), void Function()>(
    'bridge_limpiar_historial',
  );

  // ===========================================================================
  // Utilidades internas
  // ===========================================================================

  /// Convierte el `char*` devuelto por C++ a String de Dart y lo libera
  /// SIEMPRE con `bridge_free_string`.
  String _texto(_P p) {
    if (p == nullptr) {
      return 'null';
    }
    try {
      return p.toDartString();
    } finally {
      _freeString(p);
    }
  }

  T _usar<T>(T Function(_Arena a) cuerpo) {
    final arena = _Arena();
    try {
      return cuerpo(arena);
    } finally {
      arena.liberar();
    }
  }

  static int _charCode(String delimitador) =>
      delimitador.isEmpty ? 59 : delimitador.codeUnitAt(0); // 59 = ';'

  // --- Caché de portadas (APIC / PICTURE) -----------------------------------
  final Map<int, Uint8List?> _cachePortadas = {};

  Uint8List? _leerPortada(int id) {
    final outTam = calloc<Int32>();
    try {
      final p = _portadaBytes(id, outTam);
      final n = outTam.value;
      if (p == nullptr) {
        return null;
      }
      try {
        if (n <= 0) {
          return null;
        }
        return Uint8List.fromList(p.asTypedList(n));
      } finally {
        _freeBytes(p);
      }
    } finally {
      calloc.free(outTam);
    }
  }

  CancionModel _hidratarPortada(CancionModel c) {
    if (c.rutaArchivo == null || c.rutaArchivo!.isEmpty) {
      return c;
    }
    final bytes = _cachePortadas.putIfAbsent(c.id, () => _leerPortada(c.id));
    return bytes == null ? c : c.copyWith(portadaBytes: bytes);
  }

  void _invalidarPortada(int id) => _cachePortadas.remove(id);

  // --- Deserialización --------------------------------------------------------
  CancionModel _aCancion(Map<String, dynamic> m) =>
      _hidratarPortada(CancionModel.fromJson(m));

  CancionModel? _cancionONull(String json) {
    final d = jsonDecode(json);
    if (d is Map<String, dynamic>) {
      return _aCancion(d);
    }
    return null;
  }

  List<CancionModel> _listaCanciones(String json) {
    final d = jsonDecode(json);
    if (d is! List) {
      return <CancionModel>[];
    }
    return d
        .whereType<Map<String, dynamic>>()
        .map(_aCancion)
        .toList(growable: false);
  }

  static ModoRepeticion _modoDesdeJson(Map<String, dynamic> m) {
    final codigo = m['modo_repeticion_codigo'];
    if (codigo is int) {
      return ModoRepeticion.values[codigo.clamp(0, 2)];
    }
    switch (m['modo_repeticion']) {
      case 'SIN_REPETICION':
        return ModoRepeticion.sinRepeticion;
      case 'REPETIR_UNA':
        return ModoRepeticion.repetirUna;
      default:
        return ModoRepeticion.repetirTodas;
    }
  }

  PlaylistModel _aPlaylist(Map<String, dynamic> m) {
    final canciones = (m['canciones'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_aCancion)
        .toList(growable: false);
    final idx = m['indice_actual'];
    return PlaylistModel(
      id: m['id'] as String,
      nombre: m['nombre'] as String? ?? '',
      canciones: canciones,
      indiceActual: (idx is int && idx >= 0) ? idx : null,
      modoRepeticion: _modoDesdeJson(m),
      esActiva: m['es_activa'] as bool? ?? false,
    );
  }

  PlaylistModel? _playlistONull(String json) {
    final d = jsonDecode(json);
    return d is Map<String, dynamic> ? _aPlaylist(d) : null;
  }

  // ===========================================================================
  // 1. BIBLIOTECA GENERAL (ListaSimple)
  // ===========================================================================
  @override
  List<CancionModel> obtenerBiblioteca() => _listaCanciones(_texto(_biblioteca()));

  @override
  int calcularDuracionTotalBibliotecaSegundos() => _durBiblioteca();

  @override
  int siguienteIdLibreBiblioteca() => _siguienteId();

  @override
  CancionModel? buscarCancionPorId(int id) =>
      _cancionONull(_texto(_buscarPorId(id)));

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
    _invalidarPortada(id);
    final res = _usar((a) => _texto(_agregarCancion(
          id,
          a.str(titulo),
          a.str(artista),
          duracionSegundos,
          a.str(genero),
          a.str(rutaArchivo ?? ''),
          a.str(portadaUrl ?? ''),
          esArchivoLocal ? 1 : 0,
          metadataExtraida ? 1 : 0,
          tamanoBytes ?? -1,
        )));
    final c = _cancionONull(res);
    if (c == null) {
      throw StateError('El puente C++ no pudo agregar la canción $id.');
    }
    return c;
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
    final res = _usar((a) => _texto(_importarAudio(
          a.str(rutaArchivo),
          a.str(tituloOverride ?? ''),
          a.str(artistaOverride ?? ''),
          duracionSegundosOverride ?? 0,
          a.str(generoOverride ?? ''),
          tamanoBytes ?? -1,
        )));
    final d = jsonDecode(res);
    if (d is! Map<String, dynamic>) {
      throw StateError('No se pudo importar el archivo de audio: $rutaArchivo');
    }
    _invalidarPortada(d['id'] as int);
    return _aCancion(d);
  }

  @override
  bool eliminarCancionDeBibliotecaPorId(int id) {
    final ok = _eliminarCancion(id) != 0;
    if (ok) {
      _invalidarPortada(id);
    }
    return ok;
  }

  @override
  CancionModel? toggleFavoritoCancion(int id) =>
      _cancionONull(_texto(_toggleFavorito(id)));

  @override
  String exportarBibliotecaCSV({
    String delimitador = ';',
    bool incluirCamposExtendidos = false,
  }) {
    final t = _texto(_exportarBiblioteca(
      _charCode(delimitador),
      incluirCamposExtendidos ? 1 : 0,
    ));
    return t == 'null' ? '' : t;
  }

  @override
  int importarBibliotecaDesdeCSV(
    String contenidoCSV, {
    String delimitador = ';',
    bool reemplazarExistente = false,
  }) {
    _cachePortadas.clear();
    return _usar((a) => _importarBiblioteca(
          a.str(contenidoCSV),
          _charCode(delimitador),
          reemplazarExistente ? 1 : 0,
        ));
  }

  // ===========================================================================
  // 2. PLAYLISTS (ListaDobleCircular* playlists[20])
  // ===========================================================================
  @override
  List<PlaylistModel> obtenerPlaylists() {
    final d = jsonDecode(_texto(_playlists()));
    if (d is! List) {
      return <PlaylistModel>[];
    }
    return d
        .whereType<Map<String, dynamic>>()
        .map(_aPlaylist)
        .toList(growable: false);
  }

  @override
  PlaylistModel? obtenerPlaylistActiva() =>
      _playlistONull(_texto(_playlistActiva()));

  @override
  PlaylistModel? obtenerPlaylistPorId(String playlistId) =>
      _usar((a) => _playlistONull(_texto(_playlistPorId(a.str(playlistId)))));

  @override
  bool existeNombrePlaylist(String nombre, {String? ignorarPlaylistId}) =>
      _usar((a) =>
          _existeNombre(a.str(nombre), a.str(ignorarPlaylistId ?? '')) != 0);

  @override
  PlaylistModel? crearPlaylist(String nombre, {bool activarAlCrear = true}) =>
      _usar((a) => _playlistONull(
          _texto(_crearPlaylist(a.str(nombre), activarAlCrear ? 1 : 0))));

  @override
  bool renombrarPlaylist(String playlistId, String nuevoNombre) => _usar(
      (a) => _renombrar(a.str(playlistId), a.str(nuevoNombre)) != 0);

  @override
  bool eliminarPlaylist(String playlistId) =>
      _usar((a) => _eliminarPlaylist(a.str(playlistId)) != 0);

  @override
  bool seleccionarPlaylistActiva(String playlistId) =>
      _usar((a) => _seleccionarPlaylist(a.str(playlistId)) != 0);

  // ===========================================================================
  // 3. NODOS DOBLES (ListaDobleCircular)
  // ===========================================================================
  bool _estaEnBiblioteca(int id) => _texto(_buscarPorId(id)) != 'null';

  @override
  bool insertarCancionAlInicio(String playlistId, CancionModel cancion) {
    return _usar((a) {
      if (_estaEnBiblioteca(cancion.id)) {
        return _insIniPorId(a.str(playlistId), cancion.id) != 0;
      }
      return _insIni(a.str(playlistId), cancion.id, a.str(cancion.titulo),
              a.str(cancion.artista), cancion.duracionSegundos,
              a.str(cancion.genero)) !=
          0;
    });
  }

  @override
  bool insertarCancionAlFinal(String playlistId, CancionModel cancion) {
    return _usar((a) {
      if (_estaEnBiblioteca(cancion.id)) {
        return _insFinPorId(a.str(playlistId), cancion.id) != 0;
      }
      return _insFin(a.str(playlistId), cancion.id, a.str(cancion.titulo),
              a.str(cancion.artista), cancion.duracionSegundos,
              a.str(cancion.genero)) !=
          0;
    });
  }

  @override
  bool insertarCancionEnPosicion(
    String playlistId,
    CancionModel cancion,
    int posicionCeroBased,
  ) {
    return _usar((a) {
      if (_estaEnBiblioteca(cancion.id)) {
        return _insPosPorId(
                a.str(playlistId), cancion.id, posicionCeroBased) !=
            0;
      }
      return _insPos(a.str(playlistId), cancion.id, a.str(cancion.titulo),
              a.str(cancion.artista), cancion.duracionSegundos,
              a.str(cancion.genero), posicionCeroBased) !=
          0;
    });
  }

  @override
  CancionModel? eliminarCancionAlInicio(String playlistId) =>
      _usar((a) => _cancionONull(_texto(_elimIni(a.str(playlistId)))));

  @override
  CancionModel? eliminarCancionAlFinal(String playlistId) =>
      _usar((a) => _cancionONull(_texto(_elimFin(a.str(playlistId)))));

  @override
  CancionModel? eliminarCancionEnPosicion(
    String playlistId,
    int posicionCeroBased,
  ) =>
      _usar((a) => _cancionONull(
          _texto(_elimPos(a.str(playlistId), posicionCeroBased))));

  // ===========================================================================
  // 4. ALGORITMOS (GestorReproduccion)
  // ===========================================================================
  @override
  bool moverCancionEnPlaylist(
    String playlistId,
    int posOrigenCeroBased,
    int posDestinoCeroBased,
  ) =>
      _usar((a) =>
          _mover(a.str(playlistId), posOrigenCeroBased, posDestinoCeroBased) !=
          0);

  @override
  bool aplicarShuffleFisherYates(String playlistId, {int? semilla}) =>
      _usar((a) =>
          _shuffle(a.str(playlistId), semilla != null ? 1 : 0,
              (semilla ?? 0) & 0xFFFFFFFF) !=
          0);

  @override
  bool fusionarPlaylists({
    required String playlistPrincipalId,
    required String playlistSecundariaId,
    required bool vaciarSecundaria,
  }) =>
      _usar((a) =>
          _fusionar(a.str(playlistPrincipalId), a.str(playlistSecundariaId),
              vaciarSecundaria ? 1 : 0) !=
          0);

  @override
  String exportarPlaylistCSV(String playlistId, {String delimitador = ';'}) {
    final t = _usar((a) =>
        _texto(_exportarPlaylist(a.str(playlistId), _charCode(delimitador))));
    return t == 'null' ? '' : t;
  }

  @override
  PlaylistModel? importarPlaylistDesdeCSV({
    required String nombrePlaylist,
    required String contenidoCSV,
    String delimitador = ';',
  }) =>
      _usar((a) => _playlistONull(_texto(_importarPlaylist(
            a.str(nombrePlaylist),
            a.str(contenidoCSV),
            _charCode(delimitador),
          ))));

  // ===========================================================================
  // 5. MOTOR DE REPRODUCCIÓN, CURSOR CIRCULAR Y AUDIO
  // ===========================================================================
  @override
  PlaybackStateModel obtenerEstadoReproduccion() {
    final d = jsonDecode(_texto(_estado()));
    if (d is! Map<String, dynamic>) {
      return const PlaybackStateModel();
    }
    final actual = d['cancion_actual'];
    return PlaybackStateModel(
      cancionActual: actual is Map<String, dynamic> ? _aCancion(actual) : null,
      playlistActivaId: d['playlist_activa_id'] as String?,
      nombreContexto:
          d['nombre_contexto'] as String? ?? 'Sin playlist activa',
      isPlaying: d['is_playing'] as bool? ?? false,
      posicionActualSegundos: d['posicion_actual_segundos'] as int? ?? 0,
      duracionTotalSegundos: d['duracion_total_segundos'] as int? ?? 0,
      volumen: (d['volumen'] as num?)?.toDouble() ?? 0.78,
      modoRepeticion: _modoDesdeJson(d),
      ultimoShuffleSemilla: d['ultimo_shuffle_semilla'] as int?,
      mensajeEstado: d['mensaje_estado'] as String?,
    );
  }

  @override
  CancionModel? reproducirCancionEnPlaylist({
    required String playlistId,
    required int indiceNodo,
  }) {
    final res = _usar(
        (a) => _texto(_reproducirEnPlaylist(a.str(playlistId), indiceNodo)));
    final c = _cancionONull(res);
    if (c != null) {
      _invalidarPortada(c.id);
      return _aCancion(jsonDecode(res) as Map<String, dynamic>);
    }
    return null;
  }

  @override
  CancionModel? reproducirCancionDirecta(CancionModel cancion) {
    _invalidarPortada(cancion.id);
    return _usar((a) => _cancionONull(_texto(_reproducirDirecta(
          cancion.id,
          a.str(cancion.titulo),
          a.str(cancion.artista),
          cancion.duracionSegundos,
          a.str(cancion.genero),
        ))));
  }

  @override
  CancionModel? siguienteCancion() => _cancionONull(_texto(_siguiente()));

  @override
  CancionModel? anteriorCancion() => _cancionONull(_texto(_anterior()));

  @override
  void setPlaying(bool isPlaying) => _setPlaying(isPlaying ? 1 : 0);

  @override
  void seekTo(int posicionSegundos) => _seekTo(posicionSegundos);

  @override
  void setVolumen(double volumen) => _setVolumen(volumen.clamp(0.0, 1.0));

  @override
  void setModoRepeticion(ModoRepeticion nuevoModo) =>
      _setModo(nuevoModo.index); // 0=SIN, 1=UNA, 2=TODAS (mismo orden que C++)

  // ===========================================================================
  // 6. HISTORIAL (ListaSimple LIFO)
  // ===========================================================================
  @override
  List<HistorialItemModel> obtenerHistorial() {
    final d = jsonDecode(_texto(_historial()));
    if (d is! List) {
      return <HistorialItemModel>[];
    }
    final items = <HistorialItemModel>[];
    for (final m in d.whereType<Map<String, dynamic>>()) {
      final c = m['cancion'];
      if (c is! Map<String, dynamic>) {
        continue;
      }
      items.add(HistorialItemModel(
        idRegistro: m['id_registro'] as String? ?? '',
        cancion: _aCancion(c),
        fechaReproduccion:
            DateTime.tryParse(m['fecha_reproduccion'] as String? ?? '') ??
                DateTime.now(),
        origenNombre: m['origen_nombre'] as String? ?? '',
      ));
    }
    return items;
  }

  @override
  int calcularDuracionTotalHistorialSegundos() => _durHistorial();

  @override
  void registrarEnHistorial(CancionModel cancion, {String? origenNombre}) {
    _usar((a) {
      _registrarHistorial(
        cancion.id,
        a.str(cancion.titulo),
        a.str(cancion.artista),
        cancion.duracionSegundos,
        a.str(cancion.genero),
        a.str(origenNombre ?? 'Biblioteca General'),
      );
    });
  }

  @override
  void limpiarHistorial() => _limpiarHistorial();

  // ===========================================================================
  // Ciclo de vida
  // ===========================================================================

  /// Libera los TADs y el motor de audio nativo. Llamar al cerrar la app.
  void dispose() => _shutdown();
}
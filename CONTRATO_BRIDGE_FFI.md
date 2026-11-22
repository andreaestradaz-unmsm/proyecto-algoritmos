# Contrato de Datos y Capa Puente C++ FFI/JSON (`bridge_ffi`)

**Responsable:** Estudiante 2  
**Archivos del módulo:**
- [bridge_ffi.h](bridge_ffi.h): Declaraciones `extern "C"` de la API nativa (`BRIDGE_API`).
- [bridge_ffi.cpp](bridge_ffi.cpp): Implementación completa sobre los TADs reales (`ListaSimple`, `ListaDobleCircular`, `GestorReproduccion`, `Cancion`), serialización JSON RFC-8259 y gestión de memoria heap (`malloc`/`free`).
- [pruebas_bridge.cpp](pruebas_bridge.cpp): Suite de pruebas unitarias/integración del puente y exportador `--dump-json`.

---

## 1. Compilación de la Librería Compartida y Pruebas

### Con `mingw32-make` (Windows) o `make` (Linux/macOS)
```bash
# Compilar la librería nativa (eda_music_bridge.dll en Windows / libeda_music_bridge.so en Unix)
mingw32-make bridge

# Compilar y ejecutar las pruebas del puente FFI/JSON
mingw32-make test-bridge

# Compilar y ejecutar las pruebas originales del equipo
mingw32-make test
```

### Compilación manual con `g++` (Windows)
```bash
g++ -std=c++17 -Wall -Wextra -Wno-unused-parameter -pedantic -DBRIDGE_EXPORTS bridge_ffi.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp -o eda_music_bridge.dll -shared -static-libgcc -static-libstdc++
```

---

## 2. Contrato JSON (100% alineado con los modelos de Flutter)

### A) `Cancion` (`CancionModel.fromJson`)
```json
{
  "id": 1,
  "titulo": "Bohemian Rhapsody",
  "artista": "Queen",
  "duracion_segundos": 354,
  "duracion_formateada": "05:54",
  "genero": "Rock",
  "ruta_archivo": "C:\\Musica\\Queen - Bohemian Rhapsody.mp3",
  "portada_url": null,
  "es_favorita": true,
  "es_archivo_local": true,
  "metadata_extraida": true,
  "tamano_bytes": 4800000
}
```

### B) `Playlist` (`PlaylistModel`)
```json
{
  "id": "pl_1",
  "nombre": "Esenciales EDA",
  "tamano": 3,
  "esta_vacia": false,
  "indice_actual": 2,
  "modo_repeticion": "REPETIR_TODAS",
  "modo_repeticion_codigo": 2,
  "es_activa": true,
  "duracion_total_segundos": 860,
  "duracion_total_formateada": "00:14:20",
  "canciones": [ ... ]
}
```
Códigos de `ModoRepeticion`:
- `0` → `"SIN_REPETICION"`
- `1` → `"REPETIR_UNA"`
- `2` → `"REPETIR_TODAS"`

### C) `PlaybackState` (`PlaybackStateModel`)
```json
{
  "cancion_actual": { ... },
  "playlist_activa_id": "pl_1",
  "nombre_contexto": "Esenciales EDA",
  "is_playing": true,
  "posicion_actual_segundos": 42,
  "duracion_total_segundos": 294,
  "volumen": 0.650,
  "modo_repeticion": "REPETIR_TODAS",
  "modo_repeticion_codigo": 2,
  "ultimo_shuffle_semilla": 42,
  "mensaje_estado": null
}
```

### D) `HistorialItem` (`HistorialItemModel`)
```json
{
  "id_registro": "hist_1",
  "cancion": { ... },
  "fecha_reproduccion": "2026-11-22T11:30:00",
  "origen_nombre": "Esenciales EDA"
}
```

---

## 3. Guía de Conexión para el Estudiante 1 (Audio Real y Metadatos)

Dentro de [bridge_ffi.cpp](bridge_ffi.cpp) quedaron marcados con **`// === [ESPACIO PARA ESTUDIANTE 1: ...] ===`** los puntos exactos donde debes conectar tu código cuando termines tu parte:

1. **Headers y motor `miniaudio.h`:**
   - Parte superior de `bridge_ffi.cpp`: incluir tu cabecera del motor de audio.
   - `bridge_init(...)` y `bridge_shutdown()`: inicializar y liberar `ma_engine`.
2. **Campos extendidos de `Cancion` y CSV de 7 columnas:**
   - `serializarCancionJson(...)`: leer `rutaArchivo` / `portadaUrl` desde `Cancion` cuando agregues esos atributos/getters a `cancion.h`.
   - `parsearLineaCSVExtendida(...)`: delegar directamente si `Cancion::desdeCSV` ya soporta 7 columnas.
3. **Extracción real de tags y carátula embebida (`APIC` / `PICTURE`):**
   - `bridge_importar_archivo_audio_json(...)`: extraer tags reales, duración real y portada del archivo de audio.
   - `bridge_obtener_portada_bytes(...)`: devolver los bytes crudos de la carátula reservados con `std::malloc` y su longitud en `*out_tamano`.
4. **Control de reproducción en tiempo real (`EstadoReproduccionActual`):**
   - `bridge_obtener_estado_reproduccion_json()`: sincronizar `posicionActualSegundos`, `isPlaying` y detectar fin natural de pista.
   - `bridge_reproducir_cancion_en_playlist_json(...)`, `bridge_reproducir_cancion_directa_json(...)`, `bridge_siguiente_cancion_json()`, `bridge_anterior_cancion_json()`, `bridge_set_playing(...)`, `bridge_seek_to(...)` y `bridge_set_volumen(...)`: disparar carga/reproducción/pausa/seek/volumen sobre `miniaudio.h`.

---

## 4. Guía de Conexión para el Estudiante 3 (`CppMusicRepository` en Flutter)

1. Carga la biblioteca nativa (`eda_music_bridge.dll` / `libeda_music_bridge.so`) con `dart:ffi`.
2. Llama a `bridge_init(rutaCsv)` al iniciar el repositorio y `bridge_shutdown()` al cerrar.
3. Por cada método de `MusicRepository`, invoca la función `bridge_*` correspondiente, convierte el `Pointer<Utf8>` con `.toDartString()` y **libéralo inmediatamente en un bloque `try/finally` usando `bridge_free_string(ptr)`**.

| Método en `MusicRepository` (Dart) | Función `extern "C"` en `bridge_ffi.h` |
|---|---|
| `obtenerBiblioteca()` | `bridge_obtener_biblioteca_json()` |
| `calcularDuracionTotalBibliotecaSegundos()` | `bridge_calcular_duracion_total_biblioteca()` |
| `siguienteIdLibreBiblioteca()` | `bridge_siguiente_id_libre_biblioteca()` |
| `buscarCancionPorId(id)` | `bridge_buscar_cancion_por_id_json(id)` |
| `agregarCancionABiblioteca(...)` | `bridge_agregar_cancion_biblioteca_json(...)` |
| `importarArchivoAudio(...)` | `bridge_importar_archivo_audio_json(...)` |
| `eliminarCancionDeBibliotecaPorId(id)` | `bridge_eliminar_cancion_biblioteca(id)` |
| `toggleFavoritoCancion(id)` | `bridge_toggle_favorito_cancion_json(id)` |
| `exportarBibliotecaCSV(...)` | `bridge_exportar_biblioteca_csv(...)` |
| `importarBibliotecaDesdeCSV(...)` | `bridge_importar_biblioteca_csv(...)` |
| `obtenerPlaylists()` / `obtenerPlaylistActiva()` / `obtenerPlaylistPorId()` | `bridge_obtener_playlists_json()` / `bridge_obtener_playlist_activa_json()` / `bridge_obtener_playlist_por_id_json(...)` |
| `existeNombrePlaylist(...)` / `crearPlaylist(...)` / `renombrarPlaylist(...)` / `eliminarPlaylist(...)` / `seleccionarPlaylistActiva(...)` | `bridge_existe_nombre_playlist(...)` / `bridge_crear_playlist_json(...)` / `bridge_renombrar_playlist(...)` / `bridge_eliminar_playlist(...)` / `bridge_seleccionar_playlist_activa(...)` |
| `insertarCancionAlInicio/Final/EnPosicion(...)` | `bridge_playlist_insertar_inicio/final/posicion_por_id(...)` (o directo) |
| `eliminarCancionAlInicio/Final/EnPosicion(...)` | `bridge_playlist_eliminar_inicio/final/posicion_json(...)` |
| `moverCancionEnPlaylist(...)` / `aplicarShuffleFisherYates(...)` / `fusionarPlaylists(...)` | `bridge_mover_cancion_playlist(...)` / `bridge_aplicar_shuffle_fisher_yates(...)` / `bridge_fusionar_playlists(...)` |
| `exportarPlaylistCSV(...)` / `importarPlaylistDesdeCSV(...)` | `bridge_exportar_playlist_csv(...)` / `bridge_importar_playlist_csv_json(...)` |
| `obtenerEstadoReproduccion()` | `bridge_obtener_estado_reproduccion_json()` |
| `reproducirCancionEnPlaylist(...)` / `reproducirCancionDirecta(...)` | `bridge_reproducir_cancion_en_playlist_json(...)` / `bridge_reproducir_cancion_directa_json(...)` |
| `siguienteCancion()` / `anteriorCancion()` | `bridge_siguiente_cancion_json()` / `bridge_anterior_cancion_json()` |
| `setPlaying()` / `seekTo()` / `setVolumen()` / `setModoRepeticion()` | `bridge_set_playing(...)` / `bridge_seek_to(...)` / `bridge_set_volumen(...)` / `bridge_set_modo_repeticion(...)` |
| `obtenerHistorial()` / `calcularDuracionTotalHistorialSegundos()` / `registrarEnHistorial()` / `limpiarHistorial()` | `bridge_obtener_historial_json()` / `bridge_calcular_duracion_total_historial()` / `bridge_registrar_en_historial(...)` / `bridge_limpiar_historial()` |

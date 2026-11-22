#ifndef BRIDGE_FFI_H
#define BRIDGE_FFI_H

/**
 * ============================================================================
 * MODULO ASIGNADO A: ESTUDIANTE 2 (Capa Puente C++ y Contrato de Datos FFI/JSON)
 * ============================================================================
 * Proposito:
 *   Exponer una interfaz C pura (`extern "C"`) sobre las estructuras reales del
 *   curso (ListaSimple, ListaDobleCircular, GestorReproduccion y Cancion) para
 *   que Flutter/Dart (`CppMusicRepository` - Estudiante 3) pueda invocarlas via
 *   `dart:ffi` intercambiando cadenas JSON y codigos enteros.
 *
 * Reglas de memoria para quien llame desde Dart / C (Estudiante 3):
 *   - Toda cadena `char*` retornada por una funcion `bridge_*` fue reservada en
 *     heap con `malloc` y DEBE liberarse llamando a `bridge_free_string(ptr)`.
 *   - Todo buffer `unsigned char*` retornado por `bridge_obtener_portada_bytes`
 *     DEBE liberarse llamando a `bridge_free_bytes(ptr)`.
 *   - Los punteros `const char*` pasados como argumentos pertenecen al llamador.
 * ============================================================================
 */

#ifdef _WIN32
    #ifdef BRIDGE_EXPORTS
        #define BRIDGE_API __declspec(dllexport)
    #else
        #define BRIDGE_API
    #endif
#else
    #define BRIDGE_API __attribute__((visibility("default")))
#endif

#define BRIDGE_MAX_PLAYLISTS 20

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * 0. CICLO DE VIDA DEL PUENTE Y GESTION DE MEMORIA
 * ============================================================================ */

/**
 * Inicializa (o reinicia) el estado interno del puente y los TADs en memoria.
 * Si `ruta_biblioteca_csv` no es nulo ni vacio, intenta cargar la biblioteca
 * desde ese archivo CSV (soporta 5 columnas base y 7 columnas extendidas).
 * Retorna 1 si todo se inicializo correctamente; 0 si fallo al abrir el CSV
 * indicado (el puente igual queda inicializado y listo para usarse).
 */
BRIDGE_API int bridge_init(const char* ruta_biblioteca_csv);

/**
 * Libera toda la memoria dinamica interna (nodos, playlists y metadatos) y
 * detiene cualquier recurso activo del motor de audio.
 */
BRIDGE_API void bridge_shutdown(void);

/**
 * Reinicia todas las estructuras en memoria dejandolas vacias sin destruir el
 * estado listo del puente (util entre sesiones o pruebas).
 */
BRIDGE_API void bridge_reset(void);

/**
 * Libera una cadena JSON o CSV devuelta por cualquiera de las funciones `bridge_*`.
 */
BRIDGE_API void bridge_free_string(char* ptr);

/**
 * Libera un arreglo de bytes devuelto por `bridge_obtener_portada_bytes`.
 */
BRIDGE_API void bridge_free_bytes(unsigned char* ptr);

/**
 * Retorna la constante maxima de playlists soportadas (`BRIDGE_MAX_PLAYLISTS = 20`).
 */
BRIDGE_API int bridge_get_max_playlists(void);


/* ============================================================================
 * 1. BIBLIOTECA GENERAL (ListaSimple)
 * ============================================================================ */

/**
 * Retorna un arreglo JSON `[ {...}, ... ]` con todas las canciones de `biblioteca`.
 */
BRIDGE_API char* bridge_obtener_biblioteca_json(void);

/**
 * Retorna la suma de `duracion_segundos` de todas las canciones en `biblioteca`.
 */
BRIDGE_API int bridge_calcular_duracion_total_biblioteca(void);

/**
 * Retorna `max(id) + 1` en `biblioteca` (o `1` si la biblioteca esta vacia).
 */
BRIDGE_API int bridge_siguiente_id_libre_biblioteca(void);

/**
 * Busca una cancion por su `id` en `biblioteca` y retorna su objeto JSON,
 * o `"null"` si no existe.
 */
BRIDGE_API char* bridge_buscar_cancion_por_id_json(int id);

/**
 * Agrega una nueva cancion al final de `biblioteca` (`ListaSimple::agregarAlFinal`)
 * y registra sus metadatos extendidos. Retorna el objeto JSON creado.
 * Para campos opcionales desconocidos pasar `NULL`/`""` o `-1` en `tamano_bytes`.
 */
BRIDGE_API char* bridge_agregar_cancion_biblioteca_json(
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero,
    const char* ruta_archivo,
    const char* portada_url,
    int es_archivo_local,
    int metadata_extraida,
    int tamano_bytes
);

/**
 * Importa un archivo de audio local a `biblioteca`.
 * Si `titulo_override`, `artista_override` o `genero_override` son nulos o
 * vacios, infiere metadatos del nombre del archivo (y del bloque de Estudiante 1
 * cuando extraiga tags reales). Si `duracion_segundos_override <= 0`, estima o
 * consulta la duracion real. Retorna el objeto JSON creado (o `"null"` si ruta vacia).
 */
BRIDGE_API char* bridge_importar_archivo_audio_json(
    const char* ruta_archivo,
    const char* titulo_override,
    const char* artista_override,
    int duracion_segundos_override,
    const char* genero_override,
    int tamano_bytes
);

/**
 * Elimina de `biblioteca` la cancion con el `id` indicado (`ListaSimple::eliminarPorId`).
 * Las playlists conservan su copia del nodo. Retorna 1 si se elimino, 0 si no existia.
 */
BRIDGE_API int bridge_eliminar_cancion_biblioteca(int id);

/**
 * Alterna el estado `es_favorita` de la cancion con el `id` indicado.
 * Retorna el objeto JSON actualizado de la cancion, o `"null"` si el `id` no existe.
 */
BRIDGE_API char* bridge_toggle_favorito_cancion_json(int id);

/**
 * Exporta toda la biblioteca en formato CSV usando `delimitador` (ej. `';'`).
 * Si `incluir_campos_extendidos != 0`, emite 7 columnas agregando `ruta_archivo`
 * y `portada`; en caso contrario emite las 5 columnas clasicas.
 */
BRIDGE_API char* bridge_exportar_biblioteca_csv(char delimitador, int incluir_campos_extendidos);

/**
 * Importa canciones desde texto CSV en memoria hacia `biblioteca`.
 * Soporta lineas de 5 columnas y de 7 columnas. Si `reemplazar_existente != 0`,
 * limpia `biblioteca` antes de importar. Retorna el total de canciones importadas.
 */
BRIDGE_API int bridge_importar_biblioteca_csv(
    const char* contenido_csv,
    char delimitador,
    int reemplazar_existente
);

/**
 * Persiste `biblioteca` directamente en disco (`ruta_archivo`). Retorna 1 si ok, 0 si fallo.
 */
BRIDGE_API int bridge_guardar_biblioteca_archivo_csv(const char* ruta_archivo, char delimitador);

/**
 * Carga `biblioteca` directamente desde un archivo en disco (`ruta_archivo`).
 * Retorna la cantidad de canciones cargadas, o -1 si no se pudo abrir el archivo.
 */
BRIDGE_API int bridge_cargar_biblioteca_archivo_csv(const char* ruta_archivo, char delimitador);

/**
 * Expone los bytes crudos de la caratula embebida (`APIC` / `PICTURE`).
 * Escribe la longitud en `*out_tamano` y retorna el buffer (o `NULL` si no hay caratula).
 * Nota: Se completara al conectar los tags reales de Estudiante 1.
 */
BRIDGE_API unsigned char* bridge_obtener_portada_bytes(int cancion_id, int* out_tamano);


/* ============================================================================
 * 2. GESTION DE PLAYLISTS (ListaDobleCircular* playlists[20])
 * ============================================================================ */

/**
 * Retorna un arreglo JSON `[ {...}, ... ]` con todas las playlists existentes.
 */
BRIDGE_API char* bridge_obtener_playlists_json(void);

/**
 * Retorna el objeto JSON de la playlist activa, o `"null"` si no hay ninguna.
 */
BRIDGE_API char* bridge_obtener_playlist_activa_json(void);

/**
 * Retorna el objeto JSON de la playlist con `playlist_id` (ej. `"pl_1"`), o `"null"`.
 */
BRIDGE_API char* bridge_obtener_playlist_por_id_json(const char* playlist_id);

/**
 * Verifica si existe una playlist con ese nombre (insensible a mayusculas).
 * Si `ignorar_playlist_id` no es vacio, excluye esa playlist de la comprobacion.
 * Retorna 1 si ya existe, 0 si esta disponible.
 */
BRIDGE_API int bridge_existe_nombre_playlist(const char* nombre, const char* ignorar_playlist_id);

/**
 * Crea una nueva `ListaDobleCircular` en el arreglo `playlists[20]`.
 * Retorna su objeto JSON, o `"null"` si se alcanzo el limite (20), nombre vacio o duplicado.
 */
BRIDGE_API char* bridge_crear_playlist_json(const char* nombre, int activar_al_crear);

/**
 * Renombra la playlist indicada validando que no este vacio ni duplicado.
 * Retorna 1 si ok, 0 si fallo.
 */
BRIDGE_API int bridge_renombrar_playlist(const char* playlist_id, const char* nuevo_nombre);

/**
 * Libera y elimina la playlist indicada del arreglo `playlists[20]`.
 * Si era la activa, reasigna la primera disponible (o ninguna si queda vacio).
 * Retorna 1 si ok, 0 si no existia.
 */
BRIDGE_API int bridge_eliminar_playlist(const char* playlist_id);

/**
 * Selecciona `playlist_id` como playlist activa y sincroniza el estado de reproduccion.
 * Retorna 1 si ok, 0 si no existia.
 */
BRIDGE_API int bridge_seleccionar_playlist_activa(const char* playlist_id);


/* ============================================================================
 * 3. OPERACIONES DE NODOS EN PLAYLIST (ListaDobleCircular)
 * ============================================================================ */

/**
 * Inserta en la playlist indicada la cancion buscada por `cancion_id` en `biblioteca`.
 * `posicion_cero_based` debe cumplir `0 <= pos <= tamano`.
 * Retornan 1 si se inserto correctamente, 0 en caso de error.
 */
BRIDGE_API int bridge_playlist_insertar_inicio_por_id(const char* playlist_id, int cancion_id);
BRIDGE_API int bridge_playlist_insertar_final_por_id(const char* playlist_id, int cancion_id);
BRIDGE_API int bridge_playlist_insertar_posicion_por_id(
    const char* playlist_id,
    int cancion_id,
    int posicion_cero_based
);

/**
 * Variantes que reciben los datos directos de `Cancion` sin buscar en `biblioteca`.
 */
BRIDGE_API int bridge_playlist_insertar_inicio(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
);
BRIDGE_API int bridge_playlist_insertar_final(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
);
BRIDGE_API int bridge_playlist_insertar_posicion(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero,
    int posicion_cero_based
);

/**
 * Eliminan el nodo al inicio, final o en `posicion_cero_based` (`0 <= pos < tamano`).
 * Retornan el objeto JSON de la cancion eliminada, o `"null"` si la operacion fallo.
 */
BRIDGE_API char* bridge_playlist_eliminar_inicio_json(const char* playlist_id);
BRIDGE_API char* bridge_playlist_eliminar_final_json(const char* playlist_id);
BRIDGE_API char* bridge_playlist_eliminar_posicion_json(
    const char* playlist_id,
    int posicion_cero_based
);


/* ============================================================================
 * 4. ALGORITMOS DE REPRODUCCION Y LISTAS (GestorReproduccion)
 * ============================================================================ */

/**
 * Reordena un nodo desde `pos_origen_cero_based` hacia `pos_destino_cero_based`.
 * Retorna 1 si ok, 0 si playlist o posiciones invalidas.
 */
BRIDGE_API int bridge_mover_cancion_playlist(
    const char* playlist_id,
    int pos_origen_cero_based,
    int pos_destino_cero_based
);

/**
 * Aplica Fisher-Yates sobre la playlist (`GestorReproduccion::aplicarShuffleFisherYates`).
 * Si `usar_semilla == 0`, genera una semilla pseudoaleatoria automatica.
 * Retorna 1 si se mezclo (tamano > 1), 0 si no existe o tiene <= 1 cancion.
 */
BRIDGE_API int bridge_aplicar_shuffle_fisher_yates(
    const char* playlist_id,
    int usar_semilla,
    unsigned int semilla
);

/**
 * Fusiona `playlist_secundaria_id` al final de `playlist_principal_id`.
 * Si `vaciar_secundaria != 0`, deja vacia la playlist secundaria.
 * Retorna 1 si ok, 0 si fallo (IDs iguales, inexistentes o secundaria vacia).
 */
BRIDGE_API int bridge_fusionar_playlists(
    const char* playlist_principal_id,
    const char* playlist_secundaria_id,
    int vaciar_secundaria
);

/**
 * Exporta una playlist a texto CSV (`;`). Retorna `""` si no existe.
 */
BRIDGE_API char* bridge_exportar_playlist_csv(const char* playlist_id, char delimitador);

/**
 * Crea una nueva playlist y la llena parseando `contenido_csv`.
 * Retorna el objeto JSON de la playlist creada, o `"null"` si no pudo crearse.
 */
BRIDGE_API char* bridge_importar_playlist_csv_json(
    const char* nombre_playlist,
    const char* contenido_csv,
    char delimitador
);

/**
 * Guarda/carga una playlist directamente en disco usando `GestorReproduccion`.
 */
BRIDGE_API int bridge_guardar_playlist_archivo_csv(
    const char* playlist_id,
    const char* ruta_archivo,
    char delimitador
);
BRIDGE_API int bridge_cargar_playlist_archivo_csv(
    const char* playlist_id,
    const char* ruta_archivo,
    char delimitador
);


/* ============================================================================
 * 5. MOTOR DE REPRODUCCION, CURSOR CIRCULAR Y AUDIO
 * ============================================================================ */

/**
 * Retorna el objeto JSON del estado de reproduccion actual (`PlaybackState`).
 */
BRIDGE_API char* bridge_obtener_estado_reproduccion_json(void);

/**
 * Selecciona `playlist_id` como activa, posiciona el cursor circular `actual`
 * en `indice_nodo`, inicia reproduccion y registra en historial LIFO.
 * Retorna el JSON de la cancion reproducida, o `"null"` si fallo.
 */
BRIDGE_API char* bridge_reproducir_cancion_en_playlist_json(
    const char* playlist_id,
    int indice_nodo
);

/**
 * Reproduce una cancion directa (si esta en la playlist activa sincroniza su cursor;
 * si no, la reproduce con contexto de Biblioteca General) y la registra en historial.
 * Retorna el JSON de la cancion en reproduccion.
 */
BRIDGE_API char* bridge_reproducir_cancion_directa_json(
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
);

/**
 * Avanza la reproduccion en la playlist activa respetando `ModoRepeticion`
 * (`ListaDobleCircular::siguienteCancion`). Retorna JSON de la cancion o `"null"`
 * si la lista esta vacia o llego al final en modo `SIN_REPETICION`.
 */
BRIDGE_API char* bridge_siguiente_cancion_json(void);

/**
 * Retrocede al nodo anterior en la playlist activa (`ListaDobleCircular::anteriorCancion`).
 * Retorna JSON de la cancion o `"null"` si no hay playlist activa con canciones.
 */
BRIDGE_API char* bridge_anterior_cancion_json(void);

/**
 * Controla pausa/reproduccion (`is_playing != 0` intenta reanudar o iniciar).
 */
BRIDGE_API void bridge_set_playing(int is_playing);

/**
 * Posiciona la reproduccion actual en `posicion_segundos` (acotado a `[0, duracion]`).
 */
BRIDGE_API void bridge_seek_to(int posicion_segundos);

/**
 * Ajusta el volumen de reproduccion en el rango `[0.0, 1.0]`.
 */
BRIDGE_API void bridge_set_volumen(double volumen);

/**
 * Cambia el modo de repeticion de la playlist activa y del estado global:
 *   0 = SIN_REPETICION
 *   1 = REPETIR_UNA
 *   2 = REPETIR_TODAS
 */
BRIDGE_API void bridge_set_modo_repeticion(int modo_codigo);


/* ============================================================================
 * 6. HISTORIAL LIFO (ListaSimple) Y UTILIDADES
 * ============================================================================ */

/**
 * Retorna un arreglo JSON `[ {...}, ... ]` con el historial (mas reciente primero).
 */
BRIDGE_API char* bridge_obtener_historial_json(void);

/**
 * Retorna la suma de `duracion_segundos` de todas las canciones en `historial`.
 */
BRIDGE_API int bridge_calcular_duracion_total_historial(void);

/**
 * Registra manualmente una cancion al inicio del historial (`agregarAlInicio`).
 */
BRIDGE_API void bridge_registrar_en_historial(
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero,
    const char* origen_nombre
);

/**
 * Vacia todos los nodos del historial (`ListaSimple::limpiar`).
 */
BRIDGE_API void bridge_limpiar_historial(void);

/**
 * Formatea una duracion total en segundos a `"HH:MM:SS"` (equivalente a
 * `InterfazConsola::formatearDuracionTotal`). Liberar con `bridge_free_string`.
 */
BRIDGE_API char* bridge_formatear_duracion_total(int total_segundos);

#ifdef __cplusplus
}
#endif

#endif // BRIDGE_FFI_H

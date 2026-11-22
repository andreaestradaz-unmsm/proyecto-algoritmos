/**
 * ============================================================================
 * pruebas_bridge.cpp - Pruebas del Modulo Puente FFI/JSON (Estudiante 2)
 * ============================================================================
 * Valida la capa `bridge_ffi.h` / `bridge_ffi.cpp` conectada directamente a
 * los TADs reales (`Cancion`, `ListaSimple`, `ListaDobleCircular` y
 * `GestorReproduccion`), verificando reglas de negocio, memoria y JSON valido.
 *
 * Opcion especial:
 *   pruebas_bridge.exe --dump-json
 *   Imprime un objeto JSON compuesto `{biblioteca, playlists, estado, historial}`
 *   para validacion externa con PowerShell `ConvertFrom-Json`.
 * ============================================================================
 */

#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>

#include "bridge_ffi.h"

static int totalPruebas = 0;
static int pruebasFallidas = 0;

static void verificar(bool condicion, const std::string& descripcion, int linea) {
    totalPruebas++;
    if (condicion) {
        std::cout << "  [ok]    " << descripcion << "\n";
    } else {
        pruebasFallidas++;
        std::cout << "  [FALLO] " << descripcion << "   (pruebas_bridge.cpp, linea " << linea << ")\n";
    }
}
#define VERIFICAR(cond, desc) verificar((cond), (desc), __LINE__)

static void grupo(const std::string& nombre) {
    std::cout << "\n=== " << nombre << " ===\n";
}

// Convierte un `char*` reservado en el puente a `std::string` y libera el puntero.
static std::string tomarYLiberar(char* ptr) {
    if (ptr == nullptr) {
        return "";
    }
    std::string copia(ptr);
    bridge_free_string(ptr);
    return copia;
}

static bool contiene(const std::string& texto, const std::string& sub) {
    return texto.find(sub) != std::string::npos;
}

// Construye un escenario representativo para pruebas y para `--dump-json`.
static void prepararEscenarioCompleto() {
    bridge_init("biblioteca.csv");

    tomarYLiberar(bridge_importar_archivo_audio_json(
        "C:\\Musica\\Queen - We Will Rock You \"Live\".mp3",
        nullptr,
        nullptr,
        0,
        "Rock Clasico",
        4800000
    ));

    tomarYLiberar(bridge_crear_playlist_json("Esenciales EDA", 1));
    bridge_playlist_insertar_final_por_id("pl_1", 1);
    bridge_playlist_insertar_final_por_id("pl_1", 2);
    bridge_playlist_insertar_final_por_id("pl_1", 3);

    tomarYLiberar(bridge_crear_playlist_json("Secundaria", 0));
    bridge_playlist_insertar_final_por_id("pl_2", 4);
    bridge_playlist_insertar_final_por_id("pl_2", 5);

    tomarYLiberar(bridge_toggle_favorito_cancion_json(1));
    tomarYLiberar(bridge_reproducir_cancion_en_playlist_json("pl_1", 1));
    tomarYLiberar(bridge_siguiente_cancion_json());
    bridge_set_volumen(0.65);
    bridge_seek_to(42);
}

static void pruebasCicloVidaYBiblioteca() {
    grupo("Ciclo de vida y Biblioteca (ListaSimple + CSV)");
    VERIFICAR(bridge_get_max_playlists() == 20, "MAX_PLAYLISTS == 20");
    VERIFICAR(bridge_init("archivo_que_no_existe_123.csv") == 0, "init con CSV inexistente retorna 0 sin fallar");
    VERIFICAR(bridge_init("biblioteca.csv") == 1, "init carga biblioteca.csv correctamente");

    std::string bib = tomarYLiberar(bridge_obtener_biblioteca_json());
    VERIFICAR(contiene(bib, "\"titulo\":\"Bohemian Rhapsody\""), "biblioteca contiene Bohemian Rhapsody");
    VERIFICAR(bridge_calcular_duracion_total_biblioteca() == 1503, "duracion total biblioteca inicial = 1503 s");
    VERIFICAR(bridge_siguiente_id_libre_biblioteca() == 6, "siguiente ID libre inicial = 6");

    std::string buscada = tomarYLiberar(bridge_buscar_cancion_por_id_json(3));
    VERIFICAR(contiene(buscada, "\"artista\":\"Michael Jackson\""), "buscarPorId(3) encuentra Michael Jackson");
    VERIFICAR(tomarYLiberar(bridge_buscar_cancion_por_id_json(999)) == "null", "buscarPorId inexistente retorna null");

    std::string importada = tomarYLiberar(bridge_importar_archivo_audio_json(
        "C:\\Musica\\Soda_Stereo - Persiana \"Americana\".mp3",
        nullptr,
        nullptr,
        290,
        nullptr,
        6200000
    ));
    VERIFICAR(contiene(importada, "\"id\":6"), "importar audio asigna siguiente ID libre 6");
    VERIFICAR(contiene(importada, "\"ruta_archivo\":\"C:\\\\Musica\\\\Soda_Stereo - Persiana \\\"Americana\\\".mp3\""),
              "escape JSON valido para barras invertidas y comillas en ruta Windows");
    VERIFICAR(contiene(importada, "\"es_archivo_local\":true"), "marca es_archivo_local = true");

    std::string fav = tomarYLiberar(bridge_toggle_favorito_cancion_json(6));
    VERIFICAR(contiene(fav, "\"es_favorita\":true"), "toggleFavorito activa es_favorita = true");
    fav = tomarYLiberar(bridge_toggle_favorito_cancion_json(6));
    VERIFICAR(contiene(fav, "\"es_favorita\":false"), "segundo toggleFavorito vuelve a false");
    VERIFICAR(tomarYLiberar(bridge_toggle_favorito_cancion_json(8888)) == "null", "toggleFavorito ID inexistente retorna null");

    std::string csv5 = tomarYLiberar(bridge_exportar_biblioteca_csv(';', 0));
    VERIFICAR(contiene(csv5, "id;titulo;artista;duracion_segundos;genero\n"), "CSV 5 columnas incluye encabezado base");
    std::string csv7 = tomarYLiberar(bridge_exportar_biblioteca_csv(';', 1));
    VERIFICAR(contiene(csv7, "ruta_archivo;portada\n"), "CSV 7 columnas incluye columnas extendidas");
    VERIFICAR(contiene(csv7, "C:\\Musica\\Soda_Stereo"), "CSV 7 columnas conserva ruta local");

    int reimportadas = bridge_importar_biblioteca_csv(csv7.c_str(), ';', 1);
    VERIFICAR(reimportadas == 6, "reimportar CSV de 7 columnas recupera las 6 canciones");

    VERIFICAR(bridge_eliminar_cancion_biblioteca(6) == 1, "eliminar cancion ID 6 retorna 1");
    VERIFICAR(bridge_eliminar_cancion_biblioteca(6) == 0, "eliminar nuevamente ID 6 retorna 0");
    bridge_shutdown();
}

static void pruebasPlaylistsYNodosDobles() {
    grupo("Gestion de Playlists y Nodos Dobles (ListaDobleCircular)");
    bridge_init("biblioteca.csv");

    std::string pl1 = tomarYLiberar(bridge_crear_playlist_json("Rock Favoritos", 1));
    VERIFICAR(contiene(pl1, "\"id\":\"pl_1\"") && contiene(pl1, "\"es_activa\":true"), "crear playlist asigna pl_1 y la activa");
    VERIFICAR(bridge_existe_nombre_playlist("  rock favoritos  ", nullptr) == 1, "existeNombrePlaylist es case-insensitive");
    VERIFICAR(bridge_existe_nombre_playlist("rock favoritos", "pl_1") == 0, "existeNombrePlaylist ignora el propio ID");
    VERIFICAR(tomarYLiberar(bridge_crear_playlist_json("ROCK FAVORITOS", 0)) == "null", "rechaza nombre duplicado");
    VERIFICAR(tomarYLiberar(bridge_crear_playlist_json("   ", 0)) == "null", "rechaza nombre vacio");

    VERIFICAR(bridge_playlist_insertar_final_por_id("pl_1", 1) == 1, "insertarAlFinal ID 1");
    VERIFICAR(bridge_playlist_insertar_inicio_por_id("pl_1", 2) == 1, "insertarAlInicio ID 2 -> [2, 1]");
    VERIFICAR(bridge_playlist_insertar_posicion_por_id("pl_1", 3, 1) == 1, "insertarEnPosicion(1) ID 3 -> [2, 3, 1]");
    VERIFICAR(bridge_playlist_insertar_posicion_por_id("pl_1", 4, 99) == 0, "insertarEnPosicion fuera de rango retorna 0");

    std::string plActiva = tomarYLiberar(bridge_obtener_playlist_activa_json());
    VERIFICAR(contiene(plActiva, "\"tamano\":3") && contiene(plActiva, "\"duracion_total_segundos\":860"),
              "playlist activa tiene tamano 3 y duracion 860 s");

    std::string delInicio = tomarYLiberar(bridge_playlist_eliminar_inicio_json("pl_1"));
    VERIFICAR(contiene(delInicio, "\"id\":2"), "eliminarAlInicio retorna JSON de cancion 2");
    std::string delFinal = tomarYLiberar(bridge_playlist_eliminar_final_json("pl_1"));
    VERIFICAR(contiene(delFinal, "\"id\":1"), "eliminarAlFinal retorna JSON de cancion 1");
    std::string delPos = tomarYLiberar(bridge_playlist_eliminar_posicion_json("pl_1", 0));
    VERIFICAR(contiene(delPos, "\"id\":3"), "eliminarEnPosicion(0) retorna JSON de cancion 3");
    VERIFICAR(tomarYLiberar(bridge_playlist_eliminar_inicio_json("pl_1")) == "null", "eliminar en playlist vacia retorna null");

    // Validar limite MAX_PLAYLISTS = 20
    for (int i = 2; i <= 20; ++i) {
        std::string nombre = "Lista " + std::to_string(i);
        std::string creada = tomarYLiberar(bridge_crear_playlist_json(nombre.c_str(), 0));
        VERIFICAR(creada != "null", "crear playlist #" + std::to_string(i) + " dentro del limite");
    }
    VERIFICAR(tomarYLiberar(bridge_crear_playlist_json("Lista 21", 0)) == "null", "rechaza playlist #21 por MAX_PLAYLISTS = 20");

    VERIFICAR(bridge_renombrar_playlist("pl_1", "Rock Renombrada") == 1, "renombrar pl_1 funciona");
    VERIFICAR(bridge_eliminar_playlist("pl_1") == 1, "eliminar pl_1 funciona");
    std::string nuevaActiva = tomarYLiberar(bridge_obtener_playlist_activa_json());
    VERIFICAR(contiene(nuevaActiva, "\"id\":\"pl_2\""), "al eliminar playlist activa pasa a la primera disponible");

    bridge_shutdown();
}

static void pruebasAlgoritmosYReproduccion() {
    grupo("Algoritmos (GestorReproduccion), Motor Circular e Historial");
    bridge_init("biblioteca.csv");

    tomarYLiberar(bridge_crear_playlist_json("Principal", 1));
    for (int id = 1; id <= 5; ++id) {
        bridge_playlist_insertar_final_por_id("pl_1", id);
    }

    VERIFICAR(bridge_mover_cancion_playlist("pl_1", 0, 4) == 1, "moverCancion(0 -> 4) exitoso");
    VERIFICAR(bridge_mover_cancion_playlist("pl_1", 4, 0) == 1, "moverCancion(4 -> 0) restaura orden");
    VERIFICAR(bridge_mover_cancion_playlist("pl_1", -1, 2) == 0, "moverCancion invalido retorna 0");

    // Reproducibilidad de Shuffle Fisher-Yates con semilla fija
    tomarYLiberar(bridge_crear_playlist_json("Copia", 0));
    for (int id = 1; id <= 5; ++id) {
        bridge_playlist_insertar_final_por_id("pl_2", id);
    }
    VERIFICAR(bridge_aplicar_shuffle_fisher_yates("pl_1", 1, 42) == 1, "shuffle semilla 42 en pl_1");
    VERIFICAR(bridge_aplicar_shuffle_fisher_yates("pl_2", 1, 42) == 1, "shuffle semilla 42 en pl_2");

    std::string csv1 = tomarYLiberar(bridge_exportar_playlist_csv("pl_1", ';'));
    std::string csv2 = tomarYLiberar(bridge_exportar_playlist_csv("pl_2", ';'));
    VERIFICAR(csv1 == csv2, "misma semilla produce exactamente el mismo orden tras shuffle");

    // Reordenar pl_1 limpiamente para pruebas deterministas de cursor circular
    tomarYLiberar(bridge_crear_playlist_json("Circular", 1));
    bridge_playlist_insertar_final_por_id("pl_3", 1);
    bridge_playlist_insertar_final_por_id("pl_3", 2);
    bridge_playlist_insertar_final_por_id("pl_3", 3);

    std::string rep = tomarYLiberar(bridge_reproducir_cancion_en_playlist_json("pl_3", 1));
    VERIFICAR(contiene(rep, "\"id\":2"), "reproducirCancionEnPlaylist(indice=1) posiciona en ID 2");

    // Modo REPETIR_TODAS: 2 -> 3 -> 1
    bridge_set_modo_repeticion(2);
    std::string sig = tomarYLiberar(bridge_siguiente_cancion_json());
    VERIFICAR(contiene(sig, "\"id\":3"), "siguiente(REPETIR_TODAS): 2 -> 3");
    sig = tomarYLiberar(bridge_siguiente_cancion_json());
    VERIFICAR(contiene(sig, "\"id\":1"), "siguiente(REPETIR_TODAS): 3 -> 1 (cierra ciclo)");

    // Modo REPETIR_UNA: se mantiene en 1
    bridge_set_modo_repeticion(1);
    sig = tomarYLiberar(bridge_siguiente_cancion_json());
    VERIFICAR(contiene(sig, "\"id\":1"), "siguiente(REPETIR_UNA): mantiene ID 1");

    // Retroceso circular: 1 -> 3
    std::string ant = tomarYLiberar(bridge_anterior_cancion_json());
    VERIFICAR(contiene(ant, "\"id\":3"), "anterior(circular): 1 -> 3");

    // Modo SIN_REPETICION en cola: retorna null y detiene reproduccion
    bridge_set_modo_repeticion(0);
    sig = tomarYLiberar(bridge_siguiente_cancion_json());
    VERIFICAR(sig == "null", "siguiente(SIN_REPETICION) en ultima cancion retorna null");
    std::string estado = tomarYLiberar(bridge_obtener_estado_reproduccion_json());
    VERIFICAR(contiene(estado, "\"is_playing\":false"), "estado queda con is_playing=false al terminar lista");
    VERIFICAR(contiene(estado, "\"mensaje_estado\":\"Fin de la playlist"), "estado emite mensaje de fin de playlist");

    // Volumen con punto decimal invariante y seek acotado
    bridge_set_volumen(0.45);
    bridge_seek_to(99999);
    estado = tomarYLiberar(bridge_obtener_estado_reproduccion_json());
    VERIFICAR(contiene(estado, "\"volumen\":0.450"), "volumen formateado con punto decimal (0.450)");
    VERIFICAR(contiene(estado, "\"posicion_actual_segundos\":294"), "seek_to acotado a duracion de cancion (294)");

    // Fusion de listas e importacion CSV de playlist
    tomarYLiberar(bridge_crear_playlist_json("Extra", 0));
    bridge_playlist_insertar_final_por_id("pl_4", 4);
    bridge_playlist_insertar_final_por_id("pl_4", 5);
    VERIFICAR(bridge_fusionar_playlists("pl_3", "pl_4", 1) == 1, "fusionar pl_4 en pl_3 vaciando pl_4");
    std::string pl3Json = tomarYLiberar(bridge_obtener_playlist_por_id_json("pl_3"));
    std::string pl4Json = tomarYLiberar(bridge_obtener_playlist_por_id_json("pl_4"));
    VERIFICAR(contiene(pl3Json, "\"tamano\":5"), "pl_3 queda con 5 canciones tras fusion");
    VERIFICAR(contiene(pl4Json, "\"esta_vacia\":true"), "pl_4 queda vacia tras fusion con vaciar=1");

    std::string plImportada = tomarYLiberar(bridge_importar_playlist_csv_json("Importada", csv1.c_str(), ';'));
    VERIFICAR(contiene(plImportada, "\"tamano\":5"), "importarPlaylistCSV crea playlist con 5 canciones");

    // Historial LIFO
    std::string histJson = tomarYLiberar(bridge_obtener_historial_json());
    VERIFICAR(contiene(histJson, "\"id_registro\":\"hist_"), "historial contiene registros hist_N");
    VERIFICAR(bridge_calcular_duracion_total_historial() > 0, "duracion total del historial > 0");
    bridge_limpiar_historial();
    VERIFICAR(tomarYLiberar(bridge_obtener_historial_json()) == "[]", "limpiarHistorial deja historial en []");

    // Formato de duracion
    VERIFICAR(tomarYLiberar(bridge_formatear_duracion_total(5103)) == "01:25:03", "5103 s -> 01:25:03");
    VERIFICAR(tomarYLiberar(bridge_formatear_duracion_total(-5)) == "00:00:00", "negativo -> 00:00:00");

    bridge_shutdown();
}

int main(int argc, char* argv[]) {
    if (argc >= 2 && std::strcmp(argv[1], "--dump-json") == 0) {
        prepararEscenarioCompleto();
        std::string bib = tomarYLiberar(bridge_obtener_biblioteca_json());
        std::string pls = tomarYLiberar(bridge_obtener_playlists_json());
        std::string est = tomarYLiberar(bridge_obtener_estado_reproduccion_json());
        std::string his = tomarYLiberar(bridge_obtener_historial_json());

        std::cout << "{"
                  << "\"biblioteca\":" << bib << ","
                  << "\"playlists\":" << pls << ","
                  << "\"estado\":" << est << ","
                  << "\"historial\":" << his
                  << "}\n";
        bridge_shutdown();
        return 0;
    }

    std::cout << "========================================================\n"
              << "  PRUEBAS PUENTE FFI/JSON - Estudiante 2 (CC0401)\n"
              << "========================================================\n";

    pruebasCicloVidaYBiblioteca();
    pruebasPlaylistsYNodosDobles();
    pruebasAlgoritmosYReproduccion();

    std::cout << "\n========================================================\n"
              << "  Resultado: " << (totalPruebas - pruebasFallidas) << " de " << totalPruebas << " pruebas correctas\n";
    if (pruebasFallidas == 0) {
        std::cout << "  TODO CORRECTO\n";
    } else {
        std::cout << "  HAY " << pruebasFallidas << " PRUEBA(S) FALLIDA(S)\n";
    }
    std::cout << "========================================================\n";
    return pruebasFallidas == 0 ? 0 : 1;
}

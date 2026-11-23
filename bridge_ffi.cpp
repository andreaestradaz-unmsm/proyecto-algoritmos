#include "bridge_ffi.h"
#include "cancion.h"
#include "lista_simple.h"
#include "lista_doble_circular.h"
#include "reproduccion.h"

#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <string>

/**
 * ============================================================================
 * IMPLEMENTACION DEL PUENTE C++ <-> FFI/JSON (ESTUDIANTE 2)
 * ============================================================================
 * - Mantiene en memoria los TADs reales del curso sin usar contenedores STL:
 *   ListaSimple (biblioteca e historial) y ListaDobleCircular* [20].
 * - Serializa manualmente a JSON RFC-8259 compatible con los modelos Dart.
 * - Integra el motor de audio real (miniaudio), la extraccion de tags/caratulas
 *   y la compatibilidad de metadatos extendidos del TAD Cancion.
 * ============================================================================
 */

// Modulo multimedia nativo (miniaudio) y extractor de metadatos (ID3v2/FLAC/WAV)
#include "motor_audio.h"
#include "extractor_metadata.h"

// Instancia global del motor de audio que gestiona la reproduccion fisica
static MotorAudio g_motorAudio;

namespace {

// ----------------------------------------------------------------------------
// Estructuras propias con nodos y punteros (sin std::vector ni std::map)
// ----------------------------------------------------------------------------

// Almacena metadatos extendidos por ID de cancion sincronizados con las listas en memoria
struct NodoMetaCancion {
    int cancionId;
    std::string rutaArchivo;
    std::string portadaUrl;
    bool esFavorita;
    bool esArchivoLocal;
    bool metadataExtraida;
    bool tieneTamanoBytes;
    int tamanoBytes;
    NodoMetaCancion* siguiente;

    NodoMetaCancion(int id) {
        cancionId = id;
        rutaArchivo = "";
        portadaUrl = "";
        esFavorita = false;
        esArchivoLocal = false;
        metadataExtraida = false;
        tieneTamanoBytes = false;
        tamanoBytes = 0;
        siguiente = nullptr;
    }
};

// Almacena los metadatos de cada registro del historial sincronizado 1 a 1 en
// orden LIFO con `ListaSimple historial`.
struct NodoMetaHistorial {
    std::string idRegistro;
    std::string fechaReproduccion;
    std::string origenNombre;
    NodoMetaHistorial* siguiente;

    NodoMetaHistorial(const std::string& idReg, const std::string& fecha, const std::string& origen) {
        idRegistro = idReg;
        fechaReproduccion = fecha;
        origenNombre = origen;
        siguiente = nullptr;
    }
};

struct EstadoPuente {
    ListaSimple biblioteca;
    ListaSimple historial;
    ListaDobleCircular* playlists[BRIDGE_MAX_PLAYLISTS];
    std::string playlistIds[BRIDGE_MAX_PLAYLISTS];
    int cantidadPlaylists;
    int indicePlaylistActiva;
    int contadorPlaylists;
    int contadorHistorial;

    NodoMetaCancion* metaCancionesCabeza;
    NodoMetaHistorial* metaHistorialCabeza;

    // Estado de reproduccion actual
    bool tieneCancionActual;
    Cancion cancionActual;
    std::string nombreContexto;
    bool isPlaying;
    int posicionActualSegundos;
    int duracionTotalSegundos;
    double volumen;
    ModoRepeticion modoRepeticion;
    bool tieneUltimoShuffleSemilla;
    unsigned int ultimoShuffleSemilla;
    bool tieneMensajeEstado;
    std::string mensajeEstado;
    bool inicializado;

    EstadoPuente() {
        for (int i = 0; i < BRIDGE_MAX_PLAYLISTS; ++i) {
            playlists[i] = nullptr;
            playlistIds[i] = "";
        }
        cantidadPlaylists = 0;
        indicePlaylistActiva = -1;
        contadorPlaylists = 0;
        contadorHistorial = 0;
        metaCancionesCabeza = nullptr;
        metaHistorialCabeza = nullptr;
        tieneCancionActual = false;
        nombreContexto = "Sin playlist activa";
        isPlaying = false;
        posicionActualSegundos = 0;
        duracionTotalSegundos = 0;
        volumen = 0.78;
        modoRepeticion = ModoRepeticion::REPETIR_TODAS;
        tieneUltimoShuffleSemilla = false;
        ultimoShuffleSemilla = 0;
        tieneMensajeEstado = false;
        mensajeEstado = "";
        inicializado = false;
    }

    ~EstadoPuente() {
        for (int i = 0; i < cantidadPlaylists; ++i) {
            delete playlists[i];
            playlists[i] = nullptr;
        }
        NodoMetaCancion* mc = metaCancionesCabeza;
        while (mc != nullptr) {
            NodoMetaCancion* sig = mc->siguiente;
            delete mc;
            mc = sig;
        }
        metaCancionesCabeza = nullptr;

        NodoMetaHistorial* mh = metaHistorialCabeza;
        while (mh != nullptr) {
            NodoMetaHistorial* sig = mh->siguiente;
            delete mh;
            mh = sig;
        }
        metaHistorialCabeza = nullptr;
    }
};

EstadoPuente g_estado;

// ----------------------------------------------------------------------------
// Utilidades de texto, memoria C y JSON
// ----------------------------------------------------------------------------

std::string aStringSeguro(const char* ptr) {
    if (ptr == nullptr) {
        return "";
    }
    return std::string(ptr);
}

char* aHeapCString(const std::string& texto) {
    std::size_t len = texto.size();
    char* copia = static_cast<char*>(std::malloc(len + 1));
    if (copia == nullptr) {
        return nullptr;
    }
    if (len > 0) {
        std::memcpy(copia, texto.data(), len);
    }
    copia[len] = '\0';
    return copia;
}

std::string trimTexto(const std::string& s) {
    std::size_t inicio = 0;
    while (inicio < s.size() && std::isspace(static_cast<unsigned char>(s[inicio]))) {
        ++inicio;
    }
    std::size_t fin = s.size();
    while (fin > inicio && std::isspace(static_cast<unsigned char>(s[fin - 1]))) {
        --fin;
    }
    return s.substr(inicio, fin - inicio);
}

std::string aMinusculas(const std::string& s) {
    std::string res = s;
    for (std::size_t i = 0; i < res.size(); ++i) {
        res[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(res[i])));
    }
    return res;
}

std::string sanitizarCampoCSV(const std::string& s, char delimitador = ';') {
    std::string limpio = trimTexto(s);
    for (std::size_t i = 0; i < limpio.size(); ++i) {
        if (limpio[i] == delimitador || limpio[i] == '\r' || limpio[i] == '\n') {
            limpio[i] = ',';
        }
    }
    return limpio;
}

std::string escaparJson(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 8);
    for (std::size_t i = 0; i < s.size(); ++i) {
        unsigned char c = static_cast<unsigned char>(s[i]);
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b";  break;
            case '\f': out += "\\f";  break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (c < 0x20) {
                    char buf[7];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", static_cast<unsigned int>(c));
                    out += buf;
                } else {
                    out += static_cast<char>(c);
                }
                break;
        }
    }
    return out;
}

std::string cadenaJsonONull(const std::string& valor, bool esPresente) {
    if (!esPresente || valor.empty()) {
        return "null";
    }
    return "\"" + escaparJson(valor) + "\"";
}

// Formatea un double en [0.0, 1.0] o cualquier real usando siempre '.' decimal,
// sin depender del locale del sistema operativo.
std::string formatearDoubleJson(double valor) {
    if (valor < 0.0) {
        return "-" + formatearDoubleJson(-valor);
    }
    long long milesimas = static_cast<long long>(std::llround(valor * 1000.0));
    long long entero = milesimas / 1000;
    long long frac = milesimas % 1000;
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%lld.%03lld", entero, frac);
    return std::string(buf);
}

std::string fechaActualIso8601() {
    std::time_t ahora = std::time(nullptr);
    std::tm* tmLocal = std::localtime(&ahora);
    if (tmLocal == nullptr) {
        return "1970-01-01T00:00:00";
    }
    char buf[32];
    std::snprintf(
        buf,
        sizeof(buf),
        "%04d-%02d-%02dT%02d:%02d:%02d",
        tmLocal->tm_year + 1900,
        tmLocal->tm_mon + 1,
        tmLocal->tm_mday,
        tmLocal->tm_hour,
        tmLocal->tm_min,
        tmLocal->tm_sec
    );
    return std::string(buf);
}

std::string formatearDosDigitos(int n) {
    if (n < 10) {
        return "0" + std::to_string(n);
    }
    return std::to_string(n);
}

std::string formatearDuracionHHMMSS(int totalSegundos) {
    int seguro = totalSegundos < 0 ? 0 : totalSegundos;
    int horas = seguro / 3600;
    int minutos = (seguro % 3600) / 60;
    int segundos = seguro % 60;
    return formatearDosDigitos(horas) + ":" +
           formatearDosDigitos(minutos) + ":" +
           formatearDosDigitos(segundos);
}

std::string modoRepeticionAString(ModoRepeticion modo) {
    switch (modo) {
        case ModoRepeticion::SIN_REPETICION: return "SIN_REPETICION";
        case ModoRepeticion::REPETIR_UNA:    return "REPETIR_UNA";
        case ModoRepeticion::REPETIR_TODAS:  return "REPETIR_TODAS";
    }
    return "REPETIR_TODAS";
}

int modoRepeticionACodigo(ModoRepeticion modo) {
    switch (modo) {
        case ModoRepeticion::SIN_REPETICION: return 0;
        case ModoRepeticion::REPETIR_UNA:    return 1;
        case ModoRepeticion::REPETIR_TODAS:  return 2;
    }
    return 2;
}

ModoRepeticion codigoAModoRepeticion(int codigo) {
    if (codigo == 0) {
        return ModoRepeticion::SIN_REPETICION;
    }
    if (codigo == 1) {
        return ModoRepeticion::REPETIR_UNA;
    }
    return ModoRepeticion::REPETIR_TODAS;
}

// ----------------------------------------------------------------------------
// Gestion de metadatos locales del puente (listas enlazadas propias)
// ----------------------------------------------------------------------------

NodoMetaCancion* buscarMetaCancion(int cancionId) {
    NodoMetaCancion* actual = g_estado.metaCancionesCabeza;
    while (actual != nullptr) {
        if (actual->cancionId == cancionId) {
            return actual;
        }
        actual = actual->siguiente;
    }
    return nullptr;
}

NodoMetaCancion* obtenerOCrearMetaCancion(int cancionId) {
    NodoMetaCancion* existente = buscarMetaCancion(cancionId);
    if (existente != nullptr) {
        return existente;
    }
    NodoMetaCancion* nuevo = new NodoMetaCancion(cancionId);
    nuevo->siguiente = g_estado.metaCancionesCabeza;
    g_estado.metaCancionesCabeza = nuevo;
    return nuevo;
}

void limpiarMetaCanciones() {
    NodoMetaCancion* actual = g_estado.metaCancionesCabeza;
    while (actual != nullptr) {
        NodoMetaCancion* sig = actual->siguiente;
        delete actual;
        actual = sig;
    }
    g_estado.metaCancionesCabeza = nullptr;
}

void limpiarMetaHistorial() {
    NodoMetaHistorial* actual = g_estado.metaHistorialCabeza;
    while (actual != nullptr) {
        NodoMetaHistorial* sig = actual->siguiente;
        delete actual;
        actual = sig;
    }
    g_estado.metaHistorialCabeza = nullptr;
}

void agregarMetaHistorialAlInicio(const std::string& origenNombre) {
    g_estado.contadorHistorial++;
    std::string idReg = "hist_" + std::to_string(g_estado.contadorHistorial);
    NodoMetaHistorial* nuevo = new NodoMetaHistorial(
        idReg,
        fechaActualIso8601(),
        origenNombre
    );
    nuevo->siguiente = g_estado.metaHistorialCabeza;
    g_estado.metaHistorialCabeza = nuevo;
}

void limpiarEstadoReproduccionPorVacio() {
    g_estado.tieneCancionActual = false;
    g_estado.cancionActual = Cancion();
    g_estado.nombreContexto = "Sin playlist activa";
    g_estado.isPlaying = false;
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = 0;
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    // Detiene la reproduccion fisica de audio al no quedar pistas activas
    g_motorAudio.stop();
}

// ----------------------------------------------------------------------------
// Busquedas sobre playlists y cursores
// ----------------------------------------------------------------------------

int buscarIndicePlaylistPorId(const std::string& playlistId) {
    if (playlistId.empty()) {
        return -1;
    }
    for (int i = 0; i < g_estado.cantidadPlaylists; ++i) {
        if (g_estado.playlistIds[i] == playlistId) {
            return i;
        }
    }
    return -1;
}

// Calcula el indice 0-based del puntero `actual` dentro de `ListaDobleCircular`
// comparando direcciones de `NodoDoble::dato` sin modificar `lista_doble_circular.h`.
int obtenerIndiceActualPlaylist(const ListaDobleCircular& lista) {
    if (lista.estaVacia()) {
        return -1;
    }
    const Cancion* ptrActual = lista.obtenerCancionActual();
    if (ptrActual == nullptr) {
        return -1;
    }
    NodoDoble* nodo = lista.getCabeza();
    for (int i = 0; i < lista.getTamano() && nodo != nullptr; ++i) {
        if (&(nodo->dato) == ptrActual) {
            return i;
        }
        nodo = nodo->siguiente;
    }
    return -1;
}

void sincronizarPlaybackConPlaylistActiva() {
    if (g_estado.indicePlaylistActiva < 0 ||
        g_estado.indicePlaylistActiva >= g_estado.cantidadPlaylists) {
        return;
    }
    ListaDobleCircular* activa = g_estado.playlists[g_estado.indicePlaylistActiva];
    if (activa == nullptr) {
        return;
    }
    g_estado.nombreContexto = activa->getNombre();
    g_estado.modoRepeticion = activa->getModoRepeticion();
    const Cancion* ptrActual = activa->obtenerCancionActual();
    if (ptrActual == nullptr) {
        g_estado.tieneCancionActual = false;
        g_estado.cancionActual = Cancion();
        g_estado.duracionTotalSegundos = 0;
        g_estado.posicionActualSegundos = 0;
        g_estado.isPlaying = false;
    } else {
        g_estado.tieneCancionActual = true;
        g_estado.cancionActual = *ptrActual;
        g_estado.duracionTotalSegundos = ptrActual->getDuracionSegundos();
        g_estado.posicionActualSegundos = 0;
    }

    // Si la lista quedo vacia y no hay cancion que deba sonar, detiene el audio
    if (!g_estado.tieneCancionActual) {
        g_motorAudio.stop();
    }
}

bool existeCancionEnCualquierLugar(int cancionId, Cancion& cancionEncontrada) {
    if (g_estado.biblioteca.buscarPorId(cancionId, cancionEncontrada)) {
        return true;
    }
    for (int i = 0; i < g_estado.cantidadPlaylists; ++i) {
        ListaDobleCircular* pl = g_estado.playlists[i];
        if (pl == nullptr) {
            continue;
        }
        NodoDoble* nodo = pl->getCabeza();
        for (int j = 0; j < pl->getTamano() && nodo != nullptr; ++j) {
            if (nodo->dato.getId() == cancionId) {
                cancionEncontrada = nodo->dato;
                return true;
            }
            nodo = nodo->siguiente;
        }
    }
    if (g_estado.tieneCancionActual && g_estado.cancionActual.getId() == cancionId) {
        cancionEncontrada = g_estado.cancionActual;
        return true;
    }
    return false;
}

// ----------------------------------------------------------------------------
// Serializadores JSON (100% alineados con Dart `fromJson`)
// ----------------------------------------------------------------------------

std::string serializarCancionJson(const Cancion& c) {
    NodoMetaCancion* meta = buscarMetaCancion(c.getId());

    std::string rutaArchivo = "";
    std::string portadaUrl = "";
    bool esFavorita = false;
    bool esArchivoLocal = false;
    bool metadataExtraida = false;
    bool tieneTamano = false;
    int tamanoBytes = 0;

    if (meta != nullptr) {
        rutaArchivo = meta->rutaArchivo;
        portadaUrl = meta->portadaUrl;
        esFavorita = meta->esFavorita;
        esArchivoLocal = meta->esArchivoLocal;
        metadataExtraida = meta->metadataExtraida;
        tieneTamano = meta->tieneTamanoBytes;
        tamanoBytes = meta->tamanoBytes;
    }

    // Prioriza los metadatos y rutas asignados directamente en el TAD Cancion
    if (rutaArchivo.empty() && !c.getRutaArchivo().empty()) {
        rutaArchivo = c.getRutaArchivo();
        esArchivoLocal = c.getEsArchivoLocal();
    }
    if (portadaUrl.empty() && !c.getPortada().empty()) {
        portadaUrl = c.getPortada();
    }
    if (!esFavorita && c.getEsFavorita()) {
        esFavorita = true;
    }
    if (!metadataExtraida && c.getMetadataExtraida()) {
        metadataExtraida = true;
    }
    if (!tieneTamano && c.getTamanoBytes() > 0) {
        tieneTamano = true;
        tamanoBytes = c.getTamanoBytes();
    }

    std::string json = "{";
    json += "\"id\":" + std::to_string(c.getId()) + ",";
    json += "\"titulo\":\"" + escaparJson(c.getTitulo()) + "\",";
    json += "\"artista\":\"" + escaparJson(c.getArtista()) + "\",";
    json += "\"duracion_segundos\":" + std::to_string(c.getDuracionSegundos()) + ",";
    json += "\"duracion_formateada\":\"" + escaparJson(c.obtenerDuracionFormateada()) + "\",";
    json += "\"genero\":\"" + escaparJson(c.getGenero()) + "\",";
    json += "\"ruta_archivo\":" + cadenaJsonONull(rutaArchivo, !rutaArchivo.empty()) + ",";
    json += "\"portada_url\":" + cadenaJsonONull(portadaUrl, !portadaUrl.empty()) + ",";
    json += "\"es_favorita\":" + std::string(esFavorita ? "true" : "false") + ",";
    json += "\"es_archivo_local\":" + std::string(esArchivoLocal ? "true" : "false") + ",";
    json += "\"metadata_extraida\":" + std::string(metadataExtraida ? "true" : "false") + ",";
    json += "\"tamano_bytes\":" + (tieneTamano ? std::to_string(tamanoBytes) : std::string("null"));
    json += "}";
    return json;
}

std::string serializarPlaylistJson(int indice) {
    ListaDobleCircular* pl = g_estado.playlists[indice];
    if (pl == nullptr) {
        return "null";
    }
    int idxActual = obtenerIndiceActualPlaylist(*pl);
    int durTotal = pl->calcularDuracionTotalSegundos();
    bool esActiva = (indice == g_estado.indicePlaylistActiva);
    ModoRepeticion modo = pl->getModoRepeticion();

    std::string json = "{";
    json += "\"id\":\"" + escaparJson(g_estado.playlistIds[indice]) + "\",";
    json += "\"nombre\":\"" + escaparJson(pl->getNombre()) + "\",";
    json += "\"tamano\":" + std::to_string(pl->getTamano()) + ",";
    json += "\"esta_vacia\":" + std::string(pl->estaVacia() ? "true" : "false") + ",";
    json += "\"indice_actual\":" + (idxActual >= 0 ? std::to_string(idxActual) : std::string("null")) + ",";
    json += "\"modo_repeticion\":\"" + modoRepeticionAString(modo) + "\",";
    json += "\"modo_repeticion_codigo\":" + std::to_string(modoRepeticionACodigo(modo)) + ",";
    json += "\"es_activa\":" + std::string(esActiva ? "true" : "false") + ",";
    json += "\"duracion_total_segundos\":" + std::to_string(durTotal) + ",";
    json += "\"duracion_total_formateada\":\"" + formatearDuracionHHMMSS(durTotal) + "\",";
    json += "\"canciones\":[";

    NodoDoble* nodo = pl->getCabeza();
    for (int i = 0; i < pl->getTamano() && nodo != nullptr; ++i) {
        if (i > 0) {
            json += ",";
        }
        json += serializarCancionJson(nodo->dato);
        nodo = nodo->siguiente;
    }

    json += "]}";
    return json;
}

// ----------------------------------------------------------------------------
// Parser CSV seguro para 5 o 7 columnas (retrocompatible con Cancion::desdeCSV)
// ----------------------------------------------------------------------------

bool parsearLineaCSVExtendida(
    const std::string& lineaRaw,
    char delimitador,
    Cancion& outCancion,
    std::string& outRutaArchivo,
    std::string& outPortadaUrl
) {
    outRutaArchivo = "";
    outPortadaUrl = "";

    std::string linea = trimTexto(lineaRaw);
    if (linea.empty()) {
        return false;
    }
    if (linea[0] < '0' || linea[0] > '9') {
        return false;
    }

    std::string campos[7];
    int cantidadCampos = 1;
    std::string actual = "";

    for (std::size_t i = 0; i < linea.size(); ++i) {
        char c = linea[i];
        if (c == '\r' || c == '\n') {
            continue;
        }
        if (c == delimitador) {
            if (cantidadCampos < 7) {
                campos[cantidadCampos - 1] = actual;
                cantidadCampos++;
                actual = "";
            } else {
                actual += c;
            }
        } else {
            actual += c;
        }
    }
    campos[cantidadCampos - 1] = actual;

    if (cantidadCampos < 5) {
        return false;
    }

    // Reconstruimos las 5 columnas base para delegar validacion/creacion al TAD Cancion.
    std::string lineaCincoCols =
        trimTexto(campos[0]) + delimitador +
        (trimTexto(campos[1]).empty() ? std::string("Sin titulo") : trimTexto(campos[1])) + delimitador +
        (trimTexto(campos[2]).empty() ? std::string("Desconocido") : trimTexto(campos[2])) + delimitador +
        trimTexto(campos[3]) + delimitador +
        (trimTexto(campos[4]).empty() ? std::string("Sin genero") : trimTexto(campos[4]));

    // Validar enteros antes de llamar a std::stoi dentro de Cancion::desdeCSV
    std::string idStr = trimTexto(campos[0]);
    std::string durStr = trimTexto(campos[3]);
    if (idStr.empty() || durStr.empty()) {
        return false;
    }
    for (std::size_t i = 0; i < idStr.size(); ++i) {
        if (!std::isdigit(static_cast<unsigned char>(idStr[i]))) {
            return false;
        }
    }
    for (std::size_t i = 0; i < durStr.size(); ++i) {
        if (i == 0 && durStr[i] == '-' && durStr.size() > 1) {
            continue;
        }
        if (!std::isdigit(static_cast<unsigned char>(durStr[i]))) {
            return false;
        }
    }

    // Parsea la linea CSV completa (5, 6 o 7 columnas) utilizando Cancion::desdeCSV
    if (Cancion::desdeCSV(linea, outCancion, delimitador)) {
        outRutaArchivo = outCancion.getRutaArchivo();
        outPortadaUrl = outCancion.getPortada();
        return true;
    }
    if (!Cancion::desdeCSV(lineaCincoCols, outCancion, delimitador)) {
        return false;
    }

    if (cantidadCampos >= 6) {
        outRutaArchivo = trimTexto(campos[5]);
    }
    if (cantidadCampos >= 7) {
        outPortadaUrl = trimTexto(campos[6]);
    }
    return true;
}

int hashDeterministicoNombre(const std::string& texto) {
    unsigned int h = 2166136261u;
    for (std::size_t i = 0; i < texto.size(); ++i) {
        h ^= static_cast<unsigned char>(texto[i]);
        h *= 16777619u;
    }
    return static_cast<int>(h & 0x7fffffffu);
}

std::string extraerNombreArchivo(const std::string& ruta) {
    std::size_t pos = ruta.find_last_of("/\\");
    if (pos == std::string::npos) {
        return ruta;
    }
    return ruta.substr(pos + 1);
}

std::string quitarExtensionAudio(const std::string& nombreArchivo) {
    std::size_t punto = nombreArchivo.find_last_of('.');
    if (punto == std::string::npos) {
        return nombreArchivo;
    }
    std::string ext = aMinusculas(nombreArchivo.substr(punto));
    if (ext == ".mp3" || ext == ".flac" || ext == ".wav" ||
        ext == ".ogg" || ext == ".m4a" || ext == ".aac") {
        return nombreArchivo.substr(0, punto);
    }
    return nombreArchivo;
}

std::string reemplazarGuionBajoPorEspacio(const std::string& s) {
    std::string res = s;
    for (std::size_t i = 0; i < res.size(); ++i) {
        if (res[i] == '_') {
            res[i] = ' ';
        }
    }
    return res;
}

// Reubica el cursor `actual` de `ListaDobleCircular` en `indiceNodo` usando solo
// los metodos publicos de `lista_doble_circular.h` (sin modificar la cabecera de Jeick).
bool posicionarCursorEnIndice(ListaDobleCircular* pl, int indiceNodo) {
    if (pl == nullptr || indiceNodo < 0 || indiceNodo >= pl->getTamano()) {
        return false;
    }
    NodoDoble* objetivo = pl->obtenerNodoEn(indiceNodo);
    if (objetivo == nullptr) {
        return false;
    }
    if (pl->obtenerCancionActual() == &(objetivo->dato)) {
        return true;
    }

    ModoRepeticion modoPrevio = pl->getModoRepeticion();
    pl->setModoRepeticion(ModoRepeticion::REPETIR_TODAS);
    int maxPasos = pl->getTamano();
    for (int paso = 0; paso < maxPasos; ++paso) {
        if (pl->obtenerCancionActual() == &(objetivo->dato)) {
            break;
        }
        pl->siguienteCancion();
    }
    pl->setModoRepeticion(modoPrevio);
    return pl->obtenerCancionActual() == &(objetivo->dato);
}

void inicializarPuenteSiHaceFalta() {
    if (!g_estado.inicializado) {
        g_estado.inicializado = true;
    }
}

void registrarCancionEnHistorialInterno(const Cancion& cancion, const std::string& origenNombre) {
    g_estado.historial.agregarAlInicio(cancion);
    agregarMetaHistorialAlInicio(origenNombre);
}

} // namespace


/* ============================================================================
 * 0. CICLO DE VIDA DEL PUENTE Y GESTION DE MEMORIA
 * ============================================================================ */

BRIDGE_API int bridge_init(const char* ruta_biblioteca_csv) {
    bridge_reset();

    // Inicializa el dispositivo de salida PCM nativo a traves de miniaudio
    g_motorAudio.inicializar();

    std::string ruta = aStringSeguro(ruta_biblioteca_csv);
    if (!ruta.empty()) {
        int cargadas = bridge_cargar_biblioteca_archivo_csv(ruta.c_str(), ';');
        return cargadas >= 0 ? 1 : 0;
    }
    return 1;
}

BRIDGE_API void bridge_shutdown(void) {
    // Detiene la reproduccion y desvincula los recursos nativos de audio
    g_motorAudio.liberar();

    bridge_reset();
    g_estado.inicializado = false;
}

BRIDGE_API void bridge_reset(void) {
    g_estado.biblioteca.limpiar();
    g_estado.historial.limpiar();

    for (int i = 0; i < g_estado.cantidadPlaylists; ++i) {
        delete g_estado.playlists[i];
        g_estado.playlists[i] = nullptr;
        g_estado.playlistIds[i] = "";
    }
    g_estado.cantidadPlaylists = 0;
    g_estado.indicePlaylistActiva = -1;
    g_estado.contadorPlaylists = 0;
    g_estado.contadorHistorial = 0;

    limpiarMetaCanciones();
    limpiarMetaHistorial();
    ExtractorMetadata::limpiarCachePortadas();
    g_motorAudio.stop();

    g_estado.tieneCancionActual = false;
    g_estado.cancionActual = Cancion();
    g_estado.nombreContexto = "Sin playlist activa";
    g_estado.isPlaying = false;
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = 0;
    g_estado.volumen = 0.78;
    g_estado.modoRepeticion = ModoRepeticion::REPETIR_TODAS;
    g_estado.tieneUltimoShuffleSemilla = false;
    g_estado.ultimoShuffleSemilla = 0;
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";
    g_estado.inicializado = true;
}

BRIDGE_API void bridge_free_string(char* ptr) {
    if (ptr != nullptr) {
        std::free(ptr);
    }
}

BRIDGE_API void bridge_free_bytes(unsigned char* ptr) {
    if (ptr != nullptr) {
        std::free(ptr);
    }
}

BRIDGE_API int bridge_get_max_playlists(void) {
    return BRIDGE_MAX_PLAYLISTS;
}


/* ============================================================================
 * 1. BIBLIOTECA GENERAL (ListaSimple)
 * ============================================================================ */

BRIDGE_API char* bridge_obtener_biblioteca_json(void) {
    inicializarPuenteSiHaceFalta();
    std::string json = "[";
    NodoSimple* actual = g_estado.biblioteca.getCabeza();
    bool primero = true;
    while (actual != nullptr) {
        if (!primero) {
            json += ",";
        }
        json += serializarCancionJson(actual->dato);
        primero = false;
        actual = actual->siguiente;
    }
    json += "]";
    return aHeapCString(json);
}

BRIDGE_API int bridge_calcular_duracion_total_biblioteca(void) {
    inicializarPuenteSiHaceFalta();
    return g_estado.biblioteca.calcularDuracionTotalSegundos();
}

BRIDGE_API int bridge_siguiente_id_libre_biblioteca(void) {
    inicializarPuenteSiHaceFalta();
    int maximo = 0;
    NodoSimple* actual = g_estado.biblioteca.getCabeza();
    while (actual != nullptr) {
        if (actual->dato.getId() > maximo) {
            maximo = actual->dato.getId();
        }
        actual = actual->siguiente;
    }
    return maximo + 1;
}

BRIDGE_API char* bridge_buscar_cancion_por_id_json(int id) {
    inicializarPuenteSiHaceFalta();
    Cancion encontrada;
    if (!g_estado.biblioteca.buscarPorId(id, encontrada)) {
        return aHeapCString("null");
    }
    return aHeapCString(serializarCancionJson(encontrada));
}

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
) {
    inicializarPuenteSiHaceFalta();

    std::string limpioTitulo = sanitizarCampoCSV(aStringSeguro(titulo));
    std::string limpioArtista = sanitizarCampoCSV(aStringSeguro(artista));
    std::string limpioGenero = sanitizarCampoCSV(aStringSeguro(genero));

    if (limpioTitulo.empty()) {
        limpioTitulo = "Sin titulo";
    }
    if (limpioArtista.empty()) {
        limpioArtista = "Desconocido";
    }
    if (limpioGenero.empty()) {
        limpioGenero = "Sin genero";
    }
    int durFinal = duracion_segundos <= 0 ? 180 : duracion_segundos;
    int idFinal = id > 0 ? id : bridge_siguiente_id_libre_biblioteca();

    Cancion nueva(idFinal, limpioTitulo, limpioArtista, durFinal, limpioGenero);
    g_estado.biblioteca.agregarAlFinal(nueva);

    std::string rutaStr = trimTexto(aStringSeguro(ruta_archivo));
    std::string portadaStr = trimTexto(aStringSeguro(portada_url));

    NodoMetaCancion* meta = obtenerOCrearMetaCancion(idFinal);
    meta->rutaArchivo = rutaStr;
    meta->portadaUrl = portadaStr;
    meta->esArchivoLocal = (es_archivo_local != 0) || !rutaStr.empty();
    meta->metadataExtraida = (metadata_extraida != 0) || !rutaStr.empty() || !portadaStr.empty();
    if (tamano_bytes >= 0) {
        meta->tieneTamanoBytes = true;
        meta->tamanoBytes = tamano_bytes;
    }

    return aHeapCString(serializarCancionJson(nueva));
}

BRIDGE_API char* bridge_importar_archivo_audio_json(
    const char* ruta_archivo,
    const char* titulo_override,
    const char* artista_override,
    int duracion_segundos_override,
    const char* genero_override,
    int tamano_bytes
) {
    inicializarPuenteSiHaceFalta();
    std::string ruta = trimTexto(aStringSeguro(ruta_archivo));
    if (ruta.empty()) {
        return aHeapCString("null");
    }

    std::string nombreArchivo = extraerNombreArchivo(ruta);
    std::string sinExt = quitarExtensionAudio(nombreArchivo);

    std::string artistaInferido = "Artista Local";
    std::string tituloInferido = trimTexto(reemplazarGuionBajoPorEspacio(sinExt));
    std::string generoInferido = "Audio Local";
    std::string portadaInferida = "";
    int duracionCalculada = duracion_segundos_override;

    std::size_t posGuion = sinExt.find('-');
    if (posGuion != std::string::npos) {
        std::string parteIzq = trimTexto(reemplazarGuionBajoPorEspacio(sinExt.substr(0, posGuion)));
        std::string parteDer = trimTexto(reemplazarGuionBajoPorEspacio(sinExt.substr(posGuion + 1)));
        if (!parteIzq.empty()) {
            artistaInferido = parteIzq;
        }
        if (!parteDer.empty()) {
            tituloInferido = parteDer;
        }
    }

    // Extrae metadatos reales desde el archivo multimedia (tags ID3v2, Vorbis, RIFF y caratula)
    MetadatosAudio metaAudio = ExtractorMetadata::extraer(ruta);
    if (!metaAudio.titulo.empty()) tituloInferido = metaAudio.titulo;
    if (!metaAudio.artista.empty()) artistaInferido = metaAudio.artista;
    if (!metaAudio.genero.empty()) generoInferido = metaAudio.genero;
    if (metaAudio.duracionSegundos > 0 && duracionCalculada <= 0) duracionCalculada = metaAudio.duracionSegundos;
    if (!metaAudio.rutaPortadaCache.empty() && portadaInferida.empty()) portadaInferida = metaAudio.rutaPortadaCache;
    if (metaAudio.tamanoBytes > 0 && tamano_bytes <= 0) tamano_bytes = metaAudio.tamanoBytes;
    if (!metaAudio.bytesPortada.empty()) {
        int idProximo = bridge_siguiente_id_libre_biblioteca();
        ExtractorMetadata::registrarPortadaBytes(idProximo, metaAudio.bytesPortada);
    }

    std::string titOvr = trimTexto(aStringSeguro(titulo_override));
    std::string artOvr = trimTexto(aStringSeguro(artista_override));
    std::string genOvr = trimTexto(aStringSeguro(genero_override));

    std::string tituloFinal = !titOvr.empty() ? titOvr : (tituloInferido.empty() ? std::string("Audio Importado") : tituloInferido);
    std::string artistaFinal = !artOvr.empty() ? artOvr : artistaInferido;
    std::string generoFinal = !genOvr.empty() ? genOvr : generoInferido;

    if (duracionCalculada <= 0) {
        if (tamano_bytes > 0) {
            int est = tamano_bytes / 24000;
            if (est < 95) est = 95;
            if (est > 480) est = 480;
            duracionCalculada = est;
        } else {
            duracionCalculada = 185 + (hashDeterministicoNombre(nombreArchivo) % 140);
        }
    }

    int nuevoId = bridge_siguiente_id_libre_biblioteca();
    return bridge_agregar_cancion_biblioteca_json(
        nuevoId,
        tituloFinal.c_str(),
        artistaFinal.c_str(),
        duracionCalculada,
        generoFinal.c_str(),
        ruta.c_str(),
        portadaInferida.empty() ? nullptr : portadaInferida.c_str(),
        1,
        1,
        tamano_bytes
    );
}

BRIDGE_API int bridge_eliminar_cancion_biblioteca(int id) {
    inicializarPuenteSiHaceFalta();
    return g_estado.biblioteca.eliminarPorId(id) ? 1 : 0;
}

BRIDGE_API char* bridge_toggle_favorito_cancion_json(int id) {
    inicializarPuenteSiHaceFalta();
    Cancion encontrada;
    if (!existeCancionEnCualquierLugar(id, encontrada)) {
        return aHeapCString("null");
    }
    NodoMetaCancion* meta = obtenerOCrearMetaCancion(id);
    meta->esFavorita = !meta->esFavorita;
    return aHeapCString(serializarCancionJson(encontrada));
}

BRIDGE_API char* bridge_exportar_biblioteca_csv(char delimitador, int incluir_campos_extendidos) {
    inicializarPuenteSiHaceFalta();
    std::string out;
    out += std::string("id") + delimitador + "titulo" + delimitador +
           "artista" + delimitador + "duracion_segundos" + delimitador + "genero";
    if (incluir_campos_extendidos != 0) {
        out += std::string(1, delimitador) + "ruta_archivo" + delimitador + "portada";
    }
    out += "\n";

    NodoSimple* actual = g_estado.biblioteca.getCabeza();
    while (actual != nullptr) {
        out += actual->dato.aCSV(delimitador);
        if (incluir_campos_extendidos != 0) {
            NodoMetaCancion* meta = buscarMetaCancion(actual->dato.getId());
            std::string ruta = meta != nullptr ? meta->rutaArchivo : "";
            std::string portada = meta != nullptr ? meta->portadaUrl : "";
            out += std::string(1, delimitador) + ruta + delimitador + portada;
        }
        out += "\n";
        actual = actual->siguiente;
    }
    return aHeapCString(out);
}

BRIDGE_API int bridge_importar_biblioteca_csv(
    const char* contenido_csv,
    char delimitador,
    int reemplazar_existente
) {
    inicializarPuenteSiHaceFalta();
    std::string contenido = aStringSeguro(contenido_csv);

    if (reemplazar_existente != 0) {
        g_estado.biblioteca.limpiar();
    }

    int cargadas = 0;
    std::size_t pos = 0;
    while (pos < contenido.size()) {
        std::size_t finLinea = contenido.find('\n', pos);
        std::string linea;
        if (finLinea == std::string::npos) {
            linea = contenido.substr(pos);
            pos = contenido.size();
        } else {
            linea = contenido.substr(pos, finLinea - pos);
            pos = finLinea + 1;
        }

        Cancion c;
        std::string rutaExt;
        std::string portadaExt;
        if (parsearLineaCSVExtendida(linea, delimitador, c, rutaExt, portadaExt)) {
            Cancion dummy;
            int idFinal = c.getId();
            if (g_estado.biblioteca.buscarPorId(idFinal, dummy)) {
                idFinal = bridge_siguiente_id_libre_biblioteca();
                c.setId(idFinal);
            }
            g_estado.biblioteca.agregarAlFinal(c);

            if (!rutaExt.empty() || !portadaExt.empty()) {
                NodoMetaCancion* meta = obtenerOCrearMetaCancion(idFinal);
                if (!rutaExt.empty()) {
                    meta->rutaArchivo = rutaExt;
                    meta->esArchivoLocal = true;
                }
                if (!portadaExt.empty()) {
                    meta->portadaUrl = portadaExt;
                }
                meta->metadataExtraida = true;
            }
            cargadas++;
        }
    }
    return cargadas;
}

BRIDGE_API int bridge_guardar_biblioteca_archivo_csv(const char* ruta_archivo, char delimitador) {
    inicializarPuenteSiHaceFalta();
    std::string ruta = trimTexto(aStringSeguro(ruta_archivo));
    if (ruta.empty()) {
        return 0;
    }
    return g_estado.biblioteca.guardarEnCSV(ruta, delimitador) ? 1 : 0;
}

BRIDGE_API int bridge_cargar_biblioteca_archivo_csv(const char* ruta_archivo, char delimitador) {
    inicializarPuenteSiHaceFalta();
    std::string ruta = trimTexto(aStringSeguro(ruta_archivo));
    if (ruta.empty()) {
        return -1;
    }
    std::ifstream archivo(ruta);
    if (!archivo.is_open()) {
        return -1;
    }
    std::string contenido;
    std::string linea;
    while (std::getline(archivo, linea)) {
        contenido += linea + "\n";
    }
    archivo.close();
    return bridge_importar_biblioteca_csv(contenido.c_str(), delimitador, 1);
}

BRIDGE_API unsigned char* bridge_obtener_portada_bytes(int cancion_id, int* out_tamano) {
    if (out_tamano != nullptr) {
        *out_tamano = 0;
    }
    (void)cancion_id;

    // Recupera la caratula embebida y reserva un buffer con malloc para gestion de memoria en Dart FFI
    const std::vector<uint8_t>* bytes = ExtractorMetadata::obtenerPortadaBytes(cancion_id);
    if (bytes != nullptr && !bytes->empty()) {
        unsigned char* buffer = static_cast<unsigned char*>(std::malloc(bytes->size()));
        if (buffer != nullptr) {
            std::memcpy(buffer, bytes->data(), bytes->size());
            if (out_tamano != nullptr) {
                *out_tamano = static_cast<int>(bytes->size());
            }
            return buffer;
        }
    }
    return nullptr;
}


/* ============================================================================
 * 2. GESTION DE PLAYLISTS (ListaDobleCircular* playlists[20])
 * ============================================================================ */

BRIDGE_API char* bridge_obtener_playlists_json(void) {
    inicializarPuenteSiHaceFalta();
    std::string json = "[";
    for (int i = 0; i < g_estado.cantidadPlaylists; ++i) {
        if (i > 0) {
            json += ",";
        }
        json += serializarPlaylistJson(i);
    }
    json += "]";
    return aHeapCString(json);
}

BRIDGE_API char* bridge_obtener_playlist_activa_json(void) {
    inicializarPuenteSiHaceFalta();
    if (g_estado.indicePlaylistActiva < 0 ||
        g_estado.indicePlaylistActiva >= g_estado.cantidadPlaylists) {
        return aHeapCString("null");
    }
    return aHeapCString(serializarPlaylistJson(g_estado.indicePlaylistActiva));
}

BRIDGE_API char* bridge_obtener_playlist_por_id_json(const char* playlist_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return aHeapCString("null");
    }
    return aHeapCString(serializarPlaylistJson(idx));
}

BRIDGE_API int bridge_existe_nombre_playlist(const char* nombre, const char* ignorar_playlist_id) {
    inicializarPuenteSiHaceFalta();
    std::string buscado = aMinusculas(trimTexto(aStringSeguro(nombre)));
    std::string ignorar = trimTexto(aStringSeguro(ignorar_playlist_id));

    if (buscado.empty()) {
        return 0;
    }
    for (int i = 0; i < g_estado.cantidadPlaylists; ++i) {
        if (!ignorar.empty() && g_estado.playlistIds[i] == ignorar) {
            continue;
        }
        if (g_estado.playlists[i] != nullptr) {
            std::string actualNombre = aMinusculas(trimTexto(g_estado.playlists[i]->getNombre()));
            if (actualNombre == buscado) {
                return 1;
            }
        }
    }
    return 0;
}

BRIDGE_API char* bridge_crear_playlist_json(const char* nombre, int activar_al_crear) {
    inicializarPuenteSiHaceFalta();
    if (g_estado.cantidadPlaylists >= BRIDGE_MAX_PLAYLISTS) {
        return aHeapCString("null");
    }

    std::string limpio = sanitizarCampoCSV(aStringSeguro(nombre));
    if (limpio.empty() || bridge_existe_nombre_playlist(limpio.c_str(), nullptr) != 0) {
        return aHeapCString("null");
    }

    g_estado.contadorPlaylists++;
    std::string nuevoId = "pl_" + std::to_string(g_estado.contadorPlaylists);

    int idxNuevo = g_estado.cantidadPlaylists;
    g_estado.playlists[idxNuevo] = new ListaDobleCircular(limpio);
    g_estado.playlistIds[idxNuevo] = nuevoId;
    g_estado.cantidadPlaylists++;

    if (activar_al_crear != 0 || g_estado.indicePlaylistActiva == -1) {
        g_estado.indicePlaylistActiva = idxNuevo;
        sincronizarPlaybackConPlaylistActiva();
    }

    return aHeapCString(serializarPlaylistJson(idxNuevo));
}

BRIDGE_API int bridge_renombrar_playlist(const char* playlist_id, const char* nuevo_nombre) {
    inicializarPuenteSiHaceFalta();
    std::string id = aStringSeguro(playlist_id);
    int idx = buscarIndicePlaylistPorId(id);
    std::string limpio = sanitizarCampoCSV(aStringSeguro(nuevo_nombre));

    if (idx == -1 || limpio.empty() ||
        bridge_existe_nombre_playlist(limpio.c_str(), id.c_str()) != 0) {
        return 0;
    }

    g_estado.playlists[idx]->renombrar(limpio);
    if (idx == g_estado.indicePlaylistActiva) {
        g_estado.nombreContexto = limpio;
    }
    return 1;
}

BRIDGE_API int bridge_eliminar_playlist(const char* playlist_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }

    bool eraActiva = (idx == g_estado.indicePlaylistActiva);

    delete g_estado.playlists[idx];
    for (int i = idx; i < g_estado.cantidadPlaylists - 1; ++i) {
        g_estado.playlists[i] = g_estado.playlists[i + 1];
        g_estado.playlistIds[i] = g_estado.playlistIds[i + 1];
    }
    g_estado.cantidadPlaylists--;
    g_estado.playlists[g_estado.cantidadPlaylists] = nullptr;
    g_estado.playlistIds[g_estado.cantidadPlaylists] = "";

    if (g_estado.cantidadPlaylists == 0) {
        g_estado.indicePlaylistActiva = -1;
        limpiarEstadoReproduccionPorVacio();
    } else if (eraActiva) {
        g_estado.indicePlaylistActiva = 0;
        sincronizarPlaybackConPlaylistActiva();
    } else if (g_estado.indicePlaylistActiva > idx) {
        g_estado.indicePlaylistActiva--;
    }
    return 1;
}

BRIDGE_API int bridge_seleccionar_playlist_activa(const char* playlist_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    g_estado.indicePlaylistActiva = idx;
    sincronizarPlaybackConPlaylistActiva();
    return 1;
}


/* ============================================================================
 * 3. OPERACIONES DE NODOS EN PLAYLIST (ListaDobleCircular)
 * ============================================================================ */

BRIDGE_API int bridge_playlist_insertar_inicio_por_id(const char* playlist_id, int cancion_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    Cancion cancion;
    if (!g_estado.biblioteca.buscarPorId(cancion_id, cancion)) {
        return 0;
    }
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    g_estado.playlists[idx]->insertarAlInicio(cancion);
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_playlist_insertar_final_por_id(const char* playlist_id, int cancion_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    Cancion cancion;
    if (!g_estado.biblioteca.buscarPorId(cancion_id, cancion)) {
        return 0;
    }
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    g_estado.playlists[idx]->insertarAlFinal(cancion);
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_playlist_insertar_posicion_por_id(
    const char* playlist_id,
    int cancion_id,
    int posicion_cero_based
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    Cancion cancion;
    if (!g_estado.biblioteca.buscarPorId(cancion_id, cancion)) {
        return 0;
    }
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    if (!g_estado.playlists[idx]->insertarEnPosicion(cancion, posicion_cero_based)) {
        return 0;
    }
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_playlist_insertar_inicio(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    std::string tit = sanitizarCampoCSV(aStringSeguro(titulo));
    std::string art = sanitizarCampoCSV(aStringSeguro(artista));
    std::string gen = sanitizarCampoCSV(aStringSeguro(genero));
    Cancion cancion(
        id,
        tit.empty() ? std::string("Sin titulo") : tit,
        art.empty() ? std::string("Desconocido") : art,
        duracion_segundos,
        gen.empty() ? std::string("Sin genero") : gen
    );
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    g_estado.playlists[idx]->insertarAlInicio(cancion);
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_playlist_insertar_final(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    std::string tit = sanitizarCampoCSV(aStringSeguro(titulo));
    std::string art = sanitizarCampoCSV(aStringSeguro(artista));
    std::string gen = sanitizarCampoCSV(aStringSeguro(genero));
    Cancion cancion(
        id,
        tit.empty() ? std::string("Sin titulo") : tit,
        art.empty() ? std::string("Desconocido") : art,
        duracion_segundos,
        gen.empty() ? std::string("Sin genero") : gen
    );
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    g_estado.playlists[idx]->insertarAlFinal(cancion);
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_playlist_insertar_posicion(
    const char* playlist_id,
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero,
    int posicion_cero_based
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    std::string tit = sanitizarCampoCSV(aStringSeguro(titulo));
    std::string art = sanitizarCampoCSV(aStringSeguro(artista));
    std::string gen = sanitizarCampoCSV(aStringSeguro(genero));
    Cancion cancion(
        id,
        tit.empty() ? std::string("Sin titulo") : tit,
        art.empty() ? std::string("Desconocido") : art,
        duracion_segundos,
        gen.empty() ? std::string("Sin genero") : gen
    );
    bool estabaVacia = g_estado.playlists[idx]->estaVacia();
    if (!g_estado.playlists[idx]->insertarEnPosicion(cancion, posicion_cero_based)) {
        return 0;
    }
    if (idx == g_estado.indicePlaylistActiva && estabaVacia) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API char* bridge_playlist_eliminar_inicio_json(const char* playlist_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1 || g_estado.playlists[idx]->estaVacia()) {
        return aHeapCString("null");
    }
    Cancion eliminada = g_estado.playlists[idx]->getCabeza()->dato;
    if (!g_estado.playlists[idx]->eliminarAlInicio()) {
        return aHeapCString("null");
    }
    if (idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return aHeapCString(serializarCancionJson(eliminada));
}

BRIDGE_API char* bridge_playlist_eliminar_final_json(const char* playlist_id) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1 || g_estado.playlists[idx]->estaVacia()) {
        return aHeapCString("null");
    }
    Cancion eliminada = g_estado.playlists[idx]->getCola()->dato;
    if (!g_estado.playlists[idx]->eliminarAlFinal()) {
        return aHeapCString("null");
    }
    if (idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return aHeapCString(serializarCancionJson(eliminada));
}

BRIDGE_API char* bridge_playlist_eliminar_posicion_json(
    const char* playlist_id,
    int posicion_cero_based
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return aHeapCString("null");
    }
    NodoDoble* nodo = g_estado.playlists[idx]->obtenerNodoEn(posicion_cero_based);
    if (nodo == nullptr) {
        return aHeapCString("null");
    }
    Cancion eliminada = nodo->dato;
    if (!g_estado.playlists[idx]->eliminarEnPosicion(posicion_cero_based)) {
        return aHeapCString("null");
    }
    if (idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return aHeapCString(serializarCancionJson(eliminada));
}


/* ============================================================================
 * 4. ALGORITMOS DE REPRODUCCION Y LISTAS (GestorReproduccion)
 * ============================================================================ */

BRIDGE_API int bridge_mover_cancion_playlist(
    const char* playlist_id,
    int pos_origen_cero_based,
    int pos_destino_cero_based
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return 0;
    }
    bool ok = GestorReproduccion::moverCancion(
        *g_estado.playlists[idx],
        pos_origen_cero_based,
        pos_destino_cero_based
    );
    if (!ok) {
        return 0;
    }
    if (idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_aplicar_shuffle_fisher_yates(
    const char* playlist_id,
    int usar_semilla,
    unsigned int semilla
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1 || g_estado.playlists[idx]->getTamano() <= 1) {
        return 0;
    }

    unsigned int seedUsada = semilla;
    if (usar_semilla == 0) {
        static unsigned int contadorSemilla = 1;
        seedUsada = static_cast<unsigned int>(std::time(nullptr)) + (contadorSemilla++);
    }

    GestorReproduccion::aplicarShuffleFisherYates(*g_estado.playlists[idx], seedUsada);
    g_estado.tieneUltimoShuffleSemilla = true;
    g_estado.ultimoShuffleSemilla = seedUsada;

    if (idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API int bridge_fusionar_playlists(
    const char* playlist_principal_id,
    const char* playlist_secundaria_id,
    int vaciar_secundaria
) {
    inicializarPuenteSiHaceFalta();
    std::string idPrinc = aStringSeguro(playlist_principal_id);
    std::string idSec = aStringSeguro(playlist_secundaria_id);
    if (idPrinc == idSec) {
        return 0;
    }
    int idxPrinc = buscarIndicePlaylistPorId(idPrinc);
    int idxSec = buscarIndicePlaylistPorId(idSec);
    if (idxPrinc == -1 || idxSec == -1 || g_estado.playlists[idxSec]->estaVacia()) {
        return 0;
    }

    bool estabaVaciaPrinc = g_estado.playlists[idxPrinc]->estaVacia();
    GestorReproduccion::fusionarListas(
        *g_estado.playlists[idxPrinc],
        *g_estado.playlists[idxSec],
        vaciar_secundaria != 0
    );

    if ((idxPrinc == g_estado.indicePlaylistActiva && estabaVaciaPrinc) ||
        (vaciar_secundaria != 0 && idxSec == g_estado.indicePlaylistActiva)) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return 1;
}

BRIDGE_API char* bridge_exportar_playlist_csv(const char* playlist_id, char delimitador) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return aHeapCString("");
    }
    ListaDobleCircular* pl = g_estado.playlists[idx];
    std::string out = "id;titulo;artista;duracion_segundos;genero\n";
    NodoDoble* nodo = pl->getCabeza();
    for (int i = 0; i < pl->getTamano() && nodo != nullptr; ++i) {
        out += nodo->dato.aCSV(delimitador) + "\n";
        nodo = nodo->siguiente;
    }
    return aHeapCString(out);
}

BRIDGE_API char* bridge_importar_playlist_csv_json(
    const char* nombre_playlist,
    const char* contenido_csv,
    char delimitador
) {
    inicializarPuenteSiHaceFalta();
    if (g_estado.cantidadPlaylists >= BRIDGE_MAX_PLAYLISTS) {
        return aHeapCString("null");
    }

    std::string limpio = sanitizarCampoCSV(aStringSeguro(nombre_playlist));
    if (limpio.empty() || bridge_existe_nombre_playlist(limpio.c_str(), nullptr) != 0) {
        return aHeapCString("null");
    }

    g_estado.contadorPlaylists++;
    std::string nuevoId = "pl_" + std::to_string(g_estado.contadorPlaylists);
    int idxNuevo = g_estado.cantidadPlaylists;
    ListaDobleCircular* pl = new ListaDobleCircular(limpio);
    g_estado.playlists[idxNuevo] = pl;
    g_estado.playlistIds[idxNuevo] = nuevoId;
    g_estado.cantidadPlaylists++;
    g_estado.indicePlaylistActiva = idxNuevo;

    std::string contenido = aStringSeguro(contenido_csv);
    std::size_t pos = 0;
    while (pos < contenido.size()) {
        std::size_t finLinea = contenido.find('\n', pos);
        std::string linea;
        if (finLinea == std::string::npos) {
            linea = contenido.substr(pos);
            pos = contenido.size();
        } else {
            linea = contenido.substr(pos, finLinea - pos);
            pos = finLinea + 1;
        }
        Cancion c;
        std::string rutaExt;
        std::string portadaExt;
        if (parsearLineaCSVExtendida(linea, delimitador, c, rutaExt, portadaExt)) {
            pl->insertarAlFinal(c);
            if (!rutaExt.empty() || !portadaExt.empty()) {
                NodoMetaCancion* meta = obtenerOCrearMetaCancion(c.getId());
                if (!rutaExt.empty()) {
                    meta->rutaArchivo = rutaExt;
                    meta->esArchivoLocal = true;
                }
                if (!portadaExt.empty()) {
                    meta->portadaUrl = portadaExt;
                }
                meta->metadataExtraida = true;
            }
        }
    }

    sincronizarPlaybackConPlaylistActiva();
    return aHeapCString(serializarPlaylistJson(idxNuevo));
}

BRIDGE_API int bridge_guardar_playlist_archivo_csv(
    const char* playlist_id,
    const char* ruta_archivo,
    char delimitador
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    std::string ruta = trimTexto(aStringSeguro(ruta_archivo));
    if (idx == -1 || ruta.empty()) {
        return 0;
    }
    return GestorReproduccion::guardarPlaylistCSV(
        *g_estado.playlists[idx],
        ruta,
        delimitador
    ) ? 1 : 0;
}

BRIDGE_API int bridge_cargar_playlist_archivo_csv(
    const char* playlist_id,
    const char* ruta_archivo,
    char delimitador
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    std::string ruta = trimTexto(aStringSeguro(ruta_archivo));
    if (idx == -1 || ruta.empty()) {
        return -1;
    }
    int cargadas = GestorReproduccion::cargarPlaylistCSV(
        *g_estado.playlists[idx],
        ruta,
        delimitador
    );
    if (cargadas >= 0 && idx == g_estado.indicePlaylistActiva) {
        sincronizarPlaybackConPlaylistActiva();
    }
    return cargadas;
}


/* ============================================================================
 * 5. MOTOR DE REPRODUCCION, CURSOR CIRCULAR Y AUDIO
 * ============================================================================ */

BRIDGE_API char* bridge_obtener_estado_reproduccion_json(void) {
    inicializarPuenteSiHaceFalta();

    // Sincroniza la posicion actual y el estado consultando el cursor PCM del motor de audio
    g_motorAudio.sincronizarEstado();
    EstadoReproduccionActual estAudio = g_motorAudio.getEstadoActual();
    if (g_estado.tieneCancionActual) {
        g_estado.posicionActualSegundos = estAudio.posicionActualSegundos;
        g_estado.isPlaying = estAudio.isPlaying;
    }

    std::string plActivaId = "";
    bool hayPlActiva = (g_estado.indicePlaylistActiva >= 0 &&
                        g_estado.indicePlaylistActiva < g_estado.cantidadPlaylists);
    if (hayPlActiva) {
        plActivaId = g_estado.playlistIds[g_estado.indicePlaylistActiva];
    }

    std::string json = "{";
    json += "\"cancion_actual\":" +
            (g_estado.tieneCancionActual ? serializarCancionJson(g_estado.cancionActual) : std::string("null")) + ",";
    json += "\"playlist_activa_id\":" + cadenaJsonONull(plActivaId, hayPlActiva) + ",";
    json += "\"nombre_contexto\":\"" + escaparJson(g_estado.nombreContexto) + "\",";
    json += "\"is_playing\":" + std::string(g_estado.isPlaying ? "true" : "false") + ",";
    json += "\"posicion_actual_segundos\":" + std::to_string(g_estado.posicionActualSegundos) + ",";
    json += "\"duracion_total_segundos\":" + std::to_string(g_estado.duracionTotalSegundos) + ",";
    json += "\"volumen\":" + formatearDoubleJson(g_estado.volumen) + ",";
    json += "\"modo_repeticion\":\"" + modoRepeticionAString(g_estado.modoRepeticion) + "\",";
    json += "\"modo_repeticion_codigo\":" + std::to_string(modoRepeticionACodigo(g_estado.modoRepeticion)) + ",";
    json += "\"ultimo_shuffle_semilla\":" +
            (g_estado.tieneUltimoShuffleSemilla ? std::to_string(g_estado.ultimoShuffleSemilla) : std::string("null")) + ",";
    json += "\"mensaje_estado\":" + cadenaJsonONull(g_estado.mensajeEstado, g_estado.tieneMensajeEstado);
    json += "}";

    return aHeapCString(json);
}

BRIDGE_API char* bridge_reproducir_cancion_en_playlist_json(
    const char* playlist_id,
    int indice_nodo
) {
    inicializarPuenteSiHaceFalta();
    int idx = buscarIndicePlaylistPorId(aStringSeguro(playlist_id));
    if (idx == -1) {
        return aHeapCString("null");
    }
    ListaDobleCircular* pl = g_estado.playlists[idx];
    if (pl == nullptr || indice_nodo < 0 || indice_nodo >= pl->getTamano()) {
        return aHeapCString("null");
    }

    if (!posicionarCursorEnIndice(pl, indice_nodo)) {
        return aHeapCString("null");
    }

    const Cancion* actual = pl->obtenerCancionActual();
    if (actual == nullptr) {
        return aHeapCString("null");
    }

    g_estado.indicePlaylistActiva = idx;
    g_estado.tieneCancionActual = true;
    g_estado.cancionActual = *actual;
    g_estado.nombreContexto = pl->getNombre();
    g_estado.isPlaying = true;
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = actual->getDuracionSegundos();
    g_estado.modoRepeticion = pl->getModoRepeticion();
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    int tamAntes = g_estado.historial.getTamano();
    GestorReproduccion::registrarEnHistorial(*pl, g_estado.historial);
    if (g_estado.historial.getTamano() > tamAntes) {
        agregarMetaHistorialAlInicio(pl->getNombre());
    }

    // Envia la pista seleccionada en la playlist circular al motor de audio nativo
    g_motorAudio.setModoRepeticion(pl->getModoRepeticion());
    g_motorAudio.setVolume(g_estado.volumen);
    Cancion cAudio = *actual;
    NodoMetaCancion* mAudio = buscarMetaCancion(actual->getId());
    if (mAudio != nullptr && !mAudio->rutaArchivo.empty()) {
        cAudio.setRutaArchivo(mAudio->rutaArchivo);
    }
    g_motorAudio.play(cAudio);

    return aHeapCString(serializarCancionJson(*actual));
}

BRIDGE_API char* bridge_reproducir_cancion_directa_json(
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero
) {
    inicializarPuenteSiHaceFalta();

    if (g_estado.indicePlaylistActiva >= 0 &&
        g_estado.indicePlaylistActiva < g_estado.cantidadPlaylists) {
        ListaDobleCircular* activa = g_estado.playlists[g_estado.indicePlaylistActiva];
        if (activa != nullptr) {
            NodoDoble* nodo = activa->getCabeza();
            for (int i = 0; i < activa->getTamano() && nodo != nullptr; ++i) {
                if (nodo->dato.getId() == id) {
                    return bridge_reproducir_cancion_en_playlist_json(
                        g_estado.playlistIds[g_estado.indicePlaylistActiva].c_str(),
                        i
                    );
                }
                nodo = nodo->siguiente;
            }
        }
    }

    Cancion cancion;
    if (!g_estado.biblioteca.buscarPorId(id, cancion)) {
        std::string tit = sanitizarCampoCSV(aStringSeguro(titulo));
        std::string art = sanitizarCampoCSV(aStringSeguro(artista));
        std::string gen = sanitizarCampoCSV(aStringSeguro(genero));
        cancion = Cancion(
            id,
            tit.empty() ? std::string("Sin titulo") : tit,
            art.empty() ? std::string("Desconocido") : art,
            duracion_segundos,
            gen.empty() ? std::string("Sin genero") : gen
        );
    }

    g_estado.tieneCancionActual = true;
    g_estado.cancionActual = cancion;
    g_estado.nombreContexto = "Biblioteca General (ListaSimple)";
    g_estado.isPlaying = true;
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = cancion.getDuracionSegundos();
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    registrarCancionEnHistorialInterno(cancion, "Biblioteca General");

    // Inicia la reproduccion de la cancion seleccionada de la biblioteca general en el motor de audio
    g_motorAudio.setVolume(g_estado.volumen);
    Cancion cDirecta = cancion;
    NodoMetaCancion* mDirecta = buscarMetaCancion(cancion.getId());
    if (mDirecta != nullptr && !mDirecta->rutaArchivo.empty()) {
        cDirecta.setRutaArchivo(mDirecta->rutaArchivo);
    }
    g_motorAudio.play(cDirecta);

    return aHeapCString(serializarCancionJson(cancion));
}

BRIDGE_API char* bridge_siguiente_cancion_json(void) {
    inicializarPuenteSiHaceFalta();
    if (g_estado.indicePlaylistActiva < 0 ||
        g_estado.indicePlaylistActiva >= g_estado.cantidadPlaylists) {
        return aHeapCString("null");
    }
    ListaDobleCircular* activa = g_estado.playlists[g_estado.indicePlaylistActiva];
    if (activa == nullptr || activa->estaVacia()) {
        return aHeapCString("null");
    }

    const Cancion* siguiente = activa->siguienteCancion();
    if (siguiente == nullptr) {
        g_estado.isPlaying = false;
        g_estado.posicionActualSegundos = g_estado.duracionTotalSegundos;
        g_estado.tieneMensajeEstado = true;
        g_estado.mensajeEstado =
            "Fin de la playlist (modo Sin repeticion). Cambia el modo o retrocede.";

        // Detiene el motor de audio al alcanzar el fin de la playlist en modo SIN_REPETICION
        g_motorAudio.stop();

        return aHeapCString("null");
    }

    g_estado.tieneCancionActual = true;
    g_estado.cancionActual = *siguiente;
    g_estado.nombreContexto = activa->getNombre();
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = siguiente->getDuracionSegundos();
    g_estado.isPlaying = true;
    g_estado.modoRepeticion = activa->getModoRepeticion();
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    int tamAntes = g_estado.historial.getTamano();
    GestorReproduccion::registrarEnHistorial(*activa, g_estado.historial);
    if (g_estado.historial.getTamano() > tamAntes) {
        agregarMetaHistorialAlInicio(activa->getNombre());
    }

    // Envia la pista siguiente al motor de audio real aplicando volumen y modo
    g_motorAudio.setModoRepeticion(activa->getModoRepeticion());
    g_motorAudio.setVolume(g_estado.volumen);
    Cancion cSig = *siguiente;
    NodoMetaCancion* mSig = buscarMetaCancion(siguiente->getId());
    if (mSig != nullptr && !mSig->rutaArchivo.empty()) {
        cSig.setRutaArchivo(mSig->rutaArchivo);
    }
    g_motorAudio.play(cSig);

    return aHeapCString(serializarCancionJson(*siguiente));
}

BRIDGE_API char* bridge_anterior_cancion_json(void) {
    inicializarPuenteSiHaceFalta();
    if (g_estado.indicePlaylistActiva < 0 ||
        g_estado.indicePlaylistActiva >= g_estado.cantidadPlaylists) {
        return aHeapCString("null");
    }
    ListaDobleCircular* activa = g_estado.playlists[g_estado.indicePlaylistActiva];
    if (activa == nullptr || activa->estaVacia()) {
        return aHeapCString("null");
    }

    const Cancion* anterior = activa->anteriorCancion();
    if (anterior == nullptr) {
        return aHeapCString("null");
    }

    g_estado.tieneCancionActual = true;
    g_estado.cancionActual = *anterior;
    g_estado.nombreContexto = activa->getNombre();
    g_estado.posicionActualSegundos = 0;
    g_estado.duracionTotalSegundos = anterior->getDuracionSegundos();
    g_estado.isPlaying = true;
    g_estado.modoRepeticion = activa->getModoRepeticion();
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    int tamAntes = g_estado.historial.getTamano();
    GestorReproduccion::registrarEnHistorial(*activa, g_estado.historial);
    if (g_estado.historial.getTamano() > tamAntes) {
        agregarMetaHistorialAlInicio(activa->getNombre());
    }

    // Envia la pista anterior al motor de audio real aplicando volumen y modo
    g_motorAudio.setModoRepeticion(activa->getModoRepeticion());
    g_motorAudio.setVolume(g_estado.volumen);
    Cancion cAnt = *anterior;
    NodoMetaCancion* mAnt = buscarMetaCancion(anterior->getId());
    if (mAnt != nullptr && !mAnt->rutaArchivo.empty()) {
        cAnt.setRutaArchivo(mAnt->rutaArchivo);
    }
    g_motorAudio.play(cAnt);

    return aHeapCString(serializarCancionJson(*anterior));
}

BRIDGE_API void bridge_set_playing(int is_playing) {
    inicializarPuenteSiHaceFalta();
    if (!g_estado.tieneCancionActual && is_playing != 0) {
        if (g_estado.indicePlaylistActiva >= 0 &&
            g_estado.indicePlaylistActiva < g_estado.cantidadPlaylists) {
            ListaDobleCircular* activa = g_estado.playlists[g_estado.indicePlaylistActiva];
            if (activa != nullptr && !activa->estaVacia()) {
                int idx = obtenerIndiceActualPlaylist(*activa);
                char* res = bridge_reproducir_cancion_en_playlist_json(
                    g_estado.playlistIds[g_estado.indicePlaylistActiva].c_str(),
                    idx >= 0 ? idx : 0
                );
                bridge_free_string(res);
                return;
            }
        }
        if (!g_estado.biblioteca.estaVacia()) {
            const Cancion& primera = g_estado.biblioteca.getCabeza()->dato;
            char* res = bridge_reproducir_cancion_directa_json(
                primera.getId(),
                primera.getTitulo().c_str(),
                primera.getArtista().c_str(),
                primera.getDuracionSegundos(),
                primera.getGenero().c_str()
            );
            bridge_free_string(res);
            return;
        }
        return;
    }

    g_estado.isPlaying = (is_playing != 0);
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    // Reanuda o pausa el stream de audio nativo segun el comando recibido
    if (is_playing != 0) {
        g_motorAudio.resume();
    } else {
        g_motorAudio.pause();
    }
}

BRIDGE_API void bridge_seek_to(int posicion_segundos) {
    inicializarPuenteSiHaceFalta();
    int maxDur = g_estado.duracionTotalSegundos > 0 ? g_estado.duracionTotalSegundos : 0;
    int clamped = posicion_segundos;
    if (clamped < 0) clamped = 0;
    if (clamped > maxDur) clamped = maxDur;
    g_estado.posicionActualSegundos = clamped;
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";

    // Realiza el salto al segundo solicitado ajustando los frames PCM del decodificador
    g_motorAudio.seekTo(clamped);
}

BRIDGE_API void bridge_set_volumen(double volumen) {
    inicializarPuenteSiHaceFalta();
    double v = volumen;
    if (v < 0.0) v = 0.0;
    if (v > 1.0) v = 1.0;
    g_estado.volumen = v;

    // Ajusta la ganancia de volumen (0.0 a 1.0) en el motor de audio nativo
    g_motorAudio.setVolume(v);
}

BRIDGE_API void bridge_set_modo_repeticion(int modo_codigo) {
    inicializarPuenteSiHaceFalta();
    ModoRepeticion nuevoModo = codigoAModoRepeticion(modo_codigo);

    if (g_estado.indicePlaylistActiva >= 0 &&
        g_estado.indicePlaylistActiva < g_estado.cantidadPlaylists &&
        g_estado.playlists[g_estado.indicePlaylistActiva] != nullptr) {
        g_estado.playlists[g_estado.indicePlaylistActiva]->setModoRepeticion(nuevoModo);
    }
    g_estado.modoRepeticion = nuevoModo;
    g_estado.tieneMensajeEstado = false;
    g_estado.mensajeEstado = "";
}


/* ============================================================================
 * 6. HISTORIAL LIFO (ListaSimple) Y UTILIDADES
 * ============================================================================ */

BRIDGE_API char* bridge_obtener_historial_json(void) {
    inicializarPuenteSiHaceFalta();
    std::string json = "[";
    NodoSimple* actual = g_estado.historial.getCabeza();
    NodoMetaHistorial* meta = g_estado.metaHistorialCabeza;
    bool primero = true;
    int fallbackIdx = 0;

    while (actual != nullptr) {
        if (!primero) {
            json += ",";
        }
        std::string idReg = meta != nullptr
            ? meta->idRegistro
            : ("hist_auto_" + std::to_string(++fallbackIdx));
        std::string fecha = meta != nullptr
            ? meta->fechaReproduccion
            : fechaActualIso8601();
        std::string origen = meta != nullptr
            ? meta->origenNombre
            : g_estado.nombreContexto;

        json += "{";
        json += "\"id_registro\":\"" + escaparJson(idReg) + "\",";
        json += "\"cancion\":" + serializarCancionJson(actual->dato) + ",";
        json += "\"fecha_reproduccion\":\"" + escaparJson(fecha) + "\",";
        json += "\"origen_nombre\":\"" + escaparJson(origen) + "\"";
        json += "}";

        primero = false;
        actual = actual->siguiente;
        if (meta != nullptr) {
            meta = meta->siguiente;
        }
    }

    json += "]";
    return aHeapCString(json);
}

BRIDGE_API int bridge_calcular_duracion_total_historial(void) {
    inicializarPuenteSiHaceFalta();
    return g_estado.historial.calcularDuracionTotalSegundos();
}

BRIDGE_API void bridge_registrar_en_historial(
    int id,
    const char* titulo,
    const char* artista,
    int duracion_segundos,
    const char* genero,
    const char* origen_nombre
) {
    inicializarPuenteSiHaceFalta();
    std::string tit = sanitizarCampoCSV(aStringSeguro(titulo));
    std::string art = sanitizarCampoCSV(aStringSeguro(artista));
    std::string gen = sanitizarCampoCSV(aStringSeguro(genero));
    Cancion cancion(
        id,
        tit.empty() ? std::string("Sin titulo") : tit,
        art.empty() ? std::string("Desconocido") : art,
        duracion_segundos,
        gen.empty() ? std::string("Sin genero") : gen
    );
    std::string origen = trimTexto(aStringSeguro(origen_nombre));
    if (origen.empty()) {
        origen = g_estado.nombreContexto;
    }
    registrarCancionEnHistorialInterno(cancion, origen);
}

BRIDGE_API void bridge_limpiar_historial(void) {
    inicializarPuenteSiHaceFalta();
    g_estado.historial.limpiar();
    limpiarMetaHistorial();
}

BRIDGE_API char* bridge_formatear_duracion_total(int total_segundos) {
    return aHeapCString(formatearDuracionHHMMSS(total_segundos));
}

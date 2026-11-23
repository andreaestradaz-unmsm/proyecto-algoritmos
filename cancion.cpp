#include "cancion.h"

// Constructor vacio: asigna valores por defecto seguros
Cancion::Cancion() {
    id = 0;
    titulo = "Sin titulo";
    artista = "Desconocido";
    duracionSegundos = 0;
    genero = "Sin genero";
    rutaArchivo = "";
    portada = "";
    esFavorita = false;
    esArchivoLocal = false;
    metadataExtraida = false;
    tamanoBytes = 0;
}

// Constructor con 5 parametros base
Cancion::Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero) {
    this->id = id;
    this->titulo = titulo.empty() ? "Sin titulo" : titulo;
    this->artista = artista.empty() ? "Desconocido" : artista;
    this->duracionSegundos = (duracionSegundos >= 0) ? duracionSegundos : 0;
    this->genero = genero.empty() ? "Sin genero" : genero;
    this->rutaArchivo = "";
    this->portada = "";
    this->esFavorita = false;
    this->esArchivoLocal = false;
    this->metadataExtraida = false;
    this->tamanoBytes = 0;
}

// Constructor extendido con ruta de audio y caratula
Cancion::Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero,
                 std::string rutaArchivo, std::string portada) {
    this->id = id;
    this->titulo = titulo.empty() ? "Sin titulo" : titulo;
    this->artista = artista.empty() ? "Desconocido" : artista;
    this->duracionSegundos = (duracionSegundos >= 0) ? duracionSegundos : 0;
    this->genero = genero.empty() ? "Sin genero" : genero;
    this->rutaArchivo = rutaArchivo;
    this->portada = portada;
    this->esFavorita = false;
    this->esArchivoLocal = !rutaArchivo.empty();
    this->metadataExtraida = (!rutaArchivo.empty() || !portada.empty());
    this->tamanoBytes = 0;
}

// Getters base
int Cancion::getId() const { return id; }
std::string Cancion::getTitulo() const { return titulo; }
std::string Cancion::getArtista() const { return artista; }
int Cancion::getDuracionSegundos() const { return duracionSegundos; }
std::string Cancion::getGenero() const { return genero; }

// Getters extendidos
std::string Cancion::getRutaArchivo() const { return rutaArchivo; }
std::string Cancion::getPortada() const { return portada; }
std::string Cancion::getPortadaUrl() const { return portada; }
bool Cancion::getEsFavorita() const { return esFavorita; }
bool Cancion::getEsArchivoLocal() const { return esArchivoLocal; }
bool Cancion::getMetadataExtraida() const { return metadataExtraida; }
int Cancion::getTamanoBytes() const { return tamanoBytes; }

// Setters base
void Cancion::setId(int nuevoId) { id = nuevoId; }
void Cancion::setTitulo(std::string nuevoTitulo) { titulo = nuevoTitulo.empty() ? "Sin titulo" : nuevoTitulo; }
void Cancion::setArtista(std::string nuevoArtista) { artista = nuevoArtista.empty() ? "Desconocido" : nuevoArtista; }
void Cancion::setDuracionSegundos(int nuevaDuracion) { duracionSegundos = (nuevaDuracion >= 0) ? nuevaDuracion : 0; }
void Cancion::setGenero(std::string nuevoGenero) { genero = nuevoGenero.empty() ? "Sin genero" : nuevoGenero; }

// Setters extendidos
void Cancion::setRutaArchivo(std::string nuevaRuta) {
    rutaArchivo = nuevaRuta;
    if (!rutaArchivo.empty()) esArchivoLocal = true;
}
void Cancion::setPortada(std::string nuevaPortada) { portada = nuevaPortada; }
void Cancion::setPortadaUrl(std::string nuevaPortada) { portada = nuevaPortada; }
void Cancion::setEsFavorita(bool fav) { esFavorita = fav; }
void Cancion::setEsArchivoLocal(bool local) { esArchivoLocal = local; }
void Cancion::setMetadataExtraida(bool extraida) { metadataExtraida = extraida; }
void Cancion::setTamanoBytes(int bytes) { tamanoBytes = (bytes >= 0) ? bytes : 0; }

// Convierte los segundos al formato "MM:SS"
std::string Cancion::obtenerDuracionFormateada() const {
    int safe = duracionSegundos >= 0 ? duracionSegundos : 0;
    int minutos = safe / 60;
    int segundos = safe % 60;

    std::string textoMinutos = (minutos < 10) ? ("0" + std::to_string(minutos)) : std::to_string(minutos);
    std::string textoSegundos = (segundos < 10) ? ("0" + std::to_string(segundos)) : std::to_string(segundos);

    return textoMinutos + ":" + textoSegundos;
}

// Genera una cadena CSV con 5 columnas base o 7 columnas extendidas
std::string Cancion::aCSV(char delimitador, bool incluirCamposExtendidos) const {
    std::string linea = "";
    linea += std::to_string(id) + delimitador;
    linea += titulo + delimitador;
    linea += artista + delimitador;
    linea += std::to_string(duracionSegundos) + delimitador;
    linea += genero;

    if (incluirCamposExtendidos) {
        linea += delimitador;
        std::string r = rutaArchivo;
        for (char& c : r) {
            if (c == delimitador) c = '_';
        }
        linea += r + delimitador;

        std::string p = portada;
        for (char& c : p) {
            if (c == delimitador) c = '_';
        }
        linea += p;
    }

    return linea;
}

// Parsea una linea CSV soportando 5, 6 y 7 columnas
bool Cancion::desdeCSV(const std::string& lineaCSV, Cancion& cancionSalida, char delimitador) {
    if (lineaCSV.empty() || lineaCSV[0] < '0' || lineaCSV[0] > '9') {
        return false;
    }

    std::string campos[7];
    int indiceCampo = 0;
    std::string actual = "";

    for (size_t i = 0; i < lineaCSV.length(); i++) {
        char c = lineaCSV[i];
        if (c == '\r' || c == '\n') continue;
        if (c == delimitador) {
            if (indiceCampo < 6) {
                campos[indiceCampo] = actual;
                indiceCampo++;
                actual = "";
            } else {
                actual += c;
            }
        } else {
            actual += c;
        }
    }
    campos[indiceCampo] = actual;

    if (indiceCampo < 4) {
        return false;
    }

    try {
        int idLeido = std::stoi(campos[0]);
        std::string tituloLeido = campos[1].empty() ? "Sin titulo" : campos[1];
        std::string artistaLeido = campos[2].empty() ? "Desconocido" : campos[2];
        int duracionLeida = std::stoi(campos[3]);
        std::string generoLeido = campos[4].empty() ? "Sin genero" : campos[4];

        std::string rutaLeida = (indiceCampo >= 5) ? campos[5] : "";
        std::string portadaLeida = (indiceCampo >= 6) ? campos[6] : "";

        cancionSalida = Cancion(idLeido, tituloLeido, artistaLeido, duracionLeida, generoLeido, rutaLeida, portadaLeida);
        return true;
    } catch (...) {
        return false;
    }
}

// Imprime los datos de la cancion en consola
void Cancion::mostrar() const {
    std::cout << "[" << id << "] "
              << titulo << " - " << artista
              << " (" << obtenerDuracionFormateada() << ") | Genero: " << genero;
    if (!rutaArchivo.empty()) {
        std::cout << " | Archivo: " << rutaArchivo;
    }
    if (!portada.empty()) {
        std::cout << " | Portada: " << portada;
    }
    std::cout << "\n";
}

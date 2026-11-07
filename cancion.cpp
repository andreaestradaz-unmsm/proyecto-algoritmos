#include "cancion.h"

// Constructor vacio
Cancion::Cancion() {
    id = 0;
    titulo = "Sin titulo";
    artista = "Desconocido";
    duracionSegundos = 0;
    genero = "Sin genero";
}

// Constructor con parametros
Cancion::Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero) {
    this->id = id;
    this->titulo = titulo;
    this->artista = artista;
    if (duracionSegundos >= 0) {
        this->duracionSegundos = duracionSegundos;
    } else {
        this->duracionSegundos = 0;
    }
    this->genero = genero;
}

// Getters
int Cancion::getId() const {
    return id;
}

std::string Cancion::getTitulo() const {
    return titulo;
}

std::string Cancion::getArtista() const {
    return artista;
}

int Cancion::getDuracionSegundos() const {
    return duracionSegundos;
}

std::string Cancion::getGenero() const {
    return genero;
}

// Setters
void Cancion::setId(int nuevoId) {
    id = nuevoId;
}

void Cancion::setTitulo(std::string nuevoTitulo) {
    titulo = nuevoTitulo;
}

void Cancion::setArtista(std::string nuevoArtista) {
    artista = nuevoArtista;
}

void Cancion::setDuracionSegundos(int nuevaDuracion) {
    if (nuevaDuracion >= 0) {
        duracionSegundos = nuevaDuracion;
    }
}

void Cancion::setGenero(std::string nuevoGenero) {
    genero = nuevoGenero;
}

// Convierte la duracion en segundos a formato MM:SS desde cero
std::string Cancion::obtenerDuracionFormateada() const {
    int minutos = duracionSegundos / 60;
    int segundos = duracionSegundos % 60;

    std::string textoMinutos = "";
    if (minutos < 10) {
        textoMinutos = "0" + std::to_string(minutos);
    } else {
        textoMinutos = std::to_string(minutos);
    }

    std::string textoSegundos = "";
    if (segundos < 10) {
        textoSegundos = "0" + std::to_string(segundos);
    } else {
        textoSegundos = std::to_string(segundos);
    }

    return textoMinutos + ":" + textoSegundos;
}

// Arma una cadena con formato: id;titulo;artista;duracion;genero
std::string Cancion::aCSV(char delimitador) const {
    std::string linea = "";
    linea += std::to_string(id) + delimitador;
    linea += titulo + delimitador;
    linea += artista + delimitador;
    linea += std::to_string(duracionSegundos) + delimitador;
    linea += genero;
    return linea;
}

// Separa manualmente una linea CSV caracter por caracter sin librerias complejas
bool Cancion::desdeCSV(const std::string& lineaCSV, Cancion& cancionSalida, char delimitador) {
    if (lineaCSV == "") {
        return false;
    }

    // Si la primera linea es el encabezado del CSV ("id;titulo..."), no es una cancion
    if (lineaCSV[0] < '0' || lineaCSV[0] > '9') {
        return false;
    }

    std::string campos[5];
    int indiceCampo = 0;
    std::string actual = "";

    for (size_t i = 0; i < lineaCSV.length(); i++) {
        char c = lineaCSV[i];
        if (c == '\r' || c == '\n') {
            continue;
        }
        if (c == delimitador) {
            if (indiceCampo < 4) {
                campos[indiceCampo] = actual;
                indiceCampo++;
                actual = "";
            }
        } else {
            actual += c;
        }
    }
    campos[indiceCampo] = actual;

    // Deben haberse leido exactamente los 5 campos (indices 0 a 4)
    if (indiceCampo != 4) {
        return false;
    }

    int idLeido = std::stoi(campos[0]);
    std::string tituloLeido = campos[1];
    std::string artistaLeido = campos[2];
    int duracionLeida = std::stoi(campos[3]);
    std::string generoLeido = campos[4];

    cancionSalida = Cancion(idLeido, tituloLeido, artistaLeido, duracionLeida, generoLeido);
    return true;
}

// Muestra los datos de la cancion
void Cancion::mostrar() const {
    std::cout << "[" << id << "] "
              << titulo << " - " << artista
              << " (" << obtenerDuracionFormateada() << ") | Genero: " << genero << "\n";
}

#ifndef CANCION_H
#define CANCION_H

#include <string>
#include <iostream>

// TAD Cancion: representa una pista con metadatos base y campos extendidos para audio
class Cancion {
private:
    int id;
    std::string titulo;
    std::string artista;
    int duracionSegundos;
    std::string genero;
    std::string rutaArchivo;
    std::string portada;
    bool esFavorita;
    bool esArchivoLocal;
    bool metadataExtraida;
    int tamanoBytes;

public:
    // Constructores
    Cancion();
    Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero);
    Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero,
            std::string rutaArchivo, std::string portada = "");

    // Getters base
    int getId() const;
    std::string getTitulo() const;
    std::string getArtista() const;
    int getDuracionSegundos() const;
    std::string getGenero() const;

    // Getters extendidos
    std::string getRutaArchivo() const;
    std::string getPortada() const;
    std::string getPortadaUrl() const;
    bool getEsFavorita() const;
    bool getEsArchivoLocal() const;
    bool getMetadataExtraida() const;
    int getTamanoBytes() const;

    // Setters base
    void setId(int nuevoId);
    void setTitulo(std::string nuevoTitulo);
    void setArtista(std::string nuevoArtista);
    void setDuracionSegundos(int nuevaDuracion);
    void setGenero(std::string nuevoGenero);

    // Setters extendidos
    void setRutaArchivo(std::string nuevaRuta);
    void setPortada(std::string nuevaPortada);
    void setPortadaUrl(std::string nuevaPortada);
    void setEsFavorita(bool fav);
    void setEsArchivoLocal(bool local);
    void setMetadataExtraida(bool extraida);
    void setTamanoBytes(int bytes);

    // Convierte la duracion en segundos a formato "MM:SS"
    std::string obtenerDuracionFormateada() const;

    // Serializa a texto CSV (5 columnas base por defecto, o 7 si incluirCamposExtendidos es true)
    std::string aCSV(char delimitador = ';', bool incluirCamposExtendidos = false) const;

    // Parsea una linea CSV de 5, 6 o 7 columnas llenando los datos de la cancion
    static bool desdeCSV(const std::string& lineaCSV, Cancion& cancionSalida, char delimitador = ';');

    // Imprime los datos de la cancion en consola
    void mostrar() const;
};

#endif // CANCION_H

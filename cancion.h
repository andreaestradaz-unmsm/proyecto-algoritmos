#ifndef CANCION_H
#define CANCION_H

#include <string>
#include <iostream>

// TAD Cancion: representa una cancion con sus datos basicos
class Cancion {
private:
    int id;
    std::string titulo;
    std::string artista;
    int duracionSegundos;
    std::string genero;

public:
    // Constructores
    Cancion();
    Cancion(int id, std::string titulo, std::string artista, int duracionSegundos, std::string genero);

    // Getters
    int getId() const;
    std::string getTitulo() const;
    std::string getArtista() const;
    int getDuracionSegundos() const;
    std::string getGenero() const;

    // Setters
    void setId(int nuevoId);
    void setTitulo(std::string nuevoTitulo);
    void setArtista(std::string nuevoArtista);
    void setDuracionSegundos(int nuevaDuracion);
    void setGenero(std::string nuevoGenero);

    // Convierte los segundos al formato "MM:SS"
    std::string obtenerDuracionFormateada() const;

    // Convierte la cancion a una linea de texto separada por ';' para guardar en CSV
    std::string aCSV(char delimitador = ';') const;

    // Lee una linea de texto del CSV y llena los datos de la cancion
    static bool desdeCSV(const std::string& lineaCSV, Cancion& cancionSalida, char delimitador = ';');

    // Imprime los datos de la cancion en consola
    void mostrar() const;
};

#endif

#ifndef LISTA_SIMPLE_H
#define LISTA_SIMPLE_H

#include "cancion.h"
#include <string>

// Nodo de la Lista Enlazada Simple
struct NodoSimple {
    Cancion dato;
    NodoSimple* siguiente;

    NodoSimple(Cancion cancion) {
        dato = cancion;
        siguiente = nullptr;
    }
};

// Lista Enlazada Simple hecha con nodos y punteros (para Biblioteca e Historial)
class ListaSimple {
private:
    NodoSimple* cabeza;
    NodoSimple* cola;
    int tamano;

public:
    // Constructor y destructor
    ListaSimple();
    ~ListaSimple();

    // Operaciones con nodos
    void agregarAlInicio(const Cancion& cancion);
    void agregarAlFinal(const Cancion& cancion);
    bool eliminarPorId(int id);
    bool buscarPorId(int id, Cancion& cancionSalida) const;
    bool obtenerEnPosicion(int indice, Cancion& cancionSalida) const;

    // Recorrido y utilidades
    int calcularDuracionTotalSegundos() const;
    void mostrar(const std::string& tituloListado = "LISTADO DE CANCIONES") const;
    void limpiar();

    // Consultas basicas
    bool estaVacia() const;
    int getTamano() const;
    NodoSimple* getCabeza() const;

    // Guardar y cargar en archivo CSV recorriendo los nodos
    bool guardarEnCSV(const std::string& rutaArchivo, char delimitador = ';') const;
    int cargarDesdeCSV(const std::string& rutaArchivo, char delimitador = ';');
};

#endif

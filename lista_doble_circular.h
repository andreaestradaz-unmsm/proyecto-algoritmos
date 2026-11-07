#ifndef LISTA_DOBLE_CIRCULAR_H
#define LISTA_DOBLE_CIRCULAR_H

#include "cancion.h"
#include <string>

// ============================================================================
// PARTE DE JEICK — CABECERA (SOLO DECLARACIONES)
// ============================================================================
// IMPORTANTE PARA JEICK:
// Este archivo (.h) es solo el indice con los nombres de las funciones.
// NO escribas tu codigo aqui. Abre el archivo "lista_doble_circular.cpp" y
// escribe tu codigo donde dice: // <--- PON TU CODIGO AQUI
// ============================================================================

enum class ModoRepeticion {
    SIN_REPETICION,
    REPETIR_UNA,
    REPETIR_TODAS
};

// Nodo de la Lista Doblemente Enlazada Circular
struct NodoDoble {
    Cancion dato;
    NodoDoble* siguiente;
    NodoDoble* anterior;

    NodoDoble(Cancion cancion) {
        dato = cancion;
        siguiente = nullptr;
        anterior = nullptr;
    }
};

class ListaDobleCircular {
private:
    std::string nombrePlaylist;
    NodoDoble* cabeza;
    NodoDoble* cola;
    NodoDoble* actual;
    int tamano;
    ModoRepeticion modoRepeticion;

    friend class GestorReproduccion;

public:
    // Constructores y Destructor
    ListaDobleCircular(const std::string& nombre = "Mi Playlist");
    ~ListaDobleCircular();

    // Datos basicos de la playlist
    std::string getNombre() const;
    void renombrar(const std::string& nuevoNombre);
    int getTamano() const;
    bool estaVacia() const;

    // Operaciones de Insercion con nodos dobles
    void insertarAlInicio(const Cancion& cancion);
    void insertarAlFinal(const Cancion& cancion);
    bool insertarEnPosicion(const Cancion& cancion, int posicion);

    // Operaciones de Eliminacion con nodos dobles
    bool eliminarAlInicio();
    bool eliminarAlFinal();
    bool eliminarEnPosicion(int posicion);

    // Navegacion del Reproductor (Siguiente / Anterior / Repeticion)
    const Cancion* siguienteCancion();
    const Cancion* anteriorCancion();
    const Cancion* obtenerCancionActual() const;
    void setModoRepeticion(ModoRepeticion nuevoModo);
    ModoRepeticion getModoRepeticion() const;

    // Consultas, Duracion y Limpieza de Memoria
    NodoDoble* obtenerNodoEn(int posicion) const;
    NodoDoble* getCabeza() const;
    NodoDoble* getCola() const;
    int calcularDuracionTotalSegundos() const;
    void mostrar() const;
    void limpiar();
};

#endif

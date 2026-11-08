#include "lista_doble_circular.h"
#include <iostream>

/**
 * ============================================================================
 * Implementación del TAD de lista doblemente enlazada circular.
 * La estructura mantiene una cabeza, una cola y un cursor de reproducción.
 * ============================================================================
 */

ListaDobleCircular::ListaDobleCircular(const std::string& nombre) {
    nombrePlaylist = nombre;
    cabeza = nullptr;
    cola = nullptr;
    actual = nullptr;
    tamano = 0;
    modoRepeticion = ModoRepeticion::REPETIR_TODAS;
}

ListaDobleCircular::~ListaDobleCircular() {
    limpiar();
}

std::string ListaDobleCircular::getNombre() const {
    return nombrePlaylist;
}

void ListaDobleCircular::renombrar(const std::string& nuevoNombre) {
    nombrePlaylist = nuevoNombre;
}

int ListaDobleCircular::getTamano() const {
    return tamano;
}

bool ListaDobleCircular::estaVacia() const {
    return cabeza == nullptr;
}

void ListaDobleCircular::insertarAlInicio(const Cancion& cancion) {
    NodoDoble* nuevo = new NodoDoble(cancion);

    if (estaVacia()) {
        cabeza = cola = actual = nuevo;
        nuevo->siguiente = nuevo;
        nuevo->anterior = nuevo;
    } else {
        nuevo->siguiente = cabeza;
        nuevo->anterior = cola;
        cabeza->anterior = nuevo;
        cola->siguiente = nuevo;
        cabeza = nuevo;
    }

    ++tamano;
}

void ListaDobleCircular::insertarAlFinal(const Cancion& cancion) {
    NodoDoble* nuevo = new NodoDoble(cancion);

    if (estaVacia()) {
        cabeza = cola = actual = nuevo;
        nuevo->siguiente = nuevo;
        nuevo->anterior = nuevo;
    } else {
        nuevo->anterior = cola;
        nuevo->siguiente = cabeza;
        cola->siguiente = nuevo;
        cabeza->anterior = nuevo;
        cola = nuevo;
    }

    ++tamano;
}

bool ListaDobleCircular::insertarEnPosicion(const Cancion& cancion, int posicion) {
    if (posicion < 0 || posicion > tamano) {
        return false;
    }
    if (posicion == 0) {
        insertarAlInicio(cancion);
        return true;
    }
    if (posicion == tamano) {
        insertarAlFinal(cancion);
        return true;
    }

    NodoDoble* nodoActual = obtenerNodoEn(posicion);
    NodoDoble* nuevo = new NodoDoble(cancion);
    nuevo->anterior = nodoActual->anterior;
    nuevo->siguiente = nodoActual;
    nodoActual->anterior->siguiente = nuevo;
    nodoActual->anterior = nuevo;
    ++tamano;
    return true;
}

bool ListaDobleCircular::eliminarAlInicio() {
    if (estaVacia()) {
        return false;
    }

    NodoDoble* borrar = cabeza;
    if (cabeza == cola) {
        cabeza = cola = actual = nullptr;
    } else {
        if (actual == cabeza) {
            actual = cabeza->siguiente;
        }
        cabeza = cabeza->siguiente;
        cabeza->anterior = cola;
        cola->siguiente = cabeza;
    }

    delete borrar;
    --tamano;
    return true;
}

bool ListaDobleCircular::eliminarAlFinal() {
    if (estaVacia()) {
        return false;
    }
    if (cabeza == cola) {
        return eliminarAlInicio();
    }

    NodoDoble* borrar = cola;
    if (actual == cola) {
        actual = cabeza;
    }
    cola = cola->anterior;
    cola->siguiente = cabeza;
    cabeza->anterior = cola;
    delete borrar;
    --tamano;
    return true;
}

bool ListaDobleCircular::eliminarEnPosicion(int posicion) {
    if (posicion < 0 || posicion >= tamano) {
        return false;
    }
    if (posicion == 0) {
        return eliminarAlInicio();
    }
    if (posicion == tamano - 1) {
        return eliminarAlFinal();
    }

    NodoDoble* borrar = obtenerNodoEn(posicion);
    if (actual == borrar) {
        actual = borrar->siguiente;
    }
    borrar->anterior->siguiente = borrar->siguiente;
    borrar->siguiente->anterior = borrar->anterior;
    delete borrar;
    --tamano;
    return true;
}

const Cancion* ListaDobleCircular::siguienteCancion() {
    if (actual == nullptr) {
        return nullptr;
    }

    if (modoRepeticion == ModoRepeticion::REPETIR_TODAS) {
        actual = actual->siguiente;
    } else if (modoRepeticion == ModoRepeticion::SIN_REPETICION) {
        if (actual == cola) {
            return nullptr;
        }
        actual = actual->siguiente;
    }

    return &(actual->dato);
}

const Cancion* ListaDobleCircular::anteriorCancion() {
    if (actual == nullptr) {
        return nullptr;
    }
    actual = actual->anterior;
    return &(actual->dato);
}

const Cancion* ListaDobleCircular::obtenerCancionActual() const {
    if (actual == nullptr) {
        return nullptr;
    }
    return &(actual->dato);
}

void ListaDobleCircular::setModoRepeticion(ModoRepeticion nuevoModo) {
    modoRepeticion = nuevoModo;
}

ModoRepeticion ListaDobleCircular::getModoRepeticion() const {
    return modoRepeticion;
}

NodoDoble* ListaDobleCircular::obtenerNodoEn(int posicion) const {
    if (posicion < 0 || posicion >= tamano) {
        return nullptr;
    }

    NodoDoble* temp = cabeza;
    for (int i = 0; i < posicion; ++i) {
        temp = temp->siguiente;
    }
    return temp;
}

NodoDoble* ListaDobleCircular::getCabeza() const {
    return cabeza;
}

NodoDoble* ListaDobleCircular::getCola() const {
    return cola;
}

int ListaDobleCircular::calcularDuracionTotalSegundos() const {
    int total = 0;
    NodoDoble* temp = cabeza;
    for (int i = 0; i < tamano; ++i) {
        total += temp->dato.getDuracionSegundos();
        temp = temp->siguiente;
    }
    return total;
}

void ListaDobleCircular::mostrar() const {
    std::cout << "\nPLAYLIST: " << nombrePlaylist
              << " (" << tamano << " canciones)\n";
    if (estaVacia()) {
        std::cout << "[Playlist vacia]\n";
        return;
    }

    NodoDoble* temp = cabeza;
    for (int i = 0; i < tamano; ++i) {
        if (temp == actual) {
            std::cout << ">> [Reproduciendo]\n";
        }
        temp->dato.mostrar();
        temp = temp->siguiente;
    }
}

void ListaDobleCircular::limpiar() {
    if (estaVacia()) {
        return;
    }

    NodoDoble* temp = cabeza;
    for (int i = 0; i < tamano; ++i) {
        NodoDoble* siguiente = temp->siguiente;
        delete temp;
        temp = siguiente;
    }

    cabeza = cola = actual = nullptr;
    tamano = 0;
}

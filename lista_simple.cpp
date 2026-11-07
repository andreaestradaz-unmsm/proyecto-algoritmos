#include "lista_simple.h"
#include <iostream>
#include <fstream>

// Inicializa la lista vacia con punteros en nullptr
ListaSimple::ListaSimple() {
    cabeza = nullptr;
    cola = nullptr;
    tamano = 0;
}

// Destructor: libera todos los nodos al terminar
ListaSimple::~ListaSimple() {
    limpiar();
}

// Inserta un nuevo nodo al inicio de la lista (util para el historial)
void ListaSimple::agregarAlInicio(const Cancion& cancion) {
    NodoSimple* nuevo = new NodoSimple(cancion);

    if (cabeza == nullptr) {
        cabeza = nuevo;
        cola = nuevo;
    } else {
        nuevo->siguiente = cabeza;
        cabeza = nuevo;
    }
    tamano++;
}

// Inserta un nuevo nodo al final de la lista (util para la biblioteca)
void ListaSimple::agregarAlFinal(const Cancion& cancion) {
    NodoSimple* nuevo = new NodoSimple(cancion);

    if (cabeza == nullptr) {
        cabeza = nuevo;
        cola = nuevo;
    } else {
        cola->siguiente = nuevo;
        cola = nuevo;
    }
    tamano++;
}

// Busca un nodo por su ID, lo desenlaza y libera su memoria con delete
bool ListaSimple::eliminarPorId(int id) {
    if (cabeza == nullptr) {
        return false;
    }

    NodoSimple* actual = cabeza;
    NodoSimple* anterior = nullptr;

    // Recorremos los nodos buscando el ID
    while (actual != nullptr && actual->dato.getId() != id) {
        anterior = actual;
        actual = actual->siguiente;
    }

    // Si llegamos al final y no existe
    if (actual == nullptr) {
        return false;
    }

    // Caso 1: el nodo a borrar es la cabeza
    if (anterior == nullptr) {
        cabeza = actual->siguiente;
        if (cabeza == nullptr) {
            cola = nullptr;
        }
    }
    // Caso 2: el nodo esta en medio o al final
    else {
        anterior->siguiente = actual->siguiente;
        if (actual == cola) {
            cola = anterior;
        }
    }

    delete actual;
    tamano--;
    return true;
}

// Recorre los nodos desde la cabeza buscando una cancion por su ID
bool ListaSimple::buscarPorId(int id, Cancion& cancionSalida) const {
    NodoSimple* actual = cabeza;
    while (actual != nullptr) {
        if (actual->dato.getId() == id) {
            cancionSalida = actual->dato;
            return true;
        }
        actual = actual->siguiente;
    }
    return false;
}

// Avanza nodo por nodo hasta llegar a la posicion indicada
bool ListaSimple::obtenerEnPosicion(int indice, Cancion& cancionSalida) const {
    if (indice < 0 || indice >= tamano) {
        return false;
    }

    NodoSimple* actual = cabeza;
    for (int i = 0; i < indice; i++) {
        actual = actual->siguiente;
    }
    cancionSalida = actual->dato;
    return true;
}

// Recorre todos los nodos sumando la duracion en segundos de cada cancion
int ListaSimple::calcularDuracionTotalSegundos() const {
    int sumaSegundos = 0;
    NodoSimple* actual = cabeza;

    while (actual != nullptr) {
        sumaSegundos += actual->dato.getDuracionSegundos();
        actual = actual->siguiente;
    }
    return sumaSegundos;
}

// Recorre todos los nodos e imprime cada cancion
void ListaSimple::mostrar(const std::string& tituloListado) const {
    std::cout << "\n------------------------------------------------------------\n";
    std::cout << tituloListado << " (Total: " << tamano << " canciones)\n";
    std::cout << "------------------------------------------------------------\n";

    if (cabeza == nullptr) {
        std::cout << "(La lista esta vacia)\n";
        std::cout << "------------------------------------------------------------\n";
        return;
    }

    NodoSimple* actual = cabeza;
    while (actual != nullptr) {
        actual->dato.mostrar();
        actual = actual->siguiente;
    }

    int totalSeg = calcularDuracionTotalSegundos();
    int minutos = totalSeg / 60;
    int segundos = totalSeg % 60;

    std::cout << "------------------------------------------------------------\n";
    std::cout << "Duracion total de la lista: " << minutos << " min " << segundos << " seg\n";
    std::cout << "------------------------------------------------------------\n";
}

// Recorre la lista liberando nodo por nodo con delete
void ListaSimple::limpiar() {
    NodoSimple* actual = cabeza;
    while (actual != nullptr) {
        NodoSimple* siguienteNodo = actual->siguiente;
        delete actual;
        actual = siguienteNodo;
    }
    cabeza = nullptr;
    cola = nullptr;
    tamano = 0;
}

bool ListaSimple::estaVacia() const {
    return cabeza == nullptr;
}

int ListaSimple::getTamano() const {
    return tamano;
}

NodoSimple* ListaSimple::getCabeza() const {
    return cabeza;
}

// Recorre los nodos de la lista y escribe cada cancion en el archivo CSV
bool ListaSimple::guardarEnCSV(const std::string& rutaArchivo, char delimitador) const {
    std::ofstream archivo(rutaArchivo);
    if (!archivo.is_open()) {
        return false;
    }

    // Encabezado del archivo CSV
    archivo << "id" << delimitador
            << "titulo" << delimitador
            << "artista" << delimitador
            << "duracion_segundos" << delimitador
            << "genero\n";

    // Recorremos nodo por nodo y guardamos cada cancion
    NodoSimple* actual = cabeza;
    while (actual != nullptr) {
        archivo << actual->dato.aCSV(delimitador) << "\n";
        actual = actual->siguiente;
    }

    archivo.close();
    return true;
}

// Lee el archivo CSV linea por linea y crea un nodo al final por cada cancion
int ListaSimple::cargarDesdeCSV(const std::string& rutaArchivo, char delimitador) {
    std::ifstream archivo(rutaArchivo);
    if (!archivo.is_open()) {
        return -1;
    }

    limpiar();

    std::string linea;
    int cantidadCargadas = 0;

    while (std::getline(archivo, linea)) {
        if (linea == "") {
            continue;
        }

        Cancion nuevaCancion;
        if (Cancion::desdeCSV(linea, nuevaCancion, delimitador)) {
            agregarAlFinal(nuevaCancion);
            cantidadCargadas++;
        }
    }

    archivo.close();
    return cantidadCargadas;
}

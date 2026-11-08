#include "reproduccion.h"
#include <random>
#include <fstream>
#include <utility>

void GestorReproduccion::aplicarShuffleFisherYates(ListaDobleCircular& lista, unsigned int semilla) {
    int n = lista.getTamano();
    if (n <= 1) {
        return;
    }
    std::mt19937 generador(semilla);

    for (int i = n - 1; i >= 1; --i) {
        std::uniform_int_distribution<int> distribucion(0, i);
        int j = distribucion(generador);

        NodoDoble* nodoI = lista.obtenerNodoEn(i);
        NodoDoble* nodoJ = lista.obtenerNodoEn(j);

        std::swap(nodoI->dato, nodoJ->dato);
    }
}

bool GestorReproduccion::moverCancion(ListaDobleCircular& lista, int posOrigen, int posDestino) {
    int limite = lista.getTamano() - 1;
    if (posOrigen < 0 || posOrigen > limite || posDestino < 0 || posDestino > limite) {
        return false;
    }

    if (posOrigen == posDestino) {
        return true; 
    }

    NodoDoble* nodo = lista.obtenerNodoEn(posOrigen);
    Cancion cancionMovida = nodo->dato;

    lista.eliminarEnPosicion(posOrigen);
    lista.insertarEnPosicion(cancionMovida, posDestino);

    return true;
}

void GestorReproduccion::fusionarListas(ListaDobleCircular& listaPrincipal,
                                        ListaDobleCircular& listaSecundaria,
                                        bool vaciarSecundaria) {
    if (listaSecundaria.estaVacia()) {
        return;
    }

    NodoDoble* temp = listaSecundaria.getCabeza();
    for (int i = 0; i < listaSecundaria.getTamano(); ++i) {
        listaPrincipal.insertarAlFinal(temp->dato);
        temp = temp->siguiente;
    }

    if (vaciarSecundaria) {
        listaSecundaria.limpiar();
    }
}

void GestorReproduccion::registrarEnHistorial(const ListaDobleCircular& playlistActiva,
                                              ListaSimple& historial) {
    const Cancion* actual = playlistActiva.obtenerCancionActual();
    if (actual != nullptr) {
        historial.agregarAlInicio(*actual);
    }
}

bool GestorReproduccion::guardarPlaylistCSV(const ListaDobleCircular& lista,
                                            const std::string& rutaArchivo,
                                            char delimitador) {
    std::ofstream archivo(rutaArchivo);
    if (!archivo.is_open()) {
        return false;
    }

    archivo << "id;titulo;artista;duracion_segundos;genero\n";

    NodoDoble* temp = lista.getCabeza();
    for (int i = 0; i < lista.getTamano(); ++i) {
        archivo << temp->dato.aCSV(delimitador) << "\n";
        temp = temp->siguiente;
    }

    archivo.close();
    return true;
}

int GestorReproduccion::cargarPlaylistCSV(ListaDobleCircular& lista,
                                          const std::string& rutaArchivo,
                                          char delimitador) {
    std::ifstream archivo(rutaArchivo);
    if (!archivo.is_open()) {
        return -1;
    }

    lista.limpiar();

    std::string linea;
    int contador = 0;

    while (std::getline(archivo, linea)) {
        Cancion nueva;
        if (Cancion::desdeCSV(linea, nueva, delimitador)) {
            lista.insertarAlFinal(nueva);
            contador++;
        }
    }

    archivo.close();
    return contador;
}

#include "reproduccion.h"
#include <random>
#include <fstream>
#include <utility>

/**
 * ============================================================================
 * ARCHIVO DE TRABAJO DE: JUAN PABLO (reproduccion.cpp)
 * ============================================================================
 * Todas las funciones están vacías, solo tienen comentarios explicando qué
 * debes hacer y un 'return' temporal al final para que el proyecto compile.
 * Busca cada "// <--- PON TU CÓDIGO AQUÍ" y programa tu lógica.
 * ============================================================================
 */

void GestorReproduccion::aplicarShuffleFisherYates(ListaDobleCircular& lista, unsigned int semilla) {
    // QUÉ DEBES HACER (Algoritmo de Fisher-Yates):
    // 1. Obtener el tamaño: int n = lista.getTamano();
    //    Si n <= 1, no hay nada que mezclar (hacer return).
    // 2. Inicializar generador aleatorio con la semilla:
    //    std::mt19937 generador(semilla);
    // 3. Recorrer con un for desde i = n - 1 bajando hasta i = 1:
    //    - Generar un índice aleatorio j entre 0 e i:
    //      std::uniform_int_distribution<int> distribucion(0, i);
    //      int j = distribucion(generador);
    //    - Obtener los dos nodos usando el método de Jeick:
    //      NodoDoble* nodoI = lista.obtenerNodoEn(i);
    //      NodoDoble* nodoJ = lista.obtenerNodoEn(j);
    //    - Intercambiar sus canciones:
    //      std::swap(nodoI->dato, nodoJ->dato);

    // <--- PON TU CÓDIGO AQUÍ
}

bool GestorReproduccion::moverCancion(ListaDobleCircular& lista, int posOrigen, int posDestino) {
    // QUÉ DEBES HACER:
    // 1. Validar que 'posOrigen' y 'posDestino' estén dentro del rango [0, lista.getTamano() - 1].
    //    Si alguno es inválido, retornar false.
    // 2. Si posOrigen == posDestino, retornar true (no necesita moverse).
    // 3. Obtener el nodo en 'posOrigen':
    //    NodoDoble* nodo = lista.obtenerNodoEn(posOrigen);
    // 4. Guardar una copia de la canción:
    //    Cancion cancionMovida = nodo->dato;
    // 5. Eliminar el nodo de la posición original llamando a:
    //    lista.eliminarEnPosicion(posOrigen);
    // 6. Insertar la canción en la nueva posición llamando a:
    //    lista.insertarEnPosicion(cancionMovida, posDestino);
    // 7. Retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true cuando la canción se haya movido
}

void GestorReproduccion::fusionarListas(ListaDobleCircular& listaPrincipal,
                                        ListaDobleCircular& listaSecundaria,
                                        bool vaciarSecundaria) {
    // QUÉ DEBES HACER:
    // 1. Si 'listaSecundaria.estaVacia()' es true, hacer return.
    // 2. Recorrer los 'listaSecundaria.getTamano()' nodos de 'listaSecundaria'
    //    empezando desde 'NodoDoble* temp = listaSecundaria.getCabeza()':
    //    - En cada paso, agregar la canción al final de 'listaPrincipal':
    //      listaPrincipal.insertarAlFinal(temp->dato);
    //    - Avanzar 'temp = temp->siguiente;'
    // 3. Si 'vaciarSecundaria' es true, al terminar el bucle llamar a:
    //    listaSecundaria.limpiar();

    // <--- PON TU CÓDIGO AQUÍ
}

void GestorReproduccion::registrarEnHistorial(const ListaDobleCircular& playlistActiva,
                                              ListaSimple& historial) {
    // QUÉ DEBES HACER:
    // 1. Obtener la canción que se está reproduciendo en 'playlistActiva':
    //    const Cancion* actual = playlistActiva.obtenerCancionActual();
    // 2. Si 'actual != nullptr', guardarla al inicio del historial (usando ListaSimple de Andrea):
    //    historial.agregarAlInicio(*actual);

    // <--- PON TU CÓDIGO AQUÍ
}

bool GestorReproduccion::guardarPlaylistCSV(const ListaDobleCircular& lista,
                                            const std::string& rutaArchivo,
                                            char delimitador) {
    // QUÉ DEBES HACER:
    // 1. Abrir el archivo de salida: std::ofstream archivo(rutaArchivo);
    //    Si '!archivo.is_open()', retornar false.
    // 2. Escribir la primera línea de encabezado:
    //    archivo << "id;titulo;artista;duracion_segundos;genero\n";
    // 3. Recorrer los 'lista.getTamano()' nodos desde 'lista.getCabeza()':
    //    - Escribir cada canción usando el método de Andrea:
    //      archivo << temp->dato.aCSV(delimitador) << "\n";
    // 4. Cerrar el archivo y retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true si el archivo CSV se guardó bien
}

int GestorReproduccion::cargarPlaylistCSV(ListaDobleCircular& lista,
                                          const std::string& rutaArchivo,
                                          char delimitador) {
    // QUÉ DEBES HACER:
    // 1. Abrir el archivo de lectura: std::ifstream archivo(rutaArchivo);
    //    Si '!archivo.is_open()', retornar -1.
    // 2. Limpiar la playlist antes de cargar: lista.limpiar();
    // 3. Leer línea por línea con 'std::getline(archivo, linea)':
    //    - Convertir cada línea en objeto Cancion usando el método de Andrea:
    //      Cancion nueva;
    //      if (Cancion::desdeCSV(linea, nueva, delimitador)) {
    //          lista.insertarAlFinal(nueva);
    //          contador++;
    //      }
    // 4. Retornar la cantidad de canciones cargadas ('contador').

    // <--- PON TU CÓDIGO AQUÍ

    return 0; // Retorno temporal: devuelve cuántas canciones se cargaron desde el CSV
}

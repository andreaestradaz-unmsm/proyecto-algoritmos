#ifndef REPRODUCCION_H
#define REPRODUCCION_H

#include "lista_doble_circular.h"
#include "lista_simple.h"
#include <string>

/**
 * ============================================================================
 * PARTE DE JUAN PABLO — CABECERA (SOLO DECLARACIONES)
 * ============================================================================
 * IMPORTANTE PARA JUAN PABLO:
 * Este archivo (.h) es solo el índice con los nombres de las funciones.
 * NO escribas tu código aquí. Abre el archivo "reproduccion.cpp" y
 * escribe tu código donde dice: // <--- PON TU CÓDIGO AQUÍ
 * ============================================================================
 */

class GestorReproduccion {
public:
    // 1. Algoritmo de mezcla aleatoria (Shuffle de Fisher-Yates)
    static void aplicarShuffleFisherYates(ListaDobleCircular& lista, unsigned int semilla = 42);

    // 2. Mover una canción de una posición a otra dentro de la playlist
    static bool moverCancion(ListaDobleCircular& lista, int posOrigen, int posDestino);

    // 3. Fusionar dos listas de reproducción
    static void fusionarListas(ListaDobleCircular& listaPrincipal,
                               ListaDobleCircular& listaSecundaria,
                               bool vaciarSecundaria = false);

    // 4. Registrar canción actual en el Historial (ListaSimple de Andrea)
    static void registrarEnHistorial(const ListaDobleCircular& playlistActiva,
                                     ListaSimple& historial);

    // 5. Guardar y cargar una Playlist en archivo CSV
    static bool guardarPlaylistCSV(const ListaDobleCircular& lista,
                                   const std::string& rutaArchivo,
                                   char delimitador = ';');

    static int cargarPlaylistCSV(ListaDobleCircular& lista,
                                 const std::string& rutaArchivo,
                                 char delimitador = ';');
};

#endif // REPRODUCCION_H

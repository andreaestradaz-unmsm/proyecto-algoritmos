#ifndef UI_H
#define UI_H

#include "cancion.h"
#include "lista_simple.h"
#include "lista_doble_circular.h"
#include "reproduccion.h"
#include <string>

/**
 * ============================================================================
 * PARTE DE JEREMY — CABECERA (SOLO DECLARACIONES)
 * ============================================================================
 * IMPORTANTE PARA JEREMY:
 * Este archivo (.h) es solo el índice con los nombres de las funciones.
 * NO escribas tu código aquí. Abre el archivo "ui.cpp" y
 * escribe tu código donde dice: // <--- PON TU CÓDIGO AQUÍ
 * ============================================================================
 */

const int MAX_PLAYLISTS = 20;

class InterfazConsola {
private:
    ListaSimple biblioteca;                        // Biblioteca general (hecha por Andrea)
    ListaSimple historial;                         // Historial de reproducción (hecha por Andrea)
    ListaDobleCircular* playlists[MAX_PLAYLISTS];  // Arreglo de punteros a las playlists creadas
    int cantidadPlaylists;
    int indicePlaylistActiva;

public:
    InterfazConsola();
    ~InterfazConsola();

    // Menú Principal y Submenús
    void iniciar();
    void menuBiblioteca();
    void menuGestionPlaylists();
    void menuEditarPlaylistActiva();
    void menuReproductor();

    // Funciones de formato de duración y pantalla
    static std::string formatearDuracionTotal(int totalSegundos);
    void mostrarEncabezadoReproductor() const;
    static void limpiarPantalla();
    static void pausar();
};

#endif // UI_H

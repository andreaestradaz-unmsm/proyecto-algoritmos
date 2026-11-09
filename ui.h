#ifndef UI_H
#define UI_H

#include "cancion.h"
#include "lista_simple.h"
#include "lista_doble_circular.h"
#include "reproduccion.h"
#include <string>

/**
 * ============================================================================
 * PARTE DE JEREMY — CABECERA (interfaz de consola)
 * ============================================================================
 * La parte PUBLICA es la misma que se acordo con el equipo (no cambia).
 * Solo se agregaron declaraciones PRIVADAS auxiliares para no repetir codigo
 * dentro de los menus. El codigo esta en "ui.cpp".
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
    bool bibliotecaModificada;                     // true si hay cambios sin guardar en biblioteca.csv

    // --- Auxiliares internos (no forman parte de la interfaz acordada) ---
    bool hayPlaylistActiva() const;
    bool existeNombrePlaylist(const std::string& nombre, int indiceIgnorado = -1) const;
    void listarPlaylists() const;
    int  pedirIndicePlaylist(const std::string& mensaje) const;  // devuelve indice (desde 0) o -1
    int  crearPlaylist(const std::string& nombre);               // devuelve indice o -1 si no hay espacio
    void eliminarPlaylist(int indice);

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
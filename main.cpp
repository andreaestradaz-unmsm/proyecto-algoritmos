#include <iostream>
#include "cancion.h"
#include "lista_simple.h"
#include "lista_doble_circular.h"
#include "reproduccion.h"
#include "ui.h"

/**
 * ============================================================================
 * ARCHIVO PRINCIPAL: main.cpp
 * Responsable de integración UI: JEREMY
 * Base inicial de prueba (Biblioteca + CSV): ANDREA
 * ============================================================================
 */

int main() {
    std::cout << "========================================================\n";
    std::cout << "  UNMSM - Algoritmos y Estructuras de Datos (CC0401)    \n";
    std::cout << "  Proyecto 2: Reproductor de Musica con Playlists       \n";
    std::cout << "========================================================\n";

    // ------------------------------------------------------------------------
    // PRUEBA FUNCIONAL DE LA PARTE DE ANDREA (TAD Cancion + ListaSimple + CSV)
    // ------------------------------------------------------------------------
    ListaSimple biblioteca;
    const std::string archivoCSV = "biblioteca.csv";

    // Intentamos cargar desde archivo CSV; si no existe, creamos datos semilla
    int cargadas = biblioteca.cargarDesdeCSV(archivoCSV);
    if (cargadas <= 0) {
        std::cout << "\n[Info] Generando biblioteca inicial de prueba...\n";
        biblioteca.agregarAlFinal(Cancion(1, "Bohemian Rhapsody", "Queen", 354, "Rock"));
        biblioteca.agregarAlFinal(Cancion(2, "De Musica Ligera", "Soda Stereo", 212, "Rock Latino"));
        biblioteca.agregarAlFinal(Cancion(3, "Billie Jean", "Michael Jackson", 294, "Pop"));
        biblioteca.agregarAlFinal(Cancion(4, "Tren al Sur", "Los Prisioneros", 336, "New Wave"));
        biblioteca.agregarAlFinal(Cancion(5, "Clocks", "Coldplay", 307, "Alternative"));

        if (biblioteca.guardarEnCSV(archivoCSV)) {
            std::cout << "[OK] Biblioteca guardada exitosamente en '" << archivoCSV << "'.\n";
        }
    } else {
        std::cout << "\n[OK] Se cargaron " << cargadas << " canciones desde '" << archivoCSV << "'.\n";
    }

    biblioteca.mostrar("BIBLIOTECA GENERAL DE CANCIONES");

    // ------------------------------------------------------------------------
    // TODO (JEREMY): Descomentar cuando ui.cpp, lista_doble_circular.cpp y
    //                reproduccion.cpp estén implementados por el equipo:
    // ------------------------------------------------------------------------
    /*
    InterfazConsola app;
    app.iniciar();
    */

    return 0;
}


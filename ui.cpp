#include "ui.h"
#include <iostream>
#include <iomanip>
#include <sstream>

/**
 * ============================================================================
 * ARCHIVO DE TRABAJO DE: JEREMY (ui.cpp)
 * ============================================================================
 * Todas las funciones están vacías, solo tienen comentarios explicando qué
 * debes hacer y un 'return' temporal al final para que el proyecto compile.
 * Busca cada "// <--- PON TU CÓDIGO AQUÍ" y programa tu lógica.
 * ============================================================================
 */

InterfazConsola::InterfazConsola() {
    // QUÉ DEBES HACER:
    // 1. Inicializar 'cantidadPlaylists = 0' e 'indicePlaylistActiva = -1'.
    // 2. Poner todas las casillas del arreglo 'playlists[i] = nullptr' con un for.
    // 3. Cargar la biblioteca inicial desde el CSV usando el método de Andrea:
    //    biblioteca.cargarDesdeCSV("biblioteca.csv");

    // <--- PON TU CÓDIGO AQUÍ
}

InterfazConsola::~InterfazConsola() {
    // QUÉ DEBES HACER:
    // 1. Recorrer con un for desde i = 0 hasta cantidadPlaylists - 1
    //    y hacer 'delete playlists[i];' para liberar la memoria de cada playlist.

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::iniciar() {
    // QUÉ DEBES HACER:
    // 1. Crear un bucle 'do { ... } while (opcion != 0);' que muestre el Menú Principal:
    //    [1] Biblioteca de Canciones  -> llama a menuBiblioteca()
    //    [2] Gestionar Playlists      -> llama a menuGestionPlaylists()
    //    [3] Editar Playlist Activa   -> llama a menuEditarPlaylistActiva()
    //    [4] Reproductor e Historial  -> llama a menuReproductor()
    //    [0] Salir

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::menuBiblioteca() {
    // QUÉ DEBES HACER:
    // Mostrar opciones para manejar 'biblioteca' (usando los métodos ya hechos por Andrea):
    // - Ver todas las canciones:   biblioteca.mostrar("BIBLIOTECA GENERAL");
    // - Agregar nueva canción:     pedir id, titulo, artista, duracion, genero y llamar a:
    //                              biblioteca.agregarAlFinal(Cancion(id, titulo, artista, duracion, genero));
    // - Eliminar canción por ID:   biblioteca.eliminarPorId(id);
    // - Guardar cambios en CSV:    biblioteca.guardarEnCSV("biblioteca.csv");

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::menuGestionPlaylists() {
    // QUÉ DEBES HACER:
    // Mostrar opciones para administrar las listas de reproducción:
    // - Crear playlist:     playlists[cantidadPlaylists] = new ListaDobleCircular(nombre);
    //                       indicePlaylistActiva = cantidadPlaylists; cantidadPlaylists++;
    // - Renombrar playlist: playlists[i]->renombrar(nuevoNombre);
    // - Eliminar playlist:  delete playlists[i]; y recorrer los elementos restantes del arreglo.
    // - Elegir playlist activa: cambiar 'indicePlaylistActiva'.
    // - Fusionar 2 listas:  llamar a GestorReproduccion::fusionarListas(*playlists[a], *playlists[b]);
    // - Ver duración total: usar formatearDuracionTotal(playlists[i]->calcularDuracionTotalSegundos());

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::menuEditarPlaylistActiva() {
    // QUÉ DEBES HACER:
    // 1. Verificar que exista una playlist activa (indicePlaylistActiva != -1).
    // 2. Mostrar opciones sobre 'playlists[indicePlaylistActiva]':
    //    - Agregar canción desde la biblioteca (al inicio, al final o en posición):
    //      Cancion c;
    //      if (biblioteca.buscarPorId(idBuscado, c)) {
    //          playlists[indicePlaylistActiva]->insertarAlFinal(c);
    //      }
    //    - Quitar canción (al inicio, al final o en posición).
    //    - Mover una canción de posición:
    //      GestorReproduccion::moverCancion(*playlists[indicePlaylistActiva], posOrigen, posDestino);
    //    - Activar Modo Aleatorio (Shuffle Fisher-Yates):
    //      GestorReproduccion::aplicarShuffleFisherYates(*playlists[indicePlaylistActiva]);

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::menuReproductor() {
    // QUÉ DEBES HACER:
    // 1. Mostrar la canción actual con 'playlists[indicePlaylistActiva]->obtenerCancionActual()'.
    // 2. Opciones de control:
    //    - Siguiente canción:
    //      playlists[indicePlaylistActiva]->siguienteCancion();
    //      GestorReproduccion::registrarEnHistorial(*playlists[indicePlaylistActiva], historial);
    //    - Canción anterior:
    //      playlists[indicePlaylistActiva]->anteriorCancion();
    //      GestorReproduccion::registrarEnHistorial(*playlists[indicePlaylistActiva], historial);
    //    - Cambiar modo de repetición (SIN_REPETICION, REPETIR_UNA, REPETIR_TODAS):
    //      playlists[indicePlaylistActiva]->setModoRepeticion(modo);
    //    - Mostrar Historial de reproducción:
    //      historial.mostrar("HISTORIAL DE CANCIONES REPRODUCIDAS");

    // <--- PON TU CÓDIGO AQUÍ
}

std::string InterfazConsola::formatearDuracionTotal(int totalSegundos) {
    // QUÉ DEBES HACER:
    // 1. Calcular:
    //    int horas = totalSegundos / 3600;
    //    int minutos = (totalSegundos % 3600) / 60;
    //    int segundos = totalSegundos % 60;
    // 2. Formatear y retornar como texto "HH:MM:SS" (ej. "01:25:03").

    // <--- PON TU CÓDIGO AQUÍ

    return "00:00:00"; // Retorno temporal: devuelve el string con la duración formateada
}

void InterfazConsola::mostrarEncabezadoReproductor() const {
    // QUÉ DEBES HACER:
    // Imprimir un recuadro en consola mostrando qué playlist está activa,
    // qué canción está sonando actualmente y su duración.

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::limpiarPantalla() {
    // QUÉ DEBES HACER:
    // Limpiar la consola (por ejemplo: system("cls") en Windows o system("clear") en Linux).

    // <--- PON TU CÓDIGO AQUÍ
}

void InterfazConsola::pausar() {
    // QUÉ DEBES HACER:
    // Esperar a que el usuario presione Enter para continuar.

    // <--- PON TU CÓDIGO AQUÍ
}

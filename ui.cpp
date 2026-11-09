#include "ui.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <cstdlib>
#include <cctype>
#include <ctime>
#include <exception>

/**
 * ============================================================================
 * ARCHIVO DE TRABAJO DE: JEREMY (ui.cpp)
 * Interfaz de consola del reproductor: menus, entrada segura de datos y
 * formato de duraciones.
 *
 * Nota: los textos que se imprimen no llevan tildes ni caracteres especiales
 * a proposito, para que se vean bien en cualquier consola de Windows.
 * Las posiciones que ve el usuario empiezan en 1; internamente las listas
 * de Jeick usan posiciones desde 0, por eso se resta 1 al llamarlas.
 * ============================================================================
 */

// ============================================================================
// FUNCIONES AUXILIARES (solo visibles dentro de este archivo)
// ============================================================================
namespace {

const char* const ARCHIVO_BIBLIOTECA = "biblioteca.csv";

// ---------- Lectura segura de datos ----------
// Todo se lee con getline y se convierte a mano: asi nunca se "traba" la
// consola si el usuario escribe letras donde va un numero.

std::string recortar(const std::string& texto) {
    size_t inicio = texto.find_first_not_of(" \t\r\n");
    if (inicio == std::string::npos) {
        return "";
    }
    size_t fin = texto.find_last_not_of(" \t\r\n");
    return texto.substr(inicio, fin - inicio + 1);
}

// Devuelve false si ya no hay mas entrada (Ctrl+Z / Ctrl+D o fin de archivo).
bool leerLinea(const std::string& mensaje, std::string& salida) {
    std::cout << mensaje << std::flush;
    if (!std::getline(std::cin, salida)) {
        return false;
    }
    salida = recortar(salida);
    return true;
}

// Acepta solo digitos (entero >= 0, maximo 9 digitos para evitar desbordes).
bool parsearEntero(const std::string& texto, int& valor) {
    if (texto.empty() || texto.size() > 9) {
        return false;
    }
    for (size_t i = 0; i < texto.size(); ++i) {
        if (texto[i] < '0' || texto[i] > '9') {
            return false;
        }
    }
    valor = std::stoi(texto);
    return true;
}

// Repite la pregunta hasta que el numero este entre minimo y maximo.
// Devuelve false solo si se acabo la entrada.
bool leerEnteroEnRango(const std::string& mensaje, int minimo, int maximo, int& valor) {
    std::string linea;
    while (true) {
        if (!leerLinea(mensaje, linea)) {
            return false;
        }
        if (parsearEntero(linea, valor) && valor >= minimo && valor <= maximo) {
            return true;
        }
        std::cout << "  Valor no valido. Escribe un numero entre "
                  << minimo << " y " << maximo << ".\n";
    }
}

// Lee un texto. Si es obligatorio y se deja vacio, se interpreta como "cancelar".
// Se rechaza el caracter ';' porque es el separador de columnas del CSV.
bool leerTexto(const std::string& mensaje, std::string& salida, bool obligatorio) {
    while (true) {
        if (!leerLinea(mensaje, salida)) {
            return false;
        }
        if (salida.empty()) {
            return !obligatorio;
        }
        if (salida.find(';') != std::string::npos) {
            std::cout << "  No uses el caracter ';' (se usa para separar columnas del CSV).\n";
            continue;
        }
        return true;
    }
}

// Duracion en segundos ("225") o en formato "m:ss" ("3:45"). Vacio = cancelar.
bool leerDuracion(const std::string& mensaje, int& segundos) {
    std::string linea;
    while (true) {
        if (!leerLinea(mensaje, linea) || linea.empty()) {
            return false;
        }
        size_t p = linea.find(':');
        bool valido = false;
        if (p == std::string::npos) {
            valido = parsearEntero(linea, segundos);
        } else {
            int minutos = 0;
            int seg = 0;
            if (parsearEntero(linea.substr(0, p), minutos) &&
                parsearEntero(linea.substr(p + 1), seg) && seg < 60) {
                segundos = minutos * 60 + seg;
                valido = true;
            }
        }
        if (valido && segundos > 0) {
            return true;
        }
        std::cout << "  Duracion no valida. Usa segundos (ej. 225) o m:ss (ej. 3:45).\n";
    }
}

// Pregunta s/n. Si se acaba la entrada responde "no".
bool confirmar(const std::string& mensaje) {
    std::string respuesta;
    while (true) {
        if (!leerLinea(mensaje + " (s/n): ", respuesta)) {
            return false;
        }
        for (size_t i = 0; i < respuesta.size(); ++i) {
            respuesta[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(respuesta[i])));
        }
        if (respuesta == "s" || respuesta == "si") {
            return true;
        }
        if (respuesta == "n" || respuesta == "no") {
            return false;
        }
        std::cout << "  Responde con s o n.\n";
    }
}

// Opcion de un menu: -1 si lo escrito no es un numero; 0 si se acabo la entrada
// (asi todos los menus se cierran solos y nunca hay un bucle infinito).
int leerOpcion() {
    std::string linea;
    if (!leerLinea("\n  Elige una opcion: ", linea)) {
        return 0;
    }
    int opcion = 0;
    if (!parsearEntero(linea, opcion)) {
        return -1;
    }
    return opcion;
}

// ---------- Presentacion ----------

void imprimirTitulo(const std::string& texto) {
    std::cout << "\n--------------------------------------------------------------\n"
              << "  " << texto << "\n"
              << "--------------------------------------------------------------\n";
}

std::string modoATexto(ModoRepeticion modo) {
    switch (modo) {
        case ModoRepeticion::SIN_REPETICION: return "Sin repeticion";
        case ModoRepeticion::REPETIR_UNA:    return "Repetir una";
        case ModoRepeticion::REPETIR_TODAS:  return "Repetir todas";
    }
    return "Desconocido";
}

void anunciarCancion(const std::string& prefijo, const Cancion* cancion) {
    if (cancion == nullptr) {
        return;
    }
    std::cout << "\n  " << prefijo << ": " << cancion->getTitulo() << " - " << cancion->getArtista()
              << " (" << cancion->obtenerDuracionFormateada() << ")\n";
}

// Muestra la playlist con numeros de posicion (la de Jeick no los muestra) y
// marca con '>' la cancion que esta sonando.
void mostrarPlaylistNumerada(const ListaDobleCircular& playlist) {
    imprimirTitulo("PLAYLIST: " + playlist.getNombre() + " (" +
                   std::to_string(playlist.getTamano()) + " canciones)");
    if (playlist.estaVacia()) {
        std::cout << "  (La playlist esta vacia)\n";
        return;
    }
    const Cancion* sonando = playlist.obtenerCancionActual();
    NodoDoble* nodo = playlist.getCabeza();
    for (int i = 0; i < playlist.getTamano(); ++i) {
        std::cout << (&(nodo->dato) == sonando ? " > " : "   ")
                  << std::setw(2) << (i + 1) << ". ";
        nodo->dato.mostrar();
        nodo = nodo->siguiente;
    }
    std::cout << "--------------------------------------------------------------\n"
              << "  Duracion total: "
              << InterfazConsola::formatearDuracionTotal(playlist.calcularDuracionTotalSegundos())
              << "   ( > = cancion actual )\n";
}

// ---------- Biblioteca ----------

int siguienteIdLibre(const ListaSimple& biblioteca) {
    int maximo = 0;
    for (NodoSimple* nodo = biblioteca.getCabeza(); nodo != nullptr; nodo = nodo->siguiente) {
        if (nodo->dato.getId() > maximo) {
            maximo = nodo->dato.getId();
        }
    }
    return maximo + 1;
}

// Devuelve true si se agrego una cancion.
bool agregarCancionABiblioteca(ListaSimple& biblioteca) {
    imprimirTitulo("AGREGAR CANCION A LA BIBLIOTECA");
    std::cout << "  (En cualquier dato obligatorio, deja vacio y Enter para cancelar)\n\n";

    int id = 0;
    Cancion existente;
    while (true) {
        std::string pregunta = "  ID numerico (sugerido: " + std::to_string(siguienteIdLibre(biblioteca)) +
                               ", 0 = cancelar): ";
        if (!leerEnteroEnRango(pregunta, 0, 999999, id) || id == 0) {
            std::cout << "  Operacion cancelada.\n";
            return false;
        }
        if (biblioteca.buscarPorId(id, existente)) {
            std::cout << "  Ese ID ya esta usado por: ";
            existente.mostrar();
            continue;
        }
        break;
    }

    std::string titulo;
    std::string artista;
    std::string genero;
    int duracion = 0;
    if (!leerTexto("  Titulo: ", titulo, true) ||
        !leerTexto("  Artista: ", artista, true) ||
        !leerDuracion("  Duracion (segundos o m:ss): ", duracion) ||
        !leerTexto("  Genero (Enter = Sin genero): ", genero, false)) {
        std::cout << "  Operacion cancelada.\n";
        return false;
    }
    if (genero.empty()) {
        genero = "Sin genero";
    }

    Cancion nueva(id, titulo, artista, duracion, genero);
    biblioteca.agregarAlFinal(nueva);
    std::cout << "\n  [OK] Cancion agregada: ";
    nueva.mostrar();
    return true;
}

// Devuelve true si se elimino una cancion.
bool eliminarCancionDeBiblioteca(ListaSimple& biblioteca) {
    imprimirTitulo("ELIMINAR CANCION DE LA BIBLIOTECA");
    if (biblioteca.estaVacia()) {
        std::cout << "  La biblioteca esta vacia.\n";
        return false;
    }
    biblioteca.mostrar("BIBLIOTECA GENERAL");

    int id = 0;
    if (!leerEnteroEnRango("\n  ID a eliminar (0 = cancelar): ", 0, 999999, id) || id == 0) {
        std::cout << "  Operacion cancelada.\n";
        return false;
    }
    Cancion cancion;
    if (!biblioteca.buscarPorId(id, cancion)) {
        std::cout << "  No existe ninguna cancion con ID " << id << ".\n";
        return false;
    }
    std::cout << "  Se eliminara: ";
    cancion.mostrar();
    if (!confirmar("  Confirmas")) {
        std::cout << "  Operacion cancelada.\n";
        return false;
    }
    biblioteca.eliminarPorId(id);
    std::cout << "  [OK] Cancion eliminada de la biblioteca.\n"
              << "  (Las playlists que ya la tenian conservan su copia.)\n";
    return true;
}

// Muestra la biblioteca y pide el ID de una cancion existente.
bool pedirCancionDeBiblioteca(const ListaSimple& biblioteca, Cancion& salida) {
    if (biblioteca.estaVacia()) {
        std::cout << "  La biblioteca esta vacia. Agrega canciones primero (menu Biblioteca).\n";
        return false;
    }
    biblioteca.mostrar("BIBLIOTECA GENERAL");
    while (true) {
        int id = 0;
        if (!leerEnteroEnRango("\n  ID de la cancion (0 = cancelar): ", 0, 999999, id) || id == 0) {
            return false;
        }
        if (biblioteca.buscarPorId(id, salida)) {
            return true;
        }
        std::cout << "  No existe ninguna cancion con ID " << id << ".\n";
    }
}

// ---------- Edicion de una playlist ----------

// modo: 0 = al inicio, 1 = al final, 2 = en una posicion.
void agregarCancionAPlaylist(const ListaSimple& biblioteca, ListaDobleCircular& playlist, int modo) {
    imprimirTitulo("AGREGAR CANCION A '" + playlist.getNombre() + "'");
    Cancion cancion;
    if (!pedirCancionDeBiblioteca(biblioteca, cancion)) {
        std::cout << "  Operacion cancelada.\n";
        return;
    }

    if (modo == 0) {
        playlist.insertarAlInicio(cancion);
        std::cout << "\n  [OK] Agregada al inicio.\n";
    } else if (modo == 1) {
        playlist.insertarAlFinal(cancion);
        std::cout << "\n  [OK] Agregada al final.\n";
    } else {
        mostrarPlaylistNumerada(playlist);
        int tamano = playlist.getTamano();
        int posicion = 0;
        std::string pregunta = "\n  Posicion donde quedara (1 a " + std::to_string(tamano + 1) +
                               ", 0 = cancelar): ";
        if (!leerEnteroEnRango(pregunta, 0, tamano + 1, posicion) || posicion == 0) {
            std::cout << "  Operacion cancelada.\n";
            return;
        }
        if (!playlist.insertarEnPosicion(cancion, posicion - 1)) {
            std::cout << "  [ERROR] No se pudo insertar en esa posicion.\n";
            return;
        }
        std::cout << "\n  [OK] Agregada en la posicion " << posicion << ".\n";
    }
    anunciarCancion("Cancion", &cancion);
}

// modo: 0 = la primera, 1 = la ultima, 2 = de una posicion.
void quitarCancionDePlaylist(ListaDobleCircular& playlist, int modo) {
    imprimirTitulo("QUITAR CANCION DE '" + playlist.getNombre() + "'");
    if (playlist.estaVacia()) {
        std::cout << "  La playlist esta vacia.\n";
        return;
    }

    int tamano = playlist.getTamano();
    int posicion = 1;
    if (modo == 1) {
        posicion = tamano;
    } else if (modo == 2) {
        mostrarPlaylistNumerada(playlist);
        std::string pregunta = "\n  Posicion a quitar (1 a " + std::to_string(tamano) + ", 0 = cancelar): ";
        if (!leerEnteroEnRango(pregunta, 0, tamano, posicion) || posicion == 0) {
            std::cout << "  Operacion cancelada.\n";
            return;
        }
    }

    Cancion quitada = playlist.obtenerNodoEn(posicion - 1)->dato;
    bool ok = false;
    if (modo == 0) {
        ok = playlist.eliminarAlInicio();
    } else if (modo == 1) {
        ok = playlist.eliminarAlFinal();
    } else {
        ok = playlist.eliminarEnPosicion(posicion - 1);
    }

    if (ok) {
        std::cout << "\n  [OK] Se quito de la playlist.\n";
        anunciarCancion("Cancion", &quitada);
    } else {
        std::cout << "  [ERROR] No se pudo quitar la cancion.\n";
    }
}

void moverCancionEnPlaylist(ListaDobleCircular& playlist) {
    imprimirTitulo("MOVER CANCION EN '" + playlist.getNombre() + "'");
    if (playlist.getTamano() < 2) {
        std::cout << "  Se necesitan al menos 2 canciones para mover una.\n";
        return;
    }
    mostrarPlaylistNumerada(playlist);

    int tamano = playlist.getTamano();
    int origen = 0;
    int destino = 0;
    std::string rango = "(1 a " + std::to_string(tamano) + ", 0 = cancelar)";
    if (!leerEnteroEnRango("\n  Posicion de la cancion a mover " + rango + ": ", 0, tamano, origen) || origen == 0 ||
        !leerEnteroEnRango("  Nueva posicion " + rango + ": ", 0, tamano, destino) || destino == 0) {
        std::cout << "  Operacion cancelada.\n";
        return;
    }
    if (origen == destino) {
        std::cout << "  La cancion ya esta en esa posicion. No hay cambios.\n";
        return;
    }
    if (GestorReproduccion::moverCancion(playlist, origen - 1, destino - 1)) {
        std::cout << "\n  [OK] Cancion movida de la posicion " << origen << " a la " << destino << ".\n";
        mostrarPlaylistNumerada(playlist);
    } else {
        std::cout << "  [ERROR] No se pudo mover la cancion.\n";
    }
}

// ---------- Reproductor ----------

void cambiarModoRepeticion(ListaDobleCircular& playlist) {
    imprimirTitulo("MODO DE REPETICION");
    std::cout << "  Modo actual: " << modoATexto(playlist.getModoRepeticion()) << "\n\n"
              << "  [1] Sin repeticion  (al llegar a la ultima cancion, se detiene)\n"
              << "  [2] Repetir una     (la cancion actual se repite)\n"
              << "  [3] Repetir todas   (al llegar a la ultima, vuelve a la primera)\n"
              << "  [0] Cancelar\n";
    int opcion = 0;
    if (!leerEnteroEnRango("\n  Elige el modo: ", 0, 3, opcion) || opcion == 0) {
        std::cout << "  Sin cambios.\n";
        return;
    }
    ModoRepeticion modo = ModoRepeticion::SIN_REPETICION;
    if (opcion == 2) {
        modo = ModoRepeticion::REPETIR_UNA;
    } else if (opcion == 3) {
        modo = ModoRepeticion::REPETIR_TODAS;
    }
    playlist.setModoRepeticion(modo);
    std::cout << "  [OK] Modo cambiado a: " << modoATexto(modo) << "\n";
}

// ---------- Archivos de playlist ----------

std::string nombreArchivoSugerido(const std::string& nombrePlaylist) {
    std::string base;
    for (size_t i = 0; i < nombrePlaylist.size(); ++i) {
        unsigned char c = static_cast<unsigned char>(nombrePlaylist[i]);
        base += (std::isalnum(c) ? static_cast<char>(c) : '_');
    }
    if (base.empty()) {
        base = "playlist";
    }
    return "playlist_" + base + ".csv";
}

bool pedirNombreArchivo(const std::string& sugerido, std::string& ruta) {
    std::string linea;
    if (!leerLinea("  Archivo CSV (Enter = " + sugerido + ", 0 = cancelar): ", linea) || linea == "0") {
        return false;
    }
    ruta = linea.empty() ? sugerido : linea;
    if (ruta.size() < 4 || ruta.substr(ruta.size() - 4) != ".csv") {
        ruta += ".csv";
    }
    return true;
}

} // fin del espacio de nombres anonimo

// ============================================================================
// CLASE InterfazConsola
// ============================================================================

InterfazConsola::InterfazConsola() {
    cantidadPlaylists = 0;
    indicePlaylistActiva = -1;
    bibliotecaModificada = false;
    for (int i = 0; i < MAX_PLAYLISTS; ++i) {
        playlists[i] = nullptr;
    }

    // Si el CSV tiene un dato corrupto, el parser de Andrea puede lanzar una
    // excepcion: la atrapamos para que el programa no se cierre de golpe.
    try {
        biblioteca.cargarDesdeCSV(ARCHIVO_BIBLIOTECA);
    } catch (const std::exception&) {
        std::cout << "[Aviso] biblioteca.csv tiene datos invalidos; se cargo solo una parte.\n";
    }
}

InterfazConsola::~InterfazConsola() {
    for (int i = 0; i < cantidadPlaylists; ++i) {
        delete playlists[i];
        playlists[i] = nullptr;
    }
}

// ----------------------------------------------------------------------------
// Auxiliares privados
// ----------------------------------------------------------------------------

bool InterfazConsola::hayPlaylistActiva() const {
    return indicePlaylistActiva >= 0 && indicePlaylistActiva < cantidadPlaylists &&
           playlists[indicePlaylistActiva] != nullptr;
}

bool InterfazConsola::existeNombrePlaylist(const std::string& nombre, int indiceIgnorado) const {
    for (int i = 0; i < cantidadPlaylists; ++i) {
        if (i != indiceIgnorado && playlists[i]->getNombre() == nombre) {
            return true;
        }
    }
    return false;
}

void InterfazConsola::listarPlaylists() const {
    if (cantidadPlaylists == 0) {
        std::cout << "  (No hay playlists creadas)\n";
        return;
    }
    for (int i = 0; i < cantidadPlaylists; ++i) {
        const ListaDobleCircular* p = playlists[i];
        std::cout << (i == indicePlaylistActiva ? "  * " : "    ")
                  << "[" << (i + 1) << "] " << p->getNombre()
                  << " - " << p->getTamano() << " canciones - "
                  << formatearDuracionTotal(p->calcularDuracionTotalSegundos()) << "\n";
    }
    std::cout << "  (* = playlist activa)\n";
}

int InterfazConsola::pedirIndicePlaylist(const std::string& mensaje) const {
    if (cantidadPlaylists == 0) {
        std::cout << "  No hay playlists creadas. Crea una primero.\n";
        return -1;
    }
    listarPlaylists();
    int numero = 0;
    if (!leerEnteroEnRango("\n  " + mensaje + " (0 = cancelar): ", 0, cantidadPlaylists, numero) || numero == 0) {
        std::cout << "  Operacion cancelada.\n";
        return -1;
    }
    return numero - 1;
}

int InterfazConsola::crearPlaylist(const std::string& nombre) {
    if (cantidadPlaylists >= MAX_PLAYLISTS) {
        return -1;
    }
    playlists[cantidadPlaylists] = new ListaDobleCircular(nombre);
    indicePlaylistActiva = cantidadPlaylists;   // la nueva queda como activa
    cantidadPlaylists++;
    return indicePlaylistActiva;
}

void InterfazConsola::eliminarPlaylist(int indice) {
    if (indice < 0 || indice >= cantidadPlaylists) {
        return;
    }
    delete playlists[indice];
    // Recorremos los elementos restantes una casilla a la izquierda
    for (int i = indice; i < cantidadPlaylists - 1; ++i) {
        playlists[i] = playlists[i + 1];
    }
    playlists[cantidadPlaylists - 1] = nullptr;
    cantidadPlaylists--;

    // Corregimos cual es la playlist activa
    if (cantidadPlaylists == 0) {
        indicePlaylistActiva = -1;
    } else if (indice == indicePlaylistActiva) {
        indicePlaylistActiva = 0;
    } else if (indice < indicePlaylistActiva) {
        indicePlaylistActiva--;
    }
}

// ----------------------------------------------------------------------------
// Menu principal
// ----------------------------------------------------------------------------

void InterfazConsola::iniciar() {
    int opcion = -1;
    do {
        limpiarPantalla();
        std::cout << "\n  REPRODUCTOR DE MUSICA - MENU PRINCIPAL\n";
        mostrarEncabezadoReproductor();
        std::cout << "  Biblioteca: " << biblioteca.getTamano() << " canciones  |  Playlists: "
                  << cantidadPlaylists << "/" << MAX_PLAYLISTS << "\n\n"
                  << "  [1] Biblioteca de Canciones\n"
                  << "  [2] Gestionar Playlists\n"
                  << "  [3] Editar Playlist Activa\n"
                  << "  [4] Reproductor e Historial\n"
                  << "  [0] Salir\n";

        opcion = leerOpcion();
        switch (opcion) {
            case 1: menuBiblioteca(); break;
            case 2: menuGestionPlaylists(); break;
            case 3: menuEditarPlaylistActiva(); break;
            case 4: menuReproductor(); break;
            case 0: break;
            default:
                std::cout << "\n  Opcion no valida.\n";
                pausar();
                break;
        }
    } while (opcion != 0);

    if (bibliotecaModificada &&
        confirmar("\n  Hay cambios sin guardar en la biblioteca. Guardarlos en biblioteca.csv")) {
        if (biblioteca.guardarEnCSV(ARCHIVO_BIBLIOTECA)) {
            bibliotecaModificada = false;
            std::cout << "  [OK] Biblioteca guardada.\n";
        } else {
            std::cout << "  [ERROR] No se pudo escribir biblioteca.csv.\n";
        }
    }
    std::cout << "\n  Hasta luego!\n";
}

// ----------------------------------------------------------------------------
// [1] Biblioteca
// ----------------------------------------------------------------------------

void InterfazConsola::menuBiblioteca() {
    int opcion = -1;
    do {
        limpiarPantalla();
        imprimirTitulo("BIBLIOTECA DE CANCIONES (" + std::to_string(biblioteca.getTamano()) + " canciones)");
        if (bibliotecaModificada) {
            std::cout << "  * Hay cambios sin guardar en biblioteca.csv\n";
        }
        std::cout << "\n  [1] Ver todas las canciones\n"
                  << "  [2] Agregar una cancion\n"
                  << "  [3] Eliminar una cancion por ID\n"
                  << "  [4] Guardar cambios en biblioteca.csv\n"
                  << "  [0] Volver al menu principal\n";

        opcion = leerOpcion();
        switch (opcion) {
            case 1:
                biblioteca.mostrar("BIBLIOTECA GENERAL");
                pausar();
                break;
            case 2:
                if (agregarCancionABiblioteca(biblioteca)) {
                    bibliotecaModificada = true;
                }
                pausar();
                break;
            case 3:
                if (eliminarCancionDeBiblioteca(biblioteca)) {
                    bibliotecaModificada = true;
                }
                pausar();
                break;
            case 4:
                if (biblioteca.guardarEnCSV(ARCHIVO_BIBLIOTECA)) {
                    bibliotecaModificada = false;
                    std::cout << "\n  [OK] Biblioteca guardada en '" << ARCHIVO_BIBLIOTECA << "'.\n";
                } else {
                    std::cout << "\n  [ERROR] No se pudo escribir '" << ARCHIVO_BIBLIOTECA << "'.\n";
                }
                pausar();
                break;
            case 0: break;
            default:
                std::cout << "\n  Opcion no valida.\n";
                pausar();
                break;
        }
    } while (opcion != 0);
}

// ----------------------------------------------------------------------------
// [2] Gestion de playlists
// ----------------------------------------------------------------------------

void InterfazConsola::menuGestionPlaylists() {
    int opcion = -1;
    do {
        limpiarPantalla();
        imprimirTitulo("GESTIONAR PLAYLISTS");
        listarPlaylists();
        std::cout << "\n  [1] Crear playlist\n"
                  << "  [2] Renombrar playlist\n"
                  << "  [3] Eliminar playlist\n"
                  << "  [4] Elegir playlist activa\n"
                  << "  [5] Fusionar dos playlists\n"
                  << "  [6] Ver contenido y duracion total de una playlist\n"
                  << "  [7] Guardar una playlist en archivo CSV\n"
                  << "  [8] Cargar una playlist desde archivo CSV\n"
                  << "  [0] Volver al menu principal\n";

        opcion = leerOpcion();
        switch (opcion) {
            case 1: {
                imprimirTitulo("CREAR PLAYLIST");
                if (cantidadPlaylists >= MAX_PLAYLISTS) {
                    std::cout << "  Ya llegaste al limite de " << MAX_PLAYLISTS << " playlists.\n";
                    pausar();
                    break;
                }
                std::string nombre;
                if (!leerTexto("  Nombre de la nueva playlist (Enter = cancelar): ", nombre, true)) {
                    std::cout << "  Operacion cancelada.\n";
                } else if (existeNombrePlaylist(nombre)) {
                    std::cout << "  Ya existe una playlist con ese nombre.\n";
                } else {
                    crearPlaylist(nombre);
                    std::cout << "  [OK] Playlist '" << nombre << "' creada y marcada como activa.\n";
                }
                pausar();
                break;
            }
            case 2: {
                imprimirTitulo("RENOMBRAR PLAYLIST");
                int i = pedirIndicePlaylist("Playlist a renombrar");
                if (i >= 0) {
                    std::string nuevo;
                    if (!leerTexto("  Nuevo nombre (Enter = cancelar): ", nuevo, true)) {
                        std::cout << "  Operacion cancelada.\n";
                    } else if (existeNombrePlaylist(nuevo, i)) {
                        std::cout << "  Ya existe otra playlist con ese nombre.\n";
                    } else {
                        playlists[i]->renombrar(nuevo);
                        std::cout << "  [OK] Playlist renombrada a '" << nuevo << "'.\n";
                    }
                }
                pausar();
                break;
            }
            case 3: {
                imprimirTitulo("ELIMINAR PLAYLIST");
                int i = pedirIndicePlaylist("Playlist a eliminar");
                if (i >= 0) {
                    std::cout << "  Se eliminara '" << playlists[i]->getNombre() << "' con sus "
                              << playlists[i]->getTamano() << " canciones.\n";
                    if (confirmar("  Confirmas")) {
                        std::string nombre = playlists[i]->getNombre();
                        eliminarPlaylist(i);
                        std::cout << "  [OK] Playlist '" << nombre << "' eliminada.\n";
                    } else {
                        std::cout << "  Operacion cancelada.\n";
                    }
                }
                pausar();
                break;
            }
            case 4: {
                imprimirTitulo("ELEGIR PLAYLIST ACTIVA");
                int i = pedirIndicePlaylist("Playlist a activar");
                if (i >= 0) {
                    indicePlaylistActiva = i;
                    std::cout << "  [OK] Playlist activa: '" << playlists[i]->getNombre() << "'.\n";
                }
                pausar();
                break;
            }
            case 5: {
                imprimirTitulo("FUSIONAR DOS PLAYLISTS");
                if (cantidadPlaylists < 2) {
                    std::cout << "  Necesitas al menos 2 playlists para fusionar.\n";
                    pausar();
                    break;
                }
                int a = pedirIndicePlaylist("Playlist PRINCIPAL (recibe las canciones)");
                if (a < 0) {
                    pausar();
                    break;
                }
                int b = pedirIndicePlaylist("Playlist SECUNDARIA (se copian sus canciones)");
                if (b < 0) {
                    pausar();
                    break;
                }
                if (a == b) {
                    std::cout << "  Elige dos playlists distintas (no se puede fusionar una consigo misma).\n";
                    pausar();
                    break;
                }
                bool vaciar = confirmar("  Vaciar la playlist secundaria despues de fusionar");
                GestorReproduccion::fusionarListas(*playlists[a], *playlists[b], vaciar);
                std::cout << "\n  [OK] Fusion lista. '" << playlists[a]->getNombre() << "' ahora tiene "
                          << playlists[a]->getTamano() << " canciones ("
                          << formatearDuracionTotal(playlists[a]->calcularDuracionTotalSegundos()) << ").\n";
                pausar();
                break;
            }
            case 6: {
                int i = pedirIndicePlaylist("Playlist a ver");
                if (i >= 0) {
                    mostrarPlaylistNumerada(*playlists[i]);
                }
                pausar();
                break;
            }
            case 7: {
                imprimirTitulo("GUARDAR PLAYLIST EN CSV");
                int i = pedirIndicePlaylist("Playlist a guardar");
                if (i >= 0) {
                    std::string ruta;
                    if (pedirNombreArchivo(nombreArchivoSugerido(playlists[i]->getNombre()), ruta)) {
                        if (GestorReproduccion::guardarPlaylistCSV(*playlists[i], ruta)) {
                            std::cout << "  [OK] Playlist guardada en '" << ruta << "'.\n";
                        } else {
                            std::cout << "  [ERROR] No se pudo escribir '" << ruta << "'.\n";
                        }
                    } else {
                        std::cout << "  Operacion cancelada.\n";
                    }
                }
                pausar();
                break;
            }
            case 8: {
                imprimirTitulo("CARGAR PLAYLIST DESDE CSV");
                if (cantidadPlaylists >= MAX_PLAYLISTS) {
                    std::cout << "  Ya llegaste al limite de " << MAX_PLAYLISTS << " playlists.\n";
                    pausar();
                    break;
                }
                std::string ruta;
                if (!pedirNombreArchivo("playlist.csv", ruta)) {
                    std::cout << "  Operacion cancelada.\n";
                    pausar();
                    break;
                }
                std::ifstream prueba(ruta.c_str());
                if (!prueba.is_open()) {
                    std::cout << "  [ERROR] No se encontro el archivo '" << ruta
                              << "' (debe estar en la carpeta del proyecto).\n";
                    pausar();
                    break;
                }
                prueba.close();

                std::string nombre;
                bool nombreValido = false;
                while (!nombreValido) {
                    if (!leerTexto("  Nombre para la playlist cargada (Enter = cancelar): ", nombre, true)) {
                        break;
                    }
                    if (existeNombrePlaylist(nombre)) {
                        std::cout << "  Ya existe una playlist con ese nombre. Elige otro.\n";
                    } else {
                        nombreValido = true;
                    }
                }
                if (!nombreValido) {
                    std::cout << "  Operacion cancelada.\n";
                    pausar();
                    break;
                }

                int indiceNueva = crearPlaylist(nombre);
                int cargadas = 0;
                try {
                    cargadas = GestorReproduccion::cargarPlaylistCSV(*playlists[indiceNueva], ruta);
                } catch (const std::exception&) {
                    std::cout << "  [Aviso] El archivo tiene datos invalidos; se cargo solo una parte.\n";
                    cargadas = playlists[indiceNueva]->getTamano();
                }
                std::cout << "  [OK] Playlist '" << nombre << "' creada con " << cargadas
                          << " canciones y marcada como activa.\n";
                if (cargadas <= 0) {
                    std::cout << "  (El archivo no tenia canciones validas.)\n";
                }
                pausar();
                break;
            }
            case 0: break;
            default:
                std::cout << "\n  Opcion no valida.\n";
                pausar();
                break;
        }
    } while (opcion != 0);
}

// ----------------------------------------------------------------------------
// [3] Editar la playlist activa
// ----------------------------------------------------------------------------

void InterfazConsola::menuEditarPlaylistActiva() {
    if (!hayPlaylistActiva()) {
        std::cout << "\n  No hay una playlist activa. Crea una en 'Gestionar Playlists'.\n";
        pausar();
        return;
    }

    int opcion = -1;
    do {
        // Se vuelve a leer en cada vuelta por si cambia la playlist activa.
        if (!hayPlaylistActiva()) {
            return;
        }
        ListaDobleCircular& lista = *playlists[indicePlaylistActiva];

        limpiarPantalla();
        imprimirTitulo("EDITAR PLAYLIST ACTIVA: " + lista.getNombre() + " (" +
                       std::to_string(lista.getTamano()) + " canciones, " +
                       formatearDuracionTotal(lista.calcularDuracionTotalSegundos()) + ")");
        std::cout << "  [1] Ver playlist\n"
                  << "  -- Agregar una cancion de la biblioteca --\n"
                  << "  [2] Al inicio\n"
                  << "  [3] Al final\n"
                  << "  [4] En una posicion\n"
                  << "  -- Quitar una cancion --\n"
                  << "  [5] La primera\n"
                  << "  [6] La ultima\n"
                  << "  [7] De una posicion\n"
                  << "  -- Reordenar --\n"
                  << "  [8] Mover una cancion de posicion\n"
                  << "  [9] Mezclar en orden aleatorio (Shuffle)\n"
                  << "  [0] Volver al menu principal\n";

        opcion = leerOpcion();
        switch (opcion) {
            case 1:
                mostrarPlaylistNumerada(lista);
                pausar();
                break;
            case 2:
                agregarCancionAPlaylist(biblioteca, lista, 0);
                pausar();
                break;
            case 3:
                agregarCancionAPlaylist(biblioteca, lista, 1);
                pausar();
                break;
            case 4:
                agregarCancionAPlaylist(biblioteca, lista, 2);
                pausar();
                break;
            case 5:
                quitarCancionDePlaylist(lista, 0);
                pausar();
                break;
            case 6:
                quitarCancionDePlaylist(lista, 1);
                pausar();
                break;
            case 7:
                quitarCancionDePlaylist(lista, 2);
                pausar();
                break;
            case 8:
                moverCancionEnPlaylist(lista);
                pausar();
                break;
            case 9:
                imprimirTitulo("MEZCLAR PLAYLIST (SHUFFLE)");
                if (lista.getTamano() < 2) {
                    std::cout << "  Se necesitan al menos 2 canciones para mezclar.\n";
                } else {
                    // La semilla depende de la hora para que cada mezcla sea distinta.
                    GestorReproduccion::aplicarShuffleFisherYates(
                        lista, static_cast<unsigned int>(std::time(nullptr)));
                    std::cout << "  [OK] Playlist mezclada.\n";
                    mostrarPlaylistNumerada(lista);
                }
                pausar();
                break;
            case 0: break;
            default:
                std::cout << "\n  Opcion no valida.\n";
                pausar();
                break;
        }
    } while (opcion != 0);
}

// ----------------------------------------------------------------------------
// [4] Reproductor e historial
// ----------------------------------------------------------------------------

void InterfazConsola::menuReproductor() {
    if (!hayPlaylistActiva()) {
        std::cout << "\n  No hay una playlist activa. Crea una en 'Gestionar Playlists'.\n";
        pausar();
        return;
    }

    int opcion = -1;
    do {
        if (!hayPlaylistActiva()) {
            return;
        }
        ListaDobleCircular& lista = *playlists[indicePlaylistActiva];

        limpiarPantalla();
        mostrarEncabezadoReproductor();
        std::cout << "  [1] Reproducir la cancion actual\n"
                  << "  [2] Siguiente cancion\n"
                  << "  [3] Cancion anterior\n"
                  << "  [4] Cambiar modo de repeticion\n"
                  << "  [5] Ver playlist\n"
                  << "  [6] Ver historial de reproduccion\n"
                  << "  [0] Volver al menu principal\n";

        opcion = leerOpcion();
        switch (opcion) {
            case 1:
                if (lista.estaVacia()) {
                    std::cout << "\n  La playlist esta vacia. Agrega canciones en 'Editar Playlist Activa'.\n";
                } else {
                    GestorReproduccion::registrarEnHistorial(lista, historial);
                    anunciarCancion("Reproduciendo", lista.obtenerCancionActual());
                }
                pausar();
                break;
            case 2:
                if (lista.estaVacia()) {
                    std::cout << "\n  La playlist esta vacia. Agrega canciones en 'Editar Playlist Activa'.\n";
                } else {
                    const Cancion* siguiente = lista.siguienteCancion();
                    if (siguiente == nullptr) {
                        std::cout << "\n  Fin de la playlist (modo 'Sin repeticion'). "
                                  << "Cambia el modo o usa 'Cancion anterior'.\n";
                    } else {
                        GestorReproduccion::registrarEnHistorial(lista, historial);
                        anunciarCancion("Reproduciendo", siguiente);
                    }
                }
                pausar();
                break;
            case 3:
                if (lista.estaVacia()) {
                    std::cout << "\n  La playlist esta vacia. Agrega canciones en 'Editar Playlist Activa'.\n";
                } else {
                    const Cancion* anterior = lista.anteriorCancion();
                    if (anterior != nullptr) {
                        GestorReproduccion::registrarEnHistorial(lista, historial);
                        anunciarCancion("Reproduciendo", anterior);
                    }
                }
                pausar();
                break;
            case 4:
                cambiarModoRepeticion(lista);
                pausar();
                break;
            case 5:
                mostrarPlaylistNumerada(lista);
                pausar();
                break;
            case 6:
                historial.mostrar("HISTORIAL DE CANCIONES REPRODUCIDAS");
                pausar();
                break;
            case 0: break;
            default:
                std::cout << "\n  Opcion no valida.\n";
                pausar();
                break;
        }
    } while (opcion != 0);
}

// ----------------------------------------------------------------------------
// Formato y pantalla
// ----------------------------------------------------------------------------

std::string InterfazConsola::formatearDuracionTotal(int totalSegundos) {
    if (totalSegundos < 0) {
        totalSegundos = 0;
    }
    int horas = totalSegundos / 3600;
    int minutos = (totalSegundos % 3600) / 60;
    int segundos = totalSegundos % 60;

    std::ostringstream texto;
    texto << std::setfill('0') << std::setw(2) << horas << ":"
          << std::setw(2) << minutos << ":"
          << std::setw(2) << segundos;
    return texto.str();
}

void InterfazConsola::mostrarEncabezadoReproductor() const {
    std::cout << "\n==============================================================\n";
    if (!hayPlaylistActiva()) {
        std::cout << "  Playlist activa : (ninguna)\n"
                  << "  Crea una en 'Gestionar Playlists' para empezar.\n";
    } else {
        const ListaDobleCircular* lista = playlists[indicePlaylistActiva];
        std::cout << "  Playlist activa : " << lista->getNombre() << "  ("
                  << lista->getTamano() << " canciones, "
                  << formatearDuracionTotal(lista->calcularDuracionTotalSegundos()) << ")\n";

        const Cancion* actual = lista->obtenerCancionActual();
        if (actual == nullptr) {
            std::cout << "  Ahora suena     : (playlist vacia)\n";
        } else {
            std::cout << "  Ahora suena     : " << actual->getTitulo() << " - " << actual->getArtista()
                      << " (" << actual->obtenerDuracionFormateada() << ")\n";
        }
        std::cout << "  Modo repeticion : " << modoATexto(lista->getModoRepeticion()) << "\n";
    }
    std::cout << "==============================================================\n";
}

void InterfazConsola::limpiarPantalla() {
#ifdef _WIN32
    std::system("cls");
#else
    std::system("clear");
#endif
}

void InterfazConsola::pausar() {
    std::cout << "\n  Presiona Enter para continuar..." << std::flush;
    std::string descarte;
    std::getline(std::cin, descarte);
}
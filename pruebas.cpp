/**
 * ============================================================================
 * pruebas.cpp - Pruebas unitarias y de integracion del proyecto
 * Responsable: JEREMY
 *
 * Programa aparte (tiene su propio main). NO reemplaza a main.cpp.
 * No necesita librerias externas: solo imprime [ok] o [FALLO] por cada prueba.
 *
 * COMO COMPILARLO Y EJECUTARLO (desde la carpeta del proyecto):
 *
 *   g++ -std=c++17 -Wall -Wextra -Wno-unused-parameter pruebas.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp -o pruebas
 *
 *   Windows:        .\pruebas.exe
 *   Linux / macOS:  ./pruebas
 *
 * (Observa que NO se incluye main.cpp, porque este archivo ya trae su main.)
 * El programa termina con codigo 0 si todo paso y con 1 si algo fallo.
 * Crea archivos temporales "prueba_tmp_*.csv" y los borra al terminar.
 * ============================================================================
 */

#include <iostream>
#include <cstdio>
#include <string>
#include "cancion.h"
#include "lista_simple.h"
#include "lista_doble_circular.h"
#include "reproduccion.h"
#include "ui.h"

// ---------------------------------------------------------------------------
// Mini marco de pruebas
// ---------------------------------------------------------------------------
static int totalPruebas = 0;
static int pruebasFallidas = 0;

static void verificar(bool condicion, const std::string& descripcion, int linea) {
    totalPruebas++;
    if (condicion) {
        std::cout << "  [ok]    " << descripcion << "\n";
    } else {
        pruebasFallidas++;
        std::cout << "  [FALLO] " << descripcion << "   (pruebas.cpp, linea " << linea << ")\n";
    }
}
#define VERIFICAR(condicion, descripcion) verificar((condicion), (descripcion), __LINE__)

static void grupo(const std::string& nombre) {
    std::cout << "\n=== " << nombre << " ===\n";
}

// ---------------------------------------------------------------------------
// Ayudas para las pruebas
// ---------------------------------------------------------------------------
static Cancion cancionDe(int id, int segundos = 100) {
    return Cancion(id, "Titulo" + std::to_string(id), "Artista", segundos, "Genero");
}

// Devuelve los IDs de la playlist en orden, ej. "1,2,3" (vacia = "")
static std::string idsEnOrden(const ListaDobleCircular& lista) {
    std::string texto;
    NodoDoble* nodo = lista.getCabeza();
    for (int i = 0; i < lista.getTamano(); ++i) {
        if (i > 0) {
            texto += ",";
        }
        texto += std::to_string(nodo->dato.getId());
        nodo = nodo->siguiente;
    }
    return texto;
}

// Comprueba el invariante de la lista circular doble:
//  - cola->siguiente == cabeza y cabeza->anterior == cola
//  - para todo nodo: nodo->siguiente->anterior == nodo
//  - dando 'tamano' pasos hacia adelante se vuelve a la cabeza (el ciclo cierra)
static bool cicloValido(const ListaDobleCircular& lista) {
    if (lista.estaVacia()) {
        return lista.getTamano() == 0 && lista.getCabeza() == nullptr && lista.getCola() == nullptr;
    }
    if (lista.getCola()->siguiente != lista.getCabeza() || lista.getCabeza()->anterior != lista.getCola()) {
        return false;
    }
    NodoDoble* nodo = lista.getCabeza();
    for (int i = 0; i < lista.getTamano(); ++i) {
        if (nodo == nullptr || nodo->siguiente == nullptr || nodo->siguiente->anterior != nodo) {
            return false;
        }
        nodo = nodo->siguiente;
    }
    return nodo == lista.getCabeza();
}

static void llenar(ListaDobleCircular& lista, int cantidad) {
    for (int i = 1; i <= cantidad; ++i) {
        lista.insertarAlFinal(cancionDe(i));
    }
}

// ---------------------------------------------------------------------------
// 1. Utilidades de tiempo (parte de Jeremy)
// ---------------------------------------------------------------------------
static void pruebasFormatoDuracion() {
    grupo("Formato de duracion HH:MM:SS (InterfazConsola::formatearDuracionTotal)");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(0) == "00:00:00", "0 s -> 00:00:00");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(5) == "00:00:05", "5 s -> 00:00:05");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(59) == "00:00:59", "59 s -> 00:00:59");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(60) == "00:01:00", "60 s -> 00:01:00");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(354) == "00:05:54", "354 s -> 00:05:54");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(3599) == "00:59:59", "3599 s -> 00:59:59");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(3600) == "01:00:00", "3600 s -> 01:00:00");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(5103) == "01:25:03", "5103 s -> 01:25:03 (ejemplo del enunciado)");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(360000) == "100:00:00", "360000 s -> 100:00:00 (mas de 99 horas no se corta)");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(-30) == "00:00:00", "valor negativo se trata como 0");
}

// ---------------------------------------------------------------------------
// 2. TAD Cancion (Andrea)
// ---------------------------------------------------------------------------
static void pruebasCancion() {
    grupo("TAD Cancion");
    Cancion c(7, "Clocks", "Coldplay", 307, "Alternative");
    VERIFICAR(c.getId() == 7 && c.getTitulo() == "Clocks" && c.getArtista() == "Coldplay" &&
              c.getDuracionSegundos() == 307 && c.getGenero() == "Alternative", "constructor y getters");
    VERIFICAR(c.obtenerDuracionFormateada() == "05:07", "307 s -> 05:07");
    VERIFICAR(Cancion(1, "a", "b", 59, "g").obtenerDuracionFormateada() == "00:59", "59 s -> 00:59");
    VERIFICAR(Cancion(1, "a", "b", -5, "g").getDuracionSegundos() == 0, "duracion negativa en el constructor se corrige a 0");

    Cancion vacia;
    VERIFICAR(vacia.getId() == 0 && vacia.getDuracionSegundos() == 0, "constructor vacio da valores por defecto");

    std::string linea = c.aCSV();
    VERIFICAR(linea == "7;Clocks;Coldplay;307;Alternative", "aCSV genera la linea esperada");
    Cancion leida;
    VERIFICAR(Cancion::desdeCSV(linea, leida) && leida.getId() == 7 && leida.getTitulo() == "Clocks" &&
              leida.getDuracionSegundos() == 307, "desdeCSV(aCSV(c)) recupera la cancion");

    Cancion basura;
    VERIFICAR(!Cancion::desdeCSV("id;titulo;artista;duracion_segundos;genero", basura), "desdeCSV ignora el encabezado");
    VERIFICAR(!Cancion::desdeCSV("", basura), "desdeCSV rechaza linea vacia");
    VERIFICAR(!Cancion::desdeCSV("1;solo;tres", basura), "desdeCSV rechaza linea con pocas columnas");
}

// ---------------------------------------------------------------------------
// 3. Lista simple (Andrea)
// ---------------------------------------------------------------------------
static void pruebasListaSimple() {
    grupo("ListaSimple (biblioteca e historial)");
    ListaSimple l;
    VERIFICAR(l.estaVacia() && l.getTamano() == 0 && l.calcularDuracionTotalSegundos() == 0, "lista nueva: vacia, tamano 0, duracion 0");

    l.agregarAlFinal(cancionDe(1, 100));
    l.agregarAlFinal(cancionDe(2, 200));
    l.agregarAlInicio(cancionDe(3, 300));    // orden: 3,1,2
    VERIFICAR(l.getTamano() == 3, "tamano 3 tras agregar 3 canciones");
    Cancion c;
    VERIFICAR(l.obtenerEnPosicion(0, c) && c.getId() == 3, "agregarAlInicio deja la cancion 3 en la posicion 0");
    VERIFICAR(l.obtenerEnPosicion(2, c) && c.getId() == 2, "agregarAlFinal deja la cancion 2 en la ultima posicion");
    VERIFICAR(!l.obtenerEnPosicion(3, c) && !l.obtenerEnPosicion(-1, c), "obtenerEnPosicion rechaza posiciones fuera de rango");
    VERIFICAR(l.calcularDuracionTotalSegundos() == 600, "duracion total = 100+200+300 = 600");
    VERIFICAR(l.buscarPorId(1, c) && c.getDuracionSegundos() == 100, "buscarPorId encuentra una cancion existente");
    VERIFICAR(!l.buscarPorId(99, c), "buscarPorId devuelve false si no existe");

    VERIFICAR(l.eliminarPorId(1), "eliminarPorId (nodo del medio)");
    VERIFICAR(l.getTamano() == 2 && !l.buscarPorId(1, c), "tras eliminar, tamano 2 y ya no se encuentra");
    VERIFICAR(l.eliminarPorId(3), "eliminarPorId (cabeza)");
    VERIFICAR(l.eliminarPorId(2), "eliminarPorId (ultimo nodo restante)");
    VERIFICAR(l.estaVacia() && l.getCabeza() == nullptr, "lista vacia tras eliminar todo");
    VERIFICAR(!l.eliminarPorId(2), "eliminar en lista vacia devuelve false");

    l.agregarAlFinal(cancionDe(5));
    l.agregarAlFinal(cancionDe(6));
    l.eliminarPorId(6);                      // se elimina la cola: debe poder seguir agregando al final
    l.agregarAlFinal(cancionDe(7));
    VERIFICAR(l.getTamano() == 2 && l.obtenerEnPosicion(1, c) && c.getId() == 7, "se puede agregar al final despues de eliminar la cola");

    l.limpiar();
    VERIFICAR(l.estaVacia(), "limpiar deja la lista vacia");
}

// ---------------------------------------------------------------------------
// 4. Lista doblemente enlazada circular (Jeick)
// ---------------------------------------------------------------------------
static void pruebasListaDobleCircular() {
    grupo("ListaDobleCircular: estructura");
    ListaDobleCircular l("Prueba");
    VERIFICAR(l.getNombre() == "Prueba", "nombre inicial");
    l.renombrar("Otro");
    VERIFICAR(l.getNombre() == "Otro", "renombrar");
    VERIFICAR(l.estaVacia() && cicloValido(l), "lista nueva vacia");
    VERIFICAR(l.obtenerCancionActual() == nullptr && l.siguienteCancion() == nullptr && l.anteriorCancion() == nullptr,
              "navegar en lista vacia devuelve nullptr (sin romperse)");
    VERIFICAR(!l.eliminarAlInicio() && !l.eliminarAlFinal() && !l.eliminarEnPosicion(0), "eliminar en lista vacia devuelve false");

    l.insertarAlFinal(cancionDe(1));
    VERIFICAR(cicloValido(l) && l.getCabeza()->siguiente == l.getCabeza() && l.getCabeza()->anterior == l.getCabeza(),
              "con 1 nodo, apunta a si mismo en ambos sentidos");

    l.insertarAlFinal(cancionDe(2));
    l.insertarAlFinal(cancionDe(3));
    VERIFICAR(idsEnOrden(l) == "1,2,3" && cicloValido(l), "insertarAlFinal x3 -> 1,2,3 con ciclo valido");
    l.insertarAlInicio(cancionDe(0));
    VERIFICAR(idsEnOrden(l) == "0,1,2,3" && cicloValido(l), "insertarAlInicio -> 0,1,2,3");
    VERIFICAR(l.insertarEnPosicion(cancionDe(9), 2) && idsEnOrden(l) == "0,1,9,2,3" && cicloValido(l), "insertarEnPosicion (medio)");
    VERIFICAR(l.insertarEnPosicion(cancionDe(8), 0) && idsEnOrden(l) == "8,0,1,9,2,3", "insertarEnPosicion (0 = inicio)");
    VERIFICAR(l.insertarEnPosicion(cancionDe(7), l.getTamano()) && idsEnOrden(l) == "8,0,1,9,2,3,7" && cicloValido(l),
              "insertarEnPosicion (tamano = final)");
    VERIFICAR(!l.insertarEnPosicion(cancionDe(5), -1) && !l.insertarEnPosicion(cancionDe(5), l.getTamano() + 1),
              "insertarEnPosicion rechaza posiciones invalidas");
    VERIFICAR(l.getTamano() == 7, "el tamano no cambia tras inserciones rechazadas");

    VERIFICAR(l.obtenerNodoEn(0)->dato.getId() == 8 && l.obtenerNodoEn(6)->dato.getId() == 7, "obtenerNodoEn (primero y ultimo)");
    VERIFICAR(l.obtenerNodoEn(7) == nullptr && l.obtenerNodoEn(-1) == nullptr, "obtenerNodoEn fuera de rango devuelve nullptr");

    VERIFICAR(l.eliminarAlInicio() && idsEnOrden(l) == "0,1,9,2,3,7" && cicloValido(l), "eliminarAlInicio");
    VERIFICAR(l.eliminarAlFinal() && idsEnOrden(l) == "0,1,9,2,3" && cicloValido(l), "eliminarAlFinal");
    VERIFICAR(l.eliminarEnPosicion(2) && idsEnOrden(l) == "0,1,2,3" && cicloValido(l), "eliminarEnPosicion (medio)");
    VERIFICAR(!l.eliminarEnPosicion(4) && !l.eliminarEnPosicion(-1), "eliminarEnPosicion rechaza posiciones invalidas");
    while (!l.estaVacia()) {
        l.eliminarAlInicio();
    }
    VERIFICAR(cicloValido(l) && l.getTamano() == 0, "tras eliminar todos los nodos, la lista vuelve a estar vacia y consistente");

    grupo("ListaDobleCircular: duracion total");
    ListaDobleCircular d("Dur");
    VERIFICAR(d.calcularDuracionTotalSegundos() == 0, "playlist vacia dura 0 s");
    d.insertarAlFinal(cancionDe(1, 354));
    d.insertarAlFinal(cancionDe(2, 212));
    d.insertarAlFinal(cancionDe(3, 294));
    VERIFICAR(d.calcularDuracionTotalSegundos() == 860, "354+212+294 = 860 s");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(d.calcularDuracionTotalSegundos()) == "00:14:20", "860 s se muestra como 00:14:20");
    d.eliminarEnPosicion(1);
    VERIFICAR(d.calcularDuracionTotalSegundos() == 648, "al quitar una cancion de 212 s la duracion baja a 648 s");
}

static void pruebasNavegacion() {
    grupo("ListaDobleCircular: navegacion y modos de repeticion");
    ListaDobleCircular l("Nav");
    llenar(l, 3);   // 1,2,3 ; suena la 1
    VERIFICAR(l.obtenerCancionActual()->getId() == 1, "al agregar la primera cancion, esa es la que suena");
    VERIFICAR(l.getModoRepeticion() == ModoRepeticion::REPETIR_TODAS, "modo por defecto: repetir todas");

    VERIFICAR(l.siguienteCancion()->getId() == 2, "siguiente: 1 -> 2");
    VERIFICAR(l.siguienteCancion()->getId() == 3, "siguiente: 2 -> 3");
    VERIFICAR(l.siguienteCancion()->getId() == 1, "siguiente en la ultima vuelve a la primera (circular)");
    VERIFICAR(l.anteriorCancion()->getId() == 3, "anterior en la primera salta a la ultima (circular)");
    VERIFICAR(l.anteriorCancion()->getId() == 2, "anterior: 3 -> 2");

    l.setModoRepeticion(ModoRepeticion::REPETIR_UNA);
    VERIFICAR(l.getModoRepeticion() == ModoRepeticion::REPETIR_UNA, "cambiar a repetir una");
    VERIFICAR(l.siguienteCancion()->getId() == 2 && l.siguienteCancion()->getId() == 2, "repetir una: 'siguiente' no avanza");

    l.setModoRepeticion(ModoRepeticion::SIN_REPETICION);
    VERIFICAR(l.siguienteCancion()->getId() == 3, "sin repeticion: avanza normalmente hasta la ultima");
    VERIFICAR(l.siguienteCancion() == nullptr, "sin repeticion: al final devuelve nullptr");
    VERIFICAR(l.obtenerCancionActual()->getId() == 3, "sin repeticion: la cancion actual no cambia al llegar al final");

    // Eliminar la cancion que esta sonando no debe dejar un puntero colgante
    ListaDobleCircular e("Elim");
    llenar(e, 3);
    e.siguienteCancion();                         // suena la 2 (nodo del medio)
    e.eliminarEnPosicion(1);                      // se elimina la que suena
    VERIFICAR(e.obtenerCancionActual() != nullptr && e.obtenerCancionActual()->getId() == 3,
              "eliminar la cancion que suena pasa la reproduccion a la siguiente");
    e.eliminarAlFinal();                          // ahora suena la 3 (cola) y se elimina
    VERIFICAR(e.obtenerCancionActual() != nullptr && e.obtenerCancionActual()->getId() == 1,
              "eliminar la ultima mientras suena pasa la reproduccion a la primera");
    e.eliminarAlInicio();
    VERIFICAR(e.obtenerCancionActual() == nullptr, "playlist vacia: no suena nada (nullptr)");

    ListaDobleCircular u("Una");
    u.insertarAlFinal(cancionDe(4));
    VERIFICAR(u.siguienteCancion()->getId() == 4 && u.anteriorCancion()->getId() == 4, "con una sola cancion, siguiente y anterior vuelven a ella");

    l.limpiar();
    VERIFICAR(l.estaVacia() && cicloValido(l) && l.obtenerCancionActual() == nullptr, "limpiar vacia la playlist");
}

// ---------------------------------------------------------------------------
// 5. Algoritmos de Juan Pablo
// ---------------------------------------------------------------------------
static int sumaIds(const ListaDobleCircular& lista) {
    int suma = 0;
    NodoDoble* nodo = lista.getCabeza();
    for (int i = 0; i < lista.getTamano(); ++i) {
        suma += nodo->dato.getId();
        nodo = nodo->siguiente;
    }
    return suma;
}

static void pruebasAlgoritmos() {
    grupo("GestorReproduccion: mover cancion");
    ListaDobleCircular l("Mov");
    llenar(l, 5);   // 1,2,3,4,5
    VERIFICAR(GestorReproduccion::moverCancion(l, 0, 4) && idsEnOrden(l) == "2,3,4,5,1" && cicloValido(l), "mover primera al final");
    VERIFICAR(GestorReproduccion::moverCancion(l, 4, 0) && idsEnOrden(l) == "1,2,3,4,5" && cicloValido(l), "mover ultima al inicio");
    VERIFICAR(GestorReproduccion::moverCancion(l, 1, 3) && idsEnOrden(l) == "1,3,4,2,5" && cicloValido(l), "mover del medio hacia adelante");
    VERIFICAR(GestorReproduccion::moverCancion(l, 3, 1) && idsEnOrden(l) == "1,2,3,4,5", "mover del medio hacia atras");
    VERIFICAR(GestorReproduccion::moverCancion(l, 2, 2) && idsEnOrden(l) == "1,2,3,4,5", "mover a la misma posicion no cambia nada");
    VERIFICAR(!GestorReproduccion::moverCancion(l, -1, 2) && !GestorReproduccion::moverCancion(l, 0, 5) && !GestorReproduccion::moverCancion(l, 7, 1),
              "mover con posiciones invalidas devuelve false");
    VERIFICAR(idsEnOrden(l) == "1,2,3,4,5", "tras movimientos invalidos la lista no cambia");

    grupo("GestorReproduccion: shuffle Fisher-Yates");
    ListaDobleCircular s("Shuf");
    llenar(s, 20);
    int sumaAntes = sumaIds(s);
    std::string antes = idsEnOrden(s);
    GestorReproduccion::aplicarShuffleFisherYates(s, 123);
    VERIFICAR(s.getTamano() == 20 && cicloValido(s), "shuffle conserva el tamano y el ciclo");
    VERIFICAR(sumaIds(s) == sumaAntes, "shuffle conserva las mismas canciones (misma suma de IDs)");
    VERIFICAR(idsEnOrden(s) != antes, "shuffle cambia el orden (20 canciones, semilla 123)");

    // Comprobar que sigue siendo una permutacion: cada ID del 1 al 20 aparece exactamente una vez
    bool aparece[21] = {false};
    bool sinRepetidos = true;
    NodoDoble* nodo = s.getCabeza();
    for (int i = 0; i < s.getTamano(); ++i) {
        int id = nodo->dato.getId();
        if (id < 1 || id > 20 || aparece[id]) {
            sinRepetidos = false;
        } else {
            aparece[id] = true;
        }
        nodo = nodo->siguiente;
    }
    VERIFICAR(sinRepetidos, "shuffle es una permutacion (ningun ID repetido ni perdido)");

    ListaDobleCircular s2("Shuf2");
    llenar(s2, 20);
    GestorReproduccion::aplicarShuffleFisherYates(s2, 123);
    VERIFICAR(idsEnOrden(s2) == idsEnOrden(s), "misma semilla -> mismo orden (reproducible)");
    ListaDobleCircular s3("Shuf3");
    llenar(s3, 20);
    GestorReproduccion::aplicarShuffleFisherYates(s3, 999);
    VERIFICAR(idsEnOrden(s3) != idsEnOrden(s), "semilla distinta -> orden distinto");

    ListaDobleCircular vacia("V");
    ListaDobleCircular una("U");
    una.insertarAlFinal(cancionDe(1));
    GestorReproduccion::aplicarShuffleFisherYates(vacia, 1);
    GestorReproduccion::aplicarShuffleFisherYates(una, 1);
    VERIFICAR(vacia.estaVacia() && idsEnOrden(una) == "1", "shuffle en lista vacia o de 1 elemento no rompe nada");

    grupo("GestorReproduccion: fusionar listas");
    ListaDobleCircular a("A");
    ListaDobleCircular b("B");
    a.insertarAlFinal(cancionDe(1, 100));
    a.insertarAlFinal(cancionDe(2, 200));
    b.insertarAlFinal(cancionDe(3, 300));
    b.insertarAlFinal(cancionDe(4, 400));
    GestorReproduccion::fusionarListas(a, b, false);
    VERIFICAR(idsEnOrden(a) == "1,2,3,4" && cicloValido(a), "fusion: A queda con 1,2,3,4");
    VERIFICAR(idsEnOrden(b) == "3,4", "fusion sin vaciar: B queda intacta");
    VERIFICAR(a.calcularDuracionTotalSegundos() == 1000, "duracion de la lista fusionada = 1000 s");
    GestorReproduccion::fusionarListas(a, b, true);
    VERIFICAR(idsEnOrden(a) == "1,2,3,4,3,4" && b.estaVacia() && cicloValido(b), "fusion vaciando B: B queda vacia y consistente");
    ListaDobleCircular vac("Vac");
    GestorReproduccion::fusionarListas(a, vac, false);
    VERIFICAR(a.getTamano() == 6, "fusionar con una lista vacia no cambia nada");

    grupo("GestorReproduccion: historial");
    ListaDobleCircular p("Hist");
    ListaSimple historial;
    GestorReproduccion::registrarEnHistorial(p, historial);
    VERIFICAR(historial.estaVacia(), "playlist vacia no registra nada en el historial");
    llenar(p, 3);
    GestorReproduccion::registrarEnHistorial(p, historial);   // suena la 1
    p.siguienteCancion();
    GestorReproduccion::registrarEnHistorial(p, historial);   // suena la 2
    Cancion c;
    VERIFICAR(historial.getTamano() == 2, "el historial tiene 2 canciones");
    VERIFICAR(historial.obtenerEnPosicion(0, c) && c.getId() == 2, "la mas reciente queda primera en el historial");
    VERIFICAR(historial.obtenerEnPosicion(1, c) && c.getId() == 1, "la mas antigua queda al final");

    grupo("GestorReproduccion: guardar y cargar playlist en CSV");
    const std::string archivo = "prueba_tmp_playlist.csv";
    ListaDobleCircular g("Guardar");
    g.insertarAlFinal(Cancion(1, "Bohemian Rhapsody", "Queen", 354, "Rock"));
    g.insertarAlFinal(Cancion(2, "Clocks", "Coldplay", 307, "Alternative"));
    VERIFICAR(GestorReproduccion::guardarPlaylistCSV(g, archivo), "guardarPlaylistCSV devuelve true");
    ListaDobleCircular r("Recuperada");
    VERIFICAR(GestorReproduccion::cargarPlaylistCSV(r, archivo) == 2, "cargarPlaylistCSV devuelve 2 canciones");
    VERIFICAR(idsEnOrden(r) == "1,2" && r.calcularDuracionTotalSegundos() == 661 && cicloValido(r), "la playlist cargada es igual a la guardada");
    VERIFICAR(r.obtenerNodoEn(0)->dato.getTitulo() == "Bohemian Rhapsody", "se conservan los titulos");
    VERIFICAR(GestorReproduccion::cargarPlaylistCSV(r, "prueba_tmp_no_existe.csv") == -1, "cargar un archivo inexistente devuelve -1");
    std::remove(archivo.c_str());
}

// ---------------------------------------------------------------------------
// 6. Integracion: biblioteca (lista simple) -> playlist activa (lista doble circular)
// ---------------------------------------------------------------------------
static void pruebasIntegracion() {
    grupo("Integracion: biblioteca (ListaSimple) + playlist (ListaDobleCircular)");
    const std::string archivo = "prueba_tmp_biblioteca.csv";

    // Biblioteca con las 5 canciones de ejemplo, guardada y recargada desde CSV
    ListaSimple original;
    original.agregarAlFinal(Cancion(1, "Bohemian Rhapsody", "Queen", 354, "Rock"));
    original.agregarAlFinal(Cancion(2, "De Musica Ligera", "Soda Stereo", 212, "Rock Latino"));
    original.agregarAlFinal(Cancion(3, "Billie Jean", "Michael Jackson", 294, "Pop"));
    original.agregarAlFinal(Cancion(4, "Tren al Sur", "Los Prisioneros", 336, "New Wave"));
    original.agregarAlFinal(Cancion(5, "Clocks", "Coldplay", 307, "Alternative"));
    VERIFICAR(original.guardarEnCSV(archivo), "se guarda la biblioteca en CSV");

    ListaSimple biblioteca;
    VERIFICAR(biblioteca.cargarDesdeCSV(archivo) == 5 && biblioteca.getTamano() == 5, "se recarga la biblioteca: 5 canciones");
    VERIFICAR(biblioteca.calcularDuracionTotalSegundos() == 1503, "la biblioteca dura 1503 s (25 min 3 s)");

    // Se arma una playlist eligiendo canciones POR ID de la biblioteca (lo que hace el menu)
    ListaDobleCircular playlist("Mi mezcla");
    int elegidas[] = {3, 1, 5};
    bool todasEncontradas = true;
    for (int i = 0; i < 3; ++i) {
        Cancion c;
        if (biblioteca.buscarPorId(elegidas[i], c)) {
            playlist.insertarAlFinal(c);
        } else {
            todasEncontradas = false;
        }
    }
    VERIFICAR(todasEncontradas, "las canciones elegidas por ID se encuentran en la biblioteca");
    VERIFICAR(idsEnOrden(playlist) == "3,1,5" && cicloValido(playlist), "la playlist queda 3,1,5");
    VERIFICAR(playlist.calcularDuracionTotalSegundos() == 294 + 354 + 307, "duracion de la playlist = suma de las 3 elegidas");
    VERIFICAR(InterfazConsola::formatearDuracionTotal(playlist.calcularDuracionTotalSegundos()) == "00:15:55", "se muestra como 00:15:55");

    // Una cancion que no esta en la biblioteca no se puede agregar
    Cancion noExiste;
    VERIFICAR(!biblioteca.buscarPorId(42, noExiste), "un ID inexistente no se encuentra (el menu no agrega nada)");

    // La playlist guarda COPIAS: eliminar de la biblioteca no la afecta
    biblioteca.eliminarPorId(3);
    VERIFICAR(biblioteca.getTamano() == 4, "se elimina una cancion de la biblioteca");
    VERIFICAR(playlist.getTamano() == 3 && playlist.obtenerNodoEn(0)->dato.getTitulo() == "Billie Jean",
              "la playlist conserva su copia de la cancion eliminada de la biblioteca");

    // Flujo de reproduccion completo con historial
    ListaSimple historial;
    GestorReproduccion::registrarEnHistorial(playlist, historial);      // suena Billie Jean (3)
    playlist.siguienteCancion();
    GestorReproduccion::registrarEnHistorial(playlist, historial);      // suena Bohemian Rhapsody (1)
    playlist.siguienteCancion();
    GestorReproduccion::registrarEnHistorial(playlist, historial);      // suena Clocks (5)
    playlist.siguienteCancion();                                        // vuelve a la 3 (circular)
    GestorReproduccion::registrarEnHistorial(playlist, historial);
    Cancion c;
    VERIFICAR(historial.getTamano() == 4, "el historial registra las 4 reproducciones");
    VERIFICAR(historial.obtenerEnPosicion(0, c) && c.getId() == 3, "lo ultimo reproducido (la 3, por circularidad) esta primero");
    VERIFICAR(historial.obtenerEnPosicion(3, c) && c.getId() == 3, "lo primero reproducido esta al final");

    // Mover, mezclar y fusionar sobre una playlist armada desde la biblioteca
    GestorReproduccion::moverCancion(playlist, 0, 2);
    VERIFICAR(idsEnOrden(playlist) == "1,5,3", "mover la primera al final: 1,5,3");
    ListaDobleCircular otra("Otra");
    Cancion c2;
    biblioteca.buscarPorId(2, c2);
    otra.insertarAlFinal(c2);
    GestorReproduccion::fusionarListas(playlist, otra, false);
    VERIFICAR(idsEnOrden(playlist) == "1,5,3,2" && cicloValido(playlist), "fusionar con otra playlist: 1,5,3,2");
    GestorReproduccion::aplicarShuffleFisherYates(playlist, 7);
    VERIFICAR(sumaIds(playlist) == 11 && playlist.getTamano() == 4 && cicloValido(playlist), "shuffle sobre la playlist integrada conserva las 4 canciones");

    std::remove(archivo.c_str());
}

// ---------------------------------------------------------------------------
// Programa principal de las pruebas
// ---------------------------------------------------------------------------
int main() {
    std::cout << "========================================================\n"
              << "  PRUEBAS - Reproductor de Musica con Listas (CC0401)\n"
              << "========================================================\n";

    pruebasFormatoDuracion();
    pruebasCancion();
    pruebasListaSimple();
    pruebasListaDobleCircular();
    pruebasNavegacion();
    pruebasAlgoritmos();
    pruebasIntegracion();

    std::cout << "\n========================================================\n"
              << "  Resultado: " << (totalPruebas - pruebasFallidas) << " de " << totalPruebas << " pruebas correctas\n";
    if (pruebasFallidas == 0) {
        std::cout << "  TODO CORRECTO\n";
    } else {
        std::cout << "  HAY " << pruebasFallidas << " PRUEBA(S) FALLIDA(S) - revisa las lineas [FALLO]\n";
    }
    std::cout << "========================================================\n";
    return pruebasFallidas == 0 ? 0 : 1;
}
#include "lista_doble_circular.h"
#include <iostream>

/**
 * ============================================================================
 * ARCHIVO DE TRABAJO DE: JEICK (lista_doble_circular.cpp)
 * ============================================================================
 * Todas las funciones están vacías, solo tienen comentarios explicando qué
 * debes hacer y un 'return' temporal al final para que el proyecto compile.
 * Busca cada "// <--- PON TU CÓDIGO AQUÍ" y programa tu lógica.
 * ============================================================================
 */

ListaDobleCircular::ListaDobleCircular(const std::string& nombre) {
    // QUÉ DEBES HACER:
    // 1. Guardar el parámetro 'nombre' en el atributo 'nombrePlaylist'.
    // 2. Inicializar los punteros 'cabeza', 'cola' y 'actual' en nullptr.
    // 3. Inicializar 'tamano' en 0.
    // 4. Inicializar 'modoRepeticion' en ModoRepeticion::REPETIR_TODAS.

    // <--- PON TU CÓDIGO AQUÍ
}

ListaDobleCircular::~ListaDobleCircular() {
    // QUÉ DEBES HACER:
    // 1. Llamar a tu función limpiar() para liberar todos los nodos de memoria.

    // <--- PON TU CÓDIGO AQUÍ
}

std::string ListaDobleCircular::getNombre() const {
    // QUÉ DEBES HACER:
    // Retornar el atributo 'nombrePlaylist'.

    // <--- PON TU CÓDIGO AQUÍ

    return ""; // Retorno temporal (reemplázalo por: return nombrePlaylist;)
}

void ListaDobleCircular::renombrar(const std::string& nuevoNombre) {
    // QUÉ DEBES HACER:
    // Asignar 'nuevoNombre' al atributo 'nombrePlaylist'.

    // <--- PON TU CÓDIGO AQUÍ
}

int ListaDobleCircular::getTamano() const {
    // QUÉ DEBES HACER:
    // Retornar la cantidad de canciones ('tamano').

    // <--- PON TU CÓDIGO AQUÍ

    return 0; // Retorno temporal (reemplázalo por: return tamano;)
}

bool ListaDobleCircular::estaVacia() const {
    // QUÉ DEBES HACER:
    // Retornar true si 'cabeza == nullptr' (o si 'tamano == 0'), y false si tiene elementos.

    // <--- PON TU CÓDIGO AQUÍ

    return true; // Retorno temporal
}

void ListaDobleCircular::insertarAlInicio(const Cancion& cancion) {
    // QUÉ DEBES HACER:
    // 1. Crear un nuevo nodo: NodoDoble* nuevo = new NodoDoble(cancion);
    // 2. Si la lista está vacía:
    //    - cabeza = cola = actual = nuevo;
    //    - nuevo->siguiente = nuevo;
    //    - nuevo->anterior = nuevo;
    // 3. Si NO está vacía:
    //    - nuevo->siguiente = cabeza;
    //    - nuevo->anterior = cola;
    //    - cabeza->anterior = nuevo;
    //    - cola->siguiente = nuevo;
    //    - cabeza = nuevo;
    // 4. Incrementar 'tamano++'.

    // <--- PON TU CÓDIGO AQUÍ
}

void ListaDobleCircular::insertarAlFinal(const Cancion& cancion) {
    // QUÉ DEBES HACER:
    // 1. Crear un nuevo nodo: NodoDoble* nuevo = new NodoDoble(cancion);
    // 2. Si la lista está vacía, hacer lo mismo que en insertarAlInicio.
    // 3. Si NO está vacía:
    //    - Enlazar 'nuevo' después de 'cola' y antes de 'cabeza'.
    //    - Actualizar 'cola = nuevo'.
    // 4. Incrementar 'tamano++'.

    // <--- PON TU CÓDIGO AQUÍ
}

bool ListaDobleCircular::insertarEnPosicion(const Cancion& cancion, int posicion) {
    // QUÉ DEBES HACER:
    // 1. Validar que 0 <= posicion <= tamano (si no cumple, retornar false).
    // 2. Si posicion == 0: llamar a insertarAlInicio(cancion) y retornar true.
    // 3. Si posicion == tamano: llamar a insertarAlFinal(cancion) y retornar true.
    // 4. Si está en el medio:
    //    - Buscar el nodo actual en esa posición con obtenerNodoEn(posicion).
    //    - Crear el nuevo nodo y enlazarlo entre 'nodoActual->anterior' y 'nodoActual'.
    //    - Incrementar 'tamano++' y retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true cuando se inserte con éxito
}

bool ListaDobleCircular::eliminarAlInicio() {
    // QUÉ DEBES HACER:
    // 1. Si estaVacia() es true, retornar false.
    // 2. Guardar un puntero temporal al nodo a borrar: NodoDoble* borrar = cabeza;
    // 3. Si solo hay 1 nodo (cabeza == cola):
    //    - cabeza = cola = actual = nullptr;
    // 4. Si hay más de 1 nodo:
    //    - Si 'actual == cabeza', mover 'actual = cabeza->siguiente'.
    //    - cabeza = cabeza->siguiente;
    //    - cabeza->anterior = cola;
    //    - cola->siguiente = cabeza;
    // 5. Liberar memoria ('delete borrar;'), disminuir 'tamano--' y retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true si eliminó el nodo
}

bool ListaDobleCircular::eliminarAlFinal() {
    // QUÉ DEBES HACER:
    // 1. Si estaVacia() es true, retornar false.
    // 2. Si solo hay 1 nodo (cabeza == cola), llamar a eliminarAlInicio().
    // 3. Si hay más de 1 nodo:
    //    - Guardar NodoDoble* borrar = cola;
    //    - Si 'actual == cola', mover 'actual = cabeza'.
    //    - cola = cola->anterior;
    //    - cola->siguiente = cabeza;
    //    - cabeza->anterior = cola;
    //    - Hacer 'delete borrar;', disminuir 'tamano--' y retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true si eliminó el nodo
}

bool ListaDobleCircular::eliminarEnPosicion(int posicion) {
    // QUÉ DEBES HACER:
    // 1. Validar que 0 <= posicion < tamano (si no, retornar false).
    // 2. Si posicion == 0, retornar eliminarAlInicio().
    // 3. Si posicion == tamano - 1, retornar eliminarAlFinal().
    // 4. Si está en medio:
    //    - Ubicar el nodo con obtenerNodoEn(posicion).
    //    - Si 'actual' apunta a ese nodo, mover 'actual = borrar->siguiente'.
    //    - Conectar 'borrar->anterior->siguiente = borrar->siguiente'
    //      y 'borrar->siguiente->anterior = borrar->anterior'.
    //    - Hacer 'delete borrar;', disminuir 'tamano--' y retornar true.

    // <--- PON TU CÓDIGO AQUÍ

    return false; // Retorno temporal: devuelve true si eliminó el nodo
}

const Cancion* ListaDobleCircular::siguienteCancion() {
    // QUÉ DEBES HACER:
    // 1. Si 'actual == nullptr', retornar nullptr.
    // 2. Evaluar 'modoRepeticion':
    //    - Si es ModoRepeticion::REPETIR_UNA: no mover 'actual'.
    //    - Si es ModoRepeticion::REPETIR_TODAS: avanzar 'actual = actual->siguiente'.
    //    - Si es ModoRepeticion::SIN_REPETICION:
    //      si 'actual != cola', avanzar 'actual = actual->siguiente';
    //      si ya estaba en 'cola', retornar nullptr (fin de la lista).
    // 3. Retornar '&(actual->dato)'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal: devuelve puntero a la canción actual (&(actual->dato))
}

const Cancion* ListaDobleCircular::anteriorCancion() {
    // QUÉ DEBES HACER:
    // 1. Si 'actual == nullptr', retornar nullptr.
    // 2. Retroceder el cursor: actual = actual->anterior;
    // 3. Retornar '&(actual->dato)'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal: devuelve puntero a la canción actual (&(actual->dato))
}

const Cancion* ListaDobleCircular::obtenerCancionActual() const {
    // QUÉ DEBES HACER:
    // 1. Si 'actual == nullptr', retornar nullptr.
    // 2. Si no es nulo, retornar '&(actual->dato)'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal: devuelve &(actual->dato)
}

void ListaDobleCircular::setModoRepeticion(ModoRepeticion nuevoModo) {
    // QUÉ DEBES HACER:
    // Asignar 'nuevoModo' al atributo 'modoRepeticion'.

    // <--- PON TU CÓDIGO AQUÍ
}

ModoRepeticion ListaDobleCircular::getModoRepeticion() const {
    // QUÉ DEBES HACER:
    // Retornar el atributo 'modoRepeticion'.

    // <--- PON TU CÓDIGO AQUÍ

    return ModoRepeticion::REPETIR_TODAS; // Retorno temporal
}

NodoDoble* ListaDobleCircular::obtenerNodoEn(int posicion) const {
    // QUÉ DEBES HACER:
    // 1. Validar que 0 <= posicion < tamano (si no, retornar nullptr).
    // 2. Empezar en 'NodoDoble* temp = cabeza;' y avanzar 'posicion' veces con 'temp = temp->siguiente'.
    // 3. Retornar 'temp'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal: devuelve el puntero al nodo en esa posición
}

NodoDoble* ListaDobleCircular::getCabeza() const {
    // QUÉ DEBES HACER:
    // Retornar el puntero 'cabeza'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal (reemplázalo por: return cabeza;)
}

NodoDoble* ListaDobleCircular::getCola() const {
    // QUÉ DEBES HACER:
    // Retornar el puntero 'cola'.

    // <--- PON TU CÓDIGO AQUÍ

    return nullptr; // Retorno temporal (reemplázalo por: return cola;)
}

int ListaDobleCircular::calcularDuracionTotalSegundos() const {
    // QUÉ DEBES HACER:
    // 1. Si estaVacia() es true, retornar 0.
    // 2. Recorrer exactamente 'tamano' nodos empezando en 'cabeza',
    //    acumulando 'temp->dato.getDuracionSegundos()'.
    // 3. Retornar la suma total en segundos.

    // <--- PON TU CÓDIGO AQUÍ

    return 0; // Retorno temporal: devuelve la suma total de segundos de la playlist
}

void ListaDobleCircular::mostrar() const {
    // QUÉ DEBES HACER:
    // 1. Imprimir el nombre de la playlist ('nombrePlaylist') y su tamaño ('tamano').
    // 2. Si está vacía, imprimir "[Playlist vacía]".
    // 3. Si tiene canciones, recorrer 'tamano' veces desde 'cabeza':
    //    - Si el nodo coincide con 'actual', puedes imprimir un indicador ">> [Reproduciendo]"
    //    - Llamar a 'temp->dato.mostrar()' (método ya creado por Andrea).

    // <--- PON TU CÓDIGO AQUÍ
}

void ListaDobleCircular::limpiar() {
    // QUÉ DEBES HACER:
    // 1. Si estaVacia() es true, salir con return.
    // 2. ¡CUIDADO CON EL BUCLE INFINITO! Como es circular, recorre con un contador:
    //    NodoDoble* temp = cabeza;
    //    for (int i = 0; i < tamano; ++i) {
    //        NodoDoble* sig = temp->siguiente;
    //        delete temp;
    //        temp = sig;
    //    }
    // 3. Dejar cabeza = cola = actual = nullptr; y tamano = 0;

    // <--- PON TU CÓDIGO AQUÍ
}

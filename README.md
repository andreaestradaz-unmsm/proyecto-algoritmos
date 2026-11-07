# Proyecto 2: Reproductor de Música con Listas de Reproducción

**Universidad Nacional Mayor de San Marcos (UNMSM)**  
**Facultad de Ingeniería de Sistemas e Informática — E.P. Ciencia de la Computación**  
**Curso:** Algoritmos y Estructuras de Datos (`CC0401`) · Semestre 2026-II  
**Docente:** Luis Ángel Guerra Grados (G2)

---

## 0. Requisitos: lo que necesitas tener instalado

> [!WARNING]
> **Sin un compilador de C++ el proyecto NO se puede ejecutar.**
> El código C++ no se ejecuta directamente: primero hay que *compilarlo* (convertirlo en un `.exe`). Para eso necesitas tener instalado **`g++`**. Si al compilar te sale `"g++" no se reconoce como un comando...`, es porque te falta instalarlo (ver tabla abajo).

| ¿Qué? | ¿Es obligatorio? | ¿Para qué sirve? |
| :--- | :--- | :--- |
| **g++** (compilador de C++, versión con C++17 / GCC 8 o superior) | ✅ **Sí, obligatorio** | Convierte el código en un programa ejecutable |
| `mingw32-make` / `make` | ⬜ Opcional | Solo si quieres compilar con el `Makefile` (viene incluido con g++ en Windows) |
| Librerías externas | ❌ **No se necesitan** | El proyecto solo usa la biblioteca estándar de C++ (`<string>`, `<iostream>`, `<fstream>`, `<random>`), que ya viene con el compilador |

> [!NOTE]
> No hace falta un `requirements.txt`: ese archivo es de Python (`pip`). En C++ no se descargan paquetes; basta con tener `g++`.

### Cómo instalar `g++` (una sola vez)

**Windows** — abre PowerShell y ejecuta:
```bash
winget install BrechtSanders.WinLibs.POSIX.UCRT
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install g++ make
```

**macOS:**
```bash
xcode-select --install
```

> [!IMPORTANT]
> Después de instalar, **cierra y vuelve a abrir la terminal** (y el editor, si lo tenías abierto). Luego comprueba que quedó instalado con:
> ```bash
> g++ --version
> ```
> Si aparece un texto con la versión (por ejemplo `g++.exe (MinGW-W64 ...) 16.2.0`), ya está listo.

---

## Cómo correr el proyecto (paso a paso)

**Paso 1 — Descargar el proyecto** (clonarlo desde el repositorio o copiar la carpeta):
```bash
git clone <URL-del-repositorio>
cd proyecto-algoritmos
```

**Paso 2 — Abrir una terminal dentro de la carpeta del proyecto.**
En el explorador de Windows: entra a la carpeta, escribe `powershell` en la barra de direcciones y presiona Enter. (En VS Code / Antigravity: menú *Terminal → Nueva terminal*).

**Paso 3 — Compilar y ejecutar.** Elige **una** de estas opciones:

**Opción A — La más fácil (Windows):** doble clic en **`compilar.bat`**, o en la terminal:
```bash
.\compilar.bat
```
Compila y ejecuta el programa de una vez. Si falta `g++`, te avisa cómo instalarlo.

**Opción B — Con `g++` directamente (Windows, Linux o macOS):**
```bash
g++ -std=c++17 -Wall -Wextra -Wno-unused-parameter main.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp -o reproductor
```
Y luego para ejecutarlo:
```bash
.\reproductor.exe     # Windows
./reproductor         # Linux / macOS
```

**Opción C — Con el `Makefile` (opcional):**
```bash
mingw32-make          # Windows: compila
mingw32-make run      # Windows: compila y ejecuta
mingw32-make clean    # Windows: borra los archivos compilados

make                  # Linux / macOS / MSYS2 (mismo uso: make run, make clean)
```

**Resultado esperado:** en la consola debe aparecer la tabla **"BIBLIOTECA GENERAL DE CANCIONES"** con 5 canciones y su duración total.

### Problemas comunes

| Error | Causa | Solución |
| :--- | :--- | :--- |
| `"g++" no se reconoce como un comando` | No está instalado `g++` o no reiniciaste la terminal | Instálalo (ver arriba) y abre una terminal nueva |
| `"make" no se reconoce como un comando` | En Windows el comando se llama distinto | Usa `mingw32-make`, o usa `compilar.bat` |
| `undefined reference to ...` | Falta algún `.cpp` en el comando de compilación | Copia el comando completo de la Opción B (incluye los 6 archivos `.cpp`) |
| No aparecen tus canciones guardadas (sale la lista inicial de 5) | Ejecutaste el programa desde otra carpeta y no encontró `biblioteca.csv` | Ejecuta el programa estando dentro de la carpeta del proyecto |

---

## 1. ¿Qué archivo debe tocar cada integrante del equipo?

En la carpeta del proyecto **ya están creados todos los archivos** para que nadie tenga que crear archivos desde cero ni adivinar nombres de funciones:

| Integrante | Archivos que **NO** debes tocar (solo leer) | Archivo donde **SÍ** debes programar | Estado |
| :--- | :--- | :--- | :--- |
| **Andrea** | — | `cancion.h`, `cancion.cpp`, `lista_simple.h`, `lista_simple.cpp`, `Makefile` | **100% Terminado** |
| **Jeick** | `lista_doble_circular.h` *(Solo declara nombres)* | **`lista_doble_circular.cpp`** | Con comentarios guía y `// <--- PON TU CÓDIGO AQUÍ` |
| **Juan Pablo** | `reproduccion.h` *(Solo declara nombres)* | **`reproduccion.cpp`** | Con comentarios guía y `// <--- PON TU CÓDIGO AQUÍ` |
| **Jeremy** | `ui.h` *(Solo declara nombres)* | **`ui.cpp`** y activar en **`main.cpp`** | Con comentarios guía y `// <--- PON TU CÓDIGO AQUÍ` |

---

## 2. ¿Cómo trabajan Jeick, Juan Pablo y Jeremy en sus archivos `.cpp`?

Cada uno solo debe abrir su archivo `.cpp` asignado:
- **Jeick** abre **`lista_doble_circular.cpp`**
- **Juan Pablo** abre **`reproduccion.cpp`**
- **Jeremy** abre **`ui.cpp`**

Dentro de esos tres archivos `.cpp` **no hay código hecho**: cada función tiene únicamente:
1. **`// QUÉ DEBES HACER:`** explicando paso a paso qué debe programar en esa función.
2. **`// <--- PON TU CÓDIGO AQUÍ`** indicando el lugar exacto donde debe escribir su código.
3. Un **`return` temporal** al final (por ejemplo `return false;`, `return nullptr;` o `return 0;`) que solo está puesto para que el proyecto compile sin dar error mientras van avanzando, y que deben cambiar por su retorno real.

### Ejemplo de cómo se ve una función dentro de `lista_doble_circular.cpp` (Jeick):
```cpp
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
```

---

## 3. ¿Cómo se conectan las partes de todos?

1. **Parte de Andrea (`Cancion` y `ListaSimple`):**
   - Guarda y carga automáticamente las canciones desde `biblioteca.csv`.
   - Ofrece funciones listas para usar como `cancion.mostrar()`, `cancion.aCSV()`, `Cancion::desdeCSV()`, `biblioteca.agregarAlFinal()`, `biblioteca.buscarPorId()` y `historial.agregarAlInicio()`.

2. **Parte de Jeick (`lista_doble_circular.cpp`):**
   - Programa los nodos dobles (`siguiente` y `anterior`) de una Playlist circular (`cola->siguiente == cabeza`).
   - Programa insertar/eliminar al inicio, al final y en una posición, y avanzar/retroceder canción (`siguienteCancion()`, `anteriorCancion()`).

3. **Parte de Juan Pablo (`reproduccion.cpp`):**
   - Usa los métodos de la lista de Jeick (`obtenerNodoEn`, `eliminarEnPosicion`, `insertarEnPosicion`, `insertarAlFinal`) para programar el **Shuffle de Fisher-Yates**, **mover una canción** de posición y **fusionar dos listas**.
   - Usa la `ListaSimple` de Andrea para guardar cada canción reproducida en el `historial`.

4. **Parte de Jeremy (`ui.cpp` y `main.cpp`):**
   - Programa los menús en consola llamando a las funciones de Andrea, Jeick y Juan Pablo.
   - Cuando todo el equipo termine su `.cpp`, Jeremy abre `main.cpp` y descomenta las dos líneas finales:
     ```cpp
     InterfazConsola app;
     app.iniciar();
     ```

---

## 4. Avisos rojos en el editor (`'crtdbg.h' file not found`)

Si el editor marca en rojo un `#include <string>` o `#include <iostream>` con el mensaje `'crtdbg.h' file not found`, **no es un error del código** (el proyecto compila bien con `g++`). Es el analizador del editor (clangd), que por defecto busca los headers de Visual Studio.

El archivo **`.clangd`** de la raíz del proyecto ya lo corrige indicándole que use los headers de MinGW (`g++`). Ese archivo **solo lo lee el editor**: no interviene al compilar ni al ejecutar, y si alguien no usa clangd simplemente se ignora. Solo tienes que:
1. Tener `g++` (MinGW) instalado y en el `PATH`.
2. Reiniciar el analizador: `Ctrl+Shift+P` → **"clangd: Restart language server"**.

> No borres ni modifiques el archivo `.clangd`; súbanlo al repositorio para que a todos les funcione igual.

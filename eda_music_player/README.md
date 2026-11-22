# EDA Music Player

Aplicacion Flutter desarrollada para el proyecto **Reproductor de Musica con Listas de Reproduccion** del curso **Algoritmos y Estructuras de Datos (CC0401)** de la UNMSM.

Actualmente, la aplicacion utiliza un repositorio de musica de ejemplo cargado en memoria. Permite explorar las canciones disponibles, iniciar la reproduccion, avanzar o retroceder, buscar canciones y consultar el historial.

## Requisitos

Instala antes de abrir el proyecto:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) estable, incluido el SDK de Dart.
- Git.
- Visual Studio Code con las extensiones **Flutter** y **Dart**, o Android Studio.
- Una opcion para ejecutar la aplicacion:
  - Chrome para Web.
  - Un emulador o telefono con Android.
  - Un entorno habilitado para Windows, Linux o macOS.

Comprueba la instalacion:

```bash
flutter --version
flutter doctor
```

La salida de `flutter doctor` puede mostrar advertencias, pero no debe haber errores para el dispositivo que quieras utilizar.

## Obtener el proyecto

Desde GitHub:

```bash
git clone https://github.com/andreaestradaz-unmsm/proyecto-algoritmos.git
cd proyecto-algoritmos/eda_music_player
```

Si ya tienes el repositorio, abre una terminal en la carpeta `proyecto-algoritmos` y entra a la aplicacion Flutter:

```bash
cd eda_music_player
```

## Abrir el proyecto en Visual Studio Code

1. Abre Visual Studio Code.
2. Selecciona **Archivo > Abrir carpeta**.
3. Abre la carpeta `eda_music_player` (la que contiene `pubspec.yaml`).
4. Cuando VS Code reconozca Flutter, abre `lib/main.dart`.
5. Instala las dependencias desde la terminal:

```bash
flutter pub get
```

## Ejecutar la aplicacion

### Recomendado: terminal

Primero muestra los dispositivos disponibles:

```bash
flutter devices
```

Luego ejecuta en el dispositivo que desees:

```bash
flutter run
```

Para elegir explicitamente un dispositivo:

```bash
flutter run -d <device-id>
```

Ejemplos:

```bash
# Navegador Chrome
flutter run -d chrome

# Emulador o telefono Android
flutter run -d android

# Aplicacion de escritorio Linux
flutter run -d linux

# Aplicacion de escritorio Windows
flutter run -d windows

# Aplicacion de escritorio macOS
flutter run -d macos
```

En el dispositivo conectado, espera a que aparezca la pantalla principal del reproductor.

### Desde VS Code

1. Selecciona un dispositivo en la barra inferior de VS Code.
2. Abre `lib/main.dart`.
3. Pulsa **F5** o utiliza **Run > Start Debugging**.
4. Tambien puedes hacer clic en el boton de **Run** situado sobre el metodo `main`.

Durante el modo de depuracion:

- Guarda un archivo para aplicar cambios en caliente.
- Pulsa `r` en la terminal para **hot reload**.
- Pulsa `R` en la terminal para reiniciar completamente la aplicacion.
- Pulsa `q` en la terminal para detenerla.

## Construir una version lista para publicar

Navegador web:

```bash
flutter build web
```

Android:

```bash
flutter build apk
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`.

Linux:

```bash
flutter build linux
```

Windows:

```bash
flutter build windows
```

Los archivos generados se guardan dentro de `build/` y no deben subirse a GitHub.

## Comandos utiles

```bash
# Descargar o actualizar paquetes
flutter pub get

# Buscar problemas y avisos
flutter analyze

# Ejecutar las pruebas
flutter test

# Limpiar archivos generados
flutter clean
flutter pub get
```

## Problemas frecuentes

| Problema | Solucion |
|---|---|
| `flutter: command not found` | Instala Flutter y agrega su carpeta `bin` al `PATH`. Abre una terminal nueva. |
| No aparecen dispositivos | En Android abre un emulador o activa la depuracion USB. En Web usa `flutter run -d chrome`. |
| `flutter pub get` falla | Comprueba la conexion a Internet y ejecuta `flutter clean`, luego vuelve a ejecutar `flutter pub get`. |
| El emulador no inicia | Ejecuta `flutter doctor -v` y configura las herramientas Android indicadas por Flutter. |
| El analisis de VS Code no reconoce los paquetes | Ejecuta `flutter pub get` y usa **Dart: Restart Analysis Server** desde la paleta de comandos. |
| Android pide SDK, NDK o permisos | Acepta las herramientas recomendadas desde Android Studio o ejecuta `flutter doctor -v` para ver que falta. |

## Estructura principal

```text
eda_music_player/
├── lib/
│   ├── main.dart              # Punto de entrada de la aplicacion
│   ├── app/                   # Tema y configuracion visual
│   ├── models/                # Modelos de canciones y reproduccion
│   ├── screens/               # Pantallas de la aplicacion
│   ├── services/              # Controlador y repositorio de musica
│   └── widgets/               # Componentes reutilizables
├── assets/                    # Recursos graficos
├── test/                      # Pruebas Flutter
├── pubspec.yaml               # Dependencias y recursos
└── README.md
```

## Git y archivos locales

Antes de subir cambios:

```bash
git status
git add .
git commit -m "Describe tu cambio"
git push
```

No subas archivos generados ni configuracion personal. La raiz del repositorio ya incluye reglas para ignorar compilados C++, artefactos de Flutter, configuraciones locales de Android/iOS y claves o secretos.

@echo off
REM ==========================================================================
REM  compilar.bat - Compila y ejecuta el proyecto en Windows con un doble clic.
REM  Requisito unico: tener g++ (MinGW) instalado. Ver README, seccion 0.
REM ==========================================================================

where g++ >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No se encontro g++. Instalalo con:
    echo     winget install BrechtSanders.WinLibs.POSIX.UCRT
    echo y luego cierra y vuelve a abrir la terminal.
    pause
    exit /b 1
)

echo Compilando...
g++ -std=c++17 -Wall -Wextra -Wno-unused-parameter main.cpp cancion.cpp lista_simple.cpp lista_doble_circular.cpp reproduccion.cpp ui.cpp -o reproductor.exe
if errorlevel 1 (
    echo.
    echo [ERROR] La compilacion fallo. Revisa los mensajes de arriba.
    pause
    exit /b 1
)

echo [OK] Compilado. Ejecutando...
echo.
reproductor.exe
pause


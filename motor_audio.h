#ifndef MOTOR_AUDIO_H
#define MOTOR_AUDIO_H

#include "cancion.h"
#include "lista_doble_circular.h"

#include <string>
#include <chrono>

struct ma_engine;
struct ma_sound;

// Estado dinamico de la reproduccion en curso
struct EstadoReproduccionActual {
    int idCancionActiva;
    std::string rutaArchivo;
    bool isPlaying;
    int posicionActualSegundos;
    int duracionTotalSegundos;
    double volumen;
    ModoRepeticion modoRepeticion;

    EstadoReproduccionActual()
        : idCancionActiva(0),
          rutaArchivo(""),
          isPlaying(false),
          posicionActualSegundos(0),
          duracionTotalSegundos(0),
          volumen(1.0),
          modoRepeticion(ModoRepeticion::REPETIR_TODAS) {}
};

// Motor de audio multimedia basado en miniaudio
class MotorAudio {
private:
    ma_engine* pEngine;
    ma_sound* pSound;
    bool engineInicializado;
    bool soundCargado;
    bool modoSimulado;
    bool cancionTerminada;

    EstadoReproduccionActual estado;
    std::chrono::steady_clock::time_point tiempoInicioSimulado;
    int segundosBaseSimulado;

public:
    MotorAudio();
    ~MotorAudio();

    // Inicializa el dispositivo de audio nativo
    bool inicializar();

    // Libera los recursos del motor de audio
    void liberar();

    // Carga e inicia la reproduccion de una cancion
    bool play(const Cancion& cancion);

    // Pausa la reproduccion conservando la posicion
    void pause();

    // Reanuda la reproduccion pausada
    void resume();

    // Detiene la reproduccion y reinicia el cursor a 0
    void stop();

    // Cambia la posicion actual al segundo especificado
    void seekTo(int segundos);

    // Ajusta la ganancia de volumen (0.0 a 1.0)
    void setVolume(double volumen);

    // Retorna el segundo actual de reproduccion
    int getPosicionActualSegundos() const;

    // Retorna la duracion total en segundos
    int getDuracionTotalSegundos() const;

    // Retorna el progreso normalizado de 0.0 a 1.0
    double getProgreso() const;

    // Retorna el tiempo transcurrido en formato "MM:SS"
    std::string getTiempoTranscurridoFormateado() const;

    // Retorna el tiempo restante en formato "-MM:SS"
    std::string getTiempoRestanteFormateado() const;

    // Indica si el motor esta reproduciendo audio
    bool isPlaying() const;

    // Retorna el volumen actual (0.0 a 1.0)
    double getVolume() const;

    // Configura el modo de repeticion
    void setModoRepeticion(ModoRepeticion nuevoModo);

    // Retorna el modo de repeticion configurado
    ModoRepeticion getModoRepeticion() const;

    // Retorna una copia del estado dinamico de reproduccion
    EstadoReproduccionActual getEstadoActual() const;

    // Sincroniza el cursor de tiempo con el dispositivo de audio o el reloj
    void sincronizarEstado();

    // Indica si la cancion actual ha concluido
    bool haTerminadoCancion() const;
};

#endif // MOTOR_AUDIO_H

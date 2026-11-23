#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "motor_audio.h"

#include <filesystem>
#include <algorithm>

namespace fs = std::filesystem;

// Constructor: reserva estructuras internas e intenta inicializar el dispositivo de audio
MotorAudio::MotorAudio()
    : pEngine(nullptr),
      pSound(nullptr),
      engineInicializado(false),
      soundCargado(false),
      modoSimulado(true),
      cancionTerminada(false),
      segundosBaseSimulado(0) {
    pEngine = new ma_engine();
    pSound = new ma_sound();
    // inicializar();
}

// Destructor: detiene el sonido y libera la memoria de miniaudio
MotorAudio::~MotorAudio() {
    liberar();
    if (pSound != nullptr) {
        delete pSound;
        pSound = nullptr;
    }
    if (pEngine != nullptr) {
        delete pEngine;
        pEngine = nullptr;
    }
}

// Inicializa el motor de audio nativo del sistema operativo
bool MotorAudio::inicializar() {
    if (engineInicializado) return true;
    ma_result res = ma_engine_init(NULL, pEngine);
    if (res == MA_SUCCESS) {
        engineInicializado = true;
        ma_engine_set_volume(pEngine, static_cast<float>(estado.volumen));
        return true;
    }
    engineInicializado = false;
    return false;
}

// Detiene la reproduccion y desvincula los recursos nativos
void MotorAudio::liberar() {
    if (soundCargado && pSound != nullptr) {
        ma_sound_stop(pSound);
        ma_sound_uninit(pSound);
        soundCargado = false;
    }
    if (engineInicializado && pEngine != nullptr) {
        ma_engine_uninit(pEngine);
        engineInicializado = false;
    }
    estado.isPlaying = false;
    estado.posicionActualSegundos = 0;
    segundosBaseSimulado = 0;
    cancionTerminada = false;
}

// Carga e inicia la pista multimedia (o activa el reloj simulado si el archivo no existe)
bool MotorAudio::play(const Cancion& cancion) {
    if (!engineInicializado) {
        inicializar();
    }

    estado.idCancionActiva = cancion.getId();
    estado.rutaArchivo = cancion.getRutaArchivo();
    estado.duracionTotalSegundos = cancion.getDuracionSegundos();
    estado.posicionActualSegundos = 0;
    cancionTerminada = false;

    bool audioRealCargado = false;
    if (engineInicializado && !estado.rutaArchivo.empty()) {
        try {
            if (fs::exists(estado.rutaArchivo)) {
                ma_result res = ma_sound_init_from_file(pEngine, estado.rutaArchivo.c_str(), 0, NULL, NULL, pSound);
                if (res == MA_SUCCESS) {
                    soundCargado = true;
                    ma_sound_set_volume(pSound, static_cast<float>(estado.volumen));

                    float lenSec = 0.0f;
                    if (ma_sound_get_length_in_seconds(pSound, &lenSec) == MA_SUCCESS && lenSec > 0.0f) {
                        estado.duracionTotalSegundos = static_cast<int>(lenSec);
                    }

                    ma_sound_start(pSound);
                    audioRealCargado = true;
                    modoSimulado = false;
                }
            }
        } catch (...) {
            audioRealCargado = false;
        }
    }

    if (!audioRealCargado) {
        modoSimulado = true;
        tiempoInicioSimulado = std::chrono::steady_clock::now();
        segundosBaseSimulado = 0;
    }

    estado.isPlaying = true;
    return true;
}

// Pausa la reproduccion actual
void MotorAudio::pause() {
    sincronizarEstado();
    if (soundCargado && pSound != nullptr) {
        ma_sound_stop(pSound);
    }
    if (modoSimulado) {
        segundosBaseSimulado = estado.posicionActualSegundos;
    }
    estado.isPlaying = false;
}

// Reanuda la reproduccion pausada
void MotorAudio::resume() {
    if (soundCargado && pSound != nullptr) {
        ma_sound_start(pSound);
    }
    if (modoSimulado) {
        tiempoInicioSimulado = std::chrono::steady_clock::now();
    }
    estado.isPlaying = true;
}

// Detiene la reproduccion y regresa el cursor a 0
void MotorAudio::stop() {
    if (soundCargado && pSound != nullptr) {
        ma_sound_stop(pSound);
        ma_sound_seek_to_pcm_frame(pSound, 0);
    }
    estado.isPlaying = false;
    estado.posicionActualSegundos = 0;
    segundosBaseSimulado = 0;
    cancionTerminada = false;
}

// Salta a la posicion especificada en segundos
void MotorAudio::seekTo(int segundos) {
    int maxDur = estado.duracionTotalSegundos > 0 ? estado.duracionTotalSegundos : 0;
    int clamped = segundos;
    if (clamped < 0) clamped = 0;
    if (clamped > maxDur && maxDur > 0) clamped = maxDur;

    estado.posicionActualSegundos = clamped;

    if (soundCargado && pSound != nullptr) {
        ma_uint32 sampleRate = 0;
        ma_sound_get_data_format(pSound, NULL, NULL, &sampleRate, NULL, 0);
        if (sampleRate > 0) {
            ma_uint64 targetFrame = static_cast<ma_uint64>(clamped) * sampleRate;
            ma_sound_seek_to_pcm_frame(pSound, targetFrame);
        }
    }

    if (modoSimulado) {
        segundosBaseSimulado = clamped;
        tiempoInicioSimulado = std::chrono::steady_clock::now();
    }

    cancionTerminada = false;
}

// Configura el volumen acotado entre 0.0 y 1.0
void MotorAudio::setVolume(double volumen) {
    double v = volumen;
    if (v < 0.0) v = 0.0;
    if (v > 1.0) v = 1.0;
    estado.volumen = v;

    if (soundCargado && pSound != nullptr) {
        ma_sound_set_volume(pSound, static_cast<float>(v));
    }
    if (engineInicializado && pEngine != nullptr) {
        ma_engine_set_volume(pEngine, static_cast<float>(v));
    }
}

// Retorna el segundo actual de reproduccion
int MotorAudio::getPosicionActualSegundos() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    return estado.posicionActualSegundos;
}

// Retorna la duracion total en segundos
int MotorAudio::getDuracionTotalSegundos() const {
    return estado.duracionTotalSegundos;
}

// Retorna el progreso normalizado de 0.0 a 1.0
double MotorAudio::getProgreso() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    if (estado.duracionTotalSegundos <= 0) return 0.0;
    double p = static_cast<double>(estado.posicionActualSegundos) / static_cast<double>(estado.duracionTotalSegundos);
    if (p < 0.0) p = 0.0;
    if (p > 1.0) p = 1.0;
    return p;
}

// Retorna el tiempo transcurrido en formato "MM:SS"
std::string MotorAudio::getTiempoTranscurridoFormateado() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    Cancion c(0, "", "", estado.posicionActualSegundos, "");
    return c.obtenerDuracionFormateada();
}

// Retorna el tiempo restante en formato "-MM:SS"
std::string MotorAudio::getTiempoRestanteFormateado() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    int restante = estado.duracionTotalSegundos - estado.posicionActualSegundos;
    if (restante < 0) restante = 0;
    Cancion c(0, "", "", restante, "");
    return "-" + c.obtenerDuracionFormateada();
}

// Indica si el motor esta reproduciendo
bool MotorAudio::isPlaying() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    return estado.isPlaying;
}

// Retorna el volumen actual
double MotorAudio::getVolume() const {
    return estado.volumen;
}

// Asigna el modo de repeticion
void MotorAudio::setModoRepeticion(ModoRepeticion nuevoModo) {
    estado.modoRepeticion = nuevoModo;
}

// Retorna el modo de repeticion
ModoRepeticion MotorAudio::getModoRepeticion() const {
    return estado.modoRepeticion;
}

// Retorna una instantanea del estado de reproduccion
EstadoReproduccionActual MotorAudio::getEstadoActual() const {
    const_cast<MotorAudio*>(this)->sincronizarEstado();
    return estado;
}

// Sincroniza la posicion actual consultando el cursor PCM o el cronometro
void MotorAudio::sincronizarEstado() {
    if (soundCargado && pSound != nullptr) {
        float curSec = 0.0f;
        if (ma_sound_get_cursor_in_seconds(pSound, &curSec) == MA_SUCCESS) {
            estado.posicionActualSegundos = static_cast<int>(curSec);
        }
        if (ma_sound_at_end(pSound)) {
            estado.isPlaying = false;
            estado.posicionActualSegundos = estado.duracionTotalSegundos;
            cancionTerminada = true;
        }
    } else if (modoSimulado && estado.isPlaying) {
        auto ahora = std::chrono::steady_clock::now();
        auto segs = std::chrono::duration_cast<std::chrono::seconds>(ahora - tiempoInicioSimulado).count();
        int actual = segundosBaseSimulado + static_cast<int>(segs);
        if (estado.duracionTotalSegundos > 0 && actual >= estado.duracionTotalSegundos) {
            estado.posicionActualSegundos = estado.duracionTotalSegundos;
            estado.isPlaying = false;
            cancionTerminada = true;
        } else {
            estado.posicionActualSegundos = actual;
        }
    }
}

// Indica si la cancion termino su reproduccion
bool MotorAudio::haTerminadoCancion() const {
    return cancionTerminada;
}

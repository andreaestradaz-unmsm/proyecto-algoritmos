#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cassert>
#include <cmath>
#include <filesystem>

#include "cancion.h"
#include "motor_audio.h"
#include "extractor_metadata.h"
#include "lista_doble_circular.h"

namespace fs = std::filesystem;

// ============================================================================
// Macro simple de asercion con salida amigable
// ============================================================================
static int totalPruebas = 0;
static int pruebasPasadas = 0;

#define VERIFICAR(cond, desc) do { \
    totalPruebas++; \
    if (cond) { \
        pruebasPasadas++; \
        std::cout << "  [ok]    " << desc << "\n"; \
    } else { \
        std::cout << "  [FAIL]  " << desc << " (Linea: " << __LINE__ << ")\n"; \
    } \
} while(0)

static void grupo(const std::string& nombre) {
    std::cout << "\n=== " << nombre << " ===\n";
}

// ============================================================================
// Generadores de archivos de prueba de audio sintetico
// ============================================================================

// Crea un archivo .wav valido PCM de 3 segundos (44100 Hz, 16 bits, estereo)
static bool crearArchivoWavPrueba(const std::string& ruta, int duracionSegundos = 3) {
    std::ofstream f(ruta, std::ios::binary);
    if (!f.is_open()) return false;

    uint32_t sampleRate = 44100;
    uint16_t numChannels = 2;
    uint16_t bitsPerSample = 16;
    uint32_t byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    uint16_t blockAlign = numChannels * (bitsPerSample / 8);
    uint32_t dataSize = byteRate * duracionSegundos;
    uint32_t chunkSize = 36 + dataSize;

    // RIFF Header
    f.write("RIFF", 4);
    f.write(reinterpret_cast<const char*>(&chunkSize), 4);
    f.write("WAVE", 4);

    // fmt subchunk
    f.write("fmt ", 4);
    uint32_t sub1Size = 16;
    uint16_t audioFormat = 1; // PCM
    f.write(reinterpret_cast<const char*>(&sub1Size), 4);
    f.write(reinterpret_cast<const char*>(&audioFormat), 2);
    f.write(reinterpret_cast<const char*>(&numChannels), 2);
    f.write(reinterpret_cast<const char*>(&sampleRate), 4);
    f.write(reinterpret_cast<const char*>(&byteRate), 4);
    f.write(reinterpret_cast<const char*>(&blockAlign), 2);
    f.write(reinterpret_cast<const char*>(&bitsPerSample), 2);

    // data subchunk
    f.write("data", 4);
    f.write(reinterpret_cast<const char*>(&dataSize), 4);

    // Datos PCM (onda senoidal suave de 440 Hz)
    for (uint32_t i = 0; i < sampleRate * duracionSegundos; ++i) {
        double t = static_cast<double>(i) / sampleRate;
        int16_t sample = static_cast<int16_t>(10000.0 * std::sin(2.0 * 3.1415926535 * 440.0 * t));
        f.write(reinterpret_cast<const char*>(&sample), 2);
        f.write(reinterpret_cast<const char*>(&sample), 2);
    }

    f.close();
    return true;
}

// Crea un archivo simulado .mp3 con cabecera ID3v2.3 valida y frame APIC
static bool crearArchivoMp3ConID3v2(const std::string& ruta,
                                    const std::string& titulo,
                                    const std::string& artista,
                                    const std::string& genero,
                                    int duracionMs) {
    std::ofstream f(ruta, std::ios::binary);
    if (!f.is_open()) return false;

    // Construir frames ID3v2
    std::vector<uint8_t> frames;

    auto agregarFrameTexto = [&](const char* id, const std::string& texto) {
        frames.push_back(id[0]); frames.push_back(id[1]);
        frames.push_back(id[2]); frames.push_back(id[3]);

        uint32_t sz = 1 + texto.size();
        frames.push_back((sz >> 24) & 0xFF);
        frames.push_back((sz >> 16) & 0xFF);
        frames.push_back((sz >> 8) & 0xFF);
        frames.push_back(sz & 0xFF);

        frames.push_back(0); frames.push_back(0); // flags
        frames.push_back(0); // encoding ISO-8859-1
        for (char c : texto) frames.push_back(static_cast<uint8_t>(c));
    };

    agregarFrameTexto("TIT2", titulo);
    agregarFrameTexto("TPE1", artista);
    agregarFrameTexto("TCON", genero);
    agregarFrameTexto("TLEN", std::to_string(duracionMs));

    // Frame APIC con bytes JPEG simulados
    std::vector<uint8_t> dummyJpeg = { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0x00, 0x01, 0xFF, 0xD9 };
    std::string mime = "image/jpeg";
    std::string desc = "Front";

    frames.push_back('A'); frames.push_back('P'); frames.push_back('I'); frames.push_back('C');
    uint32_t apicSize = 1 + (mime.size() + 1) + 1 + (desc.size() + 1) + dummyJpeg.size();
    frames.push_back((apicSize >> 24) & 0xFF);
    frames.push_back((apicSize >> 16) & 0xFF);
    frames.push_back((apicSize >> 8) & 0xFF);
    frames.push_back(apicSize & 0xFF);
    frames.push_back(0); frames.push_back(0); // flags

    frames.push_back(0); // encoding
    for (char c : mime) frames.push_back(static_cast<uint8_t>(c));
    frames.push_back(0); // null term
    frames.push_back(3); // picture type = Cover (front)
    for (char c : desc) frames.push_back(static_cast<uint8_t>(c));
    frames.push_back(0); // null term
    frames.insert(frames.end(), dummyJpeg.begin(), dummyJpeg.end());

    // Cabecera ID3v2.3: 10 bytes
    uint8_t header[10] = { 'I', 'D', '3', 3, 0, 0, 0, 0, 0, 0 };
    uint32_t tagSize = frames.size();
    header[6] = (tagSize >> 21) & 0x7F;
    header[7] = (tagSize >> 14) & 0x7F;
    header[8] = (tagSize >> 7) & 0x7F;
    header[9] = tagSize & 0x7F;

    f.write(reinterpret_cast<const char*>(header), 10);
    f.write(reinterpret_cast<const char*>(frames.data()), frames.size());

    // Payload simulado de audio MP3 (syncword 0xFFFB)
    uint8_t mp3Frame[4] = { 0xFF, 0xFB, 0x90, 0x64 };
    for (int i = 0; i < 20; ++i) {
        f.write(reinterpret_cast<const char*>(mp3Frame), 4);
        std::vector<uint8_t> dummyData(414, 0x55);
        f.write(reinterpret_cast<const char*>(dummyData.data()), dummyData.size());
    }

    f.close();
    return true;
}

// Crea un archivo simulado .flac con bloques STREAMINFO, VORBIS_COMMENT y PICTURE
static bool crearArchivoFlacPrueba(const std::string& ruta,
                                   const std::string& titulo,
                                   const std::string& artista,
                                   const std::string& genero,
                                   int duracionSegundos = 120) {
    std::ofstream f(ruta, std::ios::binary);
    if (!f.is_open()) return false;

    // Magic number "fLaC"
    f.write("fLaC", 4);

    // Bloque 0: STREAMINFO (34 bytes)
    uint8_t blkStream[4] = { 0x00, 0x00, 0x00, 34 }; // blockType 0, length 34
    f.write(reinterpret_cast<const char*>(blkStream), 4);

    std::vector<uint8_t> streamInfo(34, 0);
    uint32_t sampleRate = 44100;
    uint64_t totalSamples = static_cast<uint64_t>(sampleRate) * duracionSegundos;

    streamInfo[10] = (sampleRate >> 12) & 0xFF;
    streamInfo[11] = (sampleRate >> 4) & 0xFF;
    streamInfo[12] = ((sampleRate & 0x0F) << 4) | (1 << 1) | 0; // 2 canales, 16 bits
    streamInfo[13] = (streamInfo[13] & 0xF0) | ((totalSamples >> 32) & 0x0F);
    streamInfo[14] = (totalSamples >> 24) & 0xFF;
    streamInfo[15] = (totalSamples >> 16) & 0xFF;
    streamInfo[16] = (totalSamples >> 8) & 0xFF;
    streamInfo[17] = totalSamples & 0xFF;

    f.write(reinterpret_cast<const char*>(streamInfo.data()), 34);

    // Bloque 4: VORBIS_COMMENT
    std::vector<uint8_t> vc;
    auto escribirLE32 = [&](std::vector<uint8_t>& buf, uint32_t val) {
        buf.push_back(val & 0xFF);
        buf.push_back((val >> 8) & 0xFF);
        buf.push_back((val >> 16) & 0xFF);
        buf.push_back((val >> 24) & 0xFF);
    };

    std::string vendor = "Reference Vorbis";
    escribirLE32(vc, vendor.size());
    for (char c : vendor) vc.push_back(static_cast<uint8_t>(c));

    std::vector<std::string> comments = {
        "TITLE=" + titulo,
        "ARTIST=" + artista,
        "GENRE=" + genero
    };
    escribirLE32(vc, comments.size());
    for (const auto& comm : comments) {
        escribirLE32(vc, comm.size());
        for (char c : comm) vc.push_back(static_cast<uint8_t>(c));
    }

    uint8_t blkVc[4] = { 0x04, 0, 0, 0 };
    uint32_t vcLen = vc.size();
    blkVc[1] = (vcLen >> 16) & 0xFF;
    blkVc[2] = (vcLen >> 8) & 0xFF;
    blkVc[3] = vcLen & 0xFF;
    f.write(reinterpret_cast<const char*>(blkVc), 4);
    f.write(reinterpret_cast<const char*>(vc.data()), vc.size());

    // Bloque 6: PICTURE (marcado como ultimo bloque: 0x86)
    std::vector<uint8_t> pic;
    auto escribirBE32 = [&](std::vector<uint8_t>& buf, uint32_t val) {
        buf.push_back((val >> 24) & 0xFF);
        buf.push_back((val >> 16) & 0xFF);
        buf.push_back((val >> 8) & 0xFF);
        buf.push_back(val & 0xFF);
    };

    std::vector<uint8_t> dummyPng = { 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00 };
    std::string mime = "image/png";

    escribirBE32(pic, 3); // front cover
    escribirBE32(pic, mime.size());
    for (char c : mime) pic.push_back(static_cast<uint8_t>(c));
    escribirBE32(pic, 0); // description len
    escribirBE32(pic, 300); // width
    escribirBE32(pic, 300); // height
    escribirBE32(pic, 24); // depth
    escribirBE32(pic, 0); // indexed colors
    escribirBE32(pic, dummyPng.size());
    pic.insert(pic.end(), dummyPng.begin(), dummyPng.end());

    uint8_t blkPic[4] = { 0x86, 0, 0, 0 }; // 0x80 = isLast, 6 = PICTURE
    uint32_t picLen = pic.size();
    blkPic[1] = (picLen >> 16) & 0xFF;
    blkPic[2] = (picLen >> 8) & 0xFF;
    blkPic[3] = picLen & 0xFF;
    f.write(reinterpret_cast<const char*>(blkPic), 4);
    f.write(reinterpret_cast<const char*>(pic.data()), pic.size());

    f.close();
    return true;
}

// ============================================================================
// Pruebas Unitarias e Integrales de Estudiante 1
// ============================================================================

void pruebasCancionExtendida() {
    grupo("Estudiante 1 - TAD Cancion Extendido y Retrocompatibilidad CSV");

    // 1. Constructor extendido y getters
    Cancion c(10, "Starman", "David Bowie", 256, "Glam Rock", "C:/Musica/starman.mp3", "C:/Musica/covers/starman.jpg");
    VERIFICAR(c.getId() == 10, "Cancion::getId correcto");
    VERIFICAR(c.getTitulo() == "Starman", "Cancion::getTitulo correcto");
    VERIFICAR(c.getArtista() == "David Bowie", "Cancion::getArtista correcto");
    VERIFICAR(c.getDuracionSegundos() == 256, "Cancion::getDuracionSegundos correcto");
    VERIFICAR(c.getGenero() == "Glam Rock", "Cancion::getGenero correcto");
    VERIFICAR(c.getRutaArchivo() == "C:/Musica/starman.mp3", "Cancion::getRutaArchivo correcto");
    VERIFICAR(c.getPortada() == "C:/Musica/covers/starman.jpg", "Cancion::getPortada correcto");
    VERIFICAR(c.getPortadaUrl() == "C:/Musica/covers/starman.jpg", "Cancion::getPortadaUrl alias correcto");
    VERIFICAR(c.getEsArchivoLocal() == true, "esArchivoLocal se activa si hay ruta");
    VERIFICAR(c.getMetadataExtraida() == true, "metadataExtraida se activa si hay ruta");

    // 2. Setters extendidos
    c.setEsFavorita(true);
    VERIFICAR(c.getEsFavorita() == true, "Cancion::setEsFavorita correcto");
    c.setTamanoBytes(4500000);
    VERIFICAR(c.getTamanoBytes() == 4500000, "Cancion::setTamanoBytes correcto");

    // 3. Retrocompatibilidad aCSV
    // Cancion sin ruta ni portada genera 5 columnas
    Cancion base(1, "Track", "Artist", 120, "Pop");
    VERIFICAR(base.aCSV(';') == "1;Track;Artist;120;Pop", "aCSV(5 cols) no incluye columnas extendidas vacias");

    // Cancion con ruta genera 7 columnas al solicitar o si incluirCamposExtendidos=true
    std::string csv7 = c.aCSV(';', true);
    VERIFICAR(csv7 == "10;Starman;David Bowie;256;Glam Rock;C:/Musica/starman.mp3;C:/Musica/covers/starman.jpg",
              "aCSV con 7 columnas incluye ruta y portada");

    // 4. desdeCSV soportando 5, 6 y 7 columnas
    Cancion salida5;
    VERIFICAR(Cancion::desdeCSV("1;Bohemian;Queen;354;Rock", salida5), "desdeCSV lee 5 columnas clasicas");
    VERIFICAR(salida5.getRutaArchivo() == "" && salida5.getPortada() == "", "desdeCSV 5 cols deja ruta y portada vacias");

    Cancion salida6;
    VERIFICAR(Cancion::desdeCSV("2;Clocks;Coldplay;307;Alt;C:/audio.mp3", salida6), "desdeCSV lee 6 columnas");
    VERIFICAR(salida6.getRutaArchivo() == "C:/audio.mp3" && salida6.getPortada() == "", "desdeCSV 6 cols asigna ruta");

    Cancion salida7;
    VERIFICAR(Cancion::desdeCSV("3;Billie Jean;MJ;294;Pop;C:/mj.flac;C:/mj.jpg", salida7), "desdeCSV lee 7 columnas");
    VERIFICAR(salida7.getRutaArchivo() == "C:/mj.flac" && salida7.getPortada() == "C:/mj.jpg", "desdeCSV 7 cols asigna ruta y portada");
    VERIFICAR(salida7.getEsArchivoLocal() == true, "desdeCSV activa esArchivoLocal");

    // 5. Manejo seguro de delimitadores y errores
    Cancion basura;
    VERIFICAR(!Cancion::desdeCSV("id;titulo;artista;duracion;genero;ruta;portada", basura), "desdeCSV ignora encabezado");
    VERIFICAR(!Cancion::desdeCSV("invalido;1;2;3", basura), "desdeCSV rechaza linea con formato invalido");
}

void pruebasExtractorMetadata() {
    grupo("Estudiante 1 - Extractor de Metadatos y Caratulas (MP3, FLAC, WAV)");

    std::string testDir = "test_audio_tmp";
    fs::create_directories(testDir);
    std::string wavPath = testDir + "/prueba_tono.wav";
    std::string mp3Path = testDir + "/prueba_queen.mp3";
    std::string flacPath = testDir + "/prueba_bowie.flac";

    // 1. WAV
    crearArchivoWavPrueba(wavPath, 4); // 4 segundos
    MetadatosAudio metaWav = ExtractorMetadata::extraer(wavPath, testDir + "/cache");
    VERIFICAR(metaWav.duracionSegundos == 4, "WAV: duracion calculada exactamente (4 s)");
    VERIFICAR(metaWav.tamanoBytes > 0, "WAV: tamano en bytes detectado");
    VERIFICAR(metaWav.metadataExtraida == true, "WAV: flag metadataExtraida activado");

    // 2. MP3 con ID3v2.3 y APIC
    crearArchivoMp3ConID3v2(mp3Path, "Bohemian Rhapsody", "Queen", "Rock", 354000);
    MetadatosAudio metaMp3 = ExtractorMetadata::extraer(mp3Path, testDir + "/cache");
    VERIFICAR(metaMp3.titulo == "Bohemian Rhapsody", "MP3 ID3v2: titulo extraido (TIT2)");
    VERIFICAR(metaMp3.artista == "Queen", "MP3 ID3v2: artista extraido (TPE1)");
    VERIFICAR(metaMp3.genero == "Rock", "MP3 ID3v2: genero extraido (TCON)");
    VERIFICAR(metaMp3.duracionSegundos == 354, "MP3 ID3v2: duracion extraida (TLEN 354 s)");
    VERIFICAR(metaMp3.tienePortada == true, "MP3 APIC: caratula detectada");
    VERIFICAR(!metaMp3.bytesPortada.empty(), "MP3 APIC: bytes de imagen presentes");
    VERIFICAR(!metaMp3.rutaPortadaCache.empty(), "MP3 APIC: archivo de caratula guardado en cache");
    VERIFICAR(fs::exists(metaMp3.rutaPortadaCache), "MP3 APIC: archivo fisico de caratula existe en disco");

    // 3. FLAC con STREAMINFO, VORBIS_COMMENT y PICTURE
    crearArchivoFlacPrueba(flacPath, "Heroes", "David Bowie", "Art Rock", 360);
    MetadatosAudio metaFlac = ExtractorMetadata::extraer(flacPath, testDir + "/cache");
    VERIFICAR(metaFlac.titulo == "Heroes", "FLAC: titulo extraido de VORBIS_COMMENT");
    VERIFICAR(metaFlac.artista == "David Bowie", "FLAC: artista extraido de VORBIS_COMMENT");
    VERIFICAR(metaFlac.genero == "Art Rock", "FLAC: genero extraido de VORBIS_COMMENT");
    VERIFICAR(metaFlac.duracionSegundos == 360, "FLAC: duracion calculada de STREAMINFO (360 s)");
    VERIFICAR(metaFlac.tienePortada == true, "FLAC: caratula METADATA_BLOCK_PICTURE detectada");
    VERIFICAR(!metaFlac.bytesPortada.empty(), "FLAC: bytes de portada presentes");

    // 4. Cache global de bytes de portadas
    ExtractorMetadata::registrarPortadaBytes(99, metaMp3.bytesPortada);
    const std::vector<uint8_t>* bRecup = ExtractorMetadata::obtenerPortadaBytes(99);
    VERIFICAR(bRecup != nullptr && bRecup->size() == metaMp3.bytesPortada.size(), "Cache memoria: bytes recuperados por ID");

    // 5. Inferencia ante metadatos faltantes
    std::string fallbackPath = testDir + "/Soda Stereo - De Musica Ligera.mp3";
    std::ofstream fb(fallbackPath, std::ios::binary);
    fb << "dummy audio data";
    fb.close();

    MetadatosAudio metaFall = ExtractorMetadata::extraer(fallbackPath, testDir + "/cache");
    VERIFICAR(metaFall.artista == "Soda Stereo", "Fallback: artista inferido del nombre de archivo");
    VERIFICAR(metaFall.titulo == "De Musica Ligera", "Fallback: titulo inferido del nombre de archivo");
    VERIFICAR(metaFall.genero == "Sin genero", "Fallback: genero por defecto asignado");

    // Limpieza
    fs::remove_all(testDir);
}

void pruebasMotorAudio() {
    grupo("Estudiante 1 - MotorAudio (miniaudio.h) y Estado Dinamico");

    MotorAudio motor;
    VERIFICAR(motor.inicializar(), "MotorAudio::inicializar exitoso");

    Cancion c(1, "Prueba Cancion", "Artista", 300, "Rock");
    motor.setModoRepeticion(ModoRepeticion::REPETIR_TODAS);
    motor.setVolume(0.85);

    // 1. Play y consulta de estado inicial
    VERIFICAR(motor.play(c), "MotorAudio::play retorna true");
    VERIFICAR(motor.isPlaying(), "MotorAudio::isPlaying es true tras play");
    VERIFICAR(motor.getDuracionTotalSegundos() == 300, "Duracion total = 300 s");
    VERIFICAR(motor.getPosicionActualSegundos() >= 0, "Posicion inicial >= 0");
    VERIFICAR(std::abs(motor.getVolume() - 0.85) < 0.001, "Volumen configurado = 0.85");

    // 2. Pause y Resume
    motor.pause();
    VERIFICAR(!motor.isPlaying(), "MotorAudio::pause detiene playback");
    motor.resume();
    VERIFICAR(motor.isPlaying(), "MotorAudio::resume reanuda playback");

    // 3. SeekTo
    motor.seekTo(150);
    VERIFICAR(motor.getPosicionActualSegundos() == 150, "MotorAudio::seekTo(150) posiciona exactamente en 150 s");
    VERIFICAR(std::abs(motor.getProgreso() - 0.5) < 0.01, "getProgreso = 0.5 (150/300)");
    VERIFICAR(motor.getTiempoTranscurridoFormateado() == "02:30", "getTiempoTranscurridoFormateado = 02:30");
    VERIFICAR(motor.getTiempoRestanteFormateado() == "-02:30", "getTiempoRestanteFormateado = -02:30");

    // 4. SeekTo con acotamiento seguro
    motor.seekTo(999);
    VERIFICAR(motor.getPosicionActualSegundos() == 300, "seekTo mayor que duracion se acota a duracion max (300 s)");
    VERIFICAR(motor.getProgreso() == 1.0, "getProgreso en el final es 1.0");

    motor.seekTo(-50);
    VERIFICAR(motor.getPosicionActualSegundos() == 0, "seekTo negativo se acota a 0 s");
    VERIFICAR(motor.getProgreso() == 0.0, "getProgreso en 0 es 0.0");

    // 5. Volumen seguro (0.0 .. 1.0)
    motor.setVolume(1.5);
    VERIFICAR(motor.getVolume() == 1.0, "Volumen > 1.0 se acota a 1.0");
    motor.setVolume(-0.5);
    VERIFICAR(motor.getVolume() == 0.0, "Volumen < 0.0 se acota a 0.0");

    // 6. Stop
    motor.stop();
    VERIFICAR(!motor.isPlaying(), "MotorAudio::stop deja isPlaying = false");
    VERIFICAR(motor.getPosicionActualSegundos() == 0, "MotorAudio::stop reinicia posicion a 0");

    // 7. EstadoReproduccionActual
    EstadoReproduccionActual est = motor.getEstadoActual();
    VERIFICAR(est.idCancionActiva == 1, "EstadoReproduccionActual::idCancionActiva correcto");
    VERIFICAR(est.duracionTotalSegundos == 300, "EstadoReproduccionActual::duracionTotalSegundos correcto");
    VERIFICAR(est.modoRepeticion == ModoRepeticion::REPETIR_TODAS, "EstadoReproduccionActual::modoRepeticion correcto");

    // 8. Reproduccion real con archivo WAV de prueba
    std::string testWav = "motor_audio_prueba.wav";
    crearArchivoWavPrueba(testWav, 2);
    Cancion cReal(2, "Onda Seno", "Sintetizador", 2, "Test", testWav);
    VERIFICAR(motor.play(cReal), "play con archivo WAV real en miniaudio");
    VERIFICAR(motor.isPlaying(), "motor reproduciendo audio real");
    motor.stop();
    fs::remove(testWav);

    motor.liberar();
}

int main() {
    std::cout << "========================================================\n";
    std::cout << "  PRUEBAS DEL ESTUDIANTE 1 - AUDIO, METADATOS Y TAD CANCION\n";
    std::cout << "  Algoritmos y Estructuras de Datos (CC0401) - UNMSM\n";
    std::cout << "========================================================\n";

    pruebasCancionExtendida();
    pruebasExtractorMetadata();
    pruebasMotorAudio();

    std::cout << "\n========================================================\n";
    std::cout << "  Resultado: " << pruebasPasadas << " de " << totalPruebas << " pruebas correctas\n";
    if (pruebasPasadas == totalPruebas) {
        std::cout << "  TODO CORRECTO - ESTUDIANTE 1 COMPLETADO AL 100%\n";
    } else {
        std::cout << "  EXISTEN PRUEBAS FALLIDAS\n";
    }
    std::cout << "========================================================\n";

    return (pruebasPasadas == totalPruebas) ? 0 : 1;
}


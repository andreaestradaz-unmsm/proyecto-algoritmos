#ifndef EXTRACTOR_METADATA_H
#define EXTRACTOR_METADATA_H

#include <string>
#include <vector>
#include <cstdint>

// Contenedor de metadatos y caratula extraidos de un archivo de audio
struct MetadatosAudio {
    std::string titulo;
    std::string artista;
    std::string album;
    std::string genero;
    int duracionSegundos;
    int tamanoBytes;
    bool tienePortada;
    std::string mimePortada;
    std::vector<uint8_t> bytesPortada;
    std::string rutaPortadaCache;
    bool metadataExtraida;

    MetadatosAudio()
        : titulo(""),
          artista(""),
          album(""),
          genero(""),
          duracionSegundos(0),
          tamanoBytes(0),
          tienePortada(false),
          mimePortada(""),
          rutaPortadaCache(""),
          metadataExtraida(false) {}
};

// Extractor de etiquetas y caratulas para archivos de audio (.mp3, .flac, .wav, .ogg)
class ExtractorMetadata {
public:
    // Analiza el archivo multimedia y retorna sus metadatos y caratula
    static MetadatosAudio extraer(const std::string& rutaArchivo,
                                 const std::string& carpetaCache = "cache_portadas");

    // Parsea frames ID3v2 (TIT2, TPE1, TALB, TCON, TLEN y APIC) en archivos MP3
    static bool extraerID3v2(const std::string& rutaArchivo,
                             MetadatosAudio& outMeta,
                             const std::string& carpetaCache);

    // Parsea bloques STREAMINFO, VORBIS_COMMENT y PICTURE en archivos FLAC
    static bool extraerFLAC(const std::string& rutaArchivo,
                            MetadatosAudio& outMeta,
                            const std::string& carpetaCache);

    // Parsea cabecera RIFF de archivos WAV para derivar duracion y canales
    static bool extraerWAV(const std::string& rutaArchivo,
                           MetadatosAudio& outMeta);

    // Calcula la duracion exacta en segundos usando decodificador miniaudio
    static int calcularDuracionConMiniaudio(const std::string& rutaArchivo);

    // Asocia los bytes binarios de la caratula al ID de una cancion en memoria
    static void registrarPortadaBytes(int cancionId, const std::vector<uint8_t>& bytes);

    // Recupera los bytes binarios de la caratula de una cancion
    static const std::vector<uint8_t>* obtenerPortadaBytes(int cancionId);

    // Limpia el cache de caratulas en memoria
    static void limpiarCachePortadas();

private:
    static std::string extraerNombreBase(const std::string& ruta);
    static std::string quitarExtension(const std::string& nombreArchivo);
    static void inferirDesdeNombreArchivo(const std::string& rutaArchivo, MetadatosAudio& outMeta);
    static bool guardarBytesEnArchivo(const std::string& rutaDestino, const std::vector<uint8_t>& bytes);
    static std::string determinarExtensionMime(const std::string& mime);
};

#endif // EXTRACTOR_METADATA_H

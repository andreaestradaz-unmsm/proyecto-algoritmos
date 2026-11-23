#include "extractor_metadata.h"
#include "miniaudio.h"

#include <fstream>
#include <sstream>
#include <algorithm>
#include <filesystem>
#include <map>
#include <cstring>
#include <cctype>

namespace fs = std::filesystem;

namespace {
    std::map<int, std::vector<uint8_t>> g_cachePortadasMemoria;

    std::string trim(const std::string& str) {
        size_t first = str.find_first_not_of(" \t\r\n\0");
        if (first == std::string::npos) return "";
        size_t last = str.find_last_not_of(" \t\r\n\0");
        return str.substr(first, (last - first + 1));
    }

    std::string aMinusculas(std::string texto) {
        for (char& c : texto) {
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }
        return texto;
    }

    uint32_t leerBE32(const uint8_t* p) {
        return (static_cast<uint32_t>(p[0]) << 24) |
               (static_cast<uint32_t>(p[1]) << 16) |
               (static_cast<uint32_t>(p[2]) << 8)  |
               static_cast<uint32_t>(p[3]);
    }

    uint32_t leerLE32(const uint8_t* p) {
        return static_cast<uint32_t>(p[0]) |
               (static_cast<uint32_t>(p[1]) << 8)  |
               (static_cast<uint32_t>(p[2]) << 16) |
               (static_cast<uint32_t>(p[3]) << 24);
    }

    // Decodifica un entero synchsafe de 28 bits (ID3v2)
    uint32_t leerSynchsafe(const uint8_t* p) {
        return ((p[0] & 0x7F) << 21) |
               ((p[1] & 0x7F) << 14) |
               ((p[2] & 0x7F) << 7)  |
               (p[3] & 0x7F);
    }

    // Decodifica cadenas de texto de frames ID3v2 (ISO-8859-1, UTF-8, UTF-16)
    std::string decodificarTextoID3(uint8_t encoding, const uint8_t* data, size_t length) {
        if (length == 0 || data == nullptr) return "";
        if (encoding == 0 || encoding == 3) {
            std::string res;
            for (size_t i = 0; i < length; ++i) {
                if (data[i] == '\0') break;
                res += static_cast<char>(data[i]);
            }
            return trim(res);
        } else if (encoding == 1 || encoding == 2) {
            std::string res;
            size_t start = 0;
            bool littleEndian = true;
            if (length >= 2) {
                if (data[0] == 0xFF && data[1] == 0xFE) {
                    littleEndian = true;
                    start = 2;
                } else if (data[0] == 0xFE && data[1] == 0xFF) {
                    littleEndian = false;
                    start = 2;
                }
            }
            for (size_t i = start; i + 1 < length; i += 2) {
                uint16_t ch = littleEndian ? (data[i] | (data[i + 1] << 8))
                                           : ((data[i] << 8) | data[i + 1]);
                if (ch == 0) break;
                if (ch < 128) {
                    res += static_cast<char>(ch);
                } else {
                    res += '?';
                }
            }
            return trim(res);
        }
        return "";
    }
}

// Retorna el nombre de archivo a partir de una ruta
std::string ExtractorMetadata::extraerNombreBase(const std::string& ruta) {
    size_t pos = ruta.find_last_of("/\\");
    if (pos == std::string::npos) return ruta;
    return ruta.substr(pos + 1);
}

// Remueve la extension del nombre de archivo
std::string ExtractorMetadata::quitarExtension(const std::string& nombreArchivo) {
    size_t punto = nombreArchivo.find_last_of('.');
    if (punto == std::string::npos) return nombreArchivo;
    return nombreArchivo.substr(0, punto);
}

// Determina la extension (.jpg, .png) segun el tipo MIME
std::string ExtractorMetadata::determinarExtensionMime(const std::string& mime) {
    std::string m = aMinusculas(mime);
    if (m.find("png") != std::string::npos) return ".png";
    if (m.find("webp") != std::string::npos) return ".webp";
    return ".jpg";
}

// Guarda un buffer binario en disco creando los directorios necesarios
bool ExtractorMetadata::guardarBytesEnArchivo(const std::string& rutaDestino, const std::vector<uint8_t>& bytes) {
    if (bytes.empty() || rutaDestino.empty()) return false;
    try {
        fs::path p(rutaDestino);
        if (p.has_parent_path()) {
            fs::create_directories(p.parent_path());
        }
        std::ofstream out(rutaDestino, std::ios::binary);
        if (!out.is_open()) return false;
        out.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
        out.close();
        return true;
    } catch (...) {
        return false;
    }
}

// Infiere artista y titulo del nombre del archivo en ausencia de etiquetas
void ExtractorMetadata::inferirDesdeNombreArchivo(const std::string& rutaArchivo, MetadatosAudio& outMeta) {
    std::string nombreBase = extraerNombreBase(rutaArchivo);
    std::string sinExt = quitarExtension(nombreBase);

    for (char& c : sinExt) {
        if (c == '_') c = ' ';
    }

    size_t posGuion = sinExt.find(" - ");
    if (posGuion != std::string::npos) {
        std::string art = trim(sinExt.substr(0, posGuion));
        std::string tit = trim(sinExt.substr(posGuion + 3));
        if (outMeta.artista.empty() && !art.empty()) outMeta.artista = art;
        if (outMeta.titulo.empty() && !tit.empty()) outMeta.titulo = tit;
    } else {
        size_t posG = sinExt.find('-');
        if (posG != std::string::npos) {
            std::string art = trim(sinExt.substr(0, posG));
            std::string tit = trim(sinExt.substr(posG + 1));
            if (outMeta.artista.empty() && !art.empty()) outMeta.artista = art;
            if (outMeta.titulo.empty() && !tit.empty()) outMeta.titulo = tit;
        } else {
            if (outMeta.titulo.empty()) outMeta.titulo = trim(sinExt);
        }
    }

    if (outMeta.titulo.empty()) outMeta.titulo = "Sin titulo";
    if (outMeta.artista.empty()) outMeta.artista = "Desconocido";
    if (outMeta.genero.empty()) outMeta.genero = "Sin genero";
}

// Calcula la duracion exacta en segundos usando el decodificador de miniaudio
int ExtractorMetadata::calcularDuracionConMiniaudio(const std::string& rutaArchivo) {
    if (rutaArchivo.empty()) return 0;
    ma_decoder decoder;
    ma_result res = ma_decoder_init_file(rutaArchivo.c_str(), NULL, &decoder);
    if (res != MA_SUCCESS) {
        return 0;
    }
    ma_uint64 totalFrames = 0;
    res = ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrames);
    ma_uint32 sampleRate = decoder.outputSampleRate;
    ma_decoder_uninit(&decoder);

    if (res == MA_SUCCESS && sampleRate > 0) {
        return static_cast<int>(totalFrames / sampleRate);
    }
    return 0;
}

// Extrae metadatos ID3v2 y caratula APIC de archivos MP3
bool ExtractorMetadata::extraerID3v2(const std::string& rutaArchivo,
                                     MetadatosAudio& outMeta,
                                     const std::string& carpetaCache) {
    std::ifstream file(rutaArchivo, std::ios::binary);
    if (!file.is_open()) return false;

    uint8_t header[10];
    if (!file.read(reinterpret_cast<char*>(header), 10)) return false;

    if (header[0] != 'I' || header[1] != 'D' || header[2] != '3') {
        return false;
    }

    uint8_t version = header[3];
    uint8_t flags = header[5];
    uint32_t tagSize = leerSynchsafe(&header[6]);

    std::vector<uint8_t> tagData(tagSize);
    if (!file.read(reinterpret_cast<char*>(tagData.data()), tagSize)) {
        return false;
    }

    size_t offset = 0;
    if (flags & 0x40) {
        if (tagSize > 4) {
            uint32_t extSize = (version == 4) ? leerSynchsafe(tagData.data()) : leerBE32(tagData.data());
            offset += extSize;
        }
    }

    while (offset + 10 <= tagSize) {
        const uint8_t* frame = &tagData[offset];
        if (frame[0] == 0) break;

        char frameId[5] = { static_cast<char>(frame[0]), static_cast<char>(frame[1]),
                            static_cast<char>(frame[2]), static_cast<char>(frame[3]), '\0' };

        uint32_t frameSize = (version == 4) ? leerSynchsafe(&frame[4]) : leerBE32(&frame[4]);
        if (frameSize == 0 || offset + 10 + frameSize > tagSize) break;

        const uint8_t* data = &frame[10];

        if (std::strcmp(frameId, "TIT2") == 0) {
            outMeta.titulo = decodificarTextoID3(data[0], data + 1, frameSize - 1);
        } else if (std::strcmp(frameId, "TPE1") == 0) {
            outMeta.artista = decodificarTextoID3(data[0], data + 1, frameSize - 1);
        } else if (std::strcmp(frameId, "TALB") == 0) {
            outMeta.album = decodificarTextoID3(data[0], data + 1, frameSize - 1);
        } else if (std::strcmp(frameId, "TCON") == 0) {
            outMeta.genero = decodificarTextoID3(data[0], data + 1, frameSize - 1);
        } else if (std::strcmp(frameId, "TLEN") == 0) {
            std::string tlenStr = decodificarTextoID3(data[0], data + 1, frameSize - 1);
            try {
                int ms = std::stoi(tlenStr);
                if (ms > 0) outMeta.duracionSegundos = ms / 1000;
            } catch (...) {}
        } else if (std::strcmp(frameId, "APIC") == 0) {
            if (frameSize > 4) {
                uint8_t encoding = data[0];
                size_t p = 1;
                std::string mime;
                while (p < frameSize && data[p] != 0) {
                    mime += static_cast<char>(data[p]);
                    p++;
                }
                p++;
                if (p < frameSize) {
                    uint8_t picType = data[p];
                    (void)picType;
                    p++;
                    if (encoding == 1 || encoding == 2) {
                        while (p + 1 < frameSize && !(data[p] == 0 && data[p + 1] == 0)) {
                            p += 2;
                        }
                        p += 2;
                    } else {
                        while (p < frameSize && data[p] != 0) {
                            p++;
                        }
                        p++;
                    }
                    if (p < frameSize) {
                        outMeta.bytesPortada.assign(data + p, data + frameSize);
                        outMeta.tienePortada = true;
                        outMeta.mimePortada = mime.empty() ? "image/jpeg" : mime;

                        std::string ext = determinarExtensionMime(outMeta.mimePortada);
                        std::string rutaCache = carpetaCache + "/portada_" +
                                                quitarExtension(extraerNombreBase(rutaArchivo)) + ext;
                        guardarBytesEnArchivo(rutaCache, outMeta.bytesPortada);
                        outMeta.rutaPortadaCache = rutaCache;
                    }
                }
            }
        }

        offset += 10 + frameSize;
    }

    outMeta.metadataExtraida = true;
    return true;
}

// Extrae metadatos y caratula de bloques FLAC
bool ExtractorMetadata::extraerFLAC(const std::string& rutaArchivo,
                                    MetadatosAudio& outMeta,
                                    const std::string& carpetaCache) {
    std::ifstream file(rutaArchivo, std::ios::binary);
    if (!file.is_open()) return false;

    char magic[4];
    if (!file.read(magic, 4) || std::memcmp(magic, "fLaC", 4) != 0) {
        return false;
    }

    bool isLast = false;
    while (!isLast && file.good()) {
        uint8_t blockHeader[4];
        if (!file.read(reinterpret_cast<char*>(blockHeader), 4)) break;

        isLast = (blockHeader[0] & 0x80) != 0;
        uint8_t blockType = blockHeader[0] & 0x7F;
        uint32_t blockLength = (static_cast<uint32_t>(blockHeader[1]) << 16) |
                               (static_cast<uint32_t>(blockHeader[2]) << 8)  |
                               static_cast<uint32_t>(blockHeader[3]);

        std::vector<uint8_t> blockData(blockLength);
        if (!file.read(reinterpret_cast<char*>(blockData.data()), blockLength)) break;

        if (blockType == 0 && blockLength >= 34) {
            const uint8_t* d = blockData.data();
            uint32_t sampleRate = (static_cast<uint32_t>(d[10]) << 12) |
                                  (static_cast<uint32_t>(d[11]) << 4)  |
                                  (static_cast<uint32_t>(d[12]) >> 4);
            uint64_t totalSamples = (static_cast<uint64_t>(d[13] & 0x0F) << 32) |
                                    (static_cast<uint64_t>(d[14]) << 24) |
                                    (static_cast<uint64_t>(d[15]) << 16) |
                                    (static_cast<uint64_t>(d[16]) << 8)  |
                                    static_cast<uint64_t>(d[17]);
            if (sampleRate > 0) {
                outMeta.duracionSegundos = static_cast<int>(totalSamples / sampleRate);
            }
        } else if (blockType == 4 && blockLength >= 8) {
            const uint8_t* d = blockData.data();
            size_t p = 0;
            uint32_t vendorLen = leerLE32(d + p);
            p += 4 + vendorLen;
            if (p + 4 <= blockLength) {
                uint32_t commentCount = leerLE32(d + p);
                p += 4;
                for (uint32_t i = 0; i < commentCount && p + 4 <= blockLength; ++i) {
                    uint32_t commLen = leerLE32(d + p);
                    p += 4;
                    if (p + commLen <= blockLength) {
                        std::string comment(reinterpret_cast<const char*>(d + p), commLen);
                        p += commLen;
                        size_t eq = comment.find('=');
                        if (eq != std::string::npos) {
                            std::string key = aMinusculas(comment.substr(0, eq));
                            std::string val = trim(comment.substr(eq + 1));
                            if (key == "title") outMeta.titulo = val;
                            else if (key == "artist") outMeta.artista = val;
                            else if (key == "album") outMeta.album = val;
                            else if (key == "genre") outMeta.genero = val;
                        }
                    } else break;
                }
            }
        } else if (blockType == 6 && blockLength >= 32) {
            const uint8_t* d = blockData.data();
            size_t p = 4;
            if (p + 4 <= blockLength) {
                uint32_t mimeLen = leerBE32(d + p);
                p += 4;
                std::string mime;
                if (p + mimeLen <= blockLength) {
                    mime = std::string(reinterpret_cast<const char*>(d + p), mimeLen);
                    p += mimeLen;
                }
                if (p + 4 <= blockLength) {
                    uint32_t descLen = leerBE32(d + p);
                    p += 4 + descLen;
                    p += 16;
                    if (p + 4 <= blockLength) {
                        uint32_t dataLen = leerBE32(d + p);
                        p += 4;
                        if (p + dataLen <= blockLength) {
                            outMeta.bytesPortada.assign(d + p, d + p + dataLen);
                            outMeta.tienePortada = true;
                            outMeta.mimePortada = mime.empty() ? "image/jpeg" : mime;

                            std::string ext = determinarExtensionMime(outMeta.mimePortada);
                            std::string rutaCache = carpetaCache + "/portada_" +
                                                    quitarExtension(extraerNombreBase(rutaArchivo)) + ext;
                            guardarBytesEnArchivo(rutaCache, outMeta.bytesPortada);
                            outMeta.rutaPortadaCache = rutaCache;
                        }
                    }
                }
            }
        }
    }

    outMeta.metadataExtraida = true;
    return true;
}

// Extrae duracion de cabecera RIFF en archivos WAV
bool ExtractorMetadata::extraerWAV(const std::string& rutaArchivo, MetadatosAudio& outMeta) {
    std::ifstream file(rutaArchivo, std::ios::binary);
    if (!file.is_open()) return false;

    char header[12];
    if (!file.read(header, 12)) return false;

    if (std::memcmp(header, "RIFF", 4) != 0 || std::memcmp(header + 8, "WAVE", 4) != 0) {
        return false;
    }

    uint32_t byteRate = 0;
    while (file.good()) {
        char chunkId[4];
        uint8_t szBytes[4];
        if (!file.read(chunkId, 4) || !file.read(reinterpret_cast<char*>(szBytes), 4)) break;

        uint32_t chunkSize = leerLE32(szBytes);

        if (std::memcmp(chunkId, "fmt ", 4) == 0 && chunkSize >= 16) {
            std::vector<uint8_t> fmt(chunkSize);
            if (!file.read(reinterpret_cast<char*>(fmt.data()), chunkSize)) break;
            byteRate = leerLE32(fmt.data() + 8);
        } else if (std::memcmp(chunkId, "data", 4) == 0) {
            if (byteRate > 0) {
                outMeta.duracionSegundos = static_cast<int>(chunkSize / byteRate);
            }
            break;
        } else {
            file.seekg(chunkSize, std::ios::cur);
        }
    }

    outMeta.metadataExtraida = true;
    return true;
}

// Analiza el archivo multimedia y retorna sus metadatos
MetadatosAudio ExtractorMetadata::extraer(const std::string& rutaArchivo, const std::string& carpetaCache) {
    MetadatosAudio meta;
    if (rutaArchivo.empty()) return meta;

    try {
        if (fs::exists(rutaArchivo)) {
            meta.tamanoBytes = static_cast<int>(fs::file_size(rutaArchivo));
        }
    } catch (...) {}

    std::string ext = aMinusculas(fs::path(rutaArchivo).extension().string());

    bool extraido = false;
    if (ext == ".mp3") {
        extraido = extraerID3v2(rutaArchivo, meta, carpetaCache);
    } else if (ext == ".flac") {
        extraido = extraerFLAC(rutaArchivo, meta, carpetaCache);
    } else if (ext == ".wav") {
        extraido = extraerWAV(rutaArchivo, meta);
    }

    if (meta.duracionSegundos <= 0) {
        meta.duracionSegundos = calcularDuracionConMiniaudio(rutaArchivo);
    }

    inferirDesdeNombreArchivo(rutaArchivo, meta);

    if (extraido || meta.duracionSegundos > 0 || meta.tamanoBytes > 0) {
        meta.metadataExtraida = true;
    }

    return meta;
}

// Registra los bytes binarios de la caratula asociados a una cancion
void ExtractorMetadata::registrarPortadaBytes(int cancionId, const std::vector<uint8_t>& bytes) {
    g_cachePortadasMemoria[cancionId] = bytes;
}

// Retorna los bytes binarios de la caratula de una cancion
const std::vector<uint8_t>* ExtractorMetadata::obtenerPortadaBytes(int cancionId) {
    auto it = g_cachePortadasMemoria.find(cancionId);
    if (it != g_cachePortadasMemoria.end() && !it->second.empty()) {
        return &(it->second);
    }
    return nullptr;
}

// Limpia el cache de caratulas en memoria
void ExtractorMetadata::limpiarCachePortadas() {
    g_cachePortadasMemoria.clear();
}

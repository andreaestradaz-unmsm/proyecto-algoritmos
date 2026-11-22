import 'dart:typed_data';

/// Modelo de datos equivalente al TAD `Cancion` de `cancion.h` / `cancion.cpp`
/// (desarrollado por Andrea en C++), preparado además con los campos extendidos
/// para la integración completa de audio real y extracción de metadatos (incluyendo
/// bytes o ruta de la portada embebida) del equipo de backend.
class CancionModel {
  const CancionModel({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.duracionSegundos,
    required this.genero,
    this.rutaArchivo,
    this.portadaUrl,
    this.portadaBytes,
    this.esFavorita = false,
    this.esArchivoLocal = false,
    this.metadataExtraida = false,
    this.tamanoBytes,
  });

  /// Campos base del TAD `Cancion` en C++ (`cancion.h`)
  final int id;
  final String titulo;
  final String artista;
  final int duracionSegundos;
  final String genero;

  /// Campos extendidos del contrato definitivo para el backend (Integrante 1):
  /// - [rutaArchivo]: ruta local en el dispositivo (ej. `/storage/.../cancion.mp3`)
  /// - [portadaUrl]: ruta local o URI de la carátula extraída de la metadata
  /// - [portadaBytes]: bytes crudos (`APIC` / `PICTURE` frame) extraídos del archivo
  final String? rutaArchivo;
  final String? portadaUrl;
  final Uint8List? portadaBytes;
  final bool esFavorita;
  final bool esArchivoLocal;
  final bool metadataExtraida;
  final int? tamanoBytes;

  bool get tienePortadaMetadata =>
      (portadaBytes != null && portadaBytes!.isNotEmpty) ||
      (portadaUrl != null && portadaUrl!.trim().isNotEmpty);

  /// Espejo exacto de `Cancion::obtenerDuracionFormateada()` en `cancion.cpp` (MM:SS).
  String obtenerDuracionFormateada() {
    final safeSeconds = duracionSegundos < 0 ? 0 : duracionSegundos;
    final minutos = safeSeconds ~/ 60;
    final segundos = safeSeconds % 60;
    final textoMinutos =
        minutos < 10 ? '0$minutos' : minutos.toString();
    final textoSegundos =
        segundos < 10 ? '0$segundos' : segundos.toString();
    return '$textoMinutos:$textoSegundos';
  }

  /// Espejo de `Cancion::aCSV(char delimitador = ';')` en `cancion.cpp`.
  String aCSV({
    String delimitador = ';',
    bool incluirCamposExtendidos = false,
  }) {
    final base =
        '$id$delimitador$titulo$delimitador$artista$delimitador$duracionSegundos$delimitador$genero';
    if (!incluirCamposExtendidos) {
      return base;
    }
    final ruta = rutaArchivo ?? '';
    final portada = portadaUrl ?? '';
    return '$base$delimitador$ruta$delimitador$portada';
  }

  /// Espejo de `Cancion::desdeCSV(const std::string& lineaCSV, Cancion& cancionSalida, char delimitador = ';')`.
  static CancionModel? desdeCSV(
    String lineaCSV, {
    String delimitador = ';',
  }) {
    final limpia = lineaCSV.trim();
    if (limpia.isEmpty) {
      return null;
    }
    final primerChar = limpia.codeUnitAt(0);
    if (primerChar < 48 || primerChar > 57) {
      return null;
    }

    final campos = limpia.split(delimitador);
    if (campos.length < 5) {
      return null;
    }

    final idLeido = int.tryParse(campos[0].trim());
    final duracionLeida = int.tryParse(campos[3].trim());
    if (idLeido == null || duracionLeida == null) {
      return null;
    }

    final tituloLeido =
        campos[1].trim().isEmpty ? 'Sin titulo' : campos[1].trim();
    final artistaLeido =
        campos[2].trim().isEmpty ? 'Desconocido' : campos[2].trim();
    final generoLeido =
        campos[4].trim().isEmpty ? 'Sin genero' : campos[4].trim();

    final rutaLeida = campos.length >= 6 && campos[5].trim().isNotEmpty
        ? campos[5].trim()
        : null;
    final portadaLeida = campos.length >= 7 && campos[6].trim().isNotEmpty
        ? campos[6].trim()
        : null;

    return CancionModel(
      id: idLeido,
      titulo: tituloLeido,
      artista: artistaLeido,
      duracionSegundos: duracionLeida < 0 ? 0 : duracionLeida,
      genero: generoLeido,
      rutaArchivo: rutaLeida,
      portadaUrl: portadaLeida,
      esArchivoLocal: rutaLeida != null,
      metadataExtraida: rutaLeida != null || portadaLeida != null,
    );
  }

  CancionModel copyWith({
    int? id,
    String? titulo,
    String? artista,
    int? duracionSegundos,
    String? genero,
    String? rutaArchivo,
    String? portadaUrl,
    Uint8List? portadaBytes,
    bool? esFavorita,
    bool? esArchivoLocal,
    bool? metadataExtraida,
    int? tamanoBytes,
  }) {
    return CancionModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      artista: artista ?? this.artista,
      duracionSegundos: duracionSegundos ?? this.duracionSegundos,
      genero: genero ?? this.genero,
      rutaArchivo: rutaArchivo ?? this.rutaArchivo,
      portadaUrl: portadaUrl ?? this.portadaUrl,
      portadaBytes: portadaBytes ?? this.portadaBytes,
      esFavorita: esFavorita ?? this.esFavorita,
      esArchivoLocal: esArchivoLocal ?? this.esArchivoLocal,
      metadataExtraida: metadataExtraida ?? this.metadataExtraida,
      tamanoBytes: tamanoBytes ?? this.tamanoBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'artista': artista,
      'duracion_segundos': duracionSegundos,
      'genero': genero,
      'ruta_archivo': rutaArchivo,
      'portada_url': portadaUrl,
      'es_favorita': esFavorita,
      'es_archivo_local': esArchivoLocal,
      'metadata_extraida': metadataExtraida,
      'tamano_bytes': tamanoBytes,
    };
  }

  factory CancionModel.fromJson(Map<String, dynamic> json) {
    return CancionModel(
      id: json['id'] as int,
      titulo: json['titulo'] as String? ?? 'Sin titulo',
      artista: json['artista'] as String? ?? 'Desconocido',
      duracionSegundos: json['duracion_segundos'] as int? ?? 0,
      genero: json['genero'] as String? ?? 'Sin genero',
      rutaArchivo: json['ruta_archivo'] as String?,
      portadaUrl: json['portada_url'] as String?,
      esFavorita: json['es_favorita'] as bool? ?? false,
      esArchivoLocal: json['es_archivo_local'] as bool? ?? false,
      metadataExtraida: json['metadata_extraida'] as bool? ?? false,
      tamanoBytes: json['tamano_bytes'] as int?,
    );
  }
}

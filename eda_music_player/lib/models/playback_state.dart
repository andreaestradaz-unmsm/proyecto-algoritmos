import 'cancion.dart';
import 'modo_repeticion.dart';

/// Estado completo del motor de reproducción.
/// Separa la duración estática almacenada en el nodo `Cancion` de la posición
/// dinámica de reproducción (`posicionActualSegundos`), volumen (`0.0..1.0`),
/// estado `isPlaying` y `modoRepeticion`, listo para el contrato con el backend C++.
class PlaybackStateModel {
  const PlaybackStateModel({
    this.cancionActual,
    this.playlistActivaId,
    this.nombreContexto = 'Sin playlist activa',
    this.isPlaying = false,
    this.posicionActualSegundos = 0,
    this.duracionTotalSegundos = 0,
    this.volumen = 0.78,
    this.modoRepeticion = ModoRepeticion.repetirTodas,
    this.ultimoShuffleSemilla,
    this.mensajeEstado,
  });

  final CancionModel? cancionActual;
  final String? playlistActivaId;
  final String nombreContexto;
  final bool isPlaying;
  final int posicionActualSegundos;
  final int duracionTotalSegundos;
  final double volumen;
  final ModoRepeticion modoRepeticion;
  final int? ultimoShuffleSemilla;
  final String? mensajeEstado;

  /// Valor normalizado `0.0 .. 1.0` para la barra de progreso personalizada.
  double get progreso {
    if (duracionTotalSegundos <= 0) {
      return 0.0;
    }
    final ratio = posicionActualSegundos / duracionTotalSegundos;
    return ratio.clamp(0.0, 1.0);
  }

  int get segundosRestantes {
    final diff = duracionTotalSegundos - posicionActualSegundos;
    return diff < 0 ? 0 : diff;
  }

  static String formatearMMSS(int segundosTotales) {
    final safe = segundosTotales < 0 ? 0 : segundosTotales;
    final min = safe ~/ 60;
    final seg = safe % 60;
    return '$min:${seg.toString().padLeft(2, '0')}';
  }

  String get tiempoTranscurridoTexto => formatearMMSS(posicionActualSegundos);

  String get tiempoRestanteTexto => '-${formatearMMSS(segundosRestantes)}';

  String get duracionTotalTexto => formatearMMSS(duracionTotalSegundos);

  PlaybackStateModel copyWith({
    CancionModel? cancionActual,
    bool clearCancionActual = false,
    String? playlistActivaId,
    String? nombreContexto,
    bool? isPlaying,
    int? posicionActualSegundos,
    int? duracionTotalSegundos,
    double? volumen,
    ModoRepeticion? modoRepeticion,
    int? ultimoShuffleSemilla,
    String? mensajeEstado,
    bool clearMensajeEstado = false,
  }) {
    return PlaybackStateModel(
      cancionActual:
          clearCancionActual ? null : (cancionActual ?? this.cancionActual),
      playlistActivaId: playlistActivaId ?? this.playlistActivaId,
      nombreContexto: nombreContexto ?? this.nombreContexto,
      isPlaying: isPlaying ?? this.isPlaying,
      posicionActualSegundos:
          posicionActualSegundos ?? this.posicionActualSegundos,
      duracionTotalSegundos:
          duracionTotalSegundos ?? this.duracionTotalSegundos,
      volumen: volumen ?? this.volumen,
      modoRepeticion: modoRepeticion ?? this.modoRepeticion,
      ultimoShuffleSemilla: ultimoShuffleSemilla ?? this.ultimoShuffleSemilla,
      mensajeEstado:
          clearMensajeEstado ? null : (mensajeEstado ?? this.mensajeEstado),
    );
  }
}

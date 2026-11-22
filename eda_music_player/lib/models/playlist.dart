import 'cancion.dart';
import 'modo_repeticion.dart';

/// Modelo que representa el estado de una `ListaDobleCircular` (`lista_doble_circular.h`
/// programada por Jeick en C++).
/// Mantiene la secuencia de nodos dobles (`cabeza` = índice 0, `cola` = índice `tamano - 1`),
/// el cursor de reproducción `indiceActual` (`NodoDoble* actual`) y el `modoRepeticion`.
class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.nombre,
    required this.canciones,
    this.indiceActual,
    this.modoRepeticion = ModoRepeticion.repetirTodas,
    this.esActiva = false,
  });

  final String id;
  final String nombre;
  final List<CancionModel> canciones;
  final int? indiceActual;
  final ModoRepeticion modoRepeticion;
  final bool esActiva;

  int get tamano => canciones.length;

  bool get estaVacia => canciones.isEmpty;

  /// Puntero `NodoDoble* cabeza`
  CancionModel? get cabeza => canciones.isEmpty ? null : canciones.first;

  /// Puntero `NodoDoble* cola`
  CancionModel? get cola => canciones.isEmpty ? null : canciones.last;

  /// Puntero `NodoDoble* actual` (`obtenerCancionActual()`)
  CancionModel? get cancionActual {
    if (canciones.isEmpty || indiceActual == null) {
      return null;
    }
    if (indiceActual! < 0 || indiceActual! >= canciones.length) {
      return null;
    }
    return canciones[indiceActual!];
  }

  /// Espejo de `ListaDobleCircular::calcularDuracionTotalSegundos()`
  int get calcularDuracionTotalSegundos {
    var total = 0;
    for (final c in canciones) {
      total += c.duracionSegundos;
    }
    return total;
  }

  /// Espejo exacto de `InterfazConsola::formatearDuracionTotal(int totalSegundos)` (`HH:MM:SS`)
  static String formatearDuracionTotal(int totalSegundos) {
    final safe = totalSegundos < 0 ? 0 : totalSegundos;
    final horas = safe ~/ 3600;
    final minutos = (safe % 3600) ~/ 60;
    final segundos = safe % 60;
    final h = horas.toString().padLeft(2, '0');
    final m = minutos.toString().padLeft(2, '0');
    final s = segundos.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get duracionTotalFormateada =>
      formatearDuracionTotal(calcularDuracionTotalSegundos);

  String get duracionTotalLegible {
    final total = calcularDuracionTotalSegundos;
    final horas = total ~/ 3600;
    final minutos = (total % 3600) ~/ 60;
    final segundos = total % 60;
    if (horas > 0) {
      return '${horas}h ${minutos}m ${segundos}s';
    }
    return '$minutos min $segundos seg';
  }

  PlaylistModel copyWith({
    String? id,
    String? nombre,
    List<CancionModel>? canciones,
    int? indiceActual,
    bool clearIndiceActual = false,
    ModoRepeticion? modoRepeticion,
    bool? esActiva,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      canciones: canciones ?? this.canciones,
      indiceActual:
          clearIndiceActual ? null : (indiceActual ?? this.indiceActual),
      modoRepeticion: modoRepeticion ?? this.modoRepeticion,
      esActiva: esActiva ?? this.esActiva,
    );
  }
}

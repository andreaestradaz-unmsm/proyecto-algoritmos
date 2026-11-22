import 'cancion.dart';

/// Representa un nodo dentro de `ListaSimple historial` (`lista_simple.h` de Andrea
/// e integración en `GestorReproduccion::registrarEnHistorial` de Juan Pablo).
/// Las reproducciones más recientes se insertan en la cabeza (`agregarAlInicio`),
/// formando un orden LIFO cronológico inverso.
class HistorialItemModel {
  const HistorialItemModel({
    required this.idRegistro,
    required this.cancion,
    required this.fechaReproduccion,
    required this.origenNombre,
  });

  final String idRegistro;
  final CancionModel cancion;
  final DateTime fechaReproduccion;
  final String origenNombre;

  String get horaFormateada {
    final h = fechaReproduccion.hour.toString().padLeft(2, '0');
    final m = fechaReproduccion.minute.toString().padLeft(2, '0');
    final s = fechaReproduccion.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

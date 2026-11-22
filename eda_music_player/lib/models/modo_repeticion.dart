import 'package:material_ui/material_ui.dart';

/// Espejo exacto de `enum class ModoRepeticion` en `lista_doble_circular.h`:
/// - `SIN_REPETICION`: Al llegar a `cola`, `siguienteCancion()` retorna `nullptr` y se detiene.
/// - `REPETIR_UNA`: Mantiene el puntero `actual` en el mismo `NodoDoble`.
/// - `REPETIR_TODAS`: Aprovecha el enlace circular (`cola->siguiente == cabeza`).
enum ModoRepeticion {
  sinRepeticion,
  repetirUna,
  repetirTodas;

  String get etiqueta {
    switch (this) {
      case ModoRepeticion.sinRepeticion:
        return 'Sin repetición';
      case ModoRepeticion.repetirUna:
        return 'Repetir una';
      case ModoRepeticion.repetirTodas:
        return 'Repetir todas';
    }
  }

  String get etiquetaCorta {
    switch (this) {
      case ModoRepeticion.sinRepeticion:
        return '1× Lineal';
      case ModoRepeticion.repetirUna:
        return 'Loop 1';
      case ModoRepeticion.repetirTodas:
        return 'Circular ∞';
    }
  }

  String get identificadorCpp {
    switch (this) {
      case ModoRepeticion.sinRepeticion:
        return 'ModoRepeticion::SIN_REPETICION';
      case ModoRepeticion.repetirUna:
        return 'ModoRepeticion::REPETIR_UNA';
      case ModoRepeticion.repetirTodas:
        return 'ModoRepeticion::REPETIR_TODAS';
    }
  }

  String get explicacionEda {
    switch (this) {
      case ModoRepeticion.sinRepeticion:
        return 'Al llegar a cola, siguienteCancion() retorna nullptr y detiene el avance.';
      case ModoRepeticion.repetirUna:
        return 'El puntero actual permanece fijo en el NodoDoble en reproducción.';
      case ModoRepeticion.repetirTodas:
        return 'Recorrido circular continuo: cola->siguiente enlaza de vuelta a cabeza.';
    }
  }

  IconData get icono {
    switch (this) {
      case ModoRepeticion.sinRepeticion:
        return Icons.trending_flat_rounded;
      case ModoRepeticion.repetirUna:
        return Icons.repeat_one_rounded;
      case ModoRepeticion.repetirTodas:
        return Icons.repeat_rounded;
    }
  }

  ModoRepeticion get siguienteModo {
    switch (this) {
      case ModoRepeticion.repetirTodas:
        return ModoRepeticion.repetirUna;
      case ModoRepeticion.repetirUna:
        return ModoRepeticion.sinRepeticion;
      case ModoRepeticion.sinRepeticion:
        return ModoRepeticion.repetirTodas;
    }
  }
}

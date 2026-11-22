import 'package:eda_music_player/main.dart';
import 'package:eda_music_player/models/modo_repeticion.dart';
import 'package:eda_music_player/services/mock_music_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets(
    'Carga inicial de biblioteca.csv, reproducción y navegación entre las 4 vistas EDA',
    (WidgetTester tester) async {
      final repo = MockMusicRepository();

      await tester.pumpWidget(
        EdaMusicPlayerApp(
          repository: repo,
          enableAutoTicker: false,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifica que la vista Now Playing carga la primera canción de biblioteca.csv
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('1:21'), findsOneWidget);

      // 2. Navega a la pestaña Biblioteca (ListaSimple) y verifica las 5 canciones semilla
      await tester.tap(find.text('Biblioteca'));
      await tester.pumpAndSettle();

      expect(find.text('Biblioteca General'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsWidgets);
      expect(find.text('De Música Ligera'), findsOneWidget);
      expect(find.text('Billie Jean'), findsOneWidget);

      // Desplaza la lista de la biblioteca para verificar las últimas canciones semilla
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Tren al Sur'), findsOneWidget);
      expect(find.text('Clocks'), findsOneWidget);

      // 3. Navega a la pestaña Playlists (ListaDobleCircular)
      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();

      expect(find.text('Playlists Circulares'), findsOneWidget);
      expect(find.textContaining('Esenciales EDA'), findsWidgets);
      expect(find.text('Fisher-Yates'), findsOneWidget);

      // 4. Navega a la pestaña Historial (ListaSimple LIFO)
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de Reproducción'), findsOneWidget);
      expect(find.text('CABEZA (Más reciente)'), findsOneWidget);
    },
  );

  test(
    'MockMusicRepository replica fielmente ListaSimple, ListaDobleCircular y GestorReproduccion',
    () {
      final repo = MockMusicRepository();

      // Verifica las 5 canciones semilla de biblioteca.csv
      expect(repo.obtenerBiblioteca().length, 5);
      expect(
        repo.calcularDuracionTotalBibliotecaSegundos(),
        354 + 212 + 294 + 336 + 307,
      );

      final activa = repo.obtenerPlaylistActiva()!;
      expect(activa.tamano, 5);
      expect(activa.cancionActual?.titulo, 'Bohemian Rhapsody');

      // Navegación siguienteCancion() y anteriorCancion() en ListaDobleCircular
      final sig = repo.siguienteCancion();
      expect(sig?.titulo, 'De Música Ligera');
      expect(repo.obtenerHistorial().first.cancion.titulo, 'De Música Ligera');

      // Retroceso circular desde cabeza hacia cola
      repo.reproducirCancionEnPlaylist(playlistId: activa.id, indiceNodo: 0);
      final cola = repo.anteriorCancion();
      expect(cola?.titulo, 'Clocks');

      // Modo SIN_REPETICION en cola se detiene y retorna null
      repo.setModoRepeticion(ModoRepeticion.sinRepeticion);
      final detenido = repo.siguienteCancion();
      expect(detenido, isNull);

      // Fusión de playlists vaciando la secundaria (GestorReproduccion::fusionarListas)
      final playlists = repo.obtenerPlaylists();
      final p1 = playlists[0];
      final p2 = playlists[1];
      final okFusion = repo.fusionarPlaylists(
        playlistPrincipalId: p1.id,
        playlistSecundariaId: p2.id,
        vaciarSecundaria: true,
      );
      expect(okFusion, isTrue);
      expect(repo.obtenerPlaylistPorId(p1.id)?.tamano, 7);
      expect(repo.obtenerPlaylistPorId(p2.id)?.estaVacia, isTrue);
    },
  );
}

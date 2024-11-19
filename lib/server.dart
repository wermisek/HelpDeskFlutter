import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final router = Router();

  // Ścieżka do odbierania zgłoszeń
  router.post('/add_problem', (Request request) async {
    try {
      // Odczytujemy dane z ciała requesta
      var data = await request.readAsString();
      Map<String, dynamic> problem = jsonDecode(data);

      // Ścieżka do pliku z problemami
      File file = File('problems.json');
      List<Map<String, dynamic>> problems = [];

      // Sprawdzamy, czy plik istnieje
      if (await file.exists()) {
        String fileContent = await file.readAsString();
        problems = List<Map<String, dynamic>>.from(jsonDecode(fileContent));
      }

      // Dodajemy nowe zgłoszenie
      problems.add(problem);

      // Zapisujemy zaktualizowane dane
      await file.writeAsString(jsonEncode(problems));

      return Response.ok('Problem zapisany', headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      });
    } catch (e) {
      return Response.internalServerError(body: 'Błąd zapisywania problemu');
    }
  });

  // Ścieżka do pobierania zgłoszeń
  router.get('/get_problems', (Request request) async {
    try {
      File file = File('problems.json');
      if (await file.exists()) {
        String fileContent = await file.readAsString();
        return Response.ok(fileContent, headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      } else {
        return Response.ok('[]', headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        });
      }
    } catch (e) {
      return Response.internalServerError(body: 'Błąd odczytu problemów');
    }
  });

  // Startujemy serwer na porcie 8080
  var server = await shelf_io.serve(router, '0.0.0.0', 8080); // Correct method to use
  print('Serwer działa na http://localhost:8080');
}

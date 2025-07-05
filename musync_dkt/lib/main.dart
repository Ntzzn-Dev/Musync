import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

final mp3UpdatedNotifier = ValueNotifier(false);
void main() {
  runApp(const MyApp());
  startServer();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FileSystemEntity> mp3Files = [];

  @override
  void initState() {
    super.initState();
    _loadMp3Files();

    mp3UpdatedNotifier.addListener(() {
      _loadMp3Files();
    });
  }

  Future<void> _loadMp3Files() async {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(dir.path, 'mp3'));
    if (!musicDir.existsSync()) musicDir.createSync(recursive: true);

    setState(() {
      mp3Files =
          musicDir.listSync().where((f) => f.path.endsWith('.mp3')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Músicas Recebidas')),
      body: ListView.builder(
        itemCount: mp3Files.length,
        itemBuilder: (context, index) {
          final file = mp3Files[index];
          return ListTile(title: Text(p.basename(file.path)));
        },
      ),
    );
  }
}

void startServer() async {
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_uploadHandler);
  final server = await io.serve(handler, '0.0.0.0', 8080);
  log('Servidor rodando em http://${server.address.host}:${server.port}');
}

Future<Response> _uploadHandler(Request request) async {
  if (request.method != 'POST' || request.url.path != 'upload') {
    return Response.notFound('Rota não encontrada');
  }

  final contentType = request.headers['content-type'] ?? '';
  if (!contentType.contains('multipart/form-data')) {
    return Response(400, body: 'Content-Type deve ser multipart/form-data');
  }

  final boundary = contentType.split('boundary=').last;
  final parts = MimeMultipartTransformer(boundary).bind(request.read());

  try {
    final dir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(dir.path, 'mp3'));
    if (!musicDir.existsSync()) musicDir.createSync(recursive: true);

    await for (final part in parts) {
      final headers = part.headers;
      final disposition = headers['content-disposition'] ?? '';
      final match = RegExp(r'filename="(.+)"').firstMatch(disposition);

      if (match == null) continue;
      final filename = match.group(1)!;
      final file = File(p.join(musicDir.path, filename));
      final sink = file.openWrite();
      await part.pipe(sink);
      await sink.close();
      log('Salvo: ${file.path}');
    }

    mp3UpdatedNotifier.value = !mp3UpdatedNotifier.value;
    return Response.ok('Arquivo recebido');
  } catch (e) {
    log('Erro: $e');
    return Response.internalServerError(body: 'Erro no upload');
  }
}

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musync_dkt/themes.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

final mp3UpdatedNotifier = ValueNotifier(false);
/*void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  startServers();
}*/
final AudioPlayer player = AudioPlayer();
late WebSocket socket;
void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8080);
  print('Servidor rodando em ws://localhost:8080');

  runApp(const MyApp());

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      socket = await WebSocketTransformer.upgrade(request);
      print('Cliente conectado!');

      socket.listen((data) async {
        try {
          final decoded = jsonDecode(data);
          final action = decoded['action'];

          print('Ação recebida: $action');
          if (action == 'audio_file') {
            log('Recebendo música...');
            final dataList = List<int>.from(decoded['data']);
            final bytes = Uint8List.fromList(dataList);
            await tocarBytes(bytes);
          } else if (action == 'pause') {
            log('pausando');
            player.pause();
          } else if (action == 'play') {
            log('tocando');
            player.resume();
          } else if (action == 'position') {
            log('${Duration(milliseconds: decoded['data'].toInt())}');
            player.seek(Duration(milliseconds: decoded['data'].toInt()));
          }
        } catch (e) {
          print('Erro ao decodificar JSON ou tocar áudio: $e');
        }
      });
    }
  }
}

void enviarParaAndroid(WebSocket socket, String action, dynamic data) {
  final message = jsonEncode({"action": action, "data": data});

  socket.add(message);
}

/*void startServers() async {
  final player = AudioPlayer();
  final server = await HttpServer.bind('0.0.0.0', 8080);
  print('Servidor WebSocket rodando em ws://localhost:8080');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);

      socket.listen((data) async {
        final jsonData = jsonDecode(data);
        final action = jsonData['action'];

        if (action == 'play') {
          final media = jsonData['mediaItem'];
          await player.setUrl(media['url']);
          player.play();
        } else if (action == 'pause') {
          player.pause();
        } else if (action == 'seek') {
          player.seek(Duration(milliseconds: jsonData['position']));
        }

        // Enviar status de volta
        socket.add(
          jsonEncode({
            'status': player.playing ? 'playing' : 'paused',
            'position': player.position.inMilliseconds,
            'duration': player.duration?.inMilliseconds ?? 0,
          }),
        );
      });
    }
  }

  final channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.0.100:8080'), // IP do Windows
  );

  // Enviar comando play
  void playMedia(Map<String, dynamic> mediaItem) {
    final jsonCommand = jsonEncode({'action': 'play', 'mediaItem': mediaItem});
    channel.sink.add(jsonCommand);
  }

  // Receber status do Windows
  channel.stream.listen((data) {
    final status = jsonDecode(data);
    print('Status do player: $status');
  });
}*/
Future<void> tocarBytes(Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_audio.mp3');

  await tempFile.writeAsBytes(bytes, flush: true);

  await player.play(DeviceFileSource(tempFile.path));

  player.onPlayerComplete.listen((event) async {
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });

  enviarParaAndroid(socket, "position", 0);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musync',
      theme: lighttheme(),
      darkTheme: darktheme(),
      themeMode: ThemeMode.system,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Duration total = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    player.onDurationChanged.listen((d) {
      setState(() {
        total = d;
      });
    });

    player.onPositionChanged.listen((p) {
      setState(() {
        position = p;
      });
    });
  }

  String formatDuration(Duration d, bool h) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${h ? '$hours:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Músicas Recebidas')),
      body: Column(
        children: [
          Slider(
            min: 0,
            max: total.inMilliseconds.toDouble(),
            value:
                position.inMilliseconds
                    .clamp(0, total.inMilliseconds)
                    .toDouble(),
            onChanged: (value) {
              final newPos = Duration(milliseconds: value.toInt());
              player.seek(newPos);
              setState(() {
                position = newPos;
              });

              enviarParaAndroid(
                socket,
                "position",
                position.inMilliseconds.toDouble(),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position, false)),
              Text(formatDuration(total, false)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:musync_dkt/Services/audio_player.dart';
import 'package:musync_dkt/Services/media_music.dart';
import 'package:musync_dkt/Widgets/list_content.dart';
import 'package:musync_dkt/Widgets/player.dart';
import 'package:musync_dkt/Widgets/popup_add.dart';
import 'package:musync_dkt/themes.dart';
import 'dart:convert';

final MusyncAudioHandler player = MusyncAudioHandler();
late WebSocket socket;
void main() async {
  runApp(const MyApp());
}

void enviarParaAndroid(WebSocket socket, String action, dynamic data) {
  final message = jsonEncode({
    "action": action,
    "data": data,
    "time": DateTime.now().millisecondsSinceEpoch,
  });

  socket.add(message);
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
  ValueNotifier<bool> connected = ValueNotifier(false);
  ValueNotifier<String> musicsPercent = ValueNotifier('0%');
  String musicsLoaded = '0/0';

  final Map<String, List<int>> fileBuffers = {};

  void startServer() async {
    final server = await HttpServer.bind('0.0.0.0', 8080);
    print('Servidor rodando em ws://localhost:8080');
    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        socket = await WebSocketTransformer.upgrade(request);
        print('Cliente conectado!');
        connected.value = true;
        enviarParaAndroid(socket, 'volume', player.vol.value);

        socket.listen(
          (data) async {
            try {
              final decoded = jsonDecode(data);
              final action = decoded['action'];
              print('Ação recebida: $action');

              if (action == 'audio_start') {
                final title = decoded['audio_title'];
                fileBuffers[title] = [];
                print("Iniciando recebimento: $title");
              } else if (action == 'audio_chunk') {
                final title = decoded['audio_title'];
                final bytes = base64Decode(decoded['data']);
                fileBuffers[title]?.addAll(bytes);
              } else if (action == 'audio_end') {
                final title = decoded['audio_title'];
                final artist = decoded['audio_artist'];

                if (fileBuffers.containsKey(title)) {
                  final fullBytes = Uint8List.fromList(fileBuffers[title]!);
                  fileBuffers.remove(title);

                  await player.tocarMusic({
                    'audio_title': title,
                    'audio_artist': artist,
                    'data': fullBytes,
                    'id': int.parse(decoded['id'].split("/").last),
                    'part': decoded['parte'],
                    'art': decoded['artUri'],
                  }, musicsLoaded.split('/').first == '0');

                  addLoaded();

                  print("Música recebida: $title");
                }
              } else if (action == 'package_start') {
                log("Iniciando pacote de músicas...");
                player.songsAtual.value.clear();
                musicsLoaded = '0/${decoded['count']}';
              } else if (action == 'package_end') {
                log("Fim da primeira parte");
              } else if (action == 'toggle_play') {
                if (decoded['data']) {
                  player.resume();
                } else {
                  player.pause();
                }
              } else if (action == 'position') {
                final pos = Duration(milliseconds: decoded['data'].toInt());
                player.seek(pos);
              } else if (action == 'volume') {
                double vol = decoded['data'].toDouble();
                player.setVolume(vol);
              } else if (action == 'newindex') {
                int newindex = decoded['data'].toInt();
                player.setIndex(newindex);
              }
            } catch (e) {
              print('Erro ao decodificar JSON ou tocar áudio: $e');
            }
          },
          onError: (error) {
            print('Erro no socket: $error');
            connected.value = false;
          },
          onDone: () {
            print('Cliente desconectado!');
            connected.value = false;
          },
          cancelOnError: true,
        );
      }
    }
  }

  void addLoaded() {
    final regex = RegExp(r'^\s*(\d+)\s*/\s*(\d+)\s*$');

    final match = regex.firstMatch(musicsLoaded);
    if (match != null) {
      final first = int.parse(match.group(1)!) + 1;
      final second = int.parse(match.group(2)!);

      musicsPercent.value = '${(first / second * 100).toStringAsFixed(1)}%';

      musicsLoaded = '$first/$second';
    }
  }

  @override
  void initState() {
    super.initState();
    startServer();
    player.setVolume(50);
  }

  void _toggleBottom() {
    bottomPosition.value = bottomPosition.value == -135 ? 0 : -135;
  }

  ValueNotifier<double> bottomPosition = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas Recebidas'),
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: musicsPercent,
            builder: (context, value, child) {
              final qnts = RegExp(
                r'^\s*(\d+)\s*/\s*(\d+)\s*$',
              ).firstMatch(musicsLoaded)?.group(2);

              return Tooltip(
                message: 'Músicas carregadas: $musicsLoaded',
                child: Row(
                  children: [
                    Icon(Icons.music_note_outlined),
                    Text(value == '100.0%' ? qnts ?? '' : value),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 9),
          ValueListenableBuilder<bool>(
            valueListenable: connected,
            builder: (context, value, child) {
              if (value) {
                return GestureDetector(
                  onTap: () async {
                    if (await showPopupAdd(
                      context,
                      'Conectado ao smartphone\nDeseja deconectar?',
                      [],
                    )) {
                      socket.close();
                    }
                  },
                  child: Icon(Icons.connected_tv),
                );
              }
              return SizedBox.shrink();
            },
          ),
          const SizedBox(width: 9),
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<List<MediaMusic>>(
            valueListenable: player.songsAtual,
            builder: (context, value, child) {
              return ListContent(
                audioHandler: player,
                songsNow: player.songsAtual.value,
                modeReorder: ModeOrderEnum.dataAZ,
              );
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: bottomPosition,
            builder: (context, value, child) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                bottom: value,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    _toggleBottom();
                  },
                  child: Player(player: player),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

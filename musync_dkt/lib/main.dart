import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musync_dkt/Services/audio_player.dart';
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
  ValueNotifier<MediaAtual> mediaAtual = ValueNotifier(
    MediaAtual(title: 'Titulo', artist: 'Artista'),
  );

  void startServer() async {
    final server = await HttpServer.bind('0.0.0.0', 8080);
    print('Servidor rodando em ws://localhost:8080');
    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        socket = await WebSocketTransformer.upgrade(request);
        print('Cliente conectado!');
        connected.value = true;

        socket.listen(
          (data) async {
            try {
              final decoded = jsonDecode(data);
              final action = decoded['action'];

              print('Ação recebida: $action');
              if (action == 'audio_file') {
                log('Recebendo música...');
                await player.tocarMusic(decoded);

                enviarParaAndroid(socket, "position", 0);
                mediaAtual.value = MediaAtual(
                  title: decoded['audio_title'],
                  artist: 'artist',
                );
              } else if (action == 'toggle_play') {
                if (decoded['data']) {
                  log('tocando');
                  player.resume();
                } else {
                  log('pausando');
                  player.pause();
                }
              } else if (action == 'position') {
                log('${Duration(milliseconds: decoded['data'].toInt())}');
                player.seek(Duration(milliseconds: decoded['data'].toInt()));
              } else if (action == 'volume') {
                double vol = decoded['data'].toDouble();
                player.setVolume(vol);
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

  @override
  void initState() {
    super.initState();
    startServer();
    player.setVolume(50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas Recebidas'),
        actions: [
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
        ],
      ),
      body: Column(children: [Player(player: player, media: mediaAtual)]),
    );
  }
}

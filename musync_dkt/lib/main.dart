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
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

final MusyncAudioHandler player = MusyncAudioHandler();
late WebSocket socket;
void main() async {
  runApp(const MyApp());
}

void enviarParaAndroid(WebSocket socket, String action, dynamic data) {
  try {
    final message = jsonEncode({
      "action": action,
      "data": data,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    socket.add(message);
  } catch (e) {
    log(e.toString());
  }
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

              switch (action) {
                case 'audio_start':
                  final title = decoded['audio_title'];
                  fileBuffers[title] = [];
                  print("Iniciando recebimento: $title");
                  break;
                case 'audio_chunk':
                  final title = decoded['audio_title'];
                  final bytes = base64Decode(decoded['data']);
                  fileBuffers[title]?.addAll(bytes);
                  break;
                case 'audio_end':
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
                  break;
                case 'add_to_atual':
                  player.songsAtual.value = [
                    ...player.songsAtual.value,
                    player.songsAll.firstWhere(
                      (msc) => msc.id == int.parse(decoded['data']),
                    ),
                  ];
                  addLoaded();
                  break;
                case 'package_start':
                  log("Iniciando pacote de músicas...");
                  player.songsAtual.value.clear();
                  musicsLoaded = '0/${decoded['count']}';
                  break;
                case 'package_end':
                  log("Fim da primeira parte");
                  enviarParaAndroid(socket, "package_end", 0);
                  break;
                case 'request_data':
                  enviarParaAndroid(
                    socket,
                    'verify_data',
                    player.songsAll.map((msc) => msc.id).join(','),
                  );
                  break;
                case 'toggle_play':
                  if (decoded['data']) {
                    player.resume();
                  } else {
                    player.pause();
                  }
                  break;
                case 'position':
                  final pos = Duration(milliseconds: decoded['data'].toInt());
                  player.seek(pos);
                  break;
                case 'volume':
                  double vol = decoded['data'].toDouble();
                  player.setVolume(vol);
                  break;
                case 'newindex':
                  int newindex = decoded['data'].toInt();
                  log(newindex.toString());
                  player.setIndex(newindex);
                  break;
              }
            } catch (e) {
              print(
                'Erro ao decodificar JSON ou tocar áudio: $e  ${jsonDecode(data)['action']}',
              );
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

  Future<String?> getLocalIPAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIp = await info.getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty) {
        return wifiIp;
      }
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();

        if (name.toLowerCase().contains("virtual") ||
            name.toLowerCase().contains("vbox") ||
            name.toLowerCase().contains("radmin") ||
            name.toLowerCase().contains("vpn") ||
            name.toLowerCase().contains("vm")) {
          continue;
        }

        for (var addr in interface.addresses) {
          final ip = addr.address;

          if (!ip.startsWith("127.") && !ip.startsWith("169.")) {
            return ip;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  void enableQRCode() async {
    final ip = await getLocalIPAddress();

    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: connected,
          builder: (context, isConnected, _) {
            if (isConnected) {
              Future.microtask(() {
                if (Navigator.canPop(context)) Navigator.pop(context);
              });
            }

            return AlertDialog(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orangeAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PrettyQrView.data(
                      data: ip ?? '',
                      decoration: PrettyQrDecoration(
                        shape: PrettyQrShape.custom(
                          PrettyQrDotsSymbol(color: baseAppColor),
                          finderPattern: PrettyQrSmoothSymbol(
                            color: baseAppColor,
                          ),
                          alignmentPatterns: PrettyQrSmoothSymbol(
                            color: baseAppColor,
                          ),
                        ),
                        image: PrettyQrDecorationImage(
                          image: AssetImage("assets/MusyncLogo.png"),
                          colorFilter: ColorFilter.mode(
                            baseAppColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      errorCorrectLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fechar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          ElevatedButton(
            onPressed: () => enableQRCode(),
            child: Icon(Icons.qr_code_rounded),
          ),
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
                aposClique: (item) async {
                  int indiceCerto = player.songsAtual.value.indexWhere(
                    (t) => t == item,
                  );
                  player.setIndex(indiceCerto);
                },
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

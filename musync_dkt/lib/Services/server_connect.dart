import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:musync_dkt/main.dart';
import 'package:musync_dkt/themes.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

late WebSocket socket;
final Map<String, List<int>> fileBuffers = {};
String musicsLoaded = '0/0';

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

void enableQRCode(BuildContext context, ValueNotifier<bool> connected) async {
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

void addLoaded(ValueNotifier<String> musicsPercent) {
  final regex = RegExp(r'^\s*(\d+)\s*/\s*(\d+)\s*$');

  final match = regex.firstMatch(musicsLoaded);
  if (match != null) {
    final first = int.parse(match.group(1)!) + 1;
    final second = int.parse(match.group(2)!);

    musicsPercent.value = '${(first / second * 100).toStringAsFixed(1)}%';

    musicsLoaded = '$first/$second';
  }
}

void startServer(
  ValueNotifier<bool> connected,
  ValueNotifier<String> musicsPercent,
) async {
  final server = await HttpServer.bind('0.0.0.0', 8080);
  print('Servidor rodando em ws://localhost:8080');
  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      socket = await WebSocketTransformer.upgrade(request);
      print('Cliente conectado!');
      connected.value = true;
      enviarParaAndroid(socket, 'volume', audPl.vol.value);

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

                  await audPl.tocarMusic({
                    'audio_title': title,
                    'audio_artist': artist,
                    'data': fullBytes,
                    'id': int.parse(decoded['id'].split("/").last),
                    'part': decoded['parte'],
                    'art': decoded['artUri'],
                  }, musicsLoaded.split('/').first == '0');

                  addLoaded(musicsPercent);

                  print("Música recebida: $title");
                }
                break;
              case 'add_to_atual':
                audPl.songsAtual.value = [
                  ...audPl.songsAtual.value,
                  audPl.songsAll.firstWhere(
                    (msc) => msc.id == int.parse(decoded['data']),
                  ),
                ];
                addLoaded(musicsPercent);
                break;
              case 'package_start':
                log("Iniciando pacote de músicas...");
                audPl.songsAtual.value.clear();
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
                  audPl.songsAll.map((msc) => msc.id).join(','),
                );
                break;
              case 'toggle_play':
                if (decoded['data']) {
                  audPl.resume();
                } else {
                  audPl.pause();
                }
                break;
              case 'position':
                final pos = Duration(milliseconds: decoded['data'].toInt());
                audPl.seek(pos);
                break;
              case 'volume':
                double vol = decoded['data'].toDouble();
                audPl.setVolume(vol);
                break;
              case 'newindex':
                int newindex = decoded['data'].toInt();
                log(newindex.toString());
                audPl.setIndex(newindex);
                break;
              case 'shuffle':
                int newshuffle = decoded['data'].toInt();
                audPl.setShuffleModeFromInt(newshuffle);
                break;
              case 'loop':
                int newloop = decoded['data'].toInt();
                audPl.setLoopModeFromInt(newloop);
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

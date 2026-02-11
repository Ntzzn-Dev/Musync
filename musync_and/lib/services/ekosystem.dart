import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/audio_player_organize.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/helpers/qrcode_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

Ekosystem eko = Ekosystem.create();

class Ekosystem {
  ValueNotifier<bool> conected;
  ValueNotifier<Map<String, dynamic>?> receivedMessage;
  String host;
  int porta;
  String status;
  WebSocketChannel? channel;

  Ekosystem._internal({
    required this.conected,
    required this.receivedMessage,
    required this.host,
    required this.porta,
    required this.status,
  });

  factory Ekosystem.create() {
    return Ekosystem._internal(
      conected: ValueNotifier(false),
      receivedMessage: ValueNotifier(null),
      host: '',
      porta: 0,
      status: 'Desconectado',
    );
  }

  static void connectGlobal({required String host, required int porta}) {
    eko.host = host;
    eko.porta = porta;
    eko.status = "Tentando conectar...";

    eko.conect(host, porta);
  }

  static void setEkosystem() async {
    Ekosystem.connectGlobal(host: hostDkt, porta: 8080);

    mscAudPl.pause();

    eko.sendEkoLoop(mscAudPl.loopMode.value);
    eko.sendEkoShuffle(mscAudPl.shuffleMode.value);

    eko.sendMessage({
      'action': 'playlist_name',
      'title': MusyncAudioHandler.actlist.atualPlaylist.value.title,
      'subtitle': MusyncAudioHandler.actlist.atualPlaylist.value.subtitle,
    });

    if (eko.conected.value) {
      eko.sendMessage({'action': 'request_data', 'data': ''});
    }

    final songsAtual = MusyncAudioHandler.actlist.getMediaItemsFromQueue();

    MusyncAudioHandler.mediaAtual = ValueNotifier(
      MediaAtual(
        total:
            songsAtual[mscAudPl.currentIndex.value].duration ?? Duration.zero,
        id: songsAtual[mscAudPl.currentIndex.value].id,
        title: songsAtual[mscAudPl.currentIndex.value].title,
        artist: songsAtual[mscAudPl.currentIndex.value].artist,
        album: songsAtual[mscAudPl.currentIndex.value].album,
        artUri: songsAtual[mscAudPl.currentIndex.value].artUri,
      ),
    );

    eko.receivedMessage.addListener(() {
      final msg = eko.receivedMessage.value;

      switch (msg?['action']) {
        case 'verify_data':
          String allIds = msg?['data'];
          int atualId = msg?['atual'] + Ekosystem.indexInitial;
          final listIds = allIds.split(',');

          eko.sendAudios(
            MusyncAudioHandler.actlist.getMediaItemsFromQueue(),
            mscAudPl.currentIndex.value,
            listIds,
          );
          Ekosystem.indexInitial = mscAudPl.currentIndex.value;

          mscAudPl.setMediaIndex(atualId);
          break;
        case 'position':
          final progress = Duration(milliseconds: msg?['data'].toInt());
          MusyncAudioHandler.mediaAtual.value.seek(progress, ekoSending: false);
          break;
        case 'toggle_play':
          MusyncAudioHandler.mediaAtual.value.pauseAndPlay(msg?['data']);
          break;
        case 'volume':
          MediaAtual.volume.value = msg?['data'].toDouble();
          break;
        case 'newloop':
          mscAudPl.loopMode.value = enumFromInt(
            msg?['data'],
            ModeLoopEnum.values,
          );
          break;
        case 'newshuffle':
          mscAudPl.shuffleMode.value = enumFromInt(
            msg?['data'],
            ModeShuffleEnum.values,
          );
          break;
        case 'newindex':
          int indexRelative = msg?['data'].toInt() + Ekosystem.indexInitial;
          mscAudPl.setMediaIndex(indexRelative);
          break;
        case 'newtemporaryorder':
          mscAudPl.reorganizeSongsAtual(msg?['data']);
          break;
        case 'package_end':
          Ekosystem.indexInitial = 0;
          break;
        case 'wait_load':
          mscAudPl.sendMediaIndexShuffleOutOfLimits(msg?['min'], msg?['max']);
          break;
        case 'close_server':
          hostDkt = '';
          break;
      }
    });
  }

  void conect(String host, int porta) async {
    try {
      final ch = WebSocketChannel.connect(Uri.parse("ws://$host:$porta"));

      ch.stream.listen(
        (msg) {
          print("Mensagem recebida: $msg");
          final decoded = jsonDecode(msg);
          receivedMessage.value = decoded;
        },
        onDone: () {
          conected.value = false;
          status = "Conexão fechada";
        },
        onError: (e) {
          log("Erro no stream: $e");
          conected.value = false;
          status = "Erro ao conectar";
        },
      );

      channel = ch;
      conected.value = true;
      status = "Conectado!";
    } catch (e) {
      log("Não foi possível conectar: $e");
      conected.value = false;
      status = "Servidor indisponível";
    }
  }

  void tryToDisconect() {
    hostDkt = '';
    conected.value = false;
    status = "Desconectado";
    channel?.sink.close();
  }

  void sendMessage(Map<String, dynamic> act) {
    if (!eko.conected.value) return;

    if (!act['action'].startsWith('audio_')) {
      log('========================================');
      log(act['action']);
      log('========================================');
    }

    try {
      final msg = jsonEncode(act);
      channel?.sink.add(msg);
    } catch (e) {
      log(e.toString());
    }
  }

  static int indexInitial = 0;

  Future<void> sendFileInChunks(MediaItem music, int part) async {
    if (!conected.value) return;
    final file = File(music.extras?['path']);
    final stream = file.openRead();

    int chunkIndex = 0;

    sendMessage({
      "action": "audio_start",
      "audio_title": music.title,
      "audio_artist": music.artist,
      "id": music.id,
    });

    await for (final chunk in stream) {
      final base64Data = base64Encode(chunk);

      sendMessage({
        "action": "audio_chunk",
        "audio_title": music.title,
        "audio_artist": music.artist,
        "id": music.id,
        "index": chunkIndex,
        "data": base64Data,
      });
      chunkIndex++;

      await Future.delayed(const Duration(milliseconds: 5));
    }
    final artBase64 = await getArtBase64(music.artUri?.toString());
    sendMessage({
      "action": "audio_end",
      "audio_title": music.title,
      "audio_artist": music.artist,
      "id": music.id,
      "parte": part,
      "artUri": artBase64,
    });
  }

  Future<String?> getArtBase64(String? artUriStr) async {
    if (artUriStr == null) return null;

    try {
      final uri = Uri.parse(artUriStr);

      if (uri.scheme == 'file') {
        final file = File(uri.toFilePath());
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        }
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final response = await http.get(Uri.parse(artUriStr));
        if (response.statusCode == 200) return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      print('Erro ao ler artUri: $e');
    }

    return null;
  }

  Future<void> sendAudios(
    List<MediaItem> musicas,
    int indx,
    List<String> idsJaBaixados,
  ) async {
    List<MediaItem> mscs1 = musicas.sublist(indx);
    List<MediaItem> mscs2 = musicas.sublist(0, indx).reversed.toList();

    sendMessage({"action": "package_start", "count": musicas.length});

    for (final music in mscs1) {
      if (idsJaBaixados.contains(music.id.split("/").last)) {
        sendMessage({
          'action': 'add_to_atual',
          'data': music.id.split("/").last,
          "parte": 1,
        });
        continue;
      }
      await sendFileInChunks(music, 1);
    }

    for (final music in mscs2) {
      if (idsJaBaixados.contains(music.id.split("/").last)) {
        sendMessage({
          'action': 'add_to_atual',
          'data': music.id.split("/").last,
          "parte": 2,
        });
        continue;
      }
      await sendFileInChunks(music, 2);
    }

    sendMessage({"action": "package_end"});
  }

  void sendEkoShuffle(ModeShuffleEnum mode) {
    int i = enumToInt(mode);
    sendMessage({'action': 'shuffle', 'data': i});
  }

  void sendEkoLoop(ModeLoopEnum mode) {
    int i = enumToInt(mode);
    sendMessage({'action': 'loop', 'data': i});
  }
}

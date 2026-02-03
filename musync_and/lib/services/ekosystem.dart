import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

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

  static Future<Ekosystem> create({
    required String host,
    required int porta,
  }) async {
    final ekosystem = Ekosystem._internal(
      conected: ValueNotifier(false),
      receivedMessage: ValueNotifier(null),
      host: host,
      porta: porta,
      status: "Tentando conectar...",
    );
    await ekosystem.tryToConect(host, porta);

    return ekosystem;
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

  Future<bool> tryToConect(String host, int porta) async {
    try {
      final socket = await Socket.connect(
        host,
        porta,
        timeout: Duration(seconds: 2),
      );
      socket.destroy();

      conect(host, porta);
      return true;
    } catch (e) {
      log("Não foi possível conectar: $e");
      return false;
    }
  }

  void tryToDisconect() {
    channel?.sink.close();
    conected.value = false;
    status = "Desconectado";
  }

  void sendMessage(Map<String, dynamic> act) {
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

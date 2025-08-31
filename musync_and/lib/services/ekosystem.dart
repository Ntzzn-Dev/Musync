import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
    act['time'] = DateTime.now().millisecondsSinceEpoch;
    final msg = jsonEncode(act);
    channel?.sink.add(msg);
  }

  Future<void> sendAudioFile(MediaItem music) async {
    File file = File(music.extras?['path']);
    final bytes = await file.readAsBytes();
    print(music.title);

    final msg = {
      "action": "audio_file",
      "audio_title": music.title,
      "data": bytes,
    };

    sendMessage(msg);
  }
}

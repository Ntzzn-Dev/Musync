import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
import 'package:musync_and/services/databasehelper.dart';

class Playlists {
  int id;
  String title;
  String subtitle;
  int ordem;
  int orderMode;

  Playlists({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ordem,
    required this.orderMode,
  });

  factory Playlists.fromMap(Map<String, dynamic> map) {
    return Playlists(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      ordem: map['ordem'],
      orderMode: map['order_mode'],
    );
  }

  static Future<String> generateHashs(String filePath) async {
    final file = File(filePath);
    final fileLength = await file.length();
    final raf = file.openSync();

    try {
      final startBytes = raf.readSync(64 * 1024);

      List<int> endBytes = [];
      if (fileLength > 128 * 1024) {
        raf.setPositionSync(fileLength - (64 * 1024));
        endBytes = raf.readSync(64 * 1024);
      }

      final combined = [...startBytes, ...endBytes];

      final digest = sha256.convert(combined);
      return digest.toString();
    } finally {
      raf.closeSync();
    }
  }

  Future<List<MediaItem>?> findMusics(List<MediaItem> listaOriginal) async {
    List<String> hashsAlvo = await DatabaseHelper().loadPlaylistMusics(id);

    final futuros = listaOriginal.map((mediaItem) async {
      if (hashsAlvo.contains(mediaItem.extras?['hash'])) return mediaItem;

      return null;
    });

    final resultados = await Future.wait(futuros);

    return resultados.whereType<MediaItem>().toList();
  }
}

import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
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

  static Future<void> editarTags(
    String filePath,
    Map<String, dynamic> newData,
  ) async {
    try {
      Tag? oldTag = await AudioTags.read(filePath);

      Tag tag = Tag(
        title: (newData['title'] ?? oldTag?.title) ?? '',
        trackArtist: (newData['trackArtist'] ?? oldTag?.trackArtist) ?? '',
        album: (newData['album'] ?? oldTag?.album) ?? '',
        albumArtist: (newData['albumArtist'] ?? oldTag?.albumArtist) ?? '',
        genre: (newData['genre'] ?? oldTag?.genre) ?? '',
        year: (newData['year'] ?? oldTag?.year) ?? 0,
        trackNumber: (newData['trackNumber'] ?? oldTag?.trackNumber) ?? 0,
        trackTotal: (newData['trackTotal'] ?? oldTag?.trackTotal) ?? 0,
        discNumber: (newData['discNumber'] ?? oldTag?.discNumber) ?? 0,
        discTotal: (newData['discTotal'] ?? oldTag?.discTotal) ?? 0,
        duration: (newData['duration'] ?? oldTag?.duration) ?? 0,
        pictures: (newData['pictures'] ?? oldTag?.pictures) ?? [],
      );

      log((newData['trackArtist'] ?? oldTag?.trackArtist) ?? '');

      AudioTags.write(filePath, tag);

      await atualizarNoMediaStore(filePath);
      log('atualiado');
    } catch (e) {
      log("Erro ao editar tags: $e");
    }
  }

  static final MethodChannel _channel = MethodChannel(
    'br.com.nathandv.musync_and/scanfile',
  );

  static Future<void> atualizarNoMediaStore(String path) async {
    try {
      await _channel.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      log('Erro ao escanear: $e');
    }
  }
}

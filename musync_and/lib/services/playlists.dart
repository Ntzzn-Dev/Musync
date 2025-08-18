import 'dart:developer';
import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';

class Playlists {
  int id;
  String title;
  String subtitle;
  int ordem;
  int orderMode;
  bool? haveMusic;

  Playlists({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ordem,
    required this.orderMode,
    this.haveMusic,
  });

  Playlists copyWith({
    int? id,
    String? title,
    String? subtitle,
    int? ordem,
    int? orderMode,
    bool? haveMusic,
  }) {
    return Playlists(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      ordem: ordem ?? this.ordem,
      orderMode: orderMode ?? this.orderMode,
      haveMusic: haveMusic ?? this.haveMusic,
    );
  }

  factory Playlists.fromMap(Map<String, dynamic> map) {
    return Playlists(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      ordem: map['ordem'],
      orderMode: map['order_mode'],
    );
  }

  Future<List<MediaItem>?> findMusics() async {
    List<String> idsAlvo = await DatabaseHelper().loadPlaylistMusics(id);

    final futuros =
        idsAlvo.map((id) async {
          try {
            return MusyncAudioHandler.songsAll.firstWhere(
              (mediaItem) => mediaItem.id == id,
            );
          } catch (e) {
            return null;
          }
        }).toList();

    final resultados = await Future.wait(futuros);

    final musicas = resultados.whereType<MediaItem>();

    log(musicas.map((msc) => msc.title).toList().toString());

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

class PlaylistUpdateNotifier extends ChangeNotifier {
  void notifyPlaylistChanged() {
    notifyListeners();
  }
}

final playlistUpdateNotifier = PlaylistUpdateNotifier();

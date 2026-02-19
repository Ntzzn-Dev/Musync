import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

class DownloadSpecs {
  static final DownloadSpecs _instance = DownloadSpecs._internal();

  factory DownloadSpecs() {
    return _instance;
  }

  DownloadSpecs._internal();

  ValueNotifier<double> progressAtual = ValueNotifier(0);
  List<Video> videos = [];
  int qntDownloads = 0;
  ValueNotifier<String> situacao = ValueNotifier('Situação: Em espera.');
  ValueNotifier<String> titleAtual = ValueNotifier('Titulo');
  ValueNotifier<String> authorAtual = ValueNotifier('Artista');
  ValueNotifier<int> isDownloading = ValueNotifier(
    0,
  ); //0 - não, 1 - sim, 2 - finalizado

  String directory = '';
  double incremento = 100 / 6;

  var yt = YoutubeExplode();

  void setDirectory(String dir) {
    directory = dir;
  }

  void configurarDownloads(List<Video> newVideos) {
    videos = newVideos;
    qntDownloads = newVideos.length;
    situacao.value = 'Situação: Em espera.';
    startDownloads();
  }

  void startDownloads() async {
    isDownloading.value = 1;

    int qnt = 0;
    situacao.value = 'Situação: 0/${videos.length} Baixados';

    for (var video in videos) {
      titleAtual.value = video.title;
      authorAtual.value = video.author;
      await baixarAudio(video, video.title, video.author);
      qnt++;
      situacao.value = 'Situação: $qnt/${videos.length} Baixados';
    }

    isDownloading.value = 2;
  }

  void finish() {
    videos = [];
    qntDownloads = 0;
    situacao.value = 'Situação: Em espera.';
    isDownloading.value = 0;
    titleAtual.value = 'Titulo';
    authorAtual.value = 'Artista';
    progressAtual.value = 0;
  }

  void atualizarProgresso(ValueNotifier<double> p) {
    if (p.value >= 100) {
      p.value = 0;
    }
    p.value = p.value + incremento;
  }

  Future<void> accessStorage() async {
    var status = await Permission.manageExternalStorage.request();

    if (!status.isGranted) {
      await openAppSettings();
    }
  }

  Future<void> baixarAudio(Video video, String title, String artist) async {
    await accessStorage().then((_) async {
      progressAtual.value = 0.1;
      var manifest = await yt.videos.streams.getManifest(
        video.id,
        ytClients: [YoutubeApiClient.androidVr],
      );
      progressAtual.value = 0;
      atualizarProgresso(progressAtual);
      log('1');

      var audio = manifest.audioOnly.withHighestBitrate();

      log('1.1 $directory');

      if (!directory.endsWith('/')) directory += '/';

      await Directory(directory).create(recursive: true);

      String webmpath =
          '$directory${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.webm';

      String mp3path =
          '$directory${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.mp3';

      log('1.2');
      var file = File(webmpath);

      log('1.3');
      await yt.videos.streamsClient.get(audio).pipe(file.openWrite());
      atualizarProgresso(progressAtual);
      log('1.4');

      await convertWebmToMp3(webmpath, mp3path);
      atualizarProgresso(progressAtual);
      log('2');

      final url = await fetchThumbnailUrl(video.id.value);
      final img = await fetchThumbnailPicture(url);

      atualizarProgresso(progressAtual);
      log('3');

      await Playlists.editarTags(mp3path, {
        'title': title,
        'trackArtist': artist,
        'year': video.uploadDate?.year,
        'pictures': img,
      });
      atualizarProgresso(progressAtual);
      log('4');

      await onAudioQuery.scanMedia(mp3path);
      final song = await waitForMediaStore(mp3path);

      if (song != null) {
        final fileStat = await File(mp3path).stat();
        final lastModified = fileStat.modified.toIso8601String();

        final musicBaixada = MediaItem(
          id: song.uri!,
          title: song.title,
          artist: song.artist,
          album: song.album,
          genre: song.genre,
          duration: Duration(milliseconds: song.duration ?? 0),
          artUri: Uri.parse(url),

          extras: {'lastModified': lastModified, 'path': song.data},
        );

        MusyncAudioHandler.actlist.songsAll.add(musicBaixada);
        MusyncAudioHandler.actlist.songsAllPlaylist.add(musicBaixada);

        log('✅ Música adicionada: ${musicBaixada.title} ${musicBaixada.id}');
        log(
          '${MusyncAudioHandler.actlist.songsAll.last.title} - ${MusyncAudioHandler.actlist.songsAll.first.title}',
        );
      }

      await Playlists.atualizarNoMediaStore(mp3path);
      atualizarProgresso(progressAtual);
      log('5');
    });
  }

  Future<SongModel?> waitForMediaStore(
    String path, {
    int attempts = 5,
    Duration delay = const Duration(seconds: 1),
  }) async {
    await onAudioQuery.scanMedia(path);

    final nullSong = SongModel({});
    for (int i = 0; i < attempts; i++) {
      final songs = await onAudioQuery.querySongs();
      final song = songs.firstWhere(
        (s) => s.data == path,
        orElse: () => nullSong,
      );

      if (song != nullSong) return song;

      await Future.delayed(delay);
    }

    return null;
  }

  Future<String> fetchThumbnailUrl(String videoId) async {
    final List<String> res = [
      'maxresdefault.jpg',
      'sddefault.jpg',
      'hqdefault.jpg',
    ];

    for (final r in res) {
      final url = 'https://img.youtube.com/vi/$videoId/$r';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return url;
      }
    }
    return '';
  }

  Future<List<Picture>> fetchThumbnailPicture(String videoUrl) async {
    final response = await http.get(Uri.parse(videoUrl));

    if (response.statusCode == 200) {
      return [
        Picture(
          bytes: response.bodyBytes,
          mimeType: MimeType.jpeg,
          pictureType: PictureType.coverFront,
        ),
      ];
    }

    return [];
  }

  Future<void> convertWebmToMp3(String webmpath, String mp3path) async {
    final comando = '-i "$webmpath" -vn -acodec libmp3lame -q:a 2 "$mp3path"';

    await FFmpegKit.execute(comando).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        log('Conversão concluída: $mp3path');

        await File(webmpath).delete();
      } else {
        log('Erro ao converter: $returnCode');
      }
    });
  }
}

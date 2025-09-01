import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/playlists.dart';
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

  Future<void> baixarAudio(Video video, String title, String artist) async {
    progressAtual.value = 0.1;
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    progressAtual.value = 0;
    atualizarProgresso(progressAtual);

    var audio = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(audio);

    String webmpath =
        '$directory${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.webm';

    String mp3path =
        '$directory${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.mp3';

    var file = File(webmpath);
    var fileStream = file.openWrite();

    final totalBytes = audio.size.totalBytes;
    int downloadedBytes = 0;

    await for (final data in stream) {
      downloadedBytes += data.length;
      fileStream.add(data);

      progressAtual.value = (downloadedBytes / totalBytes) * incremento * 2;
    }
    await fileStream.flush();
    await fileStream.close();

    await convertWebmToMp3(webmpath, mp3path);
    atualizarProgresso(progressAtual);

    final thumbUrl =
        'https://img.youtube.com/vi/${video.id.value}/hqdefault.jpg';
    final response = await http.get(Uri.parse(thumbUrl));
    final thumbBytes = response.bodyBytes;

    List<Picture> img = [];
    if (response.statusCode == 200) {
      img = [
        Picture(
          bytes: thumbBytes,
          mimeType: MimeType.jpeg,
          pictureType: PictureType.coverFront,
        ),
      ];
    }
    atualizarProgresso(progressAtual);

    await Playlists.editarTags(mp3path, {
      'title': title,
      'trackArtist': artist,
      'year': video.uploadDate?.year,
      'pictures': img,
    });
    atualizarProgresso(progressAtual);

    final fileStat = await File(mp3path).stat();
    final lastModified = fileStat.modified.toIso8601String();
    final uri = Uri.file(mp3path).toString();

    MediaItem musicBaixada = MediaItem(
      id: uri,
      title: title,
      artist: artist,
      duration: video.duration ?? Duration.zero,
      extras: {'lastModified': lastModified, 'path': mp3path},
      artUri: Uri.parse(thumbUrl),
    );

    MusyncAudioHandler.songsAll.add(musicBaixada);

    await Playlists.atualizarNoMediaStore(mp3path);
    atualizarProgresso(progressAtual);
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

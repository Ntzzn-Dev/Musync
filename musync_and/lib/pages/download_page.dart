import 'package:audio_service/audio_service.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  ValueNotifier<String> safeTitle = ValueNotifier('Titulo');
  ValueNotifier<String> safeAuthor = ValueNotifier('Artista');
  int? year = 2000;
  String thumb = '';
  bool isLoading = false;
  String directory = '/storage/emulated/0/snaptube/download/SnapTube Audio/';
  var yt = YoutubeExplode();
  Map<String, dynamic>? tagsDiferenciadas = {};

  ValueNotifier<double> progresso = ValueNotifier(0);
  double etapas = 6;
  double progressoAtual = 0;
  late double incremento;

  bool _btnsActv = true;

  @override
  void initState() {
    super.initState();
    incremento = 100 / etapas;
  }

  void atualizarProgresso(ValueNotifier<double> p) {
    progressoAtual += incremento;
    p.value = progressoAtual;
  }

  final textController = TextEditingController();
  final padding = const EdgeInsets.all(8.0);

  Future<void> buscarVideo(String link) async {
    try {
      url = link;

      var video = await yt.videos.get(link);

      safeTitle.value = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      safeAuthor.value = video.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      year = video.uploadDate?.year;
    } catch (e) {
      return;
    }
  }

  Future<void> baixarAudio() async {
    var video = await yt.videos.get(url);
    atualizarProgresso(progresso);

    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    atualizarProgresso(progresso);

    var audio = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(audio);

    String webmpath = '$directory${safeTitle.value}.webm';

    String mp3path = '$directory${safeTitle.value}.mp3';

    var file = File(webmpath);
    var fileStream = file.openWrite();

    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();
    atualizarProgresso(progresso);

    yt.close();

    await convertWebmToMp3(webmpath, mp3path);
    atualizarProgresso(progresso);

    await Playlists.editarTags(mp3path, {
      'title': preferidaOuSafe(tagsDiferenciadas?['title'], safeTitle.value),
      'trackArtist': preferidaOuSafe(
        tagsDiferenciadas?['trackArtist'],
        safeAuthor.value,
      ),
      'album': preferidaOuSafe(tagsDiferenciadas?['album'], safeAuthor.value),
      'genre': tagsDiferenciadas?['genre'],
      'year': year,
    });
    atualizarProgresso(progresso);

    final hash = await Playlists.generateHashs(mp3path);
    final fileStat = await File(mp3path).stat();
    final lastModified = fileStat.modified.toIso8601String();
    final uri = Uri.file(mp3path).toString();

    MediaItem musicBaixada = MediaItem(
      id: uri,
      title: preferidaOuSafe(tagsDiferenciadas?['title'], safeTitle.value),
      artist: preferidaOuSafe(
        tagsDiferenciadas?['trackArtist'],
        safeAuthor.value,
      ),
      duration: video.duration ?? Duration.zero,
      album: preferidaOuSafe(tagsDiferenciadas?['album'], safeAuthor.value),
      genre: tagsDiferenciadas?['genre'],
      extras: {'lastModified': lastModified, 'path': mp3path, 'hash': hash},
    );

    MyAudioHandler.songsAll.add(musicBaixada);

    await Playlists.atualizarNoMediaStore(mp3path);
    atualizarProgresso(progresso);
  }

  String preferidaOuSafe(String? preferida, String safe) {
    return (preferida != null && preferida.trim().isNotEmpty)
        ? preferida
        : safe;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Musyout Download')),
      body: Center(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              Padding(
                padding: padding,
                child: Column(
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: safeTitle,
                      builder: (context, title, _) {
                        return Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: safeAuthor,
                      builder: (context, artist, _) {
                        return Text(
                          artist,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: padding,
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    contentPadding: padding,
                    hintText: 'Colar URL',
                    suffixIcon: IconButton(
                      onPressed: () async {
                        setState(() {
                          url = textController.text;
                          isLoading = true;
                        });
                        buscarVideo(url);
                      },
                      icon: Icon(Icons.search),
                    ),
                  ),
                  onChanged: (url) => buscarVideo(url),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_btnsActv == false) return;
                      baixarAudio();

                      setState(() {
                        _btnsActv = false;
                      });
                    },
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(_btnsActv ? 3 : 0),
                      backgroundColor: WidgetStateProperty.all(
                        _btnsActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledBack,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        _btnsActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledText,
                      ),
                    ),
                    child: Text('Baixar .mp3'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_btnsActv == false) return;

                      showPopupAdd(
                        context,
                        safeTitle.value,
                        [
                          {'value': 'Título', 'type': 'text'},
                          {'value': 'Artista', 'type': 'text'},
                          {'value': 'Album', 'type': 'text'},
                          {'value': 'Gênero', 'type': 'text'},
                        ],
                        fieldValues: [
                          safeTitle.value,
                          safeAuthor.value,
                          safeAuthor.value,
                          '',
                        ],
                        onConfirm: (valores) {
                          if (valores[0] != '') {
                            tagsDiferenciadas?['title'] = valores[0];
                            safeTitle.value = valores[0];
                          }
                          if (valores[1] != '') {
                            tagsDiferenciadas?['trackArtist'] = valores[1];
                            safeAuthor.value = valores[1];
                          }
                          if (valores[2] != '') {
                            tagsDiferenciadas?['album'] = valores[2];
                          }
                          if (valores[3] != '') {
                            tagsDiferenciadas?['genre'] = valores[3];
                          }
                        },
                      );
                    },
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(_btnsActv ? 3 : 0),
                      backgroundColor: WidgetStateProperty.all(
                        _btnsActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledBack,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        _btnsActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledText,
                      ),
                    ),
                    child: Text('Editar tags'),
                  ),
                ],
              ),
              ValueListenableBuilder<double>(
                valueListenable: progresso,
                builder: (context, pgr, _) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color.fromARGB(255, 243, 160, 34),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${pgr.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 243, 160, 34),
                            ),
                          ),
                          if (pgr.toStringAsFixed(0) == '100')
                            Text(
                              'Download Concluído',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Color.fromARGB(255, 243, 160, 34),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

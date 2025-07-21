import 'package:audio_service/audio_service.dart';
import 'package:crypto/crypto.dart';
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
import 'package:path_provider/path_provider.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  ValueNotifier<String> safeTitle = ValueNotifier('Titulo');
  ValueNotifier<String> safeAuthor = ValueNotifier('Artista');
  ValueNotifier<String> situation = ValueNotifier('Situação: Vazio');
  int? year = 2000;
  String thumb = '';
  bool isLoading = false;
  String directory = '/storage/emulated/0/snaptube/download/SnapTube Audio/';
  var yt = YoutubeExplode();
  Map<String, dynamic>? tagsDiferenciadas = {};

  ValueNotifier<double> progresso = ValueNotifier(0);
  double etapas = 5;
  double progressoAtual = 0;
  late double incremento;

  bool _btnDownloadActv = true;
  bool _btnTagActv = true;

  List<Map<String, dynamic>> videos = [];

  @override
  void initState() {
    super.initState();
    incremento = 100 / etapas;
    procurarPlaylist();
  }

  void procurarPlaylist() async {
    List<Video> resultado = await buscarVideos('https');

    videos =
        resultado.map((video) => {'video': video, 'selected': false}).toList();
    setState(() {});
  }

  void atualizarProgresso(ValueNotifier<double> p) {
    if (p.value >= 100) {
      progressoAtual = 0;
    }
    progressoAtual += incremento;
    p.value = progressoAtual;
  }

  final textController = TextEditingController();
  final padding = const EdgeInsets.all(8.0);

  Future<void> buscarVideo(String link) async {
    try {
      situation.value += 'Situação: Carregando.';
      url = link;

      var video = await yt.videos.get(link);

      safeTitle.value = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      safeAuthor.value = video.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final List<String> caminhos =
          MyAudioHandler.songsAll
              .map((item) => item.extras?['path'] as String?)
              .where((path) => path != null)
              .cast<String>()
              .toList();

      final jaBaixado = await verificarAudiosIguaisComLista(caminhos, url);

      if (jaBaixado) {
        situation.value += 'Situação: Música já baixada.';
        setState(() {
          _btnDownloadActv = false;
          _btnTagActv = false;
        });
      } else {
        situation.value += 'Situação: Música pronta para baixar.';
      }

      year = video.uploadDate?.year;
    } catch (e) {
      return;
    }
  }

  Future<List<Video>> buscarVideos(String link) async {
    final playlist = await yt.playlists.get(link);
    final videosStream = yt.playlists.getVideos(playlist.id);
    return await videosStream.take(200).toList();
  }

  Widget carregarVideos() {
    if (videos == null || videos.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index]['video'] as Video;
        final title = video.title;
        return ListTile(
          tileColor:
              videos[index]['selected']
                  ? Color.fromARGB(25, 243, 160, 34)
                  : null,
          leading: Image.network(
            'https://img.youtube.com/vi/${video.id.value}/hqdefault.jpg',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).extension<CustomColors>()!.subtextForce,
            ),
          ),
          onTap: () {
            setState(() {
              videos[index]['selected'] = !videos[index]['selected'];
              if (_btnTagActv) {
                _btnTagActv = false;
              }
            });
          },
        );
      },
    );
  }

  Future<String> gerarHashStreamYouTube(String url) async {
    final yt = YoutubeExplode();
    final video = await yt.videos.get(url);
    final manifest = await yt.videos.streamsClient.getManifest(video.id);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    final tempDir = await getTemporaryDirectory();
    final streamPath =
        '${tempDir.path}/temp_stream.${audioStreamInfo.container.name}';
    final file = File(streamPath);
    final fileStream = file.openWrite();

    final stream = yt.videos.streamsClient.get(audioStreamInfo);
    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    final hash = await gerarHashWav(streamPath);

    await file.delete();

    return hash;
  }

  Future<String> gerarHashWav(String inputPath) async {
    final tempDir = await getTemporaryDirectory();
    final wavPath = '${tempDir.path}/temp_audio.wav';

    await FFmpegKit.execute('-i "$inputPath" -f wav "$wavPath"');

    final wavFile = File(wavPath);
    final bytes = await wavFile.readAsBytes();

    final hash = md5.convert(bytes);
    return hash.toString();
  }

  Future<bool> verificarAudiosIguaisComLista(
    List<String> pathsMp3Local,
    String urlYoutube,
  ) async {
    final hashStream = await gerarHashStreamYouTube(urlYoutube);

    bool encontrouIgual = false;

    for (final pathMp3 in pathsMp3Local) {
      final hashMp3 = await gerarHashWav(pathMp3);

      if (hashMp3 == hashStream) {
        print('✅ Arquivo $pathMp3 tem o áudio igual ao do YouTube!');
        encontrouIgual = true;
        break;
      } else {
        print('❌ Arquivo $pathMp3 é diferente do áudio do YouTube.');
      }
    }

    if (!encontrouIgual) {
      print('Nenhum arquivo local corresponde ao áudio do YouTube.');
    }

    return encontrouIgual;
  }

  Future<void> baixarAudio(var video, String title, String artist) async {
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    atualizarProgresso(progresso);

    var audio = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(audio);

    String webmpath = '$directory$title.webm';

    String mp3path = '$directory$title.mp3';

    var file = File(webmpath);
    var fileStream = file.openWrite();

    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();
    atualizarProgresso(progresso);

    await convertWebmToMp3(webmpath, mp3path);
    atualizarProgresso(progresso);

    await Playlists.editarTags(mp3path, {
      'title': preferidaOuSafe(tagsDiferenciadas?['title'], title),
      'trackArtist': preferidaOuSafe(tagsDiferenciadas?['trackArtist'], artist),
      'album': preferidaOuSafe(tagsDiferenciadas?['album'], artist),
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
  void dispose() {
    yt.close();
    super.dispose();
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
                    ValueListenableBuilder<String>(
                      valueListenable: situation,
                      builder: (context, stt, _) {
                        return Text(
                          stt,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
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
                    onPressed: () async {
                      if (_btnDownloadActv == false) return;

                      setState(() {
                        _btnDownloadActv = false;
                        _btnTagActv = false;
                      });

                      List<Video> videosEscolhidos =
                          videos
                              .where((v) => v['selected'] == true)
                              .map<Video>((v) => v['video'] as Video)
                              .toList();

                      if (videosEscolhidos.isEmpty) {
                        baixarAudio(
                          await yt.videos.get(url),
                          safeTitle.value,
                          safeAuthor.value,
                        );
                      } else {
                        int qnt = 0;
                        situation.value =
                            'Situação: 0/${videosEscolhidos.length} Baixados';

                        for (var video in videosEscolhidos) {
                          await baixarAudio(video, video.title, video.author);
                          qnt++;
                          situation.value =
                              'Situação: $qnt/${videosEscolhidos.length} Baixados';
                        }
                      }
                    },
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all(
                        _btnDownloadActv ? 3 : 0,
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        _btnDownloadActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledBack,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        _btnDownloadActv
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
                      if (_btnTagActv == false) return;

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
                      elevation: WidgetStateProperty.all(_btnTagActv ? 3 : 0),
                      backgroundColor: WidgetStateProperty.all(
                        _btnTagActv
                            ? null
                            : Theme.of(
                              context,
                            ).extension<CustomColors>()!.disabledBack,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        _btnTagActv
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
              Expanded(child: carregarVideos()),
            ],
          ),
        ),
      ),
    );
  }
}

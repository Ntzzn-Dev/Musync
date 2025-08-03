import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:developer';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  ValueNotifier<String> safeTitle = ValueNotifier('Titulo');
  ValueNotifier<String> safeAuthor = ValueNotifier('Artista');
  ValueNotifier<String> situation = ValueNotifier('Situação: Em espera.');
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

  bool _btnDownloadActv = true;
  bool _btnTagActv = false;

  List<Map<String, dynamic>> videos = [];
  final List<String> caminhos =
      MusyncAudioHandler.songsAll
          .map((item) => item.extras?['path'] as String?)
          .where((path) => path != null)
          .cast<String>()
          .toList();

  bool podeSalvarPlaylist = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() async {
    incremento = 100 / etapas;

    final prefs = await SharedPreferences.getInstance();
    url = prefs.getString('playlist_principal') ?? '';

    procurarPlaylist(url);
  }

  void procurarPlaylist(String url) async {
    try {
      List<Video> resultado = await buscarVideos(url);

      videos =
          resultado
              .map((video) => {'video': video, 'selected': false})
              .toList();
      if (textController.text != '') {
        podeSalvarPlaylist = true;
        _btnTagActv = true;
      }
      setState(() {});
    } catch (e) {
      return;
    }
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
      situation.value = 'Situação: Carregando.';
      url = link;

      var video = await yt.videos.get(link);

      safeTitle.value = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      safeAuthor.value = video.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      situation.value = 'Situação: Música pronta para baixar.';

      year = video.uploadDate?.year;
      _btnTagActv = true;
    } catch (e) {
      procurarPlaylist(link);
    }
  }

  Future<List<Video>> buscarVideos(String link) async {
    final playlist = await yt.playlists.get(link);
    final videosStream = yt.playlists.getVideos(playlist.id);
    return await videosStream.take(200).toList();
  }

  Widget listarVideos() {
    if (videos.isEmpty) {
      return SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index]['video'] as Video;
        final title = video.title;
        final canal = video.author;
        return Container(
          color:
              videos[index]['selected']
                  ? Color.fromARGB(25, 243, 160, 34)
                  : null,
          height: 78,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                videos[index]['selected'] = !videos[index]['selected'];
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.network(
                      'https://img.youtube.com/vi/${video.id.value}/hqdefault.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          canal,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
    atualizarProgresso(progresso);

    await Playlists.editarTags(mp3path, {
      'title': preferidaOuSafe(tagsDiferenciadas?['title'], title),
      'trackArtist': preferidaOuSafe(tagsDiferenciadas?['trackArtist'], artist),
      'album': preferidaOuSafe(tagsDiferenciadas?['album'], artist),
      'genre': tagsDiferenciadas?['genre'],
      'year': year,
      'pictures': img,
    });
    atualizarProgresso(progresso);

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
      extras: {'lastModified': lastModified, 'path': mp3path},
      artUri: Uri.parse(thumbUrl),
    );

    MusyncAudioHandler.songsAll.add(musicBaixada);

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
                        return Player.titleText(title, 20);
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
                    hintText: 'Colar URL (vídeo ou playlist)',
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
                          safeTitle.value = video.title;
                          safeAuthor.value = video.author;
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
                    onPressed: () async {
                      if (_btnTagActv == false) return;

                      if (podeSalvarPlaylist) {
                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString('playlist_principal', url);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playlist definida como principal!'),
                          ),
                        );
                        return;
                      }

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
                    child: Text(
                      podeSalvarPlaylist ? 'Definir como' : 'Editar tags',
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder<double>(
                valueListenable: progresso,
                builder: (context, pgr, _) {
                  if (pgr == 0) {
                    return SizedBox.shrink();
                  } else {
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
                  }
                },
              ),
              Expanded(child: listarVideos()),
            ],
          ),
        ),
      ),
    );
  }
}

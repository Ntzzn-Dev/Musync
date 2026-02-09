import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/download.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  String url = '';
  late YoutubeExplode yt;

  bool _btnDownloadActv = true;

  List<Map<String, dynamic>> videos = [];
  final List<String> caminhos =
      MusyncAudioHandler.actlist.songsAll
          .map((item) => item.extras?['path'] as String?)
          .where((path) => path != null)
          .cast<String>()
          .toList();

  @override
  void initState() {
    super.initState();
    initAsync();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    yt.close();
    super.dispose();
  }

  void initAsync() async {
    WidgetsFlutterBinding.ensureInitialized();
    yt = YoutubeExplode();

    final prefs = await SharedPreferences.getInstance();
    url = prefs.getString('playlist_principal') ?? '';
    String directory = prefs.getString('dir_download') ?? '';
    DownloadSpecs().setDirectory(directory);

    if (directory == '') {
      showPopupAdd(
        context,
        'Adicione um diretório padrão para musicas baixadas',
        [ContentItem(value: 'Caminho', type: ContentTypeEnum.necessary)],
        onConfirm: (values) {
          prefs.setString('dir_download', values[0]);
        },
      );
    }

    setState(() {
      _btnDownloadActv = true;
    });

    procurarPlaylist(url);
  }

  void procurarPlaylist(String url) async {
    try {
      List<Video> resultado = await buscarVideos(url);

      videos =
          resultado
              .map((video) => {'video': video, 'selected': false})
              .toList();
      setState(() {});
    } catch (e) {
      return;
    }
  }

  final textController = TextEditingController();
  final padding = const EdgeInsets.all(8.0);

  Future<void> buscarVideo(String link) async {
    try {
      DownloadSpecs().situacao.value = 'Situação: Carregando.';
      url = link;

      var video = await yt.videos.get(link);

      DownloadSpecs().titleAtual.value = video.title;
      DownloadSpecs().authorAtual.value = video.author;

      DownloadSpecs().situacao.value = 'Situação: Música pronta para baixar.';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Adicione uma playlist padrão nas configurações para exibir seus vídeos aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index]['video'] as Video;
        final title = video.title;
        final canal = video.author;

        List<Widget> children = [];

        if (index % 10 == 0) {
          children.add(
            Container(
              height: 30,
              width: double.infinity,
              color: const Color.fromARGB(255, 54, 54, 54),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color.fromARGB(255, 243, 160, 34),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
        children.add(
          Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
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
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  Future<void> pedirPermissaoStorage() async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Permissão de armazenamento não concedida');
    }
  }

  String preferidaOuSafe(String? preferida, String safe) {
    return (preferida != null && preferida.trim().isNotEmpty)
        ? preferida
        : safe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MUSYNC DOWNLOAD',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: padding,
              child: Column(
                children: [
                  Padding(
                    padding: padding,
                    child: Column(
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: DownloadSpecs().titleAtual,
                          builder: (context, title, _) {
                            /*return Player.titleText(
                              "DESATIVADO TEMPORÁRIAMENTE",
                              20,
                            );*/
                            return Player.titleText(title, 20);
                          },
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: DownloadSpecs().authorAtual,
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
                          valueListenable: DownloadSpecs().situacao,
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
                            });
                            buscarVideo(url);
                          },
                          icon: Icon(Icons.search),
                        ),
                      ),
                      onChanged: (url) => buscarVideo(url),
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: DownloadSpecs().progressAtual,
                    builder: (context, pgr, _) {
                      if (pgr == 0.0) {
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
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: listarVideos(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () async {
                if (_btnDownloadActv == false) return;

                setState(() {
                  _btnDownloadActv = false;
                });

                List<Video> videosEscolhidos =
                    videos
                        .where((v) => v['selected'] == true)
                        .map<Video>((v) => v['video'] as Video)
                        .toList();

                if (videosEscolhidos.isEmpty) {
                  DownloadSpecs().configurarDownloads([
                    await yt.videos.get(url),
                  ]);
                } else {
                  DownloadSpecs().configurarDownloads(
                    videosEscolhidos.reversed.toList(),
                  );
                }
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all(const CircleBorder()),
                padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
                backgroundColor: WidgetStateProperty.all(
                  _btnDownloadActv
                      ? Theme.of(context).appBarTheme.foregroundColor
                      : Theme.of(
                        context,
                      ).extension<CustomColors>()!.disabledBack,
                ),
                foregroundColor: WidgetStateProperty.all(
                  _btnDownloadActv
                      ? Theme.of(context).cardTheme.color
                      : Theme.of(
                        context,
                      ).extension<CustomColors>()!.disabledText,
                ),
                elevation: WidgetStateProperty.all(_btnDownloadActv ? 3 : 0),
              ),
              child: Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}

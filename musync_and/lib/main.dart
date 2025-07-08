import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'themes.dart';
import 'services/audioPlayerBase.dart';

MyAudioHandler _audioHandler = MyAudioHandler();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.nathandv.musync_and',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musync',
      theme: lighttheme(),
      themeMode: ThemeMode.system,
      home: MusicPage(audioHandler: _audioHandler),
    );
  }
}

class MusicPage extends StatefulWidget {
  final MyAudioHandler audioHandler;

  const MusicPage({super.key, required this.audioHandler});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<FileSystemEntity> mp3Files = [];
  final TextEditingController _ipController = TextEditingController();
  String pcIp = '';
  ValueNotifier<String> tituloAtual = ValueNotifier('');
  ValueNotifier<bool> toRandom = ValueNotifier(false);
  ValueNotifier<int> toLoop = ValueNotifier(0);
  int currentPlayingIndex = 0;

  List<MediaItem> songs = [];

  @override
  void initState() {
    FetchSongs.execute().then((value) {
      setState(() {
        songs = value;
      });
      widget.audioHandler.initSongs(songs: songs);
    });

    super.initState();
    _loadItems();
    _loadIp();
    _requestPermissionAndLoad();
  }

  void _loadItems() async {
    widget.audioHandler.isShuffleEnabled().then((enabled) {
      toRandom.value = enabled;
    });

    final loopMode = await widget.audioHandler.isLoopEnabled();
    toLoop.value =
        {LoopMode.off: 0, LoopMode.one: 1, LoopMode.all: 2}[loopMode]!;
  }

  Future<void> _requestPermissionAndLoad() async {
    var status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    final musicDir = Directory(
      '/storage/emulated/0/snaptube/download/SnapTube Audio',
    );
    if (musicDir.existsSync()) {
      final files = musicDir.listSync(recursive: true);
      setState(() {
        mp3Files = files.where((file) => file.path.endsWith('.mp3')).toList();
      });
      log('Arquivos encontrados: ${mp3Files.length}');
    } else {
      log('Diretório não encontrado');
    }
  }

  Future<void> _sendFileToPC(File file) async {
    if (pcIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina o IP do PC primeiro.')),
      );
      return;
    }

    final url = Uri.parse('http://$pcIp:8080/upload');

    try {
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Arquivo enviado!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro ao enviar arquivo')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pcIp = prefs.getString('pc_ip') ?? '';
      _ipController.text = pcIp;
    });
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void readMetaData(String path) async {
    final metadata = await MetadataRetriever.fromFile(File(path));

    tituloAtual.value = metadata.trackName ?? '';

    for (String arts in metadata.trackArtistNames ?? []) {
      log(arts);
    }

    log('${metadata.albumName} album');
    log('${metadata.albumArtistName} artista');
    log('${metadata.trackNumber} track');
    log('${metadata.albumLength} tamanho albun');
    log('${metadata.year} ano');
    log('${metadata.genre} genero');
    log('${metadata.authorName} autor');
    log('${metadata.writerName} escritor');
    log('${metadata.discNumber} disc');
    log('${metadata.mimeType} mime');
    log('${metadata.trackDuration} duracao');
    log('${metadata.bitrate} bitrate');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Músicas do Celular')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP do PC',
                          hintText: 'ex: 192.xxx.x.x',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'pc_ip',
                          _ipController.text.trim(),
                        );
                        setState(() {
                          pcIp = _ipController.text.trim();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IP salvo!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<MediaItem>>(
                  stream: widget.audioHandler.queue,
                  builder: (context, snapshot) {
                    final mediaItems = snapshot.data ?? [];

                    return ListView.builder(
                      itemCount: mediaItems.length,
                      itemBuilder: (context, index) {
                        final item = mediaItems[index];

                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.artist ?? "Artista desconhecido"),
                          trailing: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => _sendFileToPC(File(item.id)),
                          ),
                          tileColor:
                              currentPlayingIndex == index
                                  ? const Color.fromARGB(51, 243, 160, 34)
                                  : null,
                          onTap: () async {
                            try {
                              await widget.audioHandler.skipToQueueItem(index);
                              setState(() {
                                currentPlayingIndex = index;
                              });
                            } catch (e) {
                              log('Erro ao tocar música: $e');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Color.fromARGB(255, 255, 255, 255),
              surfaceTintColor: Colors.transparent,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    StreamBuilder<MediaItem?>(
                      stream: widget.audioHandler.mediaItem,
                      builder: (context, snapshot) {
                        final mediaItem = snapshot.data;

                        if (mediaItem == null) {
                          return const Text("...");
                        }
                        return Text(mediaItem.title);
                      },
                    ),
                    StreamBuilder<Duration>(
                      stream: widget.audioHandler.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final total =
                            widget.audioHandler.duration ?? Duration.zero;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 0),
                                child: Slider(
                                  min: 0,
                                  max: total.inMilliseconds.toDouble(),
                                  value:
                                      position.inMilliseconds
                                          .clamp(0, total.inMilliseconds)
                                          .toDouble(),
                                  onChanged: (value) {
                                    widget.audioHandler.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatDuration(position)),
                                  Text(formatDuration(total)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: toRandom,
                          builder: (context, value, child) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.all(15),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () async {
                                final newValue = !value;
                                await widget.audioHandler.setShuffleModeEnabled(
                                  newValue,
                                );
                                toRandom.value = newValue;
                              },
                              child: Icon(
                                value
                                    ? Icons.shuffle
                                    : Icons.arrow_right_alt_rounded,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.all(15),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            widget.audioHandler.skipToPrevious();
                            currentPlayingIndex =
                                widget.audioHandler.currentIndex!;
                          },
                          child: Icon(Icons.keyboard_double_arrow_left_sharp),
                        ),
                        const SizedBox(width: 16),
                        StreamBuilder<bool>(
                          stream: widget.audioHandler.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.all(15),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                isPlaying
                                    ? widget.audioHandler.pause()
                                    : widget.audioHandler.play();
                              },
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_outlined
                                    : Icons.play_arrow_outlined,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.all(15),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            widget.audioHandler.skipToNext();
                            currentPlayingIndex =
                                widget.audioHandler.currentIndex!;
                          },
                          child: Icon(Icons.keyboard_double_arrow_right_sharp),
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder<int>(
                          valueListenable: toLoop,
                          builder: (context, value, child) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.all(15),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () async {
                                LoopMode newloop = LoopMode.off;
                                final newValue = value == 2 ? 0 : value + 1;
                                switch (value) {
                                  case 0:
                                    newloop = LoopMode.off;
                                    break;
                                  case 1:
                                    newloop = LoopMode.all;
                                    break;
                                  case 2:
                                    newloop = LoopMode.one;
                                    break;
                                }
                                await widget.audioHandler.setLoopModeEnabled(
                                  newloop,
                                );
                                toLoop.value = newValue;
                              },
                              child: Icon(
                                value == 0
                                    ? Icons.arrow_right_alt_rounded
                                    : value == 1
                                    ? Icons.repeat_rounded
                                    : Icons.repeat_one_rounded,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.audioHandler.stop();
    super.dispose();
  }
}

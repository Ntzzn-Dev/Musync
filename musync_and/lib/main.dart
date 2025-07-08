import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/fetch_songs.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'themes.dart';
import 'services/audioPlayerBase.dart';

MyAudioHandler _audioHandler = MyAudioHandler();

enum ModeEnum { titleAZ, titleZA, dataAZ, dataZA }

extension ModeEnumExt on ModeEnum {
  ModeEnum next() {
    final nextIndex = (index + 1) % ModeEnum.values.length;
    return ModeEnum.values[nextIndex];
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.nathandv.musync_and',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
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
  ValueNotifier<int> currentPlayingIndex = ValueNotifier(0);

  var modeAtual = ModeEnum.titleAZ;

  List<MediaItem> songs = [];

  @override
  void initState() {
    super.initState();
    _savePreferences();
    _initFetchSongs();
    _loadLastUse();
    _loadIp();
  }

  Future<void> _initFetchSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final dirStrings = prefs.getStringList('directorys') ?? [];

    final fetchedSongs = await FetchSongs.execute(paths: dirStrings);

    setState(() {
      songs = fetchedSongs;
    });

    widget.audioHandler.initSongs(songs: songs);
  }

  Future<void> reorder(ModeEnum modeAtual) async {
    switch (modeAtual) {
      case ModeEnum.titleAZ:
        final ordenadas = [...songs]
          ..sort((a, b) => a.title.trim().compareTo(b.title.trim()));
        setState(() {
          songs = ordenadas;
        });
        await widget.audioHandler.recreateQueue(songs: songs);
        break;
      case ModeEnum.titleZA:
        final ordenadas = [...songs]
          ..sort((a, b) => b.title.trim().compareTo(a.title.trim()));
        setState(() {
          songs = ordenadas;
        });
        break;
      case ModeEnum.dataAZ:
        setState(() {
          songs.sort((a, b) {
            try {
              final rawA = a.extras?['lastModified'];
              final rawB = b.extras?['lastModified'];

              final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
              final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

              if (dateA == null || dateB == null) {
                return 0;
              }
              return dateA.compareTo(dateB);
            } catch (e) {
              log('Erro durante sort por data: $e');
              return 0;
            }
          });
        });

        break;
      case ModeEnum.dataZA:
        setState(() {
          songs.sort((a, b) {
            try {
              final rawA = a.extras?['lastModified'];
              final rawB = b.extras?['lastModified'];

              final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
              final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

              if (dateA == null || dateB == null) {
                return 0;
              }
              return dateB.compareTo(dateA);
            } catch (e) {
              log('Erro durante sort por data: $e');
              return 0;
            }
          });
        });

        break;
    }

    await widget.audioHandler.recreateQueue(songs: songs);
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

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('random_act', toRandom.value);
    prefs.setInt('loop_act', toLoop.value);
    prefs.setStringList('directorys', [
      '/storage/emulated/0/snaptube/download/SnapTube Audio',
    ]);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    toRandom.value = prefs.getBool('random_act') ?? false;
    toLoop.value = prefs.getInt('loop_act') ?? 0;
  }

  void _loadLastUse() async {
    _loadPreferences();

    widget.audioHandler.setShuffleModeEnabled(toRandom.value);

    final intToLoopMode = {0: LoopMode.off, 1: LoopMode.one, 2: LoopMode.all};

    LoopMode selectedMode = intToLoopMode[toLoop.value] ?? LoopMode.off;

    widget.audioHandler.setLoopModeEnabled(selectedMode);
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
                        /*final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'pc_ip',
                          _ipController.text.trim(),
                        );
                        setState(() {
                          pcIp = _ipController.text.trim();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IP salvo!')),
                        );*/
                        modeAtual = modeAtual.next();
                        await reorder(modeAtual);
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

                        return ValueListenableBuilder<int>(
                          valueListenable: currentPlayingIndex,
                          builder: (context, value, child) {
                            return ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                item.artist ?? "Artista desconhecido",
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () => _sendFileToPC(File(item.id)),
                              ),
                              tileColor:
                                  value == index
                                      ? const Color.fromARGB(51, 243, 160, 34)
                                      : null,
                              onTap: () async {
                                try {
                                  await widget.audioHandler.skipToQueueItem(
                                    index,
                                  );
                                  setState(() {
                                    currentPlayingIndex.value = index;
                                  });
                                } catch (e) {
                                  log('Erro ao tocar música: $e');
                                }
                              },
                            );
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
                          onPressed: () async {
                            await widget.audioHandler.skipToPrevious();
                            currentPlayingIndex.value =
                                widget.audioHandler.currentIndex! + 1;
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
                          onPressed: () async {
                            await widget.audioHandler.skipToNext();
                            currentPlayingIndex.value =
                                widget.audioHandler.currentIndex! + 1;
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

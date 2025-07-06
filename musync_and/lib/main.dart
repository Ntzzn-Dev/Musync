import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'themes.dart';
import 'dart:math' as mt;

void main() {
  runApp(const MyApp());
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
      home: const MusicPage(),
    );
  }
}

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<FileSystemEntity> mp3Files = [];
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _ipController = TextEditingController();
  String pcIp = '';
  bool isPlaying = false;
  ValueNotifier<String> tituloAtual = ValueNotifier('');
  ValueNotifier<bool> toLoop = ValueNotifier(false);
  ValueNotifier<bool> toRandom = ValueNotifier(false);
  int currentPlayingIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadIp();
    _requestPermissionAndLoad();

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
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

  void _playNext() async {
    if (currentPlayingIndex + 1 < mp3Files.length) {
      if (toRandom.value) {
        final random = mt.Random();
        currentPlayingIndex = random.nextInt(mp3Files.length);
      } else {
        currentPlayingIndex++;
      }
      final nextFile = mp3Files[currentPlayingIndex];
      try {
        await _player.setFilePath(nextFile.path);
        readMetaData(nextFile.path);
        _player.play();
        setState(() {});
      } catch (e) {
        log('Erro ao tocar próxima música: $e');
      }
    } else {
      if (toLoop.value) {
        currentPlayingIndex = -1;
        _playNext();
      } else {
        _player.stop();
      }
    }
  }

  void _playPrev() async {
    if (currentPlayingIndex - 1 > -1) {
      currentPlayingIndex--;
      final prevFile = mp3Files[currentPlayingIndex];
      try {
        await _player.setFilePath(prevFile.path);
        readMetaData(prevFile.path);
        _player.play();
        setState(() {});
      } catch (e) {
        log('Erro ao tocar música anterior: $e');
      }
    }
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
                child: ListView.builder(
                  itemCount: mp3Files.length,
                  itemBuilder: (context, index) {
                    final file = mp3Files[index];
                    return ListTile(
                      title: Text(p.basename(file.path).replaceAll('.mp3', '')),
                      onTap: () async {
                        try {
                          await _player.setFilePath(file.path);
                          readMetaData(file.path);
                          _player.play();
                          setState(() {
                            currentPlayingIndex = index;
                          });
                        } catch (e) {
                          log('Erro ao tocar música: $e');
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendFileToPC(File(file.path)),
                      ),
                      tileColor:
                          currentPlayingIndex == index
                              ? Color.fromARGB(51, 243, 160, 34)
                              : null,
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
                    ValueListenableBuilder<String>(
                      valueListenable: tituloAtual,
                      builder: (context, value, child) {
                        return Text(value);
                      },
                    ),
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final total = _player.duration ?? Duration.zero;

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
                                    _player.seek(
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
                              onPressed: () {
                                toRandom.value = !toRandom.value;
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
                            _playPrev();
                          },
                          child: Icon(Icons.keyboard_double_arrow_left_sharp),
                        ),
                        const SizedBox(width: 16),
                        StreamBuilder<bool>(
                          stream: _player.playingStream,
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
                                isPlaying ? _player.pause() : _player.play();
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
                            _playNext();
                          },
                          child: Icon(Icons.keyboard_double_arrow_right_sharp),
                        ),
                        const SizedBox(width: 16),
                        ValueListenableBuilder<bool>(
                          valueListenable: toLoop,
                          builder: (context, value, child) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.all(15),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                              ),
                              onPressed: () {
                                toLoop.value = !toLoop.value;
                              },
                              child: Icon(
                                value
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
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
    _player.dispose();
    super.dispose();
  }
}

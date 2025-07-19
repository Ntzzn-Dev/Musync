import 'package:flutter/material.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:developer';

class MainScreen extends StatefulWidget {
  final String inputUrl;
  const MainScreen({super.key, required this.inputUrl});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String url = '';
  String title = '';
  String thumb = '';
  bool isLoading = false;
  String directory = '';

  final textController = TextEditingController();
  final padding = const EdgeInsets.all(8.0);

  Future<void> baixarAudio(String url) async {
    var yt = YoutubeExplode();
    var video = await yt.videos.get(url);
    var manifest = await yt.videos.streamsClient.getManifest(video.id);
    var audio = manifest.audioOnly.withHighestBitrate();
    var stream = yt.videos.streamsClient.get(audio);

    String safeTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    String safeAuthor = video.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    String path =
        '/storage/emulated/0/snaptube/download/SnapTube Audio/$safeTitle.mp3';

    var file = File(path);
    var fileStream = file.openWrite();

    await stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    yt.close();
    log(safeAuthor);

    //Editar metadados

    log('Áudio salvo em: $path');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yout Dld')),
      body: Center(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              Padding(
                padding: padding,
                child: Column(
                  children: [
                    Text(title),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: Row(
                            children: [Text('mp3'), SizedBox(width: 10)],
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {},
                          child: Row(
                            children: [Text('mp4'), SizedBox(width: 10)],
                          ),
                        ),
                      ],
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
                    hintText: 'paste link',
                    suffixIcon: IconButton(
                      onPressed: () async {
                        log('1.1');
                        setState(() {
                          url = textController.text;
                          isLoading = true;
                        });
                        baixarAudio(url);
                      },
                      icon: Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (url) => baixarAudio(url),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

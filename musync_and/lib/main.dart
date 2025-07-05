import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MusicPage());
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

  @override
  void initState() {
    super.initState();
    _loadIp();
    _requestPermissionAndLoad();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Músicas do Celular')),
      body: Column(
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
                    await prefs.setString('pc_ip', _ipController.text.trim());
                    setState(() {
                      pcIp = _ipController.text.trim();
                    });
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('IP salvo!')));
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
                  title: Text(p.basename(file.path)),
                  onTap: () async {
                    try {
                      await _player.setFilePath(file.path);
                      _player.play();
                    } catch (e) {
                      log('Erro ao tocar música: $e');
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendFileToPC(File(file.path)),
                  ),
                );
              },
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

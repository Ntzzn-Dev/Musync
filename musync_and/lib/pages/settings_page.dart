import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final MusyncAudioHandler audioHandler;

  const SettingsPage({super.key, required this.audioHandler});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _playlistDefault = TextEditingController();
  final TextEditingController _dirDownload = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarPreferencias();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final plDefault = prefs.getString('playlist_principal') ?? '';
    final dirDownload = prefs.getString('dir_download') ?? '';

    _playlistDefault.text = plDefault;
    _dirDownload.text = dirDownload;
  }

  void salvar() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('playlist_principal', _playlistDefault.text);
    prefs.setString('dir_download', _dirDownload.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONFIGURAÇÕES',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'PREDEFINIÇÕES',
                      style: TextStyle(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _playlistDefault,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()?.textForce,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Playlist padrão',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dirDownload,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(
                              context,
                            ).extension<CustomColors>()?.textForce,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Diretório para downloads',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                horizontal: 10,
                              ),
                              child: Text("Remover Ups totais"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                bool pode = await showPopupAdd(
                                  context,
                                  "Deseja remover os ups de todas as playlists?",
                                  [],
                                );
                                if (pode) {
                                  await DatabaseHelper().unupInAllPlaylists();
                                }
                              },
                              child: Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                horizontal: 10,
                              ),
                              child: Text("Remover Ups da playlist atual"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                bool pode = await showPopupAdd(
                                  context,
                                  "Deseja remover todos os ups de \"${widget.audioHandler.atualPlaylist.value.title}\"",
                                  [],
                                );
                                if (pode) {
                                  await DatabaseHelper().unupInPlaylist(
                                    widget.audioHandler.atualPlaylist.value.tag,
                                  );
                                }
                              },
                              child: Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: carregarPreferencias,
                    child: const Text(
                      'Reverter',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: salvar,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

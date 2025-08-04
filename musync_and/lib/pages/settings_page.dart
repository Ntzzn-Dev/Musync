import 'package:flutter/material.dart';
import 'package:musync_and/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _playlistDefault = TextEditingController();
  final TextEditingController _dirDownload = TextEditingController();
  List<TextEditingController> dirControllers = [];

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
    final dirStrings = prefs.getStringList('directorys') ?? [];
    final plDefault = prefs.getString('playlist_principal') ?? '';
    final dirDownload = prefs.getString('dir_download') ?? '';

    _playlistDefault.text = plDefault;
    _dirDownload.text = dirDownload;

    setState(() {
      for (String dir in dirStrings) {
        dirControllers.add(TextEditingController(text: dir));
      }
    });
  }

  void salvar() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('playlist_principal', _playlistDefault.text);
    prefs.setString('dir_download', _dirDownload.text);
    prefs.setStringList(
      'directorys',
      dirControllers.map((item) => item.text).toList(),
    );
  }

  void addNewTextField() {
    setState(() {
      dirControllers.add(TextEditingController(text: ''));
    });
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
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
                        Theme.of(context).extension<CustomColors>()?.textForce,
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
                        Theme.of(context).extension<CustomColors>()?.textForce,
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
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'DIRETÓRIOS DE BUSCA',
                        style: TextStyle(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: addNewTextField,
                        child: Icon(Icons.add),
                      ),
                      ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children:
                            dirControllers.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.all(6),
                                child: TextField(
                                  controller: controller,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        Theme.of(
                                          context,
                                        ).extension<CustomColors>()?.textForce,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Diretório $index',
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
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
                ElevatedButton(onPressed: salvar, child: const Text('Salvar')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/audio_player_organize.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_info.dart';
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
  ValueNotifier<List<bool>> modeBattery = ValueNotifier([false, false, true]);

  @override
  void initState() {
    super.initState();
    carregarPreferencias();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final plDefault = prefs.getString('playlist_principal') ?? '';
    final dirDownload = prefs.getString('dir_download') ?? '';
    final modoEnergia = prefs.getInt('modo_energia') ?? modoDeEnergia;

    modeBattery.value = List.generate(3, (index) => index == modoEnergia);
    log(modeBattery.value[modoEnergia].toString() + 'ligado ou des');
    log(modoEnergia.toString());

    _playlistDefault.text = plDefault;
    _dirDownload.text = dirDownload;
  }

  void salvar() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('playlist_principal', _playlistDefault.text);
    prefs.setString('dir_download', _dirDownload.text);
    prefs.setInt('modo_energia', modeBattery.value.indexWhere((v) => v));
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
                                  "Deseja remover todos os ups de \"${MusyncAudioHandler.actlist.atualPlaylist.value.title}\"",
                                  [],
                                );
                                if (pode) {
                                  await DatabaseHelper().unupInPlaylist(
                                    MusyncAudioHandler
                                        .actlist
                                        .atualPlaylist
                                        .value
                                        .tag,
                                  );
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(60, 60, 60, 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Modos de energia",
                            style: TextStyle(
                              color: baseAppColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 152,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: modeBattery,
                                    builder: (_, value, s) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            'Modo Economia.............................',
                                            style: TextStyle(
                                              color:
                                                  value[0]
                                                      ? baseAppColor
                                                      : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Modo Balanceado..........................',
                                            style: TextStyle(
                                              color:
                                                  value[1]
                                                      ? baseAppColor
                                                      : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Modo Performance........................',
                                            style: TextStyle(
                                              color:
                                                  value[2]
                                                      ? baseAppColor
                                                      : Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                Column(
                                  children: [
                                    ToggleButtons(
                                      direction: Axis.vertical,
                                      isSelected: modeBattery.value,
                                      onPressed: (index) {
                                        modeBattery.value = List.generate(
                                          3,
                                          (i) => i == index,
                                        );
                                        switch (index) {
                                          case 0:
                                            showPopupInfo(
                                              context,
                                              title: 'Modo Economia!',
                                              message:
                                                  'O aplicativo não roda em segundo plano, então caso fique um tempo sem usar, o proprio android vai matar o processo.',
                                              icon:
                                                  Icons
                                                      .battery_charging_full_outlined,
                                              iconBackground: Colors.green,
                                            );
                                            break;
                                          case 1:
                                            showPopupInfo(
                                              context,
                                              title: 'Modo Balanceado!',
                                              message:
                                                  'O aplicativo fica rodando em segundo plano até 1 hora sem uso, depois disso ele permite que o android mate o processo a qualquer momento.',
                                              icon: Icons.battery_full_outlined,
                                            );
                                            break;
                                          case 2:
                                            showPopupInfo(
                                              context,
                                              title: 'Modo Performance!',
                                              message:
                                                  'O aplicativo roda em segundo plano até que seja manualmente fechado pelo usuário, podendo consumir mais bateria.',
                                              icon:
                                                  Icons
                                                      .battery_unknown_outlined,
                                              iconBackground: Colors.red,
                                            );
                                            break;
                                        }
                                        showPopupInfo(
                                          context,
                                          title: 'Aviso!',
                                          message:
                                              'É recomendado salvar e reiniciar o aplicativo para que o modo funcione corretamente.',
                                          icon: Icons.info_outline,
                                        );
                                      },
                                      children: const [
                                        Icon(
                                          Icons.battery_charging_full_outlined,
                                        ),
                                        Icon(Icons.battery_full_outlined),
                                        Icon(Icons.battery_unknown_outlined),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

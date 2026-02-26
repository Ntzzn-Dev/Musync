import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/helpers/enum_helpers.dart';
import 'package:musync_and/pages/control_page.dart';
import 'package:musync_and/pages/download_page.dart';
import 'package:musync_and/pages/settings_page.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/helpers/download_helper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:musync_and/widgets/popup_info.dart';
import 'package:musync_and/widgets/popup_list.dart';

List<Widget> reorderMenu({
  required ModeOrderEnum modeAtual,
  required BuildContext context,
  required void Function(ModeOrderEnum) onChange,
}) {
  ButtonStyle? styleFor(ModeOrderEnum mode) {
    return modeAtual == mode
        ? ButtonStyle(backgroundColor: WidgetStatePropertyAll(baseAppColor))
        : null;
  }

  Text buildText(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).extension<CustomColors>()!.textForce,
      ),
    );
  }

  return [
    MenuItemButton(
      style: styleFor(ModeOrderEnum.titleAZ),
      child: buildText('Titulo A - Z'),
      onPressed: () => onChange(ModeOrderEnum.titleAZ),
    ),
    MenuItemButton(
      style: styleFor(ModeOrderEnum.titleZA),
      child: buildText('Titulo Z - A'),
      onPressed: () => onChange(ModeOrderEnum.titleZA),
    ),
    MenuItemButton(
      style: styleFor(ModeOrderEnum.dataAZ),
      child: buildText('Data A - Z'),
      onPressed: () => onChange(ModeOrderEnum.dataAZ),
    ),
    MenuItemButton(
      style: styleFor(ModeOrderEnum.dataZA),
      child: buildText('Data Z - A'),
      onPressed: () => onChange(ModeOrderEnum.dataZA),
    ),
    MenuItemButton(
      style: styleFor(ModeOrderEnum.up),
      child: buildText('Ups'),
      onPressed: () => onChange(ModeOrderEnum.up),
    ),
  ];
}

Future<bool> selectPlaylistMenu(
  BuildContext context,
  List<String> idsMscs,
) async {
  List<Playlists> playlists = await DatabaseHelper.instance.loadPlaylists(
    idsMusic: idsMscs,
  );

  bool escolhido = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return FractionallySizedBox(
            heightFactor: 0.45,
            child: Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        showPopupAdd(
                          context,
                          'Adicionar Playlist',
                          [
                            ContentItem(
                              value: 'Título',
                              type: ContentTypeEnum.title,
                            ),
                            ContentItem(
                              value: 'Subtitulo',
                              type: ContentTypeEnum.text,
                            ),
                          ],
                          onConfirm: (valores) async {
                            DatabaseHelper.instance.insertPlaylist(
                              valores[0],
                              valores[1],
                              1,
                            );

                            playlists =
                                await DatabaseHelper.instance.loadPlaylists();
                          },
                        );
                      },
                      child: const Text("Adicionar playlist"),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return Container(
                          color:
                              playlist.haveMusic ?? false
                                  ? Color.fromARGB(255, 243, 160, 34)
                                  : null,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              for (String id in idsMscs) {
                                if (playlist.haveMusic ?? false) {
                                  await DatabaseHelper.instance
                                      .removeFromPlaylist(playlist.id, id);
                                } else {
                                  await DatabaseHelper.instance.addToPlaylist(
                                    playlist.id,
                                    id,
                                  );
                                }
                              }

                              setModalState(() {
                                playlists[index] = playlist.copyWith(
                                  haveMusic: !(playlist.haveMusic ?? false),
                                );
                              });

                              escolhido = true;

                              showSnack(
                                '${playlist.haveMusic ?? false ? 'Removido de' : 'Adicionado à'} playlist: ${playlist.title}',
                                context,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    playlist.title,
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
                                    playlist.subtitle,
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
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return escolhido;
}

Widget searchMenu(
  BuildContext context,
  TextEditingController searchController, {
  void Function(String)? onChanged,
  void Function()? onClear,
}) {
  return Container(
    color: Theme.of(context).extension<CustomColors>()!.backgroundForce,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).extension<CustomColors>()!.textForce,
              ),
              decoration: const InputDecoration(
                labelText: 'Pesquisa',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
              searchController.clear();
              onClear?.call();
            },
            child: SizedBox(
              width: 30,
              child: Icon(
                Icons.close,
                color: Color.fromARGB(255, 243, 160, 34),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget downloadVisualizerMenu({required void Function() onFinalize}) {
  return ValueListenableBuilder<int>(
    valueListenable: DownloadSpecs.instance.isDownloading,
    builder: (context, value, child) {
      if (value == 1) {
        return ElevatedButton(
          onPressed: () async {
            showPopupList(
              context,
              'Fazendo Downloads ',
              [
                InfoItem(
                  info: 'Situação',
                  value:
                      DownloadSpecs.instance.situacao.value.split(
                        'Situação: ',
                      )[1],
                ),
                InfoItem(
                  info: 'Musica Atual',
                  value: DownloadSpecs.instance.titleAtual.value,
                ),
                InfoItem(
                  info: 'Artista Atual',
                  value: DownloadSpecs.instance.authorAtual.value,
                ),
              ],
              InfoLabelSpecs(
                info: InfoLabel(
                  name: '',
                  flex: 2,
                  centralize: true,
                  bold: true,
                ),
                value: InfoLabel(
                  name: '',
                  flex: 3,
                  centralize: true,
                  bold: false,
                ),
              ),
            );
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const CircleBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).appBarTheme.foregroundColor,
            ),
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).cardTheme.color,
            ),
            elevation: WidgetStateProperty.all(3),
          ),
          child: Icon(Icons.download_rounded),
        );
      }
      if (value == 2) {
        return ElevatedButton(
          onPressed: () async {
            showPopupInfo(
              context,
              title: 'Downloads finalizados!',
              message: 'Suas músicas foram baixadas com sucesso.',
              icon: Icons.music_note,
            );
            DownloadSpecs.instance.finish();
            onFinalize();
          },
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const CircleBorder()),
            padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).appBarTheme.foregroundColor,
            ),
            foregroundColor: WidgetStateProperty.all(
              Theme.of(context).cardTheme.color,
            ),
            elevation: WidgetStateProperty.all(3),
          ),
          child: Icon(Icons.download_done_rounded),
        );
      } else {
        return SizedBox.shrink();
      }
    },
  );
}

List<Widget> routesMenu({
  required BuildContext context,
  required ModeOrderEnum modeAtual,
  required void Function(BuildContext) onConnect,
  required void Function(ModeOrderEnum) onSwitchMode,
}) {
  return [
    SubmenuButton(
      menuChildren: reorderMenu(
        modeAtual: modeAtual,
        context: context,
        onChange: onSwitchMode,
      ),
      child: Text(
        'Reordenar',
        style: TextStyle(
          color: Theme.of(context).extension<CustomColors>()!.textForce,
        ),
      ),
    ),
    MenuItemButton(
      child: Text(
        'Download',
        style: TextStyle(
          color: Theme.of(context).extension<CustomColors>()!.textForce,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DownloadPage(),
            settings: RouteSettings(name: 'donwload'),
          ),
        ).then((_) => onSwitchMode(modeAtual));
      },
    ),
    MenuItemButton(
      child: Text(
        'Configurações',
        style: TextStyle(
          color: Theme.of(context).extension<CustomColors>()!.textForce,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(),
            settings: RouteSettings(name: 'settings'),
          ),
        );
      },
    ),
    MenuItemButton(
      child: Text(
        'SuperControl',
        style: TextStyle(
          color: Theme.of(context).extension<CustomColors>()!.textForce,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ControlPage(audioHandler: mscAudPl),
            settings: RouteSettings(name: 'control'),
          ),
        ).then((_) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SystemChrome.restoreSystemUIOverlays();
          });
        });
      },
    ),
    MenuItemButton(
      onPressed: () => onConnect(context),
      child: Text(
        'Connect Desktop',
        style: TextStyle(
          color: Theme.of(context).extension<CustomColors>()!.textForce,
        ),
      ),
    ),
  ];
}

void showSnack(String message, BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.center)));
}

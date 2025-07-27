import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup.dart';
import 'package:musync_and/widgets/popup_add.dart';

class ListPlaylist extends StatefulWidget {
  final void Function(Playlists)? escolhaDePlaylist;
  final void Function(String)? escolhaDeArtista;

  const ListPlaylist({
    super.key,
    this.escolhaDePlaylist,
    this.escolhaDeArtista,
  });
  @override
  State<ListPlaylist> createState() => _ListPlaylistState();
}

class _ListPlaylistState extends State<ListPlaylist> {
  dynamic convertReorder(dynamic value) {
    int? reorderFromString(String str) =>
        {'Titulo A-Z': 1, 'Titulo Z-A': 2, 'Data A-Z': 3, 'Data Z-A': 4}[str];

    String? reorderFromInt(int val) =>
        {1: 'Titulo A-Z', 2: 'Titulo Z-A', 3: 'Data A-Z', 4: 'Data Z-A'}[val];

    if (value is int) return reorderFromInt(value);
    if (value is String) return reorderFromString(value);
    return null;
  }

  List<Playlists> pls = [];
  List<String> arts = [];

  @override
  void initState() {
    super.initState();
    carregarPlaylists();
  }

  void carregarPlaylists() async {
    final listas = await DatabaseHelper().loadPlaylists();
    setState(() {
      pls = listas;
      arts =
          MyAudioHandler.songsAll
              .map((item) => (item.artist?.trim() ?? '').trim())
              .where((artist) => artist.trim().isNotEmpty)
              .toSet()
              .toList();
    });
    log(arts.length.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            showPopupAdd(
              context,
              'Adicionar Playlist',
              [
                {'value': 'Título', 'type': 'necessary'},
                {'value': 'Subtitulo', 'type': 'text'},
                {
                  'value': 'Modo de organização',
                  'type': 'dropdown',
                  'opts': ['Titulo A-Z', 'Titulo Z-A', 'Data A-Z', 'Data Z-A'],
                },
              ],
              onConfirm: (valores) async {
                DatabaseHelper().insertPlaylist(
                  valores[0],
                  valores[1],
                  1,
                  convertReorder(valores[2]),
                );

                carregarPlaylists();
              },
            );
          },
          child: Text('Adicionar Playlist'),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  itemCount: pls.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = pls[index];
                    return ListTile(
                      contentPadding: EdgeInsets.only(left: 16, right: 8),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).extension<CustomColors>()!.textForce,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).extension<CustomColors>()!.subtextForce,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color:
                                Theme.of(
                                  context,
                                ).extension<CustomColors>()!.textForce,
                          ),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            await showPopup(context, item.title, [
                              {
                                'opt': 'Apagar Playlist',
                                'funct': () async {
                                  if (await showPopupAdd(
                                    context,
                                    'Deletar playlist?',
                                    [],
                                  )) {
                                    await DatabaseHelper().removePlaylist(
                                      item.id,
                                    );

                                    pls =
                                        await DatabaseHelper().loadPlaylists();

                                    setState(() {});

                                    Navigator.of(context).pop();
                                  }
                                },
                              },
                              {
                                'opt': 'Editar Playlist',
                                'funct': () async {
                                  await showPopupAdd(
                                    context,
                                    'Editar Playlist',
                                    [
                                      {'value': 'Título', 'type': 'necessary'},
                                      {'value': 'Subtitulo', 'type': 'text'},
                                      {
                                        'value': 'Modo de organização',
                                        'type': 'dropdown',
                                        'opts': [
                                          'Titulo A-Z',
                                          'Titulo Z-A',
                                          'Data A-Z',
                                          'Data Z-A',
                                        ],
                                      },
                                    ],
                                    fieldValues: [
                                      item.title,
                                      item.subtitle,
                                      convertReorder(item.orderMode),
                                    ],
                                    onConfirm: (valores) async {
                                      await DatabaseHelper().updatePlaylist(
                                        item.id,
                                        title: valores[0],
                                        subtitle: valores[1],
                                        orderMode: convertReorder(valores[2]),
                                      );

                                      pls =
                                          await DatabaseHelper()
                                              .loadPlaylists();

                                      setState(() {});

                                      await ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Playlist Atualizada'),
                                        ),
                                      );
                                    },
                                  );
                                  Navigator.of(context).pop();
                                },
                              },
                            ]);
                          },
                        ),
                      ),
                      onTap: () async {
                        widget.escolhaDePlaylist?.call(item);
                      },
                    );
                  },
                ),

                Container(
                  height: 30,
                  width: double.infinity,
                  color: const Color.fromARGB(255, 54, 54, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Artistas',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 243, 160, 34),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                ListView.builder(
                  itemCount: arts.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 78,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          widget.escolhaDeArtista?.call(arts[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  arts[index],
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).extension<CustomColors>()!.textForce,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        /*Positioned(
          top: 60,
          left: 10,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 0, 0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              
            ),
          ),
        ),),*/
      ],
    );
  }
}

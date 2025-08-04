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
  final TextEditingController? searchController;

  const ListPlaylist({
    super.key,
    this.escolhaDePlaylist,
    this.escolhaDeArtista,
    this.searchController,
  });
  @override
  State<ListPlaylist> createState() => _ListPlaylistState();
}

class _ListPlaylistState extends State<ListPlaylist> {
  List<Playlists> plsBase = [];
  List<String> artsBase = [];

  List<Playlists> pls = [];
  List<String> arts = [];

  @override
  void initState() {
    super.initState();
    widget.searchController?.addListener(_onSearchChanged);
    carregarPlaylists();
  }

  void _onSearchChanged() {
    final valueSearch = widget.searchController?.text.toLowerCase().trim();
    setState(() {
      if (valueSearch != '') {
        pls =
            plsBase
                .where(
                  (pl) =>
                      pl.title.toLowerCase().trim().contains(valueSearch ?? ''),
                )
                .toList();
        arts =
            artsBase
                .where(
                  (art) => art.toLowerCase().trim().contains(valueSearch ?? ''),
                )
                .toList();
      } else {
        pls = plsBase;
        arts = artsBase;
      }
    });
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(_onSearchChanged);
    super.dispose();
  }

  void carregarPlaylists() async {
    final listas = await DatabaseHelper().loadPlaylists();
    setState(() {
      plsBase = listas;
      pls = plsBase;
      artsBase =
          MusyncAudioHandler.songsAll
              .expand(
                (item) => (item.artist ?? '')
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty),
              )
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      arts = artsBase;
    });
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
              ],
              onConfirm: (valores) async {
                DatabaseHelper().insertPlaylist(valores[0], valores[1], 1);

                carregarPlaylists();
              },
            );
          },
          child: Text('Adicionar Playlist'),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ...pls.map(
                (item) => ListTile(
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
                                await DatabaseHelper().removePlaylist(item.id);

                                pls = await DatabaseHelper().loadPlaylists();

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
                                ],
                                fieldValues: [item.title, item.subtitle],
                                onConfirm: (valores) async {
                                  await DatabaseHelper().updatePlaylist(
                                    item.id,
                                    title: valores[0],
                                    subtitle: valores[1],
                                  );

                                  plsBase =
                                      await DatabaseHelper().loadPlaylists();
                                  pls = plsBase;

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
                ),
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
                ),
              ),

              ...arts.map(
                (artist) => SizedBox(
                  height: 78,
                  child: InkWell(
                    onTap: () => widget.escolhaDeArtista?.call(artist),
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
                              artist,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

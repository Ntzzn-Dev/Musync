import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/popup_option.dart';
import 'package:musync_and/widgets/popup_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListPlaylist extends StatefulWidget {
  final MusyncAudioHandler audioHandler;
  final void Function(Playlists)? escolhaDePlaylist;
  final void Function(String)? escolhaDeArtista;
  final void Function(String)? escolhaDePasta;
  final void Function(String)? trocaDeMain;
  final TextEditingController? searchController;

  const ListPlaylist({
    super.key,
    required this.audioHandler,
    this.escolhaDePlaylist,
    this.escolhaDeArtista,
    this.escolhaDePasta,
    this.trocaDeMain,
    this.searchController,
  });

  static String getFolderName(String fullPath) {
    final folderPath = File(fullPath).parent.path;
    return '/${folderPath.split('/').last}';
  }

  static Future<String> getMainPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playlist_main') ?? '/Todas';
  }

  @override
  State<ListPlaylist> createState() => _ListPlaylistState();
}

class _ListPlaylistState extends State<ListPlaylist> {
  List<Playlists> plsBase = [];
  List<String> artsBase = [];
  List<String> foldsBase = [];

  List<Playlists> pls = [];
  List<String> arts = [];
  List<String> folds = [];

  String mainPlaylist = '';

  @override
  void initState() {
    super.initState();
    widget.searchController?.addListener(_onSearchChanged);
    ListPlaylist.getMainPlaylist().then((value) {
      setState(() {
        mainPlaylist = value;
      });
    });
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
        //folders =
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
    final playlists = await DatabaseHelper().loadPlaylists();
    final allSongs = MusyncAudioHandler.actlist.songsAll;

    List<List<String>> artists = [];
    List<String> folders = ['/Todas'];

    for (var song in allSongs) {
      final artistList =
          (song.artist ?? '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      artistList.sort();
      artists.add(artistList);

      final rawPath = "${song.extras?['path'] ?? ""}";

      final folderList = ListPlaylist.getFolderName(rawPath);
      if (!folders.contains(folderList)) {
        folders.add(folderList);
      }
    }

    Map<String, int> artistCount = {};
    for (var artist in artists) {
      final uniqueArtists = artist.toSet();
      for (var art in uniqueArtists) {
        artistCount[art] = (artistCount[art] ?? 0) + 1;
      }
    }

    List<List<String>> groupedArtists = [];
    Set<String> artistsAlreadyGrouped = {};

    for (var artist in artists) {
      if (artist.any((a) => artistsAlreadyGrouped.contains(a))) {
        continue;
      }

      bool allUnique = artist.every((a) => artistCount[a] == 1);

      if (allUnique && artist.length > 1) {
        groupedArtists.add(artist);
        artistsAlreadyGrouped.addAll(artist);
      } else {
        for (var art in artist) {
          if (!artistsAlreadyGrouped.contains(art)) {
            groupedArtists.add([art]);
            artistsAlreadyGrouped.add(art);
          }
        }
      }
    }

    List<String> foldersBase = folders;

    setState(() {
      plsBase = playlists;
      pls = plsBase;

      artsBase =
          groupedArtists.map((group) => group.join(', ')).toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      arts = artsBase;

      foldsBase = foldersBase;
      folds = foldsBase;
    });
  }

  List<OptionItem> moreOptions(BuildContext context, Playlists item) {
    return [
      OptionItem(
        actions: [
          OptionAction(
            label: 'Tornar principal',
            icon: Icons.emoji_events,
            funct: () async {
              await showPopupAdd(
                context,
                'Editar Playlist',
                [
                  ContentItem(value: 'Título', type: ContentTypeEnum.title),
                  ContentItem(value: 'Subtulo', type: ContentTypeEnum.text),
                ],
                fieldValues: [item.title, item.subtitle],
                onConfirm: (valores) async {
                  await DatabaseHelper().updatePlaylist(
                    item.id,
                    title: valores[0],
                    subtitle: valores[1],
                  );

                  plsBase = await DatabaseHelper().loadPlaylists();
                  pls = plsBase;

                  setState(() {});

                  await ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist Atualizada')),
                  );
                },
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Tornar principal',
            icon: Icons.edit,
            funct: () async {
              final turnMain = await showPopupAdd(
                context,
                'Tornar ${item.title} a playlist principal?',
                [],
              );

              if (turnMain) {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  mainPlaylist = '${item.id}';
                  prefs.setString('playlist_main', '${item.id}');
                  widget.trocaDeMain?.call('${item.id}');
                });
              }
            },
          ),
        ],
      ),
      OptionItem(
        actions: [
          OptionAction(
            label: 'Apagar Playlist',
            icon: Icons.delete_forever,
            funct: () async {
              if (await showPopupAdd(context, 'Deletar playlist?', [])) {
                await DatabaseHelper().removePlaylist(item.id);

                pls = await DatabaseHelper().loadPlaylists();

                setState(() {});

                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    ];
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
                ContentItem(value: 'Título', type: ContentTypeEnum.title),
                ContentItem(value: 'Subtitulo', type: ContentTypeEnum.text),
              ],
              onConfirm: (valores) async {
                DatabaseHelper().insertPlaylist(valores[0], valores[1], 1);

                widget.audioHandler.searchPlaylists();
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
                  tileColor:
                      mainPlaylist == '${item.id}'
                          ? baseAppColor
                          : Color.fromARGB(0, 0, 0, 0),
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
                        await showPopupOptions(
                          context,
                          item.title,
                          moreOptions(context, item),
                        );
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
                color: baseFundoDark,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pastas',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 243, 160, 34),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              ...folds.map(
                (folder) => Container(
                  color:
                      mainPlaylist == folder
                          ? baseAppColor
                          : Color.fromARGB(0, 0, 0, 0),
                  height: 78,
                  child: InkWell(
                    onTap: () => widget.escolhaDePasta?.call(folder),
                    onLongPress: () async {
                      final turnMain = await showPopupAdd(
                        context,
                        'Tornar $folder a playlist principal?',
                        [],
                      );

                      if (turnMain) {
                        final prefs = await SharedPreferences.getInstance();
                        setState(() {
                          mainPlaylist = folder;
                          prefs.setString('playlist_main', folder);
                          widget.trocaDeMain?.call(folder);
                        });
                      }
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
                              folder,
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

              Container(
                height: 30,
                width: double.infinity,
                color: baseFundoDark,
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
                (artist) => Container(
                  color:
                      mainPlaylist == artist
                          ? baseAppColor
                          : Color.fromARGB(0, 0, 0, 0),
                  height: 78,
                  child: InkWell(
                    onTap: () => widget.escolhaDeArtista?.call(artist),
                    onLongPress: () async {
                      final turnMain = await showPopupAdd(
                        context,
                        'Tornar todas as musicas de $artist a playlist principal?',
                        [],
                      );

                      if (turnMain) {
                        final prefs = await SharedPreferences.getInstance();
                        setState(() {
                          mainPlaylist = artist;
                          prefs.setString('playlist_main', artist);
                          widget.trocaDeMain?.call(artist);
                        });
                      }
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

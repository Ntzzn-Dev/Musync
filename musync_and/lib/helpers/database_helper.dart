import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/helpers/enum_helpers.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<void> accessStorage() async {
    final status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      final result = await Permission.manageExternalStorage.request();

      if (result.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  Future<String> getExternalDBPath() async {
    final directory = Directory("/storage/emulated/0/MuSyncDB");

    await accessStorage().then((_) async {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    });

    return "${directory.path}/musync.db";
  }

  Future<Database> _initDatabase() async {
    final externalPath = await getExternalDBPath();
    final dbFile = File(externalPath);

    if (dbFile.existsSync()) {
      return await openDatabase(
        externalPath,
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    }

    return await openDatabase(
      externalPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            subtitle TEXT,
            ordem INTEGER,
            order_mode INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE playlists_musics (
            id_playlist INTEGER,
            id_music TEXT,
            ordem INTEGER,
            FOREIGN KEY (id_playlist) REFERENCES playlists(id) ON DELETE CASCADE,
            PRIMARY KEY (id_playlist, id_music)
          )
        ''');

        await db.execute('''
          CREATE TABLE up_musics (
            id_playlist TEXT,
            id_music TEXT,
            added_at INTEGER,
            title TEXT,
            PRIMARY KEY (id_playlist, id_music)
          )
        ''');

        await db.execute('''
          CREATE TABLE desup_musics (
            id_playlist TEXT,
            id_music TEXT,
            added_at INTEGER,
            title TEXT,
            PRIMARY KEY (id_playlist, id_music)
          )
        ''');
      },
    );
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getExternalDBPath();
    await deleteDatabase(dbPath);
    log('Banco de dados deletado com sucesso.');
  }

  /* PLAYLISTS */
  Future<int> insertPlaylist(String title, String subtitle, int ordem) async {
    final db = await database;

    final id = await db.insert('playlists', {
      'title': title,
      'subtitle': subtitle,
      'ordem': ordem,
      'order_mode': 4,
    });
    return id;
  }

  Future<void> removePlaylist(int id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePlaylist(
    int id, {
    String? title,
    String? subtitle,
    int? ordem,
    int? orderMode,
  }) async {
    final db = await database;

    Map<String, dynamic> sql = {};

    if (title != null) sql['title'] = title;
    if (subtitle != null) sql['subtitle'] = subtitle;
    if (ordem != null) sql['ordem'] = ordem;
    if (orderMode != null) sql['order_mode'] = orderMode;

    await db.update('playlists', sql, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addToPlaylist(int idplaylist, String idMusic) async {
    final db = await database;

    await db.insert('playlists_musics', {
      'id_playlist': idplaylist,
      'id_music': idMusic,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    playlistUpdateNotifier.notifyPlaylistChanged();
  }

  Future<void> removeFromPlaylist(int idplaylist, String idMusic) async {
    final db = await database;

    await db.delete(
      'playlists_musics',
      where: 'id_playlist = ? AND id_music = ?',
      whereArgs: [idplaylist, idMusic],
    );

    playlistUpdateNotifier.notifyPlaylistChanged();
  }

  Future<List<Playlists>> loadPlaylists({
    String? idMusic,
    List<String>? idsMusic,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> playlistsFromDB = await db.query(
      'playlists',
      orderBy: 'ordem ASC',
    );

    if (idMusic == null && idsMusic == null) {
      return playlistsFromDB.map((e) => Playlists.fromMap(e)).toList();
    }

    if (idsMusic != null) {
      return Future.wait(
        playlistsFromDB.map((playlist) async {
          final idPlaylist = playlist['id'] as int;

          final result = await db.query(
            'playlists_musics',
            where:
                'id_playlist = ? AND id_music IN (${List.filled(idsMusic.length, '?').join(',')})',
            whereArgs: [idPlaylist, ...idsMusic],
          );

          final hasMusic = result.length == idsMusic.length;

          return Playlists(
            id: idPlaylist,
            title: playlist['title'],
            subtitle: playlist['subtitle'],
            ordem: playlist['ordem'],
            orderMode: playlist['order_mode'],
            haveMusic: hasMusic,
          );
        }),
      );
    }

    return Future.wait(
      playlistsFromDB.map((playlist) async {
        final idPlaylist = playlist['id'] as int;

        final result = await db.query(
          'playlists_musics',
          where: 'id_playlist = ? AND id_music = ?',
          whereArgs: [idPlaylist, idMusic],
        );

        final hasMusic = result.isNotEmpty;

        return Playlists(
          id: idPlaylist,
          title: playlist['title'],
          subtitle: playlist['subtitle'],
          ordem: playlist['ordem'],
          orderMode: playlist['order_mode'],
          haveMusic: hasMusic,
        );
      }),
    );
  }

  Future<Playlists?> loadPlaylist(int idPl) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [idPl],
    );

    if (result.isNotEmpty) {
      return Playlists.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<String> verifyPlaylistTitle(String baseTitle) async {
    final db = await database;
    String title = baseTitle.trim();
    int counter = 1;

    while (true) {
      final result = await db.query(
        'playlists',
        where: 'title = ?',
        whereArgs: [title],
      );

      if (result.isEmpty) {
        break;
      }

      title = '${baseTitle.trim()} ($counter)';
      counter++;
    }

    return title;
  }

  Future<List<String>> loadPlaylistMusics(int idplaylist) async {
    final db = await database;
    final List<Map<String, dynamic>> idsFromPlaylists = await db.query(
      'playlists_musics',
      where: 'id_playlist = ?',
      whereArgs: [idplaylist],
      orderBy: 'ordem ASC',
    );

    return List.generate(idsFromPlaylists.length, (i) {
      return idsFromPlaylists[i]['id_music'];
    });
  }

  Future<void> updateOrderMusics(List<MediaItem> songs, int idPlaylist) async {
    final db = await database;
    final batch = db.batch();

    log(songs.map((msc) => msc.title).toList().toString());

    int cont = 0;
    for (MediaItem song in songs) {
      cont++;
      batch.update(
        'playlists_musics',
        {'ordem': cont},
        where: 'id_playlist = ? AND id_music = ?',
        whereArgs: [idPlaylist, song.id],
      );
    }

    await batch.commit(noResult: true);
  }

  /* UP */
  Future<void> upInPlaylist(
    String idPlaylist,
    String idMusic,
    String title,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'up_musics',
        where: 'id_music = ? AND id_playlist = ?',
        whereArgs: [idMusic, idPlaylist],
      );
      await txn.delete(
        'desup_musics',
        where: 'id_music = ? AND id_playlist = ?',
        whereArgs: [idMusic, idPlaylist],
      );
    });

    await db.insert('up_musics', {
      'id_playlist': idPlaylist,
      'id_music': idMusic,
      'added_at': DateTime.now().millisecondsSinceEpoch,
      'title': title,
    });
  }

  Future<void> unupInPlaylist(String idplaylist) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'up_musics',
        where: 'id_playlist = ?',
        whereArgs: [idplaylist],
      );
      await txn.delete(
        'desup_musics',
        where: 'id_playlist = ?',
        whereArgs: [idplaylist],
      );
    });
  }

  Future<void> unupInAllPlaylists() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('up_musics');
      await txn.delete('desup_musics');
    });
  }

  Future<List<String>> loadUpMusics(String idplaylist) async {
    final db = await database;
    final List<Map<String, dynamic>> idsFromPlaylists = await db.query(
      'up_musics',
      where: 'id_playlist = ?',
      whereArgs: [idplaylist],
      orderBy: 'added_at DESC',
    );

    return List.generate(idsFromPlaylists.length, (i) {
      return idsFromPlaylists[i]['id_music'];
    });
  }

  /* DESUP */
  Future<void> desupInPlaylist(
    String idPlaylist,
    String idMusic,
    String title,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'up_musics',
        where: 'id_music = ? AND id_playlist = ?',
        whereArgs: [idMusic, idPlaylist],
      );
      await txn.delete(
        'desup_musics',
        where: 'id_music = ? AND id_playlist = ?',
        whereArgs: [idMusic, idPlaylist],
      );
    });

    await db.insert('desup_musics', {
      'id_playlist': idPlaylist,
      'id_music': idMusic,
      'added_at': DateTime.now().millisecondsSinceEpoch,
      'title': title,
    });
  }

  Future<List<String>> loadDesupMusics(String idplaylist) async {
    final db = await database;
    final List<Map<String, dynamic>> idsFromPlaylists = await db.query(
      'desup_musics',
      where: 'id_playlist = ?',
      whereArgs: [idplaylist],
      orderBy: 'added_at ASC',
    );

    return List.generate(idsFromPlaylists.length, (i) {
      return idsFromPlaylists[i]['id_music'];
    });
  }

  Future<List<MediaItem>> reorderToUp(
    String idPlAtual,
    List<MediaItem> setList,
  ) async {
    log(idPlAtual);
    List<String> ordemDasUps = await instance.loadUpMusics(idPlAtual);
    List<String> ordemDasDesups = await instance.loadDesupMusics(idPlAtual);

    final mapById = {for (var item in setList) item.id: item};

    log(setList.length.toString());

    List<MediaItem> resultadoUps =
        ordemDasUps.asMap().entries.map((entry) {
          final index = ordemDasUps.length - (entry.key);
          final id = entry.value;

          final mediaItem = mapById[id]!;

          mediaItem.extras!['prioridade'] = index;

          return mediaItem;
        }).toList();

    List<MediaItem> resultadoDesups =
        ordemDasDesups.asMap().entries.map((entry) {
          final index = (entry.key) + 1;
          final id = entry.value;

          final mediaItem = mapById[id]!;

          mediaItem.extras!['prioridade'] = -index;

          return mediaItem;
        }).toList();

    List<MediaItem> resultadoResto =
        setList
            .where(
              (x) => !resultadoUps.contains(x) && !resultadoDesups.contains(x),
            )
            .toList();

    List<MediaItem> restoReordenado = await reorderMusics(
      ModeOrderEnum.dataZA,
      resultadoResto,
    );

    return [...resultadoUps, ...restoReordenado, ...resultadoDesups];
  }

  /* TRIGGER */
  Future<void> deleteMusicTrigger(String idMusic) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'playlists_musics',
        where: 'id_music = ?',
        whereArgs: [idMusic],
      );

      await txn.delete(
        'up_musics',
        where: 'id_music = ?',
        whereArgs: [idMusic],
      );

      await txn.delete(
        'desup_musics',
        where: 'id_music = ?',
        whereArgs: [idMusic],
      );
    });
  }
}

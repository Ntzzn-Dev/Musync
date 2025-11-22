import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getExternalDBPath() async {
    final dir = await getExternalStorageDirectory();
    final dbDir = Directory("${dir!.path}/MusyncDB");

    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    return "${dbDir.path}/musync.db";
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
      },
    );
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'musyncand.db');
    await deleteDatabase(path);
    log('Banco de dados deletado com sucesso.');
  }

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
}

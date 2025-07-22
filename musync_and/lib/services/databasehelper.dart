import 'dart:developer';
import 'package:musync_and/services/playlists.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'musyncand.db');

    return await openDatabase(
      path,
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
            FOREIGN KEY (id_playlist) REFERENCES playlists(id) ON DELETE CASCADE,
            PRIMARY KEY (id_playlist, id_music)
          )
        ''');

        await db.execute('''
          CREATE TABLE music_hashes (
            id_music TEXT,
            hash_music TEXT,
            PRIMARY KEY (id_music, hash_music)
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

  Future<int> insertPlaylist(
    String title,
    String subtitle,
    int ordem,
    int orderMode,
  ) async {
    final db = await database;

    final id = await db.insert('playlists', {
      'title': title,
      'subtitle': subtitle,
      'ordem': ordem,
      'order_mode': orderMode,
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
  }

  Future<void> removeFromPlaylist(int idplaylist, String idMusic) async {
    final db = await database;

    await db.delete(
      'playlists_musics',
      where: 'id_playlist = ? AND id_music = ?',
      whereArgs: [idplaylist, idMusic],
    );
  }

  Future<List<Playlists>> loadPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> playlistsFromDB = await db.query(
      'playlists',
    );

    return List.generate(playlistsFromDB.length, (i) {
      return Playlists.fromMap(playlistsFromDB[i]);
    });
  }

  Future<List<String>> loadPlaylistMusics(int idplaylist) async {
    final db = await database;
    final List<Map<String, dynamic>> hashsFromPlaylists = await db.query(
      'playlists_musics',
      where: 'id_playlist = ?',
      whereArgs: [idplaylist],
    );

    return List.generate(hashsFromPlaylists.length, (i) {
      return hashsFromPlaylists[i]['id_music'];
    });
  }

  Future<void> addHash(String idMusic, String hashMusic) async {
    final db = await database;

    await db.insert('music_hashes', {
      'id_music': idMusic,
      'hash_music': hashMusic,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeHash(String idMusic, String hashMusic) async {
    final db = await database;

    await db.delete(
      'music_hashes',
      where: 'id_music = ? AND hash_music = ?',
      whereArgs: [idMusic, hashMusic],
    );
  }

  Future<String?> loadHashes(String idMusic) async {
    final db = await database;
    final result = await db.query(
      'music_hashes',
      where: 'id_music = ?',
      whereArgs: [idMusic],
    );

    if (result.isNotEmpty) {
      return result.first['hash_music'] as String;
    } else {
      return '';
    }
  }
}

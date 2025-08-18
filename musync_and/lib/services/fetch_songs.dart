import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

OnAudioQuery onAudioQuery = OnAudioQuery();

Future<void> accessStorage() async =>
    await Permission.storage.status.isGranted.then((granted) async {
      if (granted == false) {
        PermissionStatus permissionStatus = await Permission.storage.request();
        if (permissionStatus == PermissionStatus.permanentlyDenied) {
          await openAppSettings();
        }
      }
    });

Future<Uri?> _getArtUri(SongModel song) async {
  final artwork = await onAudioQuery.queryArtwork(song.id, ArtworkType.AUDIO);
  if (artwork != null) {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${song.id}.jpg');
    await file.writeAsBytes(artwork);
    return Uri.file(file.path);
  }
  return null;
}

class FetchSongs {
  static Future<List<MediaItem>> execute({List<String>? paths}) async {
    List<MediaItem> items = [];

    await accessStorage().then((_) async {
      List<SongModel> songs = await onAudioQuery.querySongs();

      if (paths != null && paths.isNotEmpty) {
        songs =
            songs.where((song) {
              return paths.any((path) => song.data.startsWith(path));
            }).toList();
      }

      final futures =
          songs.map((song) async {
            if (song.isMusic == true) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                song.dateAdded! * 1000,
              );
              await Playlists.atualizarNoMediaStore(song.data);

              return MediaItem(
                id: song.uri!,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre,
                duration: Duration(milliseconds: song.duration!),
                artUri: await _getArtUri(song),
                extras: {
                  'lastModified': date.toIso8601String(),
                  'path': song.data,
                },
              );
            }
            return null;
          }).toList();

      final results = await Future.wait(futures);
      items = results.whereType<MediaItem>().toList();
    });

    return items;
  }
}

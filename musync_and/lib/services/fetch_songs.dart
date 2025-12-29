import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

OnAudioQuery onAudioQuery = OnAudioQuery();

Future<void> accessStorage() async {
  final status = await Permission.audio.status;

  if (!status.isGranted) {
    final result = await Permission.audio.request();

    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
}

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
  static Future<List<MediaItem>> execute() async {
    List<MediaItem> items = [];

    await accessStorage().then((_) async {
      List<SongModel> songs = await onAudioQuery.querySongs();

      final futures =
          songs.map((song) async {
            if (song.isMusic == true) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                song.dateAdded! * 1000,
              );
              await Playlists.atualizarNoMediaStore(song.data);

              String album = song.album ?? '';

              return MediaItem(
                id: song.uri!,
                title: song.title,
                artist: song.artist,
                album: (album.isEmpty) ? '' : song.album,
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

import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

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

Future<Uint8List?> art({required int id}) async {
  return await onAudioQuery.queryArtwork(id, ArtworkType.AUDIO, quality: 100);
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
              final uint8list = await art(id: song.id);
              final bytes = uint8list?.toList();
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
                artUri: uint8list == null ? null : Uri.dataFromBytes(bytes!),
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

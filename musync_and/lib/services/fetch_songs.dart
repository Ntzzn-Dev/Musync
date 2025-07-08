import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
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

Future<Uint8List?> toImage({required Uri uri}) async {
  return base64.decode(uri.data!.toString().split(',').last);
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

      for (SongModel song in songs) {
        if (song.isMusic == true) {
          Uint8List? uint8list = await art(id: song.id);
          List<int> bytes = [];
          if (uint8list != null) {
            bytes = uint8list.toList();
          }
          final date = DateTime.fromMillisecondsSinceEpoch(
            song.dateAdded! * 1000,
          );
          items.add(
            MediaItem(
              id: song.uri!,
              title: song.title,
              artist: song.artist,
              duration: Duration(milliseconds: song.duration!),
              artUri: uint8list == null ? null : Uri.dataFromBytes(bytes),
              extras: {'lastModified': date.toIso8601String()},
            ),
          );
        }
      }
    });
    return items;
  }
}

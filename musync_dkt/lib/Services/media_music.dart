import 'dart:typed_data';

class MediaMusic {
  int id;
  String title;
  String artist;
  Uint8List bytes;
  Uint8List artUri;

  MediaMusic({
    required this.id,
    required this.title,
    required this.artist,
    required this.bytes,
    required this.artUri,
  });
}

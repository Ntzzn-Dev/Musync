import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';

class MediaAtual extends MediaItem {
  final Duration total;
  final ValueNotifier<Duration> position;
  static ValueNotifier<double> volume = ValueNotifier(50);
  double volumeatual = volume.value;
  bool muted = false;

  Timer? _timer;
  ValueNotifier<bool> isPlaying;

  MediaAtual({
    required this.total,
    required String id,
    required String title,
    Duration? start,
    String? album,
    String? artist,
    String? genre,
    Uri? artUri,
    Duration? duration,
    Map<String, dynamic>? extras,
  }) : position = ValueNotifier(start ?? Duration.zero),
       isPlaying = ValueNotifier(true),
       super(
         id: id,
         title: title,
         album: album,
         artist: artist,
         genre: genre,
         artUri: artUri,
         duration: duration ?? total,
         extras: extras,
       ) {
    _startTimer();
  }

  MediaAtual.fromMediaItem(MediaItem item, {Duration? start})
    : this(
        total: item.duration ?? Duration.zero,
        id: item.id,
        title: item.title,
        album: item.album,
        artist: item.artist,
        genre: item.genre,
        artUri: item.artUri,
        duration: item.duration,
        extras: item.extras,
        start: start,
      );

  void pauseAndPlay(bool playing) {
    isPlaying.value = playing;
  }

  void sendPauseAndPlay(bool playing) {
    isPlaying.value = playing;

    if (MusyncAudioHandler.eko?.conected.value ?? false) {
      MusyncAudioHandler.eko?.sendMessage({
        "action": 'toggle_play',
        "data": playing,
      });
    }
  }

  void toggleMute() {
    muted = !muted;
    if (muted) {
      volumeatual = volume.value;
      setVolume(0);
    } else {
      setVolume(volumeatual);
    }
  }

  void setVolume(double vol) {
    volume.value = vol;
    if (MusyncAudioHandler.eko?.conected.value ?? false) {
      MusyncAudioHandler.eko?.sendMessage({"action": 'volume', "data": vol});
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPlaying.value) {
        final next = position.value + const Duration(seconds: 1);

        if (next >= total) {
          position.value = total;
          timer.cancel();
        } else {
          position.value = next;
        }
      }
    });
  }

  void seek(Duration pos, {bool enviando = true}) {
    position.value = pos;

    if (enviando && (MusyncAudioHandler.eko?.conected.value ?? false)) {
      MusyncAudioHandler.eko?.sendMessage({
        "action": 'position',
        "data": pos.inMilliseconds.toDouble(),
      });
    }
  }

  void dispose() {
    _timer?.cancel();
    position.dispose();
    isPlaying.dispose();
  }
}

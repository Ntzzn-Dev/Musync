import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/ekosystem.dart';

class MediaAtual extends MediaItem {
  final Duration total;
  final Duration? start;
  final ValueNotifier<Duration> position;
  static ValueNotifier<double> volume = ValueNotifier(50);
  double volumeatual = volume.value;
  bool muted = false;

  Timer? _timer;
  ValueNotifier<bool> isPlaying;

  MediaAtual({
    required this.total,
    required super.id,
    required super.title,
    this.start,
    super.album,
    super.artist,
    super.genre,
    super.artUri,
    Duration? duration,
    super.extras,
  }) : position = ValueNotifier(start ?? Duration.zero),
       isPlaying = ValueNotifier(true),
       super(duration: duration ?? total) {
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

    if (eko.conected.value) {
      eko.sendMessage({"action": 'toggle_play', "data": playing});
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
    if (eko.conected.value) {
      eko.sendMessage({"action": 'volume', "data": vol});
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

  void seek(Duration pos, {bool ekoSending = true}) {
    position.value = pos;

    if (ekoSending && (eko.conected.value)) {
      eko.sendMessage({
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

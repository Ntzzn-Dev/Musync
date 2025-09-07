import 'dart:async';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player_base.dart';

class MediaAtual {
  Duration total;
  ValueNotifier<Duration> position;
  static ValueNotifier<double> volume = ValueNotifier(50);
  double volumeatual = volume.value;
  bool muted = false;

  Timer? _timer;
  ValueNotifier<bool> isPlaying;

  MediaAtual({required this.total, Duration? start})
    : position = ValueNotifier(start ?? Duration.zero),
      isPlaying = ValueNotifier(true) {
    _startTimer();
  }

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

  void seek(Duration pos) {
    position.value = pos;

    if (MusyncAudioHandler.eko?.conected.value ?? false) {
      MusyncAudioHandler.eko?.sendMessage({
        "action": 'position',
        "data": position.value.inMilliseconds.toDouble(),
      });
    }
  }

  void dispose() {
    _timer?.cancel();
    position.dispose();
    isPlaying.dispose();
  }
}

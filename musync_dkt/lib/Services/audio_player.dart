import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musync_dkt/Services/media_music.dart';
import 'package:musync_dkt/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum ModeShuffleEnum { shuffleOff, shuffleNormal, shuffleOptional }

enum ModeOrderEnum { titleAZ, titleZA, dataAZ, dataZA, manual }

enum ModeLoopEnum { off, all, one }

extension ModeShuffleEnumExt on ModeShuffleEnum {
  ModeShuffleEnum next() {
    final nextIndex = (index + 1) % ModeShuffleEnum.values.length;
    return ModeShuffleEnum.values[nextIndex];
  }

  static ModeShuffleEnum convert(int i) {
    return ModeShuffleEnum.values[i - 1];
  }

  int disconvert() {
    return index + 1;
  }
}

extension ModeOrderEnumExt on ModeOrderEnum {
  ModeOrderEnum next() {
    int nextIndex = (index + 1) % 4;
    return ModeOrderEnum.values[nextIndex];
  }

  static ModeOrderEnum convert(int i) {
    return ModeOrderEnum.values[i - 1];
  }

  int disconvert() {
    return index + 1;
  }
}

extension ModeLoopEnumExt on ModeLoopEnum {
  ModeLoopEnum next() {
    final nextIndex = (index + 1) % ModeLoopEnum.values.length;
    return ModeLoopEnum.values[nextIndex];
  }

  static ModeLoopEnum convert(int i) {
    return ModeLoopEnum.values[i - 1];
  }

  int disconvert() {
    return index + 1;
  }
}

class MusyncAudioHandler extends AudioPlayer {
  AudioPlayer audPl = AudioPlayer();
  ValueNotifier<int> currentIndex = ValueNotifier(0);
  ValueNotifier<double> vol = ValueNotifier(50);
  bool muted = false;
  double volumeatual = 50;
  File? tempFile;
  List<MediaMusic> songsAtual = [];
  ValueNotifier<MediaMusic> musicAtual = ValueNotifier(
    MediaMusic(id: 0, title: 'title', artist: 'artist', bytes: Uint8List(0)),
  );

  void toggleMute() {
    muted = !muted;
    if (muted) {
      volumeatual = vol.value;
      vol.value = 0;
    } else {
      vol.value = volumeatual;
    }
    setVolume(vol.value);
  }

  MusyncAudioHandler() {
    audPl.onPlayerComplete.listen((event) async {
      try {
        if (tempFile != null && await tempFile!.exists()) {
          await tempFile?.delete();
        }
      } catch (e) {
        print('Erro ao deletar arquivo: $e');
      }
      enviarParaAndroid(socket, "finalizou", true);
    });
  }

  void setIndex(int index) async {
    if (index > songsAtual.length) {
      log('Esperar carregar todas');
      return;
    }

    currentIndex.value = index;
    final tempDir = await getTemporaryDirectory();

    tempFile = File(
      p.join(tempDir.path, 'temp_${safeFileName(songsAtual[index].title)}.mp3'),
    );

    if (!await tempFile!.exists()) {
      await tempFile?.writeAsBytes(songsAtual[index].bytes, flush: true);
    }

    musicAtual.value = songsAtual[index];

    await audPl.play(DeviceFileSource(tempFile!.path));
  }

  Future<void> tocarMusic(dynamic music) async {
    bool iniciar = songsAtual.isEmpty;

    songsAtual.add(
      MediaMusic(
        id: music['id'],
        title: music['audio_title'],
        artist: music['audio_artist'],
        bytes: Uint8List.fromList(List<int>.from(music['data'])),
      ),
    );
    if (iniciar) {
      setIndex(0);
    }
  }

  String safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void next() {
    if (currentIndex.value + 1 < songsAtual.length) {
      currentIndex.value += 1;
      setIndex(currentIndex.value);
      enviarParaAndroid(socket, 'newindex', currentIndex.value);
    }
  }

  void prev() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
      setIndex(currentIndex.value);
      enviarParaAndroid(socket, 'newindex', currentIndex.value);
    }
  }

  @override
  Future<void> pause() async {
    audPl.pause();
  }

  @override
  Future<void> resume() async {
    audPl.resume();
  }

  @override
  Future<void> setVolume(double volume) async {
    vol.value = volume;
    await audPl.setVolume(volume / 100);
  }

  @override
  Future<Duration?> getCurrentPosition() => audPl.getCurrentPosition();

  @override
  Stream<Duration> get onDurationChanged => audPl.onDurationChanged;

  @override
  Stream<Duration> get onPositionChanged => audPl.onPositionChanged;

  @override
  Stream<PlayerState> get onPlayerStateChanged => audPl.onPlayerStateChanged;

  @override
  Future<void> seek(Duration position) async => audPl.seek(position);
}

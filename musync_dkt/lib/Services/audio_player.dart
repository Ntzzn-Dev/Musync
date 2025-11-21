import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
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
  List<MediaMusic> songsAll = [];
  ValueNotifier<List<MediaMusic>> songsAtual = ValueNotifier([]);
  ValueNotifier<MediaMusic> musicAtual = ValueNotifier(
    MediaMusic(
      id: 0,
      title: 'title',
      artist: 'artist',
      bytes: Uint8List(0),
      artUri: Uint8List(0),
    ),
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
      skipToNextAuto();
    });
  }

  void setIndex(int index) async {
    if (index >= songsAtual.value.length) {
      log('Esperar carregar todas');
      return;
    }

    currentIndex.value = index;
    final tempDir = await getTemporaryDirectory();

    tempFile = File(
      p.join(
        tempDir.path,
        'temp_${safeFileName(songsAtual.value[index].title)}.mp3',
      ),
    );

    if (!await tempFile!.exists()) {
      await tempFile?.writeAsBytes(songsAtual.value[index].bytes, flush: true);
    }

    musicAtual.value = songsAtual.value[index];

    enviarParaAndroid(socket, 'newindex', currentIndex.value);

    await audPl.play(DeviceFileSource(tempFile!.path));
  }

  Future<void> tocarMusic(dynamic music, bool? iniciar) async {
    final newMsc = MediaMusic(
      id: music['id'],
      title: music['audio_title'],
      artist: music['audio_artist'],
      bytes: Uint8List.fromList(List<int>.from(music['data'])),
      artUri: music['art'] != null ? base64Decode(music['art']) : Uint8List(0),
    );
    final novaLista = List<MediaMusic>.from(songsAtual.value)
      ..insert(music['part'] == 2 ? 0 : songsAtual.value.length, newMsc);

    songsAtual.value = novaLista;
    songsAll.add(newMsc);

    currentIndex.value = novaLista.indexOf(musicAtual.value);

    if (iniciar ?? false) {
      setIndex(0);
    }
  }

  void reorganizeQueue({required List<MediaMusic> songs}) {
    songsAtual.value = songs;
    currentIndex.value = songs.indexOf(musicAtual.value);

    Map<String, int> temporaryOrder = {
      for (int i = 0; i < songs.length; i++) songs[i].id.toString(): i,
    };

    enviarParaAndroid(socket, 'newtemporaryorder', temporaryOrder);
  }

  String safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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

  ValueNotifier<ModeShuffleEnum> shuffleMode = ValueNotifier<ModeShuffleEnum>(
    ModeShuffleEnum.shuffleOff,
  );

  ValueNotifier<ModeLoopEnum> loopMode = ValueNotifier<ModeLoopEnum>(
    ModeLoopEnum.all,
  );

  void setShuffleModeEnabled() {
    shuffleMode.value = shuffleMode.value.next();
    prepareShuffle();
    enviarParaAndroid(socket, 'newshuffle', shuffleMode.value.disconvert());
  }

  ModeShuffleEnum isShuffleEnabled() {
    return shuffleMode.value;
  }

  void setLoopModeEnabled() {
    loopMode.value = loopMode.value.next();
    enviarParaAndroid(socket, 'newloop', loopMode.value.disconvert());
  }

  ModeLoopEnum isLoopEnabled() {
    return loopMode.value;
  }

  Future<void> next() async {
    if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
      playNextShuffled();
    } else {
      await playNext();
    }
  }

  void skipToNextAuto() {
    if (shuffleMode.value == ModeShuffleEnum.shuffleNormal) {
      playNextShuffled();
    } else {
      playNext();
    }
  }

  Future<void> prev() async {
    Duration pos = await audPl.getCurrentPosition() ?? Duration(seconds: 0);
    if (pos > Duration(seconds: 5)) {
      await audPl.seek(Duration.zero);
    } else if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
      playPreviousShuffled();
    } else {
      playPrevious();
    }
  }

  Future<void> playNext() async {
    final shouldStop = await repeatNormal();
    if (shouldStop) return;

    if (currentIndex.value + 1 < songsAtual.value.length) {
      setIndex(currentIndex.value + 1);

      enviarParaAndroid(socket, 'newindex', currentIndex.value);
    }

    if (shuffleMode.value == ModeShuffleEnum.shuffleOptional) {
      unplayed.removeWhere((i) => i == currentIndex.value);
      played.add(currentIndex.value);
    }
  }

  Future<void> playPrevious() async {
    final shouldStop = await repeatNormal();
    if (shouldStop) return;

    if (currentIndex.value > 0) {
      currentIndex.value--;
      setIndex(currentIndex.value);
      enviarParaAndroid(socket, 'newindex', currentIndex.value);
    }
  }

  Future<bool> repeatNormal() async {
    if (loopMode.value == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      resume();
      return true;
    } else if (loopMode.value == ModeLoopEnum.all &&
        currentIndex.value + 1 >= songsAtual.value.length) {
      currentIndex.value = -1;
      return false;
    } else {
      return false;
    }
  }

  /* SHUFFLE PERSONALIZED */
  List<int> played = [];
  List<int> unplayed = [];

  void prepareShuffle() {
    played.clear();
    reshuffle();
    played.add(currentIndex.value);
  }

  void reshuffle() {
    int countSongs = songsAtual.value.length;
    unplayed = List.generate(countSongs, (i) => i)..shuffle();
  }

  Future<void> playNextShuffled() async {
    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    int nextIndex = unplayed.removeAt(0);

    played.add(nextIndex);

    setIndex(nextIndex);
    enviarParaAndroid(socket, 'newindex', currentIndex.value);
  }

  Future<void> playPreviousShuffled() async {
    if (played.length <= 1) return;

    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    setIndex(prevIndex);
    enviarParaAndroid(socket, 'newindex', currentIndex.value);
  }

  Future<bool> repeatShuffled() async {
    if (loopMode.value == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      resume();
      return true;
    } else if (loopMode.value == ModeLoopEnum.all) {
      if (unplayed.isEmpty) {
        reshuffle();
      }
      return false;
    } else {
      if (unplayed.isEmpty) return true;
      return false;
    }
  }
}

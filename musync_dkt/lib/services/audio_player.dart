import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:musync_dkt/services/media_music.dart';
import 'package:musync_dkt/services/server_connect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum ModeShuffleEnum { shuffleOff, shuffleNormal, shuffleOptional }

enum ModeOrderEnum { titleAZ, titleZA, dataAZ, dataZA, manual, up }

enum ModeLoopEnum { off, all, one }

T enumNext<T extends Enum>(T value, List<T> values) {
  final limit = values.length;
  final nextIndex = (value.index + 1) % limit;
  return values[nextIndex];
}

T enumFromInt<T extends Enum>(int i, List<T> values) {
  return values[i - 1];
}

int enumToInt<T extends Enum>(T value) {
  return value.index + 1;
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
      path: '',
    ),
  );

  ValueNotifier<String> playlistName = ValueNotifier('Musicas Recebidas');

  ValueNotifier<PlayerState> playstate = ValueNotifier(PlayerState.playing);

  Map<String, dynamic> receiving = {'first': '', 'last': ''};

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
        if (loopMode.value != ModeLoopEnum.one &&
            tempFile != null &&
            await tempFile!.exists()) {
          await tempFile?.delete();
        }
      } catch (e) {
        print('Erro ao deletar arquivo: $e');
      }
      skipToNextAuto();
    });
  }

  void setIndex(int index) async {
    if (index >= songsAtual.value.length || index < 0) {
      log('Esperar carregar todas');
      sendMessageAnd({
        'action': 'wait_load',
        'min': receiving['first'],
        'max': receiving['last'],
      });
      return;
    }

    final tempDir = await getTemporaryDirectory();

    if (tempFile != null && await tempFile!.exists()) {
      await tempFile?.delete();
    }

    tempFile = File(
      p.join(
        tempDir.path,
        'temp_${safeFileName(songsAtual.value[index].title)}.mp3',
      ),
    );

    if (!await tempFile!.exists()) {
      await tempFile?.writeAsBytes(songsAtual.value[index].bytes, flush: true);
    }

    songsAtual.value[index].path = tempFile?.path ?? '';
    musicAtual.value = songsAtual.value[index];

    currentIndex.value = index;

    sendMessageAnd({'action': 'newindex', 'data': currentIndex.value});

    await audPl.play(DeviceFileSource(tempFile!.path));
  }

  Future<void> tocarMusic(dynamic music, bool? iniciar) async {
    final newMsc = MediaMusic(
      id: music['id'],
      title: music['audio_title'],
      artist: music['audio_artist'],
      bytes: Uint8List.fromList(List<int>.from(music['data'])),
      artUri: music['art'] != null ? base64Decode(music['art']) : Uint8List(0),
      path: '',
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

    sendMessageAnd({'action': 'newtemporaryorder', 'data': temporaryOrder});
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
    sendMessageAnd({"action": 'volume', "data": volume});
    
    await audPl.setVolume(volume / 100);
  }

  @override
  Future<Duration?> getDuration() => audPl.getDuration();

  @override
  Future<Duration?> getCurrentPosition() => audPl.getCurrentPosition();

  @override
  Stream<Duration> get onDurationChanged =>
      audPl.onDurationChanged.asBroadcastStream();

  @override
  Stream<Duration> get onPositionChanged =>
      audPl.onPositionChanged.asBroadcastStream();

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
    shuffleMode.value = enumNext(shuffleMode.value, ModeShuffleEnum.values);
    prepareShuffle();
    sendMessageAnd({
      'action': 'newshuffle',
      'data': enumToInt(shuffleMode.value),
    });
  }

  void setShuffleModeFromInt(int i) {
    shuffleMode.value = enumFromInt(i, ModeShuffleEnum.values);
    prepareShuffle();
  }

  ModeShuffleEnum isShuffleEnabled() {
    return shuffleMode.value;
  }

  void setLoopModeEnabled() {
    loopMode.value = enumNext(loopMode.value, ModeLoopEnum.values);
    sendMessageAnd({'action': 'newloop', 'data': enumToInt(loopMode.value)});
  }

  void setLoopModeFromInt(int i) {
    loopMode.value = enumFromInt(i, ModeLoopEnum.values);
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
    }
  }

  Future<bool> repeatNormal() async {
    if (loopMode.value == ModeLoopEnum.one) {
      setIndex(currentIndex.value);
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
    sendMessageAnd({'action': 'newindex', 'data': currentIndex.value});
  }

  Future<void> playPreviousShuffled() async {
    if (played.length <= 1) return;

    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    setIndex(prevIndex);
    sendMessageAnd({'action': 'newindex', 'data': currentIndex.value});
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

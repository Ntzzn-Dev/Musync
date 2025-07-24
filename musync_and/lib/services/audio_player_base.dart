import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

enum ModeShuffleEnum { shuffleOff, shuffleNormal, shuffleOptional }

extension ModeEnumExt on ModeShuffleEnum {
  ModeShuffleEnum next() {
    final nextIndex = (index + 1) % ModeShuffleEnum.values.length;
    return ModeShuffleEnum.values[nextIndex];
  }

  ModeShuffleEnum convert(int i) {
    return ModeShuffleEnum.values[i - 1];
  }
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioPlayer audPl = AudioPlayer();
  ValueNotifier<int> currentIndex = ValueNotifier(0);

  static List<MediaItem> songsAll = [];
  List<MediaItem> songsAtual = [];

  MediaControl get shuffleButton {
    switch (shuffleMode) {
      case ModeShuffleEnum.shuffleOff:
        return MediaControl.custom(
          androidIcon: 'drawable/ic_random_off',
          label: 'Aleatorizar Off',
          name: 'random',
        );
      case ModeShuffleEnum.shuffleNormal:
        return MediaControl.custom(
          androidIcon: 'drawable/ic_random_on',
          label: 'Aleatorizar On',
          name: 'random',
        );
      case ModeShuffleEnum.shuffleOptional:
        return MediaControl.custom(
          androidIcon: 'drawable/ic_random_opcional',
          label: 'Aleatorizar Optional',
          name: 'random',
        );
    }
  }

  void _broadcastState([PlaybackEvent? event]) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          shuffleButton,
          MediaControl.skipToPrevious,
          if (audPl.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.custom,
        },
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[audPl.processingState]!,
        playing: audPl.playing,
        updatePosition: audPl.position,
        bufferedPosition: audPl.bufferedPosition,
        speed: audPl.speed,
        queueIndex: event?.currentIndex ?? audPl.currentIndex,
      ),
    );
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'random':
        shuffleMode = shuffleMode.next();
        prepareShuffle();
        _broadcastState();
        break;
      default:
        log('Ação customizada desconhecida: $name');
    }
  }

  Future<void> setCurrentTrack(int index) async {
    currentIndex.value = index;
    final item = songsAtual[index];
    final src = ProgressiveAudioSource(Uri.parse(item.id));
    await audPl.setAudioSource(src);
    mediaItem.add(item);
  }

  Future<void> initSongs({required List<MediaItem> songs}) async {
    audPl.playbackEventStream.listen(_broadcastState);

    songsAtual = songs;

    await setCurrentTrack(0);

    final newQueue = queue.value..addAll(songsAtual);
    queue.add(newQueue);

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNextAuto();
      }
    });
  }

  Future<void> recreateQueue({required List<MediaItem> songs}) async {
    final currentQueue = queue.value;

    final isEqual =
        currentQueue.length == songs.length &&
        List.generate(
          songs.length,
          (i) => songs[i].id == currentQueue[i].id,
        ).every((e) => e);

    if (isEqual) {
      log('Fila já está atualizada, não será recriada.');
      return;
    }

    audPl.playbackEventStream.listen(_broadcastState);

    songsAtual = songs;
    currentIndex.value = 0;

    await setCurrentTrack(0);

    queue.add(songs);

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNextAuto();
      }
    });

    if (shuffleMode != ModeShuffleEnum.shuffleOff) {
      prepareShuffle();
    }
  }

  Stream<Duration> get positionStream => audPl.positionStream;

  Duration? get duration => audPl.duration;

  Stream<bool> get playingStream => audPl.playingStream;

  ModeShuffleEnum shuffleMode = ModeShuffleEnum.shuffleOff;

  Future<void> setShuffleModeEnabled() async {
    shuffleMode = shuffleMode.next();
    prepareShuffle();
  }

  Future<ModeShuffleEnum> isShuffleEnabled() async {
    return shuffleMode;
  }

  Future<void> setLoopModeEnabled(LoopMode mode) async {
    await audPl.setLoopMode(mode);
  }

  Future<LoopMode> isLoopEnabled() async {
    return audPl.loopMode;
  }

  @override
  Future<void> play() async => audPl.play();

  @override
  Future<void> pause() async => audPl.pause();

  @override
  Future<void> seek(Duration position) async => audPl.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    await setCurrentTrack(index);
    play();
  }

  @override
  Future<void> skipToNext() async {
    if (shuffleMode != ModeShuffleEnum.shuffleOff) {
      playNextShuffled();
    } else {
      playNext();
    }
  }

  Future<void> skipToNextAuto() async {
    if (shuffleMode == ModeShuffleEnum.shuffleNormal) {
      playNextShuffled();
    } else {
      playNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (shuffleMode != ModeShuffleEnum.shuffleOff) {
      playPreviousShuffled();
    } else {
      playPrevious();
    }
  }

  Future<void> playNext() async {
    final shouldStop = await repeatNormal();
    if (shouldStop) return;

    if (currentIndex.value + 1 < songsAtual.length) {
      currentIndex.value++;
      await setCurrentTrack(currentIndex.value);
      play();
    }

    if (shuffleMode == ModeShuffleEnum.shuffleOptional) {
      unplayed.removeWhere((i) => i == currentIndex.value);
      played.add(currentIndex.value);
    }
  }

  Future<void> playPrevious() async {
    final shouldStop = await repeatNormal();
    if (shouldStop) return;

    if (currentIndex.value - 1 > 0) {
      currentIndex.value--;
      await setCurrentTrack(currentIndex.value);
      play();
    }
  }

  Future<bool> repeatNormal() async {
    final modo = await isLoopEnabled();

    if (modo == LoopMode.one) {
      await audPl.seek(Duration.zero);
      play();
      return true;
    } else if (modo == LoopMode.all) {
      if (currentIndex.value + 1 == songsAtual.length) {
        currentIndex.value = -1;
      }
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
    int countSongs = queue.value.length;
    unplayed = List.generate(countSongs, (i) => i)..shuffle();
  }

  Future<void> playNextShuffled() async {
    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    int nextIndex = unplayed.removeAt(0);

    played.add(nextIndex);

    await setCurrentTrack(nextIndex);
    play();
  }

  Future<void> playPreviousShuffled() async {
    if (played.length <= 1) return;

    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    await setCurrentTrack(prevIndex);
    play();
  }

  Future<bool> repeatShuffled() async {
    final modo = await isLoopEnabled();

    if (modo == LoopMode.one) {
      await audPl.seek(Duration.zero);
      play();
      return true;
    } else if (modo == LoopMode.all) {
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

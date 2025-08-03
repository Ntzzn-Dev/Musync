import 'dart:developer';
import 'package:collection/collection.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModeShuffleEnum { shuffleOff, shuffleNormal, shuffleOptional }

enum ModeOrderEnum { titleAZ, titleZA, dataAZ, dataZA }

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
    final nextIndex = (index + 1) % ModeOrderEnum.values.length;
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

class MusyncAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayer audPl = AudioPlayer();
  ValueNotifier<int> currentIndex = ValueNotifier(0);
  final _equality = const DeepCollectionEquality();

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

  void savePl(String plDynamic) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pl_last', plDynamic.toString());
  }

  void saveInd(int mscInd) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('msc_last', mscInd);
  }

  Future<void> setCurrentTrack({int? index}) async {
    if (index != null) {
      saveInd(index);
    }
    currentIndex.value = index ?? 0;
    final item = songsAtual[index ?? 0];
    final src = ProgressiveAudioSource(Uri.parse(item.id));
    await audPl.setAudioSource(src);
    mediaItem.add(item);
  }

  Future<void> initSongs({required List<MediaItem> songs}) async {
    audPl.playbackEventStream.listen(_broadcastState);

    songsAtual = songs;

    await setCurrentTrack();

    queue.add(List.from(songsAtual));

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        log('aaa');
        skipToNextAuto();
      }
    });
  }

  Future<void> recreateQueue({required List<MediaItem> songs}) async {
    final currentQueue = queue.value;

    if (_equality.equals(
      songs.map((e) => e.id).toList(),
      currentQueue.map((e) => e.id).toList(),
    )) {
      log('Fila já está atualizada, não será recriada.');
      return;
    }

    songsAtual = songs;
    currentIndex.value = 0;

    await setCurrentTrack(index: 0);

    queue.add(songs);

    if (shuffleMode != ModeShuffleEnum.shuffleOff) {
      prepareShuffle();
    }
  }

  Stream<Duration> get positionStream => audPl.positionStream;

  Duration? get duration => audPl.duration;

  Stream<bool> get playingStream => audPl.playingStream;

  ModeShuffleEnum shuffleMode = ModeShuffleEnum.shuffleOff;

  ModeLoopEnum loopMode = ModeLoopEnum.off;

  void setShuffleModeEnabled() {
    shuffleMode = shuffleMode.next();
    prepareShuffle();
    _broadcastState();
  }

  ModeShuffleEnum isShuffleEnabled() {
    return shuffleMode;
  }

  void setLoopModeEnabled() {
    loopMode = loopMode.next();
  }

  ModeLoopEnum isLoopEnabled() {
    return loopMode;
  }

  @override
  Future<void> play() async {
    if (!audPl.playing) await audPl.play();
  }

  @override
  Future<void> pause() async => audPl.pause();

  @override
  Future<void> seek(Duration position) async => audPl.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    await setCurrentTrack(index: index);
    if (shuffleMode != ModeShuffleEnum.shuffleOff) {
      prepareShuffle();
    }
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

  void skipToNextAuto() {
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
      await setCurrentTrack(index: currentIndex.value + 1);
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

    if (currentIndex.value > 0) {
      currentIndex.value--;
      await setCurrentTrack(index: currentIndex.value);
      play();
    }
  }

  Future<bool> repeatNormal() async {
    if (loopMode == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      play();
      return true;
    } else if (loopMode == ModeLoopEnum.all &&
        currentIndex.value + 1 >= songsAtual.length) {
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
    int countSongs = queue.value.length;
    unplayed = List.generate(countSongs, (i) => i)..shuffle();
  }

  Future<void> playNextShuffled() async {
    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    int nextIndex = unplayed.removeAt(0);

    played.add(nextIndex);

    await setCurrentTrack(index: nextIndex);
    play();
  }

  Future<void> playPreviousShuffled() async {
    if (played.length <= 1) return;

    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    await setCurrentTrack(index: prevIndex);
    play();
  }

  Future<bool> repeatShuffled() async {
    if (loopMode == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      play();
      return true;
    } else if (loopMode == ModeLoopEnum.all) {
      if (unplayed.isEmpty) {
        reshuffle();
      }
      return false;
    } else {
      if (unplayed.isEmpty) return true;
      return false;
    }
  }

  /* REORDER */

  static List<MediaItem> reorder(
    ModeOrderEnum modeAtual,
    List<MediaItem> songs,
  ) {
    List<MediaItem> ordenadas = [];
    switch (modeAtual) {
      case ModeOrderEnum.titleAZ:
        ordenadas = [...songs]..sort(
          (a, b) => a.title.trim().toLowerCase().compareTo(
            b.title.trim().toLowerCase(),
          ),
        );
        break;
      case ModeOrderEnum.titleZA:
        ordenadas = [...songs]..sort(
          (a, b) => b.title.trim().toLowerCase().compareTo(
            a.title.trim().toLowerCase(),
          ),
        );
        break;
      case ModeOrderEnum.dataAZ:
        ordenadas = [...songs]..sort((a, b) {
          try {
            final rawA = a.extras?['lastModified'];
            final rawB = b.extras?['lastModified'];

            final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
            final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

            if (dateA == null || dateB == null) {
              return 0;
            }
            return dateA.compareTo(dateB);
          } catch (e) {
            log('Erro durante sort por data: $e');
            return 0;
          }
        });
        break;
      case ModeOrderEnum.dataZA:
        ordenadas = [...songs]..sort((a, b) {
          try {
            final rawA = a.extras?['lastModified'];
            final rawB = b.extras?['lastModified'];

            final dateA = rawA is String ? DateTime.tryParse(rawA) : null;
            final dateB = rawB is String ? DateTime.tryParse(rawB) : null;

            if (dateA == null || dateB == null) {
              return 0;
            }
            return dateB.compareTo(dateA);
          } catch (e) {
            log('Erro durante sort por data: $e');
            return 0;
          }
        });
        break;
    }
    return ordenadas;
  }
}

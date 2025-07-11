import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioPlayer audPl = AudioPlayer();

  UriAudioSource _createAudioSource(MediaItem item) {
    return ProgressiveAudioSource(Uri.parse(item.id));
  }

  void _listenForCurrentSongIndexChanges() {
    audPl.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
  }

  final myCustomButton = MediaControl.custom(
    androidIcon: 'drawable/ic_random',
    label: 'Aleatorizar',
    name: 'random',
  );

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          myCustomButton,
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
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'random':
        log('Botão de aleatório pressionado!');
        shuffled = !shuffled;
        prepareShuffle();
        break;
      default:
        log('Ação customizada desconhecida: $name');
    }
  }

  Future<void> initSongs({required List<MediaItem> songs}) async {
    audPl.playbackEventStream.listen(_broadcastState);

    final audSrc = songs.map(_createAudioSource);

    await audPl.setAudioSource(
      ConcatenatingAudioSource(children: audSrc.toList()),
    );

    final newQueue = queue.value..addAll(songs);
    queue.add(newQueue);

    _listenForCurrentSongIndexChanges();

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });
  }

  Future<void> recreateQueue({required List<MediaItem> songs}) async {
    audPl.playbackEventStream.listen(_broadcastState);

    final audSrc = songs.map(_createAudioSource).toList();

    await audPl.setAudioSource(ConcatenatingAudioSource(children: audSrc));

    queue.add(songs);

    _listenForCurrentSongIndexChanges();

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });
  }

  Stream<Duration> get positionStream => audPl.positionStream;

  Duration? get duration => audPl.duration;

  Stream<bool> get playingStream => audPl.playingStream;

  int? get currentIndex => audPl.currentIndex;

  Future<void> setShuffleModeEnabled(bool enabled) async {
    shuffled = enabled;
    prepareShuffle();
  }

  Future<bool> isShuffleEnabled() async {
    return shuffled;
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
    await audPl.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> skipToNext() async => shuffled ? playNext() : audPl.seekToNext();

  @override
  Future<void> skipToPrevious() async =>
      shuffled ? playPrevious() : audPl.seekToPrevious();

  /* SHUFFLE PERSONALIZED */
  bool shuffled = false;
  List<int> played = [];
  List<int> unplayed = [];

  void prepareShuffle() {
    played.clear();
    reshuffle();
    played.add(audPl.currentIndex ?? 0);
  }

  void reshuffle() {
    int countSongs = queue.value.length;
    unplayed = List.generate(countSongs, (i) => i)..shuffle();
  }

  Future<void> playNext() async {
    repeat().then((value) {
      if (value) return;
    });

    int nextIndex = unplayed.removeAt(0);

    played.add(nextIndex);
    await audPl.seek(Duration.zero, index: nextIndex);
    await audPl.play();
  }

  Future<void> playPrevious() async {
    if (played.length <= 1) return;

    repeat().then((value) {
      if (value) return;
    });

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    await audPl.seek(Duration.zero, index: prevIndex);
    await audPl.play();
  }

  Future<bool> repeat() async {
    final modo = await isLoopEnabled();

    if (modo == LoopMode.one) {
      await audPl.seek(Duration.zero);
      await audPl.play();
      return true;
    } else if (modo == LoopMode.all) {
      if (unplayed.isEmpty) {
        reshuffle();
      }
      return false;
    } else {
      if (unplayed.isEmpty) return true;
    }
    return false;
  }
}

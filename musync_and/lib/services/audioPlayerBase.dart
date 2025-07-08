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

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (audPl.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
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

  Future<void> initSongs({required List<MediaItem> songs}) async {
    audPl.playbackEventStream.listen(_broadcastState);

    final audSrc = songs.map(_createAudioSource);

    await audPl.setAudioSource(
      ConcatenatingAudioSource(children: audSrc.toList()),
    );

    await audPl.shuffle();
    await audPl.setShuffleModeEnabled(true);

    final newQueue = queue.value..addAll(songs);
    queue.add(newQueue);

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
    await audPl.setShuffleModeEnabled(enabled);
  }

  Future<bool> isShuffleEnabled() async {
    return audPl.shuffleModeEnabled;
  }

  Future<void> setLoopModeEnabled(LoopMode mode) async {
    await audPl.setLoopMode(mode);
  }

  Future<Enum> isLoopEnabled() async {
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
  Future<void> skipToNext() async => audPl.seekToNext();

  @override
  Future<void> skipToPrevious() async => audPl.seekToPrevious();
}

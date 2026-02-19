import 'dart:async';
import 'dart:developer';
import 'dart:math' as mt;
import 'package:collection/collection.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/actionlist.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MusyncAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayer audPl = AudioPlayer();
  ValueNotifier<int> currentIndex = ValueNotifier(0);
  final _equality = const DeepCollectionEquality();

  static ActionList actlist = ActionList();

  late List<Playlists> playlists;

  static late ValueNotifier<MediaAtual> mediaAtual;

  void reorganizeSongsAtual(Map<String, dynamic> ordem) {
    //songsAtual.sort((a, b) {
    //  final posA = ordem[a.id.split('/').last] ?? 0;
    //  final posB = ordem[b.id.split('/').last] ?? 0;
    //  return posA.compareTo(posB);
    //});
  }

  MediaControl get shuffleButton {
    switch (shuffleMode.value) {
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

  MediaControl get upButton {
    return MediaControl.custom(
      androidIcon: 'drawable/ic_random_off', //MUDAR ICON
      label: 'Upar',
      name: 'up',
    );
  }

  void _broadcastState([PlaybackEvent? event]) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          shuffleButton,
          MediaControl.skipToPrevious,
          if (audPl.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          upButton,
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
        setShuffleModeEnabled();
        break;
      case 'up':
        upAtualMedia();
        _broadcastState();
        break;
      default:
        log('Ação customizada desconhecida: $name');
    }
  }

  void upAtualMedia() async {
    MediaItem song = actlist.getMusicAtual(currentIndex.value);
    await DatabaseHelper().upInPlaylist(
      actlist.atualPlaylist.value.title,
      song.id,
      song.title,
    );

    actlist.songsAllPlaylist = await reorderMusics(
      ModeOrderEnum.up,
      actlist.getMediaItemsFromQueue(),
    );
    actlist.setMusicListAtual(actlist.songsAllPlaylist);

    setCurrentTrack(index: 0);
  }

  Future<void> searchPlaylists() async {
    playlists = await DatabaseHelper().loadPlaylists();

    if (!playlists.any((pl) => pl.title == actlist.mainPlaylist.title)) {
      int id = int.tryParse(actlist.mainPlaylist.tag) ?? 0;

      playlists.insert(
        0,
        Playlists(
          id: id,
          title: actlist.mainPlaylist.title,
          subtitle: actlist.mainPlaylist.subtitle,
          ordem: 0,
          orderMode: 0,
        ),
      );
    }

    if (!playlists.any((pl) => pl.title == actlist.atualPlaylist.value.title)) {
      int id = int.tryParse(actlist.atualPlaylist.value.tag) ?? -1;

      playlists.insert(
        0,
        Playlists(
          id: id,
          title: actlist.atualPlaylist.value.title,
          subtitle: actlist.atualPlaylist.value.subtitle,
          ordem: 0,
          orderMode: 0,
        ),
      );
    }
  }

  void savePl(SetList SetList) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pl_last', SetList.tag);

    actlist.setSetList(SetListType.atual, SetList);
  }

  void returnToCheckpoint() {
    log("has retornado al checkpoint");
  }

  Future<void> skipPlaylist(bool next) async {
    await searchPlaylists();
    List<int> idsPls = playlists.map((pl) => pl.id).toList();

    int currentIndex = idsPls.indexOf(
      int.tryParse(actlist.atualPlaylist.value.tag) ?? 0,
    );
    if (actlist.atualPlaylist.value.tag == actlist.mainPlaylist.tag) {
      currentIndex = 1;
    }

    final nextIndex = (currentIndex + (next ? 1 : -1)) % idsPls.length;
    final idNext = idsPls[nextIndex];

    final nextPlaylist = playlists.firstWhere((pl) => pl.id == idNext);

    actlist.setSetList(
      SetListType.atual,
      SetList(
        title: nextPlaylist.title,
        subtitle: nextPlaylist.subtitle,
        tag: nextPlaylist.id.toString(),
      ),
    );

    List<MediaItem> newsongs = await nextPlaylist.findMusics();

    if (newsongs.isEmpty) newsongs = actlist.songsAllPlaylist;

    await recreateQueue(songs: newsongs);
  }

  void saveInd(int mscInd) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('msc_last', mscInd);
  }

  Future<void> setCurrentTrack({int? index}) async {
    if (index != null) {
      saveInd(index);
    } else {
      index = 0;
    }
    if (actlist.queueIsEmpty()) return;
    currentIndex.value = index;
    final item = actlist.queueList[index];
    item.execute();
  }

  bool _executando = false;

  Future<void> executeMusic(ProgressiveAudioSource src, MediaItem item) async {
    if (!_executando) {
      _executando = true;
      await audPl.pause();
      await audPl.setAudioSource(src);
      mediaItem.add(item);
      _executando = false;
      log(item.title);

      if (item.id != actlist.getMusicAtual(currentIndex.value).id) {
        log("executando correção");
        final item = actlist.queueList[currentIndex.value];
        item.execute();
        play();
      }
    }
  }

  Future<void> initSongs({required List<MediaItem> songs}) async {
    actlist.setSetList(SetListType.atual, actlist.mainPlaylist);
    await searchPlaylists();

    audPl.playbackEventStream.listen(_broadcastState);

    actlist.setMusicListAtual(songs);

    setCurrentTrack();

    queue.add(actlist.getMediaItemsFromQueue());

    audPl.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNextAuto();
      }
    });
  }

  Future<bool> recreateQueue({required List<MediaItem> songs}) async {
    final currentQueue = queue.value;
    final currentSetListQueue = actlist.getMediaItemsFromQueue();

    if (_equality.equals(
          songs.map((e) => e.id).toList(),
          currentQueue.map((e) => e.id).toList(),
        ) &&
        _equality.equals(
          songs.map((e) => e.id).toList(),
          currentSetListQueue.map((e) => e.id).toList(),
        )) {
      log('Fila já está atualizada, não será recriada.');
      return false;
    }

    final idAtual =
        (actlist.queueList[currentIndex.value] as MusicItem).mediaItem.id;

    actlist.setMusicListAtual(songs);

    if (eko.conected.value) {
      eko.sendMessage({'action': 'request_data', 'data': ''});

      queue.add(songs);
    } else {
      final indiceNewList = actlist.queueList.indexWhere(
        (e) => (e as MusicItem).mediaItem.id == idAtual,
      );

      setCurrentTrack(index: indiceNewList != -1 ? indiceNewList : 0);

      queue.add(songs);

      if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
        log('recriar shuffle ${played.length} - ${unplayed.length}');
        reshuffle();
      }
    }
    return true;
  }

  void reorganizeQueue({required List<MediaItem> songs}) {
    MediaItem songAtual = actlist.getMusicAtual(
      currentIndex.value == -1 ? 0 : currentIndex.value,
    );

    actlist.setMusicListAtual(songs);

    currentIndex.value = songs.indexOf(songAtual);

    queue.add(songs);

    if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
      log('reorganizar shuffle ${played.length} - ${unplayed.length}');
      reshuffle();
    }
  }

  Stream<Duration> get positionStream => audPl.positionStream;

  Duration? get duration => audPl.duration;

  Stream<bool> get playingStream => audPl.playingStream;

  ValueNotifier<ModeShuffleEnum> shuffleMode = ValueNotifier<ModeShuffleEnum>(
    ModeShuffleEnum.shuffleOff,
  );

  ValueNotifier<ModeLoopEnum> loopMode = ValueNotifier<ModeLoopEnum>(
    ModeLoopEnum.off,
  );

  void setShuffleModeEnabled() {
    shuffleMode.value = enumNext(shuffleMode.value, ModeShuffleEnum.values);
    reshuffle();
    _broadcastState();

    if (eko.conected.value) {
      eko.sendEkoShuffle(shuffleMode.value);
    }
  }

  ModeShuffleEnum isShuffleEnabled() {
    return shuffleMode.value;
  }

  void setLoopModeEnabled() {
    loopMode.value = enumNext(loopMode.value, ModeLoopEnum.values);
    if (eko.conected.value) {
      eko.sendEkoLoop(loopMode.value);
    }
  }

  ModeLoopEnum isLoopEnabled() {
    return loopMode.value;
  }

  @override
  Future<void> play() async {
    _idleTimer?.cancel();
    if (!audPl.playing) audPl.play();
  }

  @override
  Future<void> pause() async {
    audPl.pause();
    if (modoDeEnergia == 1) {
      _startIdleTimer();
    }
  }

  @override
  Future<void> stop() async {
    _idleTimer?.cancel();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    audPl.seek(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (eko.conected.value) {
      sendMediaIndex(index);
    } else {
      setCurrentTrack(index: index);
      if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
        reshuffle();
      }
      play();
    }
  }

  void sendMediaIndexShuffleOutOfLimits(String first, String last) {
    final min = actlist.songsAllPlaylist.indexWhere((msc) => msc.id == first);

    final max = actlist.songsAllPlaylist.indexWhere((msc) => msc.id == last);

    if (min == -1 || max == -1) {
      return;
    }

    final random = mt.Random();
    final index =
        min +
        random.nextInt(max - min + 1); //CORRIGIR PARA ITENS DA SEGUNDA METADE
    log(index.toString());
    sendMediaIndex(index);
  }

  void sendMediaIndex(int index) {
    if (eko.conected.value) {
      int indexRelative = index - Ekosystem.indexInitial;
      eko.sendMessage({
        'action': 'newindex',
        'data': indexRelative,
        'DEVE SER APAGADO': '',
        'index': index,
        'indexInicial': Ekosystem.indexInitial,
      });
      log('$indexRelative ${Ekosystem.indexInitial}');
    }

    //setMediaIndex(index);
  }

  void setMediaIndex(int index) {
    final item = actlist.getMusicAtual(index);

    musyncMediaUpdateNotifier.notifyMediaChanged(item);

    currentIndex.value = index;
    mediaItem.add(item);
  }

  @override
  Future<void> skipToNext() async {
    await playNext(false);
  }

  void skipToNextAuto() {
    playNext(true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (audPl.position > Duration(seconds: 5)) {
      await audPl.seek(Duration.zero);
    } else {
      playPrevious();
    }
  }

  /* MODO BALACEADO */
  Timer? _idleTimer;

  static const Duration idleTimeout = Duration(hours: 1);

  void _startIdleTimer() {
    log('[IDLE] Timer iniciado');

    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () async {
      log('[IDLE] Timer disparou');

      final isPlaying = playbackState.value.playing;
      log('[IDLE] isPlaying = $isPlaying');

      if (!isPlaying) {
        log('[IDLE] Encerrando serviço');
        await _shutdownService();
      }
    });
  }

  Future<void> _shutdownService() async {
    log('[IDLE] shutdownService()');

    _idleTimer?.cancel();

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );

    await stop();
  }
}

class MusyncMediaUpdateNotifier extends ChangeNotifier {
  late MediaItem _lastUpdate;

  MediaItem get lastUpdate => _lastUpdate;

  void notifyMediaChanged(MediaItem value) {
    _lastUpdate = value;
    notifyListeners();
  }
}

final musyncMediaUpdateNotifier = MusyncMediaUpdateNotifier();

import 'dart:async';
import 'dart:developer';
import 'dart:math' as mt;
import 'package:collection/collection.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/actionlist.dart';
import 'package:musync_and/services/databasehelper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/services/playlists.dart';
import 'package:musync_and/services/setlist.dart';
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

  static Ekosystem? eko;
  static late ValueNotifier<MediaAtual> mediaAtual;

  void setEkosystem(Ekosystem ekosystem) {
    eko = ekosystem;
    pause();

    eko?.sendEkoLoop(loopMode.value);
    eko?.sendEkoShuffle(shuffleMode.value);

    eko?.sendMessage({
      'action': 'playlist_name',
      'data': actlist.atualPlaylist.value.title,
    });

    if (eko?.conected.value ?? false) {
      eko?.sendMessage({'action': 'request_data', 'data': ''});
    }

    final songsAtual = actlist.getMediaItemsFromQueue();

    mediaAtual = ValueNotifier(
      MediaAtual(
        total: songsAtual[currentIndex.value].duration ?? Duration.zero,
        id: songsAtual[currentIndex.value].id,
        title: songsAtual[currentIndex.value].title,
        artist: songsAtual[currentIndex.value].artist,
        album: songsAtual[currentIndex.value].album,
        artUri: songsAtual[currentIndex.value].artUri,
      ),
    );

    eko?.receivedMessage.addListener(() {
      final msg = eko?.receivedMessage.value;
      switch (msg?['action']) {
        case 'verify_data':
          String allIds = msg?['data'];
          final listIds = allIds.split(',');

          eko?.sendAudios(
            actlist.getMediaItemsFromQueue(),
            currentIndex.value,
            listIds,
          );
          Ekosystem.indexInitial = currentIndex.value;
          break;
        case 'position':
          final progress = Duration(milliseconds: msg?['data'].toInt());
          mediaAtual.value.seek(progress);
          break;
        case 'toggle_play':
          MusyncAudioHandler.mediaAtual.value.pauseAndPlay(msg?['data']);
          break;
        case 'volume':
          MediaAtual.volume.value = msg?['data'].toDouble();
          break;
        case 'newloop':
          loopMode.value = enumFromInt(msg?['data'], ModeLoopEnum.values);
          break;
        case 'newshuffle':
          shuffleMode.value = enumFromInt(msg?['data'], ModeShuffleEnum.values);
          break;
        case 'newindex':
          int indexRelative = msg?['data'].toInt() + Ekosystem.indexInitial;
          setMediaIndex(indexRelative);
          break;
        case 'newtemporaryorder':
          reorganizeSongsAtual(msg?['data']);
          break;
        case 'package_end':
          Ekosystem.indexInitial = 0;
          break;
        case 'wait_load':
          sendMediaIndexShuffleOutOfLimits(msg?['min'], msg?['max']);
          break;
      }
    });
  }

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
        shuffleMode.value = enumNext(shuffleMode.value, ModeShuffleEnum.values);
        prepareShuffle();
        _broadcastState();
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

    actlist.songsAllPlaylist = await MusyncAudioHandler.reorder(
      ModeOrderEnum.up,
      actlist.getMediaItemsFromQueue(),
    );
    actlist.setMusicListAtual(actlist.songsAllPlaylist, this);

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

  void savePl(Setlist setlist) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pl_last', setlist.tag);

    actlist.setSetList(SetListType.atual, setlist);
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
      Setlist(
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
    item.execute(this);
  }

  bool _executando = false;
  Future<void> executeMusic(ProgressiveAudioSource src, MediaItem item) async {
    if (!_executando) {
      _executando = true;
      await audPl.pause();
      await audPl.setAudioSource(src);
      mediaItem.add(item);
      _executando = false;

      if (item.id != actlist.getMusicAtual(currentIndex.value).id) {
        log("executando correção");
        final item = actlist.queueList[currentIndex.value];
        item.execute(this);
        play();
      }
    }
  }

  Future<void> initSongs({required List<MediaItem> songs}) async {
    actlist.setSetList(SetListType.atual, actlist.mainPlaylist);
    await searchPlaylists();

    audPl.playbackEventStream.listen(_broadcastState);
    log(songs.length.toString());
    actlist.setMusicListAtual(songs, this);

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

    if (_equality.equals(
      songs.map((e) => e.id).toList(),
      currentQueue.map((e) => e.id).toList(),
    )) {
      log('Fila já está atualizada, não será recriada.');
      return false;
    }

    actlist.setMusicListAtual(songs, this);

    if (eko?.conected.value ?? false) {
      eko?.sendMessage({'action': 'request_data', 'data': ''});

      queue.add(songs);
    } else {
      currentIndex.value = 0;

      setCurrentTrack(index: 0);

      queue.add(songs);

      if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
        prepareShuffle();
      }
    }
    return true;
  }

  void reorganizeQueue({required List<MediaItem> songs}) {
    MediaItem songAtual = actlist.getMusicAtual(
      currentIndex.value == -1 ? 0 : currentIndex.value,
    );

    actlist.setMusicListAtual(songs, this);

    currentIndex.value = songs.indexOf(songAtual);

    queue.add(songs);

    if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
      prepareShuffle();
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
    prepareShuffle();
    _broadcastState();
  }

  ModeShuffleEnum isShuffleEnabled() {
    return shuffleMode.value;
  }

  void setLoopModeEnabled() {
    loopMode.value = enumNext(loopMode.value, ModeLoopEnum.values);
  }

  ModeLoopEnum isLoopEnabled() {
    return loopMode.value;
  }

  @override
  Future<void> play() async {
    if (!audPl.playing) audPl.play();
  }

  @override
  Future<void> pause() async {
    audPl.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    audPl.seek(position);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (eko?.conected.value ?? false) {
      sendMediaIndex(index);
    } else {
      setCurrentTrack(index: index);
      if (shuffleMode.value != ModeShuffleEnum.shuffleOff) {
        prepareShuffle();
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
    final index = min + random.nextInt(max - min + 1);
    log(index.toString());
    sendMediaIndex(index);
  }

  void sendMediaIndex(int index) {
    if (eko?.conected.value ?? false) {
      if (Ekosystem.indexSending < index) return;
      int indexRelative = index - Ekosystem.indexInitial;
      eko?.sendMessage({'action': 'newindex', 'data': indexRelative});
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

  @override
  Future<void> skipToPrevious() async {
    if (audPl.position > Duration(seconds: 5)) {
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

    if (currentIndex.value + 1 < actlist.getLengthActionsListAtual()) {
      if (eko?.conected.value ?? false) {
        sendMediaIndex(currentIndex.value + 1);
      } else {
        await setCurrentTrack(index: currentIndex.value + 1);
        play();
      }
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
      if (eko?.conected.value ?? false) {
        sendMediaIndex(currentIndex.value);
      } else {
        setCurrentTrack(index: currentIndex.value);
        play();
      }
    }
  }

  Future<bool> repeatNormal() async {
    if (loopMode.value == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      play();
      return true;
    } else if (loopMode.value == ModeLoopEnum.all &&
        currentIndex.value + 1 >= actlist.getLengthActionsListAtual()) {
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

    if (eko?.conected.value ?? false) {
      sendMediaIndex(nextIndex);
    } else {
      setCurrentTrack(index: nextIndex);
      play();
    }
  }

  Future<void> playPreviousShuffled() async {
    if (played.length <= 1) return;

    final shouldStop = await repeatShuffled();
    if (shouldStop) return;

    unplayed.add(played.last);
    played.removeLast();

    int prevIndex = played.last;
    if (eko?.conected.value ?? false) {
      sendMediaIndex(prevIndex);
    } else {
      setCurrentTrack(index: prevIndex);
      play();
    }
  }

  Future<bool> repeatShuffled() async {
    if (loopMode.value == ModeLoopEnum.one) {
      await audPl.seek(Duration.zero);
      play();
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

  /* REORDER */

  static Future<List<MediaItem>> reorder(
    ModeOrderEnum modeAtual,
    List<MediaItem> songs, {
    List<int>? order,
  }) async {
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
      case ModeOrderEnum.manual:
        if (order != null && order.length == songs.length) {
          final posicoes = {for (int i = 0; i < order.length; i++) order[i]: i};

          ordenadas = [...songs]..sort((a, b) {
            final idxA = posicoes[int.tryParse(a.id)] ?? 99999;
            final idxB = posicoes[int.tryParse(b.id)] ?? 99999;
            return idxA.compareTo(idxB);
          });
        } else {
          ordenadas = [...songs];
        }
        break;
      case ModeOrderEnum.up:
        ordenadas = await DatabaseHelper().reorderToUp(
          actlist.viewingPlaylist.tag.toString(),
          songs,
        );
        break;
    }
    return ordenadas;
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

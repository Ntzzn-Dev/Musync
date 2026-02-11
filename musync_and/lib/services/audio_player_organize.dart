import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/ekosystem.dart';

MusyncAudioHandler mscAudPl = MusyncAudioHandler();
int modoDeEnergia = 2;

/* SHUFFLES */
List<int> played = [];
List<int> unplayed = [];

void prepareShuffle() {
  played.clear();
  reshuffle();
  played.add(mscAudPl.currentIndex.value);
}

void reshuffle() {
  int countSongs = mscAudPl.queue.value.length;
  unplayed = List.generate(countSongs, (i) => i)..shuffle();
}

/* PLAYS */
Future<void> playNext() async {
  final shouldStop = await repeatNormal();
  if (shouldStop) return;

  if (mscAudPl.currentIndex.value + 1 <
      MusyncAudioHandler.actlist.getLengthActionsListAtual()) {
    if (eko.conected.value) {
      mscAudPl.sendMediaIndex(mscAudPl.currentIndex.value + 1);
    } else {
      await mscAudPl.setCurrentTrack(index: mscAudPl.currentIndex.value + 1);
      mscAudPl.play();
    }
  }

  if (mscAudPl.shuffleMode.value == ModeShuffleEnum.shuffleOptional) {
    unplayed.removeWhere((i) => i == mscAudPl.currentIndex.value);
    played.add(mscAudPl.currentIndex.value);
  }
}

Future<void> playPrevious() async {
  final shouldStop = await repeatNormal();
  if (shouldStop) return;

  if (mscAudPl.currentIndex.value > 0) {
    mscAudPl.currentIndex.value--;
    if (eko.conected.value) {
      mscAudPl.sendMediaIndex(mscAudPl.currentIndex.value);
    } else {
      mscAudPl.setCurrentTrack(index: mscAudPl.currentIndex.value);
      mscAudPl.play();
    }
  }
}

Future<void> playNextShuffled() async {
  final shouldStop = await repeatShuffled();
  if (shouldStop) return;

  int nextIndex = unplayed.removeAt(0);

  played.add(nextIndex);

  if (eko.conected.value) {
    mscAudPl.sendMediaIndex(nextIndex);
  } else {
    mscAudPl.setCurrentTrack(index: nextIndex);
    mscAudPl.play();
  }
}

Future<void> playPreviousShuffled() async {
  if (played.length <= 1) return;

  final shouldStop = await repeatShuffled();
  if (shouldStop) return;

  unplayed.add(played.last);
  played.removeLast();

  int prevIndex = played.last;
  if (eko.conected.value) {
    mscAudPl.sendMediaIndex(prevIndex);
  } else {
    mscAudPl.setCurrentTrack(index: prevIndex);
    mscAudPl.play();
  }
}

/* REPEATS */
Future<bool> repeatNormal() async {
  if (mscAudPl.loopMode.value == ModeLoopEnum.one) {
    await mscAudPl.seek(Duration.zero);
    mscAudPl.play();
    return true;
  } else if (mscAudPl.loopMode.value == ModeLoopEnum.all &&
      mscAudPl.currentIndex.value + 1 >=
          MusyncAudioHandler.actlist.getLengthActionsListAtual()) {
    mscAudPl.currentIndex.value = -1;
    return false;
  } else {
    return false;
  }
}

Future<bool> repeatShuffled() async {
  if (mscAudPl.loopMode.value == ModeLoopEnum.one) {
    await mscAudPl.seek(Duration.zero);
    mscAudPl.play();
    return true;
  } else if (mscAudPl.loopMode.value == ModeLoopEnum.all) {
    if (unplayed.isEmpty) {
      reshuffle();
    }
    return false;
  } else {
    if (unplayed.isEmpty) return true;
    return false;
  }
}

Future<List<MediaItem>> reorderMusics(
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
        MusyncAudioHandler.actlist.viewingPlaylist.tag.toString(),
        songs,
      );
      break;
  }
  return ordenadas;
}

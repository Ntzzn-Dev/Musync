import 'dart:developer';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/services/ekosystem.dart';

late final MusyncAudioHandler mscAudPl;
int modoDeEnergia = 2;

/* SHUFFLES */
List<int> played = [];
List<int> unplayed = [];

void reshuffle() {
  played.clear();

  int countSongs = mscAudPl.queue.value.length;
  unplayed = List.generate(countSongs, (i) => i)..shuffle();

  played.add(mscAudPl.currentIndex.value);
  unplayed.removeWhere((i) => i == mscAudPl.currentIndex.value);
}

/* PLAYS */
Future<void> playNext(bool auto) async {
  final shouldStop = await shouldToStop();
  if (shouldStop) return;

  int nextIndex = mscAudPl.currentIndex.value + 1;

  if ((mscAudPl.shuffleMode.value == ModeShuffleEnum.shuffleNormal && auto) ||
      (mscAudPl.shuffleMode.value != ModeShuffleEnum.shuffleOff && !auto)) {
    nextIndex = unplayed.removeAt(0);

    played.add(nextIndex);
  }

  if (nextIndex < mscAudPl.actlist.getLengthActionsListAtual()) {
    if (eko.conected.value) {
      mscAudPl.sendMediaIndex(nextIndex);
    } else {
      await mscAudPl.setCurrentTrack(index: nextIndex);
      mscAudPl.play();
    }
  }

  if (mscAudPl.shuffleMode.value == ModeShuffleEnum.shuffleOptional) {
    unplayed.removeWhere((i) => i == mscAudPl.currentIndex.value);
    played.add(mscAudPl.currentIndex.value);
  }
}

Future<void> playPrevious() async {
  final shouldStop = await shouldToStop();
  if (shouldStop) return;

  int prevIndex = mscAudPl.currentIndex.value - 1;
  if (mscAudPl.shuffleMode.value != ModeShuffleEnum.shuffleOff) {
    if (played.length <= 1) return;

    unplayed.add(played.last);
    played.removeLast();

    prevIndex = played.last;
  }

  if (prevIndex >= 0) {
    if (eko.conected.value) {
      mscAudPl.sendMediaIndex(prevIndex);
    } else {
      mscAudPl.setCurrentTrack(index: prevIndex);
      log('c ${mscAudPl.currentIndex.value}');
      mscAudPl.play();
    }
  }
}

/* REPEATS */
Future<bool> shouldToStop() async {
  bool isShuffle = mscAudPl.shuffleMode.value != ModeShuffleEnum.shuffleOff;
  if (mscAudPl.loopMode.value == ModeLoopEnum.one) {
    await mscAudPl.seek(Duration.zero);
    mscAudPl.play();
    return true;
  } else if (mscAudPl.loopMode.value == ModeLoopEnum.all) {
    if (isShuffle) {
      if (unplayed.isEmpty) {
        reshuffle();
      }
    } else if (mscAudPl.currentIndex.value + 1 >=
        mscAudPl.actlist.getLengthActionsListAtual()) {
      mscAudPl.currentIndex.value = -1;
    }
    return false;
  } else {
    if (isShuffle && unplayed.isEmpty) return true;
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
        mscAudPl.actlist.viewingPlaylist.tag.toString(),
        songs,
      );
      break;
  }
  return ordenadas;
}

/* DELETE */
Future<void> deletarMusicas(
  List<MediaItem> itensOriginal, {
  required Function(MediaItem) removeLists,
  VoidCallback? aoFinal,
}) async {
  final itens = List<MediaItem>.from(itensOriginal);
  for (MediaItem item in itens) {
    final path = item.extras?['path'];

    if (path == null) {
      continue;
    }

    final file = File(path);

    try {
      final exists = await file.exists();

      if (!exists) {
        continue;
      }

      removeLists.call(item);

      await mscAudPl.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await file.delete();

      await DatabaseHelper().deleteMusicTrigger(item.id);
    } catch (e, stack) {
      log('Erro: $e | $stack');
    }
  }
  aoFinal?.call();
}

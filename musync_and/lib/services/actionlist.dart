import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musync_and/services/audio_player_organize.dart';
import 'package:musync_and/services/setlist.dart';

enum SetListType { main, view, atual }

class ActionList {
  List<MediaItem> songsAll = [];
  List<MediaItem> songsAllPlaylist = [];
  List<SetItem> queueList = [];

  Setlist mainPlaylist = Setlist();
  Setlist viewingPlaylist = Setlist();
  ValueNotifier<Setlist> atualPlaylist = ValueNotifier(Setlist());

  bool queueIsEmpty() {
    return queueList.isEmpty;
  }

  int getLengthActionsListAtual() {
    return queueList.length;
  }

  MediaItem getMusicAtual(int index) {
    final List<MusicItem> songs = queueList.whereType<MusicItem>().toList();
    return songs[index].mediaItem;
  }

  List<MediaItem> getMediaItemsFromQueue() {
    return queueList.whereType<MusicItem>().map((m) => m.mediaItem).toList();
  }

  int getLengthMusicListAtual() {
    final List<MusicItem> songs = queueList.whereType<MusicItem>().toList();
    return songs.length;
  }

  void setMusicListAtual(
    List<MediaItem> songs
  ) {
    final List<MusicItem> songsF =
        songs
            .map(
              (media) =>
                  MusicItem(mediaItem: media),
            )
            .toList();

    queueList = [...songsF];
  }

  void setSetList(SetListType type, Setlist list) {
    switch (type) {
      case SetListType.main:
        mainPlaylist = list;
        break;
      case SetListType.view:
        viewingPlaylist = list;
        break;
      case SetListType.atual:
        atualPlaylist.value = atualPlaylist.value.copyWith(
          subtitle: list.subtitle,
          title: list.title,
          tag: list.tag,
        );
        break;
    }
  }
}

class SetItem {
  void execute() {}
}

class MusicItem extends SetItem {
  final MediaItem mediaItem;

  MusicItem({required this.mediaItem});

  @override
  void execute() {
    final src = ProgressiveAudioSource(Uri.parse(mediaItem.id));
    audPl.executeMusic(src, mediaItem);
  }
}

class ActionItem extends SetItem {
  final void Function() action;

  ActionItem(this.action);

  @override
  void execute() {
    action();
  }
}

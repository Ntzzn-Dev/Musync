import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/themes.dart';
import 'package:musync_and/widgets/player.dart';

enum ButtonTypes { prev, next, shuffle, repeat }

enum ExtraButtonTypes { nextBtn, prevBtn, modal }

Widget buildSliderMusic() {
  if (eko.conected.value) {
    return ValueListenableBuilder<MediaAtual>(
      valueListenable: MusyncAudioHandler.mediaAtual,
      builder: (context, value, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: value.position,
          builder: (context, pos, child) {
            return _buildSlider(context, pos, media: value);
          },
        );
      },
    );
  } else {
    return StreamBuilder<Duration>(
      stream: mscAudPl.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = mscAudPl.duration ?? Duration.zero;

        return _buildSlider(context, position, total: total);
      },
    );
  }
}

Widget _buildSlider(
  BuildContext context,
  Duration position, {
  Duration? total,
  MediaAtual? media,
}) {
  final Duration durationTotal = media?.total ?? total ?? Duration.zero;

  final int maxMs = durationTotal.inMilliseconds;
  final int posMs = position.inMilliseconds.clamp(0, maxMs);

  return Column(
    children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          min: 0,
          max: maxMs.toDouble(),
          value: posMs.toDouble(),
          onChanged: (value) {
            final target = Duration(milliseconds: value.toInt());
            if (eko.conected.value) {
              media?.seek(target);
            } else {
              mscAudPl.seek(target);
            }
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Player.formatDuration(position, false),
              style: const TextStyle(fontFamily: 'Default-Thin'),
            ),
            if (eko.conected.value)
              Text(
                'CONECTADO AO DESKTOP',
                style: TextStyle(
                  fontFamily: 'Default-Thin',
                  color: baseAppColor,
                ),
              ),
            Text(
              Player.formatDuration(durationTotal, false),
              style: const TextStyle(fontFamily: 'Default-Thin'),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildPlayPauseButton() {
  if (eko.conected.value) {
    return ValueListenableBuilder<MediaAtual>(
      valueListenable: MusyncAudioHandler.mediaAtual,
      builder: (context, mediaAtual, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: mediaAtual.isPlaying,
          builder: (context, isPlaying, child) {
            return buildButton(
              Icon(
                isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
                size: 45,
              ),
              () {
                mediaAtual.sendPauseAndPlay(!isPlaying);
              },
              1,
              1,
            );
          },
        );
      },
    );
  }

  return StreamBuilder<bool>(
    stream: mscAudPl.playingStream,
    builder: (context, snapshot) {
      final isPlaying = snapshot.data ?? false;
      return buildButton(
        Icon(
          isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
          size: 45,
        ),
        () {
          isPlaying ? mscAudPl.pause() : mscAudPl.play();
        },
        1,
        1,
      );
    },
  );
}

Widget buildAudioHandlerButtons(ButtonTypes type) {
  switch (type) {
    case ButtonTypes.next:
      return ValueListenableBuilder<ModeShuffleEnum>(
        valueListenable: mscAudPl.shuffleMode,
        builder: (context, value, child) {
          return buildButton(
            value != ModeShuffleEnum.shuffleOptional
                ? Icon(Icons.keyboard_double_arrow_right_sharp, size: 45)
                : Image.asset(
                  'assets/dice.png',
                  color: baseAppColor,
                  colorBlendMode: BlendMode.srcIn,
                  width: 45,
                ),
            () async {
              await mscAudPl.skipToNext();
            },
            1,
            1,
          );
        },
      );
    case ButtonTypes.prev:
      return buildButton(
        Icon(Icons.keyboard_double_arrow_left_sharp, size: 45),
        () async {
          await mscAudPl.skipToPrevious();
        },
        1,
        1,
      );
    case ButtonTypes.shuffle:
      return ValueListenableBuilder<ModeShuffleEnum>(
        valueListenable: mscAudPl.shuffleMode,
        builder: (context, value, child) {
          return buildButton(
            value != ModeShuffleEnum.shuffleOptional
                ? Icon(
                  value == ModeShuffleEnum.shuffleNormal
                      ? Icons.shuffle
                      : Icons.arrow_right_alt_rounded,
                  size: 45,
                )
                : Image.asset(
                  'assets/dice.png',
                  color: baseAppColor,
                  colorBlendMode: BlendMode.srcIn,
                  width: 45,
                ),
            () {
              mscAudPl.setShuffleModeEnabled();
            },
            3 / 2,
            2,
          );
        },
      );
    case ButtonTypes.repeat:
      return ValueListenableBuilder<ModeLoopEnum>(
        valueListenable: mscAudPl.loopMode,
        builder: (context, value, child) {
          return buildButton(
            Icon(
              value == ModeLoopEnum.off
                  ? Icons.arrow_right_alt_rounded
                  : value == ModeLoopEnum.all
                  ? Icons.repeat_rounded
                  : Icons.repeat_one_rounded,
              size: 45,
            ),
            () {
              mscAudPl.setLoopModeEnabled();
            },
            3 / 2,
            2,
          );
        },
      );
  }
}

Widget buildButton(
  Widget icon,
  VoidCallback onPressed,
  double aspect,
  int flex,
) {
  return Expanded(
    flex: flex,
    child: AspectRatio(
      aspectRatio: aspect,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(15),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: icon,
      ),
    ),
  );
}

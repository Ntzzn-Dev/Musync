import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:musync_and/services/audio_player.dart';
import 'package:musync_and/services/media_atual.dart';
import 'package:musync_and/themes.dart';
import 'package:volume_controller/volume_controller.dart';

class SoundControl extends StatefulWidget {
  final bool ekoConnected;
  final double? height;
  const SoundControl({super.key, required this.ekoConnected, this.height});

  @override
  State<SoundControl> createState() => _SoundControlState();
}

class _SoundControlState extends State<SoundControl> {
  double volume = 0.0;
  late double height;
  IconData iconeVol = Icons.volume_down_outlined;
  VoidCallback? mediaListener;

  @override
  void initState() {
    super.initState();
    if (!widget.ekoConnected) {
      VolumeController().getVolume().then((v) => setState(() => volume = v));
      VolumeController().listener((v) => setState(() => volume = v));
    } else {
      volume = MediaAtual.volume.value / 100;
      mediaListener = () {
        setState(() {
          volume = MediaAtual.volume.value / 100;
        });
      };
      MediaAtual.volume.addListener(mediaListener!);
    }

    height = widget.height ?? 52;
  }

  @override
  void dispose() {
    if (!widget.ekoConnected) {
      VolumeController().removeListener();
    } else {
      if (mediaListener != null) {
        MediaAtual.volume.removeListener(mediaListener!);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final knobSize = height.clamp(0.0, 36.0);
        final knobTop = (height - knobSize) / 2;

        final knobX = (totalWidth * volume) - (knobSize / 2) - 16;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            final width = context.size!.width;
            double delta = details.localPosition.dx / width;
            delta = delta.clamp(0.0, 1.0);

            setState(() {
              volume = delta;

              if (widget.ekoConnected) {
                MusyncAudioHandler.mediaAtual.value.setVolume(volume * 100);
              } else {
                VolumeController().setVolume(delta);
              }

              if (volume <= 0.02) {
                iconeVol = Icons.volume_mute_outlined;
              } else if (volume < 0.5) {
                iconeVol = Icons.volume_down_outlined;
              } else {
                iconeVol = Icons.volume_up_outlined;
              }
            });
          },
          child: Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 48, 48, 48),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: baseAppColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      width: totalWidth * volume,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: knobX.clamp(0, totalWidth - knobSize * 1.5),
                top: knobTop,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Center(child: Icon(iconeVol, size: knobSize)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

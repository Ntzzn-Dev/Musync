import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

class SoundControl extends StatefulWidget {
  const SoundControl({super.key});

  @override
  State<SoundControl> createState() => _SoundControlState();
}

class _SoundControlState extends State<SoundControl> {
  double volume = 0.0;
  IconData iconeVol = Icons.volume_down_outlined;

  @override
  void initState() {
    super.initState();
    VolumeController().getVolume().then((v) => setState(() => volume = v));
    VolumeController().listener((v) => setState(() => volume = v));
  }

  @override
  void dispose() {
    VolumeController().removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final width = context.size!.width;
        double delta = details.localPosition.dx / width;
        delta = delta.clamp(0.0, 1.0);

        setState(() {
          volume = delta;
          VolumeController().setVolume(delta);

          if (volume <= 0.02) {
            iconeVol = Icons.volume_mute_outlined;
          } else if (volume < 0.5) {
            iconeVol = Icons.volume_down_outlined;
          } else {
            iconeVol = Icons.volume_up_outlined;
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final knobSize = 36.0;

          final knobX = (totalWidth * volume) - (knobSize / 2) - 16;

          return Stack(
            children: [
              Container(
                height: 52,
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
                        color: const Color.fromARGB(255, 243, 160, 34),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      width: totalWidth * volume,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: knobX.clamp(0, totalWidth - knobSize),
                top: 8,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Center(child: Icon(iconeVol, size: 32)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

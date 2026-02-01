import 'package:flutter/material.dart';
import 'package:musync_dkt/services/audio_player.dart';
import 'package:musync_dkt/themes.dart';

class SoundControl extends StatefulWidget {
  final double? height;
  final MusyncAudioHandler audPl;

  const SoundControl({
    super.key,
    this.height,
    required this.audPl,
  });

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

    volume = widget.audPl.vol.value / 100;
    _updateIcon(volume);

    mediaListener = () {
      if (!mounted) return;
      setState(() {
        volume = widget.audPl.vol.value / 100;
        _updateIcon(volume);
      });
    };

    widget.audPl.vol.addListener(mediaListener!);

    height = widget.height ?? 52;
  }

  @override
  void dispose() {
    if (mediaListener != null) {
      widget.audPl.vol.removeListener(mediaListener!);
    }
    super.dispose();
  }

  void _updateIcon(double v) {
    if (v <= 0.02) {
      iconeVol = Icons.volume_mute_outlined;
    } else if (v < 0.5) {
      iconeVol = Icons.volume_down_outlined;
    } else {
      iconeVol = Icons.volume_up_outlined;
    }
  }

  void _setVolume(double v) {
    v = v.clamp(0.0, 1.0);

    setState(() {
      volume = v;
      _updateIcon(v);
    });

    widget.audPl.setVolume(v * 100);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            final width = context.size!.width;
            final delta = (details.localPosition.dx / width).clamp(0.0, 1.0);
            _setVolume(delta);
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
                      width: totalWidth * volume,
                      decoration: BoxDecoration(
                        color: baseAppColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

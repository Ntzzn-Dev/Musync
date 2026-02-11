import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:musync_and/services/ekosystem.dart';
import 'package:musync_and/widgets/popup_add.dart';

class VerticalPopupMenu extends StatefulWidget {
  const VerticalPopupMenu({Key? key}) : super(key: key);

  @override
  State<VerticalPopupMenu> createState() => _VerticalPopupMenuState();
}

class _VerticalPopupMenuState extends State<VerticalPopupMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _topAnimation;
  late Animation<Offset> _bottomAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _topAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _bottomAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _roundButton(
    IconData icon,
    String tip,
    VoidCallback onTap, {
    String? label,
  }) {
    log((label != null).toString());
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF181614),
              ),
              child: Icon(icon, color: Color(0xFFF3A022), size: 28),
            ),
            if (label != null) ...[
              const SizedBox(width: 8), // espaço entre botão e texto
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _closePopup() async {
    await _controller.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 56;
    const double spacing = 10;
    const double padding = 10;

    final double containerHeight = buttonSize * 3 + spacing * 2 + padding * 2;
    final double containerWidth = buttonSize + padding * 2;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: containerWidth,
            height: containerHeight,
            padding: const EdgeInsets.all(padding),
            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SlideTransition(
                  position: _topAnimation,
                  child: _roundButton(
                    Icons.connected_tv,
                    'Desconectar',
                    () async {
                      if (await showPopupAdd(
                        context,
                        'Deseja deconectar do desktop?',
                        [],
                      )) {
                        eko.tryToDisconect();
                        await _closePopup();
                      }
                    },
                    label: 'Desconectar',
                  ),
                ),

                _roundButton(Icons.crop_square, 'Minimizar', () async {
                  eko.sendMessage({'action': 'minimize_window'});

                  await _closePopup();
                }, label: 'Minimizar'),

                SlideTransition(
                  position: _bottomAnimation,
                  child: _roundButton(Icons.close, 'Fechar', () async {
                    if (await showPopupAdd(
                      context,
                      'Deseja fechar Musync do desktop?',
                      [],
                    )) {
                      eko.sendMessage({'action': 'close_window'});
                      await _closePopup();
                    }
                  }, label: 'Fechar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

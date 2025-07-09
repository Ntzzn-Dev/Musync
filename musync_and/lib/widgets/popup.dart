import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

Future<void> showPopup(
  BuildContext context,
  String label,
  List<Map<String, dynamic>> options,
) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: SizedBox(
              height: 50,
              child: Marquee(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold),
                scrollAxis: Axis.horizontal,
                blankSpace: 20,
                velocity: 60,
                pauseAfterRound: Duration(seconds: 1),
                startPadding: 10,
                accelerationDuration: Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              options[index]['funct']?.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(options[index]['opt']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

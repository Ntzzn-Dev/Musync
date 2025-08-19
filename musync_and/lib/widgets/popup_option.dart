import 'package:flutter/material.dart';
import 'package:musync_and/widgets/letreiro.dart';

Future<void> showPopupOptions(
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
            title: Letreiro(
              key: ValueKey(label),
              texto: label,
              blankSpace: 90,
              fullTime: 12,
              timeStoped: 1500,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(options.length, (index) {
                  final IconData? iconData =
                      options[index]['icon'] as IconData?;
                  final String? label = options[index]['opt'] as String?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        options[index]['funct']?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (iconData != null)
                              Icon(
                                iconData,
                                size: 18,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.color,
                              ),
                            if (iconData != null) const SizedBox(width: 16),
                            if (label != null)
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                  child: Icon(Icons.close),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

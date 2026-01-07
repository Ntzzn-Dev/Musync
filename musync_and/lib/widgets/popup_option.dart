import 'package:flutter/material.dart';
import 'package:musync_and/widgets/letreiro.dart';

class OptionAction {
  final String label;
  final IconData icon;
  final VoidCallback funct;

  const OptionAction({
    required this.label,
    required this.icon,
    required this.funct,
  });
}

class OptionItem {
  final List<OptionAction> actions;

  const OptionItem({required this.actions});

  bool get isSingle => actions.length == 1;
  bool get isDouble => actions.length == 2;
}

Future<void> showPopupOptions(
  BuildContext context,
  String label,
  List<OptionItem> options,
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
                  final option = options[index];

                  final IconData iconData = option.actions.first.icon;
                  final String label = option.actions.first.label;

                  IconData? iconData2;
                  String? label2;

                  if (option.isDouble) {
                    iconData2 = option.actions[1].icon;
                    label2 = option.actions[1].label;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              options[index].actions.first.funct.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    iconData,
                                    size: 18,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.color,
                                  ),
                                  const SizedBox(width: 16),
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
                        ),
                        if (options[index].isDouble) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                options[index].actions[1].funct.call();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      iconData2,
                                      size: 18,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.color,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      label2 ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

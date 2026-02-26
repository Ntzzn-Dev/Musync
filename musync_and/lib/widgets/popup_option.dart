import 'package:flutter/material.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:musync_and/themes.dart';
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
  bool get isTriple => actions.length == 3;
}

Future<void> showPopupOptions(
  BuildContext context,
  String label,
  List<OptionItem> options, {
  int? indexMsc,
}) async {
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: List.generate(option.actions.length, (
                        actionIndex,
                      ) {
                        final action = option.actions[actionIndex];
                        final isCheck = mscAudPl.checkpoint.isCheckpoint(
                          currentMusic: indexMsc ?? -1,
                          currentSetList: mscAudPl.actlist.viewingPlaylist.tag,
                        );

                        final isCheckAction = action.label == 'Check';

                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              action.funct;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    action.funct();
                                    setState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          isCheck && isCheckAction
                                              ? baseAppColor
                                              : null,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 16.0,
                                      ),
                                      child:
                                          !option.isTriple
                                              ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    action.icon,
                                                    size: 18,
                                                    color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    action.label,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    action.icon,
                                                    size: 24,
                                                    color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    action.label,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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

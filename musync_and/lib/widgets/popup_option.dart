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
                  if (options[index].containsKey('opts')) {
                    final IconData? iconDataLeft =
                        options[index]['icons'][0] as IconData?;
                    final IconData? iconDataRight =
                        options[index]['icons'][1] as IconData?;
                    final String? labelLeft = options[index]['opts'][0] as String?;
                    final String? labelRight = options[index]['opts'][1] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row (
                        children: [ 
                          Expanded(
                          child:
                            InkWell(
                              onTap: () {
                                options[index]['functs'][0]?.call();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    if (iconDataLeft != null)
                                      Icon(
                                        iconDataLeft,
                                        size: 18,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.color,
                                      ),
                                    if (iconDataLeft != null) const SizedBox(width: 16),
                                    if (labelLeft != null)
                                      Text(
                                        labelLeft,
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
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                options[index]['functs'][1]?.call();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    if (labelRight != null)
                                      Text(
                                        labelRight,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    if (iconDataRight != null) const SizedBox(width: 16),
                                    if (iconDataRight != null)
                                      Icon(
                                        iconDataRight,
                                        size: 18,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.color,
                                      ),
                                    
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    );
                  } else {
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
                  }
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musync_and/helpers/database_helper.dart';
import 'package:musync_and/helpers/menu_helper.dart';

enum ContentTypeEnum { title, text, necessary }

class ContentItem {
  final String value;
  final ContentTypeEnum type;

  ContentItem({required this.value, required this.type});
}

Future<bool> showPopupAdd(
  BuildContext context,
  String label,
  List<ContentItem> fieldLabels, {
  List<String>? fieldValues,
  void Function(List<String> values)? onConfirm,
}) async {
  final List<TextEditingController> controllers = List.generate(
    fieldLabels.length,
    (index) => TextEditingController(
      text:
          fieldValues != null && index < fieldValues.length
              ? fieldValues[index]
              : '',
    ),
  );

  final List<bool> hasError = List.generate(
    fieldLabels.length,
    (index) => false,
  );

  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(fieldLabels.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[index],
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              labelText: fieldLabels[index].value,
                              errorText:
                                  hasError[index] ? 'Campo inválido' : null,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      hasError[index]
                                          ? Colors.red
                                          : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            actionsPadding: const EdgeInsets.only(
              top: 0,
              right: 16,
              bottom: 12,
              left: 16,
            ),
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
                    onPressed: () async {
                      List<String> values =
                          controllers
                              .map((controller) => controller.text)
                              .toList();

                      List<int> matchingIndicesTitle = [];
                      List<int> matchingIndicesNecessarys = [];

                      for (var entry in fieldLabels.asMap().entries) {
                        final index = entry.key;
                        final item = entry.value;

                        if (item.type == ContentTypeEnum.title) {
                          matchingIndicesTitle.add(index);
                        }

                        if (item.type == ContentTypeEnum.necessary) {
                          matchingIndicesNecessarys.add(index);
                        }
                      }

                      bool hasAnyError = false;

                      for (int i in matchingIndicesTitle) {
                        String value = values[i];
                        if (value.trim() !=
                            (await DatabaseHelper.instance.verifyPlaylistTitle(
                              value,
                            )).trim()) {
                          setState(() {
                            hasError[i] = true;
                          });
                          hasAnyError = true;
                        } else if (value == "" || value.isEmpty) {
                          setState(() {
                            hasError[i] = true;
                          });
                          hasAnyError = true;
                        } else {
                          setState(() {
                            hasError[i] = false;
                          });
                        }
                      }

                      for (int i in matchingIndicesNecessarys) {
                        String value = values[i];
                        if (value == "" || value.isEmpty) {
                          setState(() {
                            hasError[i] = true;
                          });
                          hasAnyError = true;
                        } else {
                          setState(() {
                            hasError[i] = false;
                          });
                        }
                      }

                      if (hasAnyError) {
                        showSnack('Corrija os campos', context);
                        return;
                      }

                      if (onConfirm != null) {
                        onConfirm(values);
                      }

                      Navigator.of(context).pop(true);
                    },
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

  return result ?? false;
}

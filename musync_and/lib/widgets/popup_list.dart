import 'package:flutter/material.dart';

class InfoItem {
  final String info;
  final String value;

  InfoItem({required this.info, required this.value});
}

class InfoLabel {
  final String name;
  final int flex;
  final bool centralize;
  final bool bold;

  InfoLabel({
    required this.name,
    required this.flex,
    required this.centralize,
    required this.bold,
  });
}

class InfoLabelSpecs {
  InfoLabel info;
  InfoLabel value;

  InfoLabelSpecs({required this.info, required this.value});
}

Future<void> showPopupList(
  BuildContext context,
  String label,
  List<InfoItem> values,
  InfoLabelSpecs fieldLabels,
) async {
  Widget createOrdem(List<InfoItem> dados) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: fieldLabels.info.flex,
              child: Center(child: Text(fieldLabels.info.name)),
            ),

            Expanded(
              flex: fieldLabels.value.flex,
              child: Center(child: Text(fieldLabels.value.name)),
            ),
          ],
        ),

        const Divider(),

        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children:
                  dados.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: fieldLabels.info.flex,
                            child:
                                fieldLabels.info.centralize
                                    ? Center(
                                      child: Text(
                                        item.info.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight:
                                              fieldLabels.info.bold
                                                  ? FontWeight.bold
                                                  : null,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      item.info.toString(),
                                      style: TextStyle(
                                        fontWeight:
                                            fieldLabels.info.bold
                                                ? FontWeight.bold
                                                : null,
                                      ),
                                    ),
                          ),
                          Expanded(
                            flex: fieldLabels.value.flex,
                            child:
                                fieldLabels.value.centralize
                                    ? Center(
                                      child: Text(
                                        item.info.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight:
                                              fieldLabels.value.bold
                                                  ? FontWeight.bold
                                                  : null,
                                        ),
                                      ),
                                    )
                                    : Text(
                                      item.info.toString(),
                                      style: TextStyle(
                                        fontWeight:
                                            fieldLabels.value.bold
                                                ? FontWeight.bold
                                                : null,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Center(
              child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            content: createOrdem(values),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sair'),
              ),
            ],
          );
        },
      );
    },
  );
}

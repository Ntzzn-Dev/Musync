import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> openQrScanner(BuildContext context) async {
  String? codeFinal;
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      final String? code = barcode.rawValue;

                      if (code != null) {
                        Navigator.pop(context);
                        codeFinal = code;
                      }
                    },
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  return codeFinal;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  _QRCodeScannerScreenState createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skanuj QR Code')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (scannedData != null)
                  ? Text('Zeskanowane dane: $scannedData')
                  : const Text('Przyłóż kamerę do QR kodu'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (scannedData != null) {
            Navigator.of(context).pop(scannedData);
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scannedData = scanData.code;
      });
      controller.pauseCamera();
      Navigator.of(context).pop(scannedData);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

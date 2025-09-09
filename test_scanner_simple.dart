import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Test',
      home: SimpleScannerScreen(),
    );
  }
}

class SimpleScannerScreen extends StatefulWidget {
  @override
  State<SimpleScannerScreen> createState() => _SimpleScannerScreenState();
}

class _SimpleScannerScreenState extends State<SimpleScannerScreen> {
  MobileScannerController? controller;
  
  @override
  void initState() {
    super.initState();
    print("📱 Initialisation du scanner simple");
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Scanner Simple'),
      ),
      body: controller == null
          ? Center(child: CircularProgressIndicator())
          : MobileScanner(
              controller: controller!,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  print("🔍 Code détecté: ${barcode.displayValue}");
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Code scanné'),
                      content: Text('Code: ${barcode.displayValue}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}

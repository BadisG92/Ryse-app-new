import 'package:flutter/material.dart';
import 'lib/screens/ai_scanner_screen.dart';
import 'lib/screens/barcode_scanner_screen.dart';
import 'lib/screens/select_recipe_screen.dart';
import 'lib/bottom_sheets/add_food_bottom_sheet.dart';

void main() {
  runApp(TestNavigationApp());
}

class TestNavigationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Navigation',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Navigation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIScannerScreen(),
                  ),
                );
              },
              child: Text('Test AI Scanner'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BarcodeScannerScreen(),
                  ),
                );
              },
              child: Text('Test Barcode Scanner'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectRecipeScreen(),
                  ),
                );
              },
              child: Text('Test Recipe Screen'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AddFoodBottomSheet.show(context, () {
                  print('Manual entry callback called');
                });
              },
              child: Text('Test Bottom Sheet'),
            ),
          ],
        ),
      ),
    );
  }
} 
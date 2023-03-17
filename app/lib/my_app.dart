import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Selectable Text with ClipPath')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                CustomPaint(
                  painter: ClipPathPainter(),
                  child: Container(),
                ),
                const SelectableText(
                  'This is some sample text that can be selected and copied.',
                  style: TextStyle(fontSize: 18),
                  cursorColor: Colors.blue,
                  showCursor: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClipPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

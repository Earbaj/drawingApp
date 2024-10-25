import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Painting App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PaintingBoard(),
    );
  }
}

class PaintingBoard extends StatefulWidget {
  const PaintingBoard({super.key});

  @override
  _PaintingBoardState createState() => _PaintingBoardState();
}

class _PaintingBoardState extends State<PaintingBoard>
    with TickerProviderStateMixin {
  List<Offset?> points = []; // Store points where the user draws
  Color selectedColor = Colors.black; // Default drawing color
  late AnimationController _controller;
  late Animation<double> _animation;
  bool showArrow =
      false; // Initially hide the arrow until left stroke is detected
  int count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          const Duration(seconds: 2), // Duration of the left arrow animation
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painting App with Left Arrow Animation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                count = 0;
                points.clear(); // Clear the drawing when the button is pressed
                showArrow = false; // Reset arrow visibility
                _controller.reset(); // Reset the animation controller
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Draw the animated left arrow for letter A (only if `showArrow` is true)
          CustomPaint(
            painter: ArrowPainter(_animation.value, count),
            child: Container(),
          ),

          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                points.add(details.localPosition); // Capture touch position
              });
            },
            onPanEnd: (details) {
              setState(() {
                _controller.reset();
                count++;
                if (count == 1) {
                  _controller.forward();
                } else if (count == 2) {
                  _controller.forward();
                }
                points.add(null); // End of stroke
              });
            },
            child: CustomPaint(
              painter: DrawingPainter(points, selectedColor), // Pass the color
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show color picker dialog
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Choose Color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color; // Update selected color
                      });
                      Navigator.of(context).pop(); // Close dialog
                    },
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.color_lens),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  DrawingPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color // Set the drawing color
      ..strokeWidth = 6.0 // Thickness of the stroke
      ..strokeCap = StrokeCap.round; // Round ends for the strokes

    // Draw lines between points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever points change
  }
}

class ArrowPainter extends CustomPainter {
  final double animationValue;
  final int steps;

  ArrowPainter(this.animationValue, this.steps);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red // Arrow color
      ..strokeWidth = 6.0 // Thickness of the stroke
      ..style = PaintingStyle.stroke;

    final double leftX = size.width * 0.1; // Leftmost point (10% from the left)
    final double topY =
        size.height * 0.2; // Top center point (20% from the top)
    final double centerX = size.width / 2;

    if (steps == 0) {
      // Left arrow stroke (animate the arrow from leftmost to top center)
      drawArrow(
        canvas,
        paint,
        Offset(leftX, size.height * 0.8),
        Offset(leftX + (centerX - leftX) * animationValue,
            size.height * 0.8 - (size.height * 0.8 - topY) * animationValue),
      );
    } else if (steps == 1) {
      // Right arrow stroke (animate from center top to bottom right)
      drawArrow(
        canvas,
        paint,
        Offset(centerX, size.height * 0.2),
        Offset(
            centerX + (centerX - leftX) * animationValue,
            topY +
                (size.height - topY - 140) *
                    animationValue), // Adjust Y position downward
      );
    } else if (steps == 2) {
      // Horizontal middle arrow
      drawArrow(
        canvas,
        paint,
        Offset(centerX - 70, topY + 200), // Start point (slightly below top)
        Offset(
            centerX + 80 * animationValue, topY + 200), // Animate horizontally
      );
    }
  }

  void drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) {
    canvas.drawLine(from, to, paint);

    // Arrowhead logic
    const double arrowSize = 10.0;
    final double angle = atan2(to.dy - from.dy, to.dx - from.dx);
    final Offset arrow1 = Offset(
      to.dx - arrowSize * cos(angle - pi / 6),
      to.dy - arrowSize * sin(angle - pi / 6),
    );
    final Offset arrow2 = Offset(
      to.dx - arrowSize * cos(angle + pi / 6),
      to.dy - arrowSize * sin(angle + pi / 6),
    );
    canvas.drawLine(to, arrow1, paint);
    canvas.drawLine(to, arrow2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

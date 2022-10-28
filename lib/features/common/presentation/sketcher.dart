import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@immutable
class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double stroke;

  const DrawnLine({
    required this.path,
    required this.color,
    required this.stroke,
  });
}

class SketcherController extends ChangeNotifier {
  late Queue<DrawnLine> _linesQueue;
  DrawnLine? _currentDrawLine;
  late Color _color;
  late double _stroke;

  SketcherController({
    Iterable<DrawnLine>? lines,
    Color? color,
    double? stroke,
  }) {
    _linesQueue = Queue.from(lines ?? <DrawnLine>[]);
    _color = color ?? Colors.black;
    _stroke = stroke ?? 1.0;
  }

  Color get color => _color;

  set color(Color color) {
    if (_color == color) return;

    _color = color;
    notifyListeners();
  }

  double get stroke => _stroke;

  set stroke(double stroke) {
    if (_stroke == stroke) return;

    // захардкоженные границы min/max значений
    if (stroke < 1.0) {
      _stroke = 1.0;
    } else if (stroke > 5.0) {
      _stroke = 5.0;
    } else {
      _stroke = stroke;
    }

    notifyListeners();
  }

  void startDrawingLine(Offset position) {
    _currentDrawLine = DrawnLine(
      path: <Offset>[position],
      color: _color,
      stroke: _stroke,
    );
    notifyListeners();
  }

  void addLinePath(Offset position) {
    if (_currentDrawLine == null) return startDrawingLine(position);

    _currentDrawLine = DrawnLine(
      path: <Offset>[..._currentDrawLine!.path, position],
      color: _color,
      stroke: _stroke,
    );
    notifyListeners();
  }

  void endDrawingLine() {
    if (_currentDrawLine == null) return;

    _linesQueue.add(_currentDrawLine!);
    _currentDrawLine = null;
    notifyListeners();
  }

  void addLine(DrawnLine line) {
    _linesQueue.add(line);
    notifyListeners();
  }

  void removeLastLine() {
    if (_currentDrawLine != null) {
      _currentDrawLine = null;
      notifyListeners();
      return;
    }

    if (_linesQueue.isEmpty) return;

    _linesQueue.removeLast();
    notifyListeners();
  }

  void reset() {
    _currentDrawLine = null;
    _linesQueue.clear();
    notifyListeners();
  }

  Iterable<DrawnLine> get lines => _linesQueue;

  DrawnLine? get currentDrawLine => _currentDrawLine;
}

class Sketcher extends StatefulWidget {
  final SketcherController controller;
  final Widget child;

  const Sketcher({
    required this.child,
    required this.controller,
    super.key,
  });

  @override
  State<Sketcher> createState() => _SketcherState();
}

class _SketcherState extends State<Sketcher> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: GestureDetector(
        onPanStart: (details) {
          widget.controller.startDrawingLine(details.localPosition);
        },
        onPanUpdate: (details) {
          widget.controller.addLinePath(details.localPosition);
        },
        onPanEnd: (details) {
          widget.controller.endDrawingLine();
        },
        child: Consumer<SketcherController>(
          builder: (_, controller, __) {
            return CustomPaint(
              foregroundPainter: _SketcherPainter(
                currentDrawnLine: controller.currentDrawLine,
                lines: controller.lines,
              ),
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

class _SketcherPainter extends CustomPainter {
  final DrawnLine? currentDrawnLine;
  final Iterable<DrawnLine> lines;

  const _SketcherPainter({
    required this.currentDrawnLine,
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mergedLines = <DrawnLine>[...lines];
    if (currentDrawnLine != null) {
      mergedLines.add(currentDrawnLine!);
    }

    for (final line in mergedLines) {
      final paint = Paint()
        ..strokeWidth = line.stroke
        ..color = line.color
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(line.path.first.dx, line.path.first.dy);

      for (var i = 1; i < line.path.length; i++) {
        final pathSegment = line.path[i];

        if (pathSegment.dx > size.width || pathSegment.dx < 0 || pathSegment.dy > size.height || pathSegment.dy < 0) {
          continue;
        }

        path.lineTo(pathSegment.dx, pathSegment.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => oldDelegate is _SketcherPainter;
}

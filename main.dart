import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitaFeeling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ColorPallete(
        notifier: ColorPalleteNotifier(),
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CanvasArea(),
          Align(
            alignment: Alignment.bottomCenter,
            child: ColorSelectionWidget(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: UndoButtonBar(),
          )
        ],

      ),
    );
  }
}

class CanvasArea extends StatefulWidget {
  @override
  _CanvasAreaState createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  late ColorPath _colorPath;

  void _onPanStart(DragStartDetails details) {
    _colorPath.setFirstPoint(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _colorPath.updatePath(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    ColorPath.paths.add(_colorPath);
    setState(() {
      _colorPath = ColorPath(ColorPallete.of(context).selectedColor);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorPath = ColorPath(ColorPallete.of(context).selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          for (final colorPath in ColorPath.paths)
            CustomPaint(
              size: Size.infinite,
              painter: PathPainter(colorPath),
            ),
          CustomPaint(
            size: Size.infinite,
            painter: PathPainter(_colorPath),
          ),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final ColorPath colorPath;

  PathPainter(this.colorPath);

  Paint get paintBrush {
    return Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = colorPath.color
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(colorPath.path, paintBrush);
  }

  @override
  bool shouldRepaint(PathPainter old) {
    return true;
  }
}

class ColorSelectionWidget extends StatelessWidget {
  static const double _circleWidth = 25;

  @override
  Widget build(BuildContext context) {
    final colorPallete = ColorPallete.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < colorPallete.colors.length; i++)
              ColorCircle(
                index: i,
                width: _circleWidth,
              ),
          ],
        ),
        const SizedBox(height: _circleWidth / 10),
        ColorSlider(),
      ],
    );
  }
}

class ColorCircle extends StatelessWidget {
  final int index;
  final double width;

  const ColorCircle({
    Key? key,
    required this.index,
    required this.width,
  }) : super(key: key);

  static final Matrix4 _transform = Matrix4.identity()..scale(1.4);

  @override
  Widget build(BuildContext context) {
    final colorPallete = ColorPallete.of(context);
    final selected = colorPallete.selectedIndex == index;

    return GestureDetector(
      onTap: selected ? null : () => colorPallete.select(index),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: ColorHelper.colorToHue(colorPallete.colors[index]),
        ),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Container(
            width: width,
            height: width,
            transformAlignment: Alignment.center,
            transform: selected ? _transform : null,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorHelper.hueToColor(value),
              border: Border.all(
                color: selected ? Colors.black54 : Colors.white70,
                width: 6,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ColorSlider extends StatelessWidget {
  void _onChanged(BuildContext context, double value) {
    final colorPallete = ColorPallete.of(context);
    colorPallete.changeColor(ColorHelper.hueToColor(value));
  }

  @override
  Widget build(BuildContext context) {
    final colorPallete = ColorPallete.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            height: 15,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  for (var i = 0; i <= 360; i++)
                    HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor(),
                ],
                stops: [
                  for (var i = 0; i <= 360; i++) (i / 360).toDouble(),
                ],
              ),
            ),
          ),
        ),
        Slider(
          value: ColorHelper.colorToHue(colorPallete.selectedColor),
          onChanged: (value) => _onChanged(context, value),
          min: 0,
          max: 360,
        ),
      ],
    );
  }
}

class UndoButtonBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ButtonBar(
      children: [
        IconButton(
          icon: const Icon(Icons.undo_rounded),
          color: Colors.black38,
          onPressed: () => _undo(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete_rounded),
          color: Colors.black38,
          onPressed: () => _clear(context),
        ),
      ],
    );
  }

  void _clear(BuildContext context) {
    ColorPath.paths.clear();
    ColorPallete.of(context).rebuild();
  }

  void _undo(BuildContext context) {
    ColorPath.paths.removeLast();
    ColorPallete.of(context).rebuild();
  }
}

class ColorHelper {
  static Color hueToColor(double hueValue) =>
      HSVColor.fromAHSV(1.0, hueValue, 1.0, 1.0).toColor();

  static double colorToHue(Color color) => HSVColor.fromColor(color).hue;
}

class ColorPath {
  final Path path = Path();
  final Color color;
  ColorPath(this.color);

  static List<ColorPath> paths = [];

  void setFirstPoint(Offset point) {
    path.moveTo(point.dx, point.dy);
  }

  void updatePath(Offset point) {
    path.lineTo(point.dx, point.dy);
  }
}

class ColorPalleteNotifier extends ChangeNotifier {
  List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lightGreen,
    Colors.green,
    Colors.lightBlue,
    Colors.blue,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.pink,
  ];

  int selectedIndex = 0;

  Color get selectedColor => colors[selectedIndex];

  void changeColor(Color newColor) {
    colors[selectedIndex] = newColor;
    notifyListeners();
  }

  void select(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void rebuild() {
    notifyListeners();
  }
}

class ColorPallete extends InheritedNotifier<ColorPalleteNotifier> {
  const ColorPallete({
    Key? key,
    required ColorPalleteNotifier notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static ColorPalleteNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ColorPallete>()!
        .notifier!;
  }
}
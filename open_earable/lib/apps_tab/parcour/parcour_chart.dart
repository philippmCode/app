import 'dart:async';

import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:simple_kalman/simple_kalman.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'dart:core';

/// A class representing a Chart for Jump Height.
class ParcourChart extends StatefulWidget {
  /// The OpenEarable object.
  final OpenEarable openEarable;

  /// The title of the chart.
  final String title;

  /// Constructs a JumpHeightChart object with an OpenEarable object and a title.
  const ParcourChart(this.openEarable, this.title, {super.key});

  @override
  State<ParcourChart> createState() => _ParcourChartState();
}

/// A class representing the state of a JumpHeightChart.
class _ParcourChartState extends State<ParcourChart> {
  /// The data of the chart.
  late List<DataValue> _data;

  /// The subscription to the data.
  StreamSubscription? _dataSubscription;

  /// The minimum x value of the chart.
  late int _minX = 0;

  /// The maximum x value of the chart.
  late int _maxX = 0;

  /// The colors of the chart.
  late List<String> colors;

  /// The series of the chart.
  List<charts.Series<dynamic, num>> seriesList = [];

  /// The minimum y value of the chart.
  late double _minY;

  /// The maximum y value of the chart.
  late double _maxY;

  /// The error measure of the Kalman filter.
  final _errorMeasureAcc = 5.0;

  /// The Kalman filter for the x value.
  late SimpleKalman _kalmanX;

  /// The Kalman filter for the y value.
  late SimpleKalman _kalmanY;

  /// The Kalman filter for the z value.
  late SimpleKalman _kalmanZ;

  /// The number of datapoints to display on the chart.
  final int _numDatapoints = 200;

  /// The velocity of the device.
  double _velocity = 0.0;

  /// Sampling rate time slice (inverse of frequency).
  final double _timeSlice = 1.0 / 30.0;

  /// Standard gravity in m/s^2.
  final double _gravity = 9.81;

  /// Pitch angle in radians.
  double _pitch = 0.0;

  /// The height of the jump.
  double _height = 0.0;

  /// Flag to indicate if the height is over 10 cm.
  bool _isHeightOverThreshold = false;

    late Player player;
    List<Obstacle> obstacles = [];
    late Timer timer;
    double lastUpdateTime = 0.0;
      
  /// Sets up the listeners for the data.
  void _setupListeners() {
    _kalmanX = SimpleKalman(
      errorMeasure: _errorMeasureAcc,
      errorEstimate: _errorMeasureAcc,
      q: 0.9,
    );
    _kalmanY = SimpleKalman(
      errorMeasure: _errorMeasureAcc,
      errorEstimate: _errorMeasureAcc,
      q: 0.9,
    );
    _kalmanZ = SimpleKalman(
      errorMeasure: _errorMeasureAcc,
      errorEstimate: _errorMeasureAcc,
      q: 0.9,
    );
    _dataSubscription = widget.openEarable.sensorManager
        .subscribeToSensorData(0)
        .listen((data) {
      int timestamp = data["timestamp"];
      _pitch = data["EULER"]["PITCH"];

      XYZValue filteredAccData = XYZValue(
        timestamp: timestamp,
        x: _kalmanX.filtered(data["ACC"]["X"]),
        y: _kalmanY.filtered(data["ACC"]["Y"]),
        z: _kalmanZ.filtered(data["ACC"]["Z"]),
        units: {"X": "m/s²", "Y": "m/s²", "Z": "m/s²"},
      );

      switch (widget.title) {
        case "Parcour":
          DataValue height = _calculateHeightData(filteredAccData);
          _updateData(height);
          break;
        case "Height Data":
          DataValue height = _calculateHeightData(filteredAccData);
          _updateData(height);
          break;
        default:
          throw ArgumentError("Invalid tab title.");
      }
    });
  }

  /// Calculates the height of the jump.
  DataValue _calculateHeightData(XYZValue accValue) {
    // Subtract gravity to get acceleration due to movement.
    double currentAcc =
        accValue.z * cos(_pitch) + accValue.x * sin(_pitch) - _gravity;

    double threshold = 0.3;
    double accMagnitude = sqrt(
      accValue.x * accValue.x +
          accValue.y * accValue.y +
          accValue.z * accValue.z,
    );
    bool isStationary = (accMagnitude > _gravity - threshold) &&
        (accMagnitude < _gravity + threshold);
    // Checks if the device is stationary based on acceleration magnitude.
    if (isStationary) {
      _velocity = 0.0;
      _height = 0.0;
    } else {
      // Integrate acceleration to get velocity.
      _velocity += currentAcc * _timeSlice;

      // Integrate velocity to get height.
      _height += _velocity * _timeSlice;
    }
    // Prevent height from going negative.
    _height = max(0, _height);

    return Jump(
      DateTime.fromMillisecondsSinceEpoch(accValue._timestamp),
      _height,
    );
  }

  /// Updates the data of the chart.
  void _updateData(DataValue value) {
    setState(() {
      _data.add(value);
      _checkLength(_data);
      DataValue? maxXYZValue = maxBy(_data, (DataValue b) => b.getMax());
      DataValue? minXYZValue = minBy(_data, (DataValue b) => b.getMin());
      if (minXYZValue == null) {
        return;
      }
      double maxAbsValue =
          max(maxXYZValue?.getMax().abs() ?? 0, minXYZValue.getMin().abs());
      _maxY = maxAbsValue;

      _minY = -maxAbsValue;
      _maxX = value._timestamp;
      _minX = _data[0]._timestamp;

      _isHeightOverThreshold = _height > 0.1;
    });
  }

  /// Gets the color of the chart lines.
  List<String> _getColor(String title) {
    switch (title) {
        case "Parcour":
        // Blue, Orange, and Teal - Good for colorblindness
        return ['#007bff', '#ff7f0e', '#2ca02c'];
      case "Height Data":
        // Blue, Orange, and Teal - Good for colorblindness
        return ['#007bff', '#ff7f0e', '#2ca02c'];
      default:
        throw ArgumentError("Invalid tab title.");
    }
  }

  @override
  void initState() {
    print("init von parcour_chart");
    super.initState();
    _data = [];
    colors = _getColor(widget.title);
    _minY = -25;
    _maxY = 25;
    _setupListeners();
        player = Player(
        x: 150,
        y: 100,
        width: 50,
        height: 50,
        groundLevel: 100,
    );
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      double currentTime = timer.tick * 0.016;
      double dt = currentTime - lastUpdateTime;
      lastUpdateTime = currentTime;
      updateGame(dt);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dataSubscription?.cancel();
  }

  /// Checks the length of the data an removes the oldest data if it is too long.
  void _checkLength(data) {
    if (data.length > _numDatapoints) {
      data.removeRange(0, data.length - _numDatapoints);
    }
  }

  void updateGame(double dt) {
    print("updating game");
    print("dt: $dt");
    setState(() {
      player.update(dt);
      print("Player updated");
      for (var obstacle in obstacles) {
        obstacle.update(dt);
      }
      print("Obstacles updated");
      obstacles.removeWhere((obstacle) => obstacle.x < -obstacle.width);
      if (obstacles.isEmpty || obstacles.last.x < 200) {
        obstacles.add(Obstacle(
          x: MediaQuery.of(context).size.width,
          y: 100,
          width: 50,
          height: 50,
        ),);
      }
      checkCollisions();
    });
  }

  void checkCollisions() {
    for (var obstacle in obstacles) {
      if (player.getRect().overlaps(obstacle.getRect())) {
        // Kollision erkannt, Spiel beenden oder Leben verlieren
        timer.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title == "Height Data") {
      seriesList = [
        charts.Series<DataValue, int>(
          id: 'Height (m)',
          colorFn: (_, __) => charts.Color.fromHex(code: colors[0]),
          domainFn: (DataValue data, _) => data._timestamp,
          measureFn: (DataValue data, _) => (data as Jump)._height,
          data: _data,
        ),
      ];
    } else if (widget.title == "Parcour") {
      print("parcour chart building");
      double currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      double dt = currentTime - lastUpdateTime;
      lastUpdateTime = currentTime;
      updateGame(dt);
      return GestureDetector(
        onTap: () {
          player.jump();
        },
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
              painter: ParcourPainter(player: player, obstacles: obstacles),
              child: Container(),
              ),
            ),
          ],
        ),
      );
    } else {
      throw ArgumentError("Invalid tab title.");
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
        ),
        Expanded(
          child: charts.LineChart(
            seriesList,
            animate: false,
            behaviors: [
              charts.SeriesLegend(
                position: charts.BehaviorPosition.bottom,
                // To position the legend at the end (bottom). You can change this as per requirement.
                outsideJustification:
                    charts.OutsideJustification.middleDrawArea,
                // To justify the position.
                horizontalFirst: false,
                // To stack items horizontally.
                desiredMaxRows: 1,
                // Optional if you want to define max rows for the legend.
                entryTextStyle: charts.TextStyleSpec(
                  // Optional styling for the text.
                  color: charts.Color(r: 255, g: 255, b: 255),
                  fontSize: 12,
                ),
              ),
            ],
            primaryMeasureAxis: charts.NumericAxisSpec(
              renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  fontSize: 14,
                  color: charts.MaterialPalette.white, // Set the color here
                ),
              ),
              viewport: charts.NumericExtents(_minY, _maxY),
            ),
            domainAxis: charts.NumericAxisSpec(
              renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                  fontSize: 14,
                  color: charts.MaterialPalette.white, // Set the color here
                ),
              ),
              viewport: charts.NumericExtents(_minX, _maxX),
            ),
          ),
        ),
      ],
    );
  }
}

/// A class representing a generic data value.
abstract class DataValue {
  /// The timestamp of the data.
  final int _timestamp;

  /// The units of the data.
  final Map<dynamic, dynamic> _units;

  /// Returns the minimum value of the data.
  double getMin();

  /// Returns the maximum value of the data.
  double getMax();

  /// Constructs a DataValue object with a timestamp and units.
  DataValue({required int timestamp, required Map<dynamic, dynamic> units})
      : _units = units,
        _timestamp = timestamp;
}

/// A class representing a generic XYZ value.
class XYZValue extends DataValue {
  /// The x value of the data.
  final double x;

  /// The y value of the data.
  final double y;

  /// The z value of the data.
  final double z;

  /// Constructs a XYZValue object with a timestamp, x, y, z, and units.
  XYZValue({
    required super.timestamp,
    required this.x,
    required this.y,
    required this.z,
    required super.units,
  });

  @override
  double getMax() {
    return max(x, max(y, z));
  }

  @override
  double getMin() {
    return min(x, min(y, z));
  }

  @override
  String toString() {
    return "timestamp: $_timestamp\nx: $x, y: $y, z: $z";
  }
}

/// A class representing a jump with a time and height.
class Jump extends DataValue {
  /// The time of the jump.
  final DateTime _time;

  /// The height of the jump.
  final double _height;

  /// Constructs a Jump object with a time and height.
  Jump(DateTime time, double height)
      : _time = time,
        _height = height,
        super(
          timestamp: time.millisecondsSinceEpoch,
          units: {'height': 'meters'},
        );

  @override
  double getMin() {
    return 0.0;
  }

  @override
  double getMax() {
    return _height;
  }

  @override
  String toString() {
    return "timestamp: ${_time.millisecondsSinceEpoch}\nheight $_height";
  }
}

class Player {
  double x;
  double y;
  double width;
  double height;
  bool isJumping;
  double gravity;
  double groundLevel;
  double targetHeight;

  Player({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isJumping = false,
    this.targetHeight = 0.0,
    this.gravity = 9.8,
    required this.groundLevel,
  });

  void update(double dt) {
    if (isJumping) {
      y -= (targetHeight) * dt; // Bewege den Spieler zur Zielhöhe
      if (y <= groundLevel - targetHeight) {
        y = groundLevel - targetHeight;
        isJumping = false;
      }
      print('Current player height: $y'); // Debug-Ausgabe der aktuellen Höhe
    } else {
      print("player is not jumping");
      if (y < groundLevel) {
        y += (targetHeight) * dt; // Bewege den Spieler zurück zum Boden
        if (y > groundLevel) {
          y = groundLevel;
        }
      }
    }
    print("position: $x, $y");
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      targetHeight = 3 * height;
      print('Jump initiated to height: $targetHeight'); // Debug-Ausgabe der Sprunggeschwindigkeit
    }
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.speed = 200.0,
  });

  void update(double dt) {
    x -= speed * dt;
    print("new obstacle position: $x, $y");
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class ParcourPainter extends CustomPainter {

  final Player player;
  final List<Obstacle> obstacles;

  ParcourPainter({required this.player, required this.obstacles});

  @override
  void paint(Canvas canvas, Size size) {
    // 0-Linie zeichnen
    print("painting");
    final zeroLinePaint = Paint()..color = Colors.black;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), zeroLinePaint);

    // Vertikale Linie mit Höhenmarkierungen zeichnen
    final verticalLinePaint = Paint()..color = Colors.blue;
    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (double i = 0; i <= size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(10, i), verticalLinePaint);
      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(15, i - 6));
    }

        // Spieler zeichnen
    final playerPaint = Paint()..color = Colors.yellow;
    canvas.drawRect(player.getRect(), playerPaint);
    print('Player: ${player.getRect()}'); // Debug-Ausgabe

    // Hindernisse zeichnen
    final obstaclePaint = Paint()..color = Colors.red;
    for (var obstacle in obstacles) {
      canvas.drawRect(obstacle.getRect(), obstaclePaint);
      print('Obstacle: ${obstacle.getRect()}'); // Debug-Ausgabe
    }

    // Horizontale Skala auf der x-Achse zeichnen
    final horizontalLinePaint = Paint()..color = Colors.green;
    for (double i = 0; i <= size.width; i += 50) {
      canvas.drawLine(Offset(i, player.groundLevel - 10), Offset(i, player.groundLevel + 10), horizontalLinePaint);
      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(i - 10, player.groundLevel + 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    print("we should repaint");
    return true;
  }
}

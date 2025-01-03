import 'dart:async';

import 'package:open_earable/apps_tab/parcour/level.dart';
import 'package:open_earable/apps_tab/parcour/parcour.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:flutter/material.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'dart:core';

/// class representing the ParcourChart
class ParcourChart extends StatefulWidget {

  final OpenEarable openEarable;
  final GameState gameState;
  final ParcourState parcourState;

  /// The title of the chart.
  final String title;

  /// Constructs a ParcourChart object with a title, openEarable, gameState, and parcourState.
  const ParcourChart(this.parcourState, this.gameState, this.openEarable, this.title, {super.key});

  @override
  State<ParcourChart> createState() => _ParcourChartState();
}

/// A class representing the state of a ParcourChart.
class _ParcourChartState extends State<ParcourChart> {
  /// The data of the chart.
  late List<DataValue> _data;

  /// The subscription to the data.
  StreamSubscription? _dataSubscription;

  /// The error measure of the Kalman filter.
  final _errorMeasureAcc = 5.0;

  /// The Kalman filter for the x value.
  late SimpleKalman _kalmanX;

  /// The Kalman filter for the y value.
  late SimpleKalman _kalmanY;

  /// The Kalman filter for the z value.
  late SimpleKalman _kalmanZ;

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

  late Player player;
  List<Obstacle> obstacles = [];
  List<Platform> platforms = [];
  List<Gap> gaps = [];
  double lastUpdateTime = 0.0;
  bool enteredPlatform = false;
  bool enteredGap = false;
  late LevelManager levelManager;

  @override
  void initState() {
    ///print("init von parcour_chart");
    super.initState();
    _data = [];
    double screenWidth = MediaQuery.of(context).size.width; // Breite des Bildschirms
    levelManager = LevelManager(screenWidth: screenWidth);
    _setupListeners();
      player = Player(
        x: 150,
        y: 200,
        width: 50,
        height: 50,
        groundLevel: 200,
    );
  }
      
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

    if (_height > 0.1) {
      player.jump();
    }

    return Jump(
      DateTime.fromMillisecondsSinceEpoch(accValue._timestamp),
      _height,
    );
  }

  /// Updates the data of the chart.
  void _updateData(DataValue value) {
    setState(() {
      _data.add(value);
      DataValue? minXYZValue = minBy(_data, (DataValue b) => b.getMin());
      if (minXYZValue == null) {
        return;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _dataSubscription?.cancel();
  }


  void updateGame(double dt) {
    if (!widget.gameState.isGameRunning) return; // Verhindere weitere Updates, wenn das Spiel gestoppt wurde
    //print("updating game");
    setState(() {

      player.update(dt);

      List<Platform> platformsToRemove = [];
      for (var platform in platforms) {
        platform.update(dt);
        if (platform.x < -platform.width) {
          platformsToRemove.add(platform); // Füge das Hindernis zur Liste der zu entfernenden Hindernisse hinzu
        }
      }
      platforms.removeWhere((platform) => platformsToRemove.contains(platform));

      List<Gap> gapsToRemove = [];
      for (var gap in gaps) {
        gap.update(dt);
        if (gap.x < -gap.width) {
          gapsToRemove.add(gap); // Füge das Hindernis zur Liste der zu entfernenden Hindernisse hinzu
        }
      }
      gaps.removeWhere((gap) => gapsToRemove.contains(gap));

      List<Obstacle> obstaclesToRemove = [];
      for (var obstacle in obstacles) {
        obstacle.update(dt);
        if (obstacle.x < -obstacle.width) {
          obstaclesToRemove.add(obstacle); // Füge das Hindernis zur Liste der zu entfernenden Hindernisse hinzu
          widget.gameState.obstaclesOvercome++; // Erhöhe den Zähler
        }
      }
      obstacles.removeWhere((obstacle) => obstaclesToRemove.contains(obstacle));

      if (obstacles.isEmpty && platforms.isEmpty && gaps.isEmpty) {
        
        print("wir rufen ein level auf");
        
        Level actualLevel = levelManager.getLevel();
        print("actualLevel: ${actualLevel.name}");
        obstacles = actualLevel.obstacles.map((obstacle) => Obstacle(
          x: obstacle.x,
          y: obstacle.y,
          width: obstacle.width,
          height: obstacle.height,
          speed: obstacle.speed,
        ),).toList();
        platforms = actualLevel.platforms.map((platform) => Platform(
          x: platform.x,
          y: platform.y,
          width: platform.width,
          height: platform.height,
          speed: platform.speed,
        ),).toList();
        gaps = actualLevel.gaps.map((gap) => Gap(
          x: gap.x,
          y: gap.y,
          width: gap.width,
          height: gap.height,
          speed: gap.speed,
        )).toList();
      }
      checkGap();
      checkPlatform();
      checkCollisions();
    });
  }

  void checkGap() {

    for (var gap in gaps) {

      var playerRect = player.getRect();
      var gapRect = gap.getRect();

      // Prüfen, ob der Spieler über der Plattform ist (nicht Berührung, sondern oberhalb)
      bool isOverGap = playerRect.right > gapRect.left && playerRect.right < gapRect.right;

      if (isOverGap && !enteredGap) {
        player.enterGap(gap);
        enteredGap = true;
        break; // break the loop
      }
      else if (enteredGap && !isOverGap) {
        print("calling the method to leave the gap");
        player.leaveGap();
        enteredGap = false;
      }
    }
  }

  void checkPlatform() {

    for (var platform in platforms) {

      var playerRect = player.getRect();
      var platformRect = platform.getRect();

      // Prüfen, ob der Spieler über der Plattform ist (nicht Berührung, sondern oberhalb)
      bool isOverPlatform = playerRect.bottom <= platformRect.top &&
                            playerRect.right > platformRect.left &&
                            playerRect.left < platformRect.right;
      if (isOverPlatform && !enteredPlatform) {
        player.enterPlatform(platform);
        enteredPlatform = true;
        break; // break the loop
      }
      else if (enteredPlatform && !isOverPlatform) {
        print("calling the method to leave the platform");
        player.leavePlatform();
        enteredPlatform = false;
      }
    }
  }

  void checkCollisions() {
    ///print("checking collisions");
    for (var obstacle in obstacles) {
      print("obstacle x: ${obstacle.x}");
      if (player.getRect().overlaps(obstacle.getRect())) {
        print("obstacle collision detected");
        _handleCollision();
        break; // break the loop
      }
    }
    ///player collides right side of the gap
    for (var gap in gaps) {
      if (player.getRect().right >= gap.getRect().right &&
      player.getRect().left < gap.getRect().right && // Spieler ist noch innerhalb des Gaps auf der linken Seite
      player.getRect().bottom >= gap.getRect().top && // Spieler ist nicht unterhalb des Gaps
      player.getRect().top <= gap.getRect().bottom) {
        print("gap collision detected");
        print("player right: ${player.getRect().right}");
        print ("gap right: ${gap.getRect().right}");
        print("player bottom: ${player.getRect().bottom}");
        print("gap top: ${gap.getRect().top}");
        _handleCollision();
        break; // break the loop
      }
    }
  }

  void _handleCollision() {
  // Beispiel: Zeige eine Nachricht an und setze den Spielzustand zurück
    print("collision detected");
    levelManager.reset();
    widget.parcourState.stopGame();
    widget.gameState.lastUpdateTime = 0.0; // set the time back
    obstacles.clear(); // clear the obstacles
    platforms.clear(); // clear the platforms
    gaps.clear(); // clear the gaps
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Kollision erkannt!"),
        content: Text("Das Spiel wird neu gestartet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}

void _resetGame() {
  setState(() {
    //print("resetting game");
    player = Player(
      x: 200,
      y: 200,
      width: 50,
      height: 50,
      groundLevel: 200,
    );
    widget.gameState.startGameState(); // restart the game
  });
}

  @override
  Widget build(BuildContext context) {
  
    ///print("parcour chart building");
    if (widget.gameState.isGameRunning) {
      double timeNow = widget.gameState.currentTime;
      //print("currentTime: $timeNow" "lastUpdateTime: ${widget.gameState.lastUpdateTime}");  
      double dt = timeNow - widget.gameState.lastUpdateTime;
      widget.gameState.lastUpdateTime = timeNow;
      //print("dt setzen: $dt");
      updateGame(dt);
    }
    return Container(
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: ParcourPainter(player: player, obstacles: obstacles, platforms: platforms, gaps: gaps, color: Theme.of(context).colorScheme.surface),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}


/// A class representing a generic data value.
abstract class DataValue {
  /// The timestamp of the data.
  final int _timestamp;

  /// Returns the minimum value of the data.
  double getMin();

  /// Returns the maximum value of the data.
  double getMax();

  /// Constructs a DataValue object with a timestamp and units.
  DataValue({required int timestamp, required Map<dynamic, dynamic> units})
      : _timestamp = timestamp;
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

class Platform {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  void update(double dt) {
    x -= speed * dt;
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class Gap {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Gap({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  void update(double dt) {
    x -= speed * dt;
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
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
  double jumpHeight;
  bool enteredPlatform = false;
  Platform? platform;
  bool enteredGap = false;
  Gap? gap;

  Player({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isJumping = false,
    this.jumpHeight = 0.0,
    this.gravity = 9.8,
    required this.groundLevel,
  });

  void enterGap(Gap gap) {
    print("player entered gap");
    enteredGap = true;
    this.gap = gap;
  }

  void leaveGap() {
    print("player left gap");
    enteredGap = false;
    gap = null;
  }

  void enterPlatform(Platform platform) {
    print("player entered platform");
    enteredPlatform = true;
    this.platform = platform;
    isJumping = false;
  }

  void leavePlatform() {
    print("player left platform");
    enteredPlatform = false;
    platform = null;
  }

  void sinkdown(double dt, double targetHeight) {

    print("targetHeight: $targetHeight");
    double movement = targetHeight * dt;
    if (y + movement < targetHeight) {
      y += movement; // move player back towards the ground
    }
    else {
      y = targetHeight;
    }
  }

  void riseUp(double dt) {

    y -= (jumpHeight) * dt; // move player towards target height

    // check if player reached target height
    if (y <= groundLevel - jumpHeight) {
      y = groundLevel - jumpHeight;
      isJumping = false;
    }
  }

  void update(double dt) {

    if (isJumping) {
      
      riseUp(dt);
    } 
    else if (enteredPlatform) {

        print("platform height: ${platform!.y}");
        print("rechnung: ${platform!.y - height}");
        double movement = jumpHeight * dt;
        if (y + movement < platform!.y - height) {
          print("move player back to platform");
          y += movement; // move player back towards the ground
        } 
        else {
          y = platform!.y - height;
          print("auf plattform gelandet");
        }
    }
    else if (enteredGap) {

      if (!isJumping && y < gap!.y) {
        print("move player down in the gap");
        sinkdown(dt, groundLevel + gap!.height);
      }

    }
    else if (y < groundLevel) {
      print("sinkdown");
      sinkdown(dt, groundLevel);
    }
  }

  void jump() {
    print("calling jump");
    if (!isJumping) {
      isJumping = true;
      jumpHeight = 3.5 * height;
      ///print('Jump initiated to height: $targetHeight'); // Debug-Ausgabe der Sprunggeschwindigkeit
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
    ///print("Obstacle updated: x = $x, speed = $speed, dt = $dt"); // Debug-Ausgabe
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class ParcourPainter extends CustomPainter {

  final Player player;
  final List<Obstacle> obstacles;
  final List<Platform> platforms;
  final List<Gap> gaps;
  final Color color;

  ParcourPainter({required this.player, required this.obstacles, required this.platforms, required this.gaps, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 0-Linie zeichnen
    ///print("painting");
    final zeroLinePaint = Paint()..color = Colors.black;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), zeroLinePaint);

    // Zeichne die Fläche unter der 0-Linie grün
    final greenPaint = Paint()..color = Colors.green;
    canvas.drawRect(
      Rect.fromLTRB(0, 250, size.width, size.height),
      greenPaint,
    );

    // vertical scale with 50px steps
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

    // draw obstacles
    final obstaclePaint = Paint()..color = Colors.red;
    for (var obstacle in obstacles) {
      ///print("obstacle x: ${obstacle.x}");
      canvas.drawRect(obstacle.getRect(), obstaclePaint);
    }

    //draw gaps
    final gapPaint = Paint()..color = color;
    for (var gap in gaps) {
      canvas.drawRect(gap.getRect(), gapPaint); 
    }

    //draw platforms
    final platformPaint = Paint()..color = Colors.green;
    for (var platform in platforms) {
      canvas.drawRect(platform.getRect(), platformPaint);
    }

    // draw player
    final playerPaint = Paint()..color = Colors.yellow;
    canvas.drawRect(player.getRect(), playerPaint);

    // horizontal scale on x axis with 50px steps
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
    return true;
  }
}

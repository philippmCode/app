import 'dart:async';

import 'package:flutter/services.dart';
import 'package:open_earable/apps_tab/parcour/parcour_painter.dart';
import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/level.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/parcour.dart';
import 'package:open_earable/apps_tab/parcour/player.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';
import 'package:open_earable/apps_tab/parcour/scenario.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:flutter/material.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'dart:math';
import 'dart:core';
import 'dart:ui' as ui;

/// A class representing the ParcourUI.
class ParcourUI extends StatefulWidget {

  final OpenEarable openEarable;
  final GameState gameState;
  final ParcourState parcourState;

  /// The title of the page.
  final String title;

  /// Constructs a ParcourUI object with a title, openEarable, gameState, and parcourState.
  const ParcourUI(this.parcourState, this.gameState, this.openEarable, this.title, {super.key});

  @override
  State<ParcourUI> createState() => _ParcourUIState();
}

/// A class representing the state of a ParcourUI.
class _ParcourUIState extends State<ParcourUI> {

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

  // the player object
  late Player player;
  late Rect playerRect;

  // the images for all game elements
  late ui.Image playerImage;
  late ui.Image obstacleImage;
  bool pictureLoaded = false;

  // the currently active game elements
  List<Obstacle> obstacles = [];
  List<Platform> platforms = [];
  List<Gap> gaps = [];

  // describe the situation of the player
  bool enteredPlatform = false;
  bool enteredGap = false;
  double progress = 0.0;
  double distanceAtLevelStart = 0.0;

  // the game mechanics
  late LevelManager levelManager;
  double lastUpdateTime = 0.0;
  bool showLevelText = false;
  String levelText = "";


  @override
  void initState() {
    print("init von parcour_chart");
    super.initState();
    double screenWidth = MediaQuery.of(context).size.width; // Breite des Bildschirms
    levelManager = LevelManager(screenWidth: screenWidth);
    _setupListeners();
      player = Player(
        x: 350,
        y: 300,
        width: 50,
        height: 50,
        groundLevel: 300,
    );
    playerRect = player.getRect();
    // load the images
    _loadImage('lib/apps_tab/parcour/assets/Player.jpeg').then((image) {
      playerImage = image;
      pictureLoaded = true;
      print("Player image loaded: ${image.width}x${image.height}");
    });
    _loadImage('lib/apps_tab/parcour/assets/Obstacle.jpg').then((image) {
      obstacleImage = image;
      pictureLoaded = true;
      print("Obstacle image loaded: ${image.width}x${image.height}");
    });

  }

  // load the image from the assets
  Future<ui.Image> _loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), completer.complete);
    return completer.future;
  }
      
  /// Sets up the listeners for the data.
  void _setupListeners() {
    print("setupListeners");
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

      _calculateHeightData(filteredAccData);
      print("wir sind hier fertig");
      setState(() {});
    });
  }

  /// Calculates the height of the jump.
  void _calculateHeightData(XYZValue accValue) {

    print("gehen rein in die height data");
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

    if (_height > 0.1 && player.hasGroundContact()) {
      player.jump();
    }
  }


  @override
  void dispose() {
    super.dispose();
    _dataSubscription?.cancel();
  }


  void updateGame(double dt) {

    if (!widget.gameState.isGameRunning) return; // Verhindere weitere Updates, wenn das Spiel gestoppt wurde
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
        }
      }
      obstacles.removeWhere((obstacle) => obstaclesToRemove.contains(obstacle));

      //update the distance the player has covered
      widget.gameState.distance += (levelManager.getLevelSpeed() / 100) * dt;

      if (obstacles.isEmpty && platforms.isEmpty && gaps.isEmpty) {
        
        Scenario actualScenario = levelManager.getScenario();

        obstacles = actualScenario.obstacles.map((obstacle) => Obstacle(
          x: obstacle.x,
          y: obstacle.y,
          width: obstacle.width,
          height: obstacle.height,
          speed: obstacle.speed,
        ),).toList();
        platforms = actualScenario.platforms.map((platform) => Platform(
          x: platform.x,
          y: platform.y,
          width: platform.width,
          height: platform.height,
          speed: platform.speed,
        ),).toList();
        gaps = actualScenario.gaps.map((gap) => Gap(
          x: gap.x,
          y: gap.y,
          width: gap.width,
          height: gap.height,
          speed: gap.speed,
        ),).toList();

        if (levelManager.getNewLevel()) {
            
            // Zeige den Level-Text an
            distanceAtLevelStart = widget.gameState.distance;
            setState(() {
              showLevelText = true;
              levelText = "Level ${levelManager.levelId + 1 + levelManager.roundtTrips*levelManager.levels.length}";
            });

            // Blende den Level-Text nach 1 Sekunde aus
            Timer(Duration(seconds: 1), () {
              setState(() {
                showLevelText = false;
              });
            });
        }
      }
      setState(() {
        progress = ((levelManager.scenarioId -1) / levelManager.levels[levelManager.levelId].scenarios.length);
      });
      playerRect = player.getRect();
      checkGap();
      checkPlatform();
      checkCollisions();
    });
  }

  // check if the player is over a gap
  void checkGap() {

    for (var gap in gaps) {

      var gapRect = gap.getRect();

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

  // check if the player is over a platform
  void checkPlatform() {

    for (var platform in platforms) {

      var platformRect = platform.getRect();

      bool isOverPlatform = playerRect.bottom <= platformRect.top &&
                            playerRect.right > platformRect.left &&
                            playerRect.left < platformRect.right;
      if (isOverPlatform && !enteredPlatform) {
        print("player is over platform");
        player.enterPlatform(platform);
        enteredPlatform = true;
        break; // break the loop
      }
      else if (enteredPlatform && !isOverPlatform && platform == player.platform) {
        print("calling the method to leave the platform");
        player.leavePlatform();
        enteredPlatform = false;
      }
    }
  }

  // check if the player collides with an obstacle or the right side of a gap
  void checkCollisions() {

    for (var obstacle in obstacles) {

      if (player.getRect().overlaps(obstacle.getRect())) {
        print("obstacle collision detected");
        _handleCollision();
        break; // break the loop
      }
    }
    ///player collides right side of the gap
    for (var gap in gaps) {
      if (player.getRect().right >= gap.getRect().right &&
      player.getRect().left < gap.getRect().right && // player has not yet entered the gap
      player.getRect().bottom >= gap.getRect().top && // player is at the same height as the gap
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
  
  // handle the collision
  void _handleCollision() {

    print("collision detected");
    levelManager.reset();
    widget.gameState.endGameState();
    widget.gameState.distance = distanceAtLevelStart; // set the distance back
    widget.gameState.lastUpdateTime = 0.0; // set the time back
    obstacles.clear(); // clear the obstacles
    platforms.clear(); // clear the platforms
    gaps.clear(); // clear the gaps
    progress = 0.0; // reset the progress
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Collision detected!"),
        content: Text("Try again!"),
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

// reset the game
void _resetGame() {
  setState(() {
    player = Player(
      x: 350,
      y: 300,
      width: 50,
      height: 50,
      groundLevel: 300,
    );
    widget.gameState.startGameState(); // restart the game
  });
}

  @override
  Widget build(BuildContext context) {
  
    if (widget.gameState.isGameRunning) {
      double timeNow = widget.gameState.currentTime; 
      double dt = timeNow - widget.gameState.lastUpdateTime;
      widget.gameState.lastUpdateTime = timeNow;
      updateGame(dt);
    }
    return pictureLoaded
        ? Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: ParcourPainter(
                    player: player,
                    obstacles: obstacles,
                    platforms: platforms,
                    gaps: gaps,
                    color: Theme.of(context).colorScheme.surface,
                    playerImage: playerImage,
                    obstacleImage: obstacleImage,
                  ),
                  child: Container(),
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
          if (showLevelText) 
            Align(
              alignment: Alignment.topCenter, 
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0), // move text down
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.black54,
                  child: Text(
                    levelText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ): Center(child: CircularProgressIndicator());
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

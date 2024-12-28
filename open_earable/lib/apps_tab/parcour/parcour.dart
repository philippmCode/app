import 'package:flutter/material.dart';
import 'package:open_earable/apps_tab/parcour/parcour_chart.dart';
import 'dart:async';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'dart:math';
import 'package:open_earable/shared/earable_not_connected_warning.dart';

/// A game where you steer the player using the OpenEarable device.
class Parcour extends StatefulWidget {
  /// Instance of OpenEarable device.
  final OpenEarable openEarable;

  /// Constructs a Parcour instance widget with a given OpenEarable device.
  const Parcour(this.openEarable, {super.key});

  /// state for the Parcour widget.
  @override
  State<Parcour> createState() => ParcourState();
}

class GameState {

  late Timer timer;
  bool isGameRunning = false;
  double lastUpdateTime = 0.0;
  double currentTime = 0.0;
  int obstaclesOvercome = 0;
  int highScore = 0;

  void initializeTimer() {
    lastUpdateTime = 0.0;
    currentTime = 0.0;
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      currentTime = timer.tick * 0.016;
    });
    //print("lastUpdateTime: $lastUpdateTime");
    //print("Game State Time: $currentTime");
  }

  void startGameState() {
    //print("starten das Game");
    isGameRunning = true;
  }

  double getCurrentTime() {
    return DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  void stopGameState() {
    if (obstaclesOvercome > highScore) {
      highScore = obstaclesOvercome;
    }
    obstaclesOvercome = 0;
    isGameRunning = false;
    timer.cancel();
  }
}

/// State class for Parcour widget.
class ParcourState extends State<Parcour>
    with SingleTickerProviderStateMixin {
  /// Manages the game state.
  final GameState gameState = GameState();

  /// Current height calculated from sensor data.
  double _currentHeight = 0.0;

  // if the game has started and is active
  bool _gameActive = false;

  /// Flag to check if an OpenEarable device is connected.
  bool _earableConnected = false;

  /// Subscription to IMU sensor data.
  StreamSubscription? _imuSubscription;

  /// Stores the maximum height achieved in a jump.
  double _maxHeight = 0.0; // Variable to keep track of maximum jump height
  /// Error measure for Kalman filter.
  final _errorMeasureAcc = 5.0;

  /// Kalman filters for accelerometer data.
  late SimpleKalman _kalmanX, _kalmanY, _kalmanZ;

  /// Current velocity calculated from acceleration.
  double _velocity = 0.0;

  /// Sampling rate time slice (inverse of frequency).
  final double _timeSlice = 1 / 30.0;

  /// Standard gravity in m/s^2.
  final double _gravity = 9.81;

  /// X-axis acceleration.
  double _accX = 0.0;

  /// Y-axis acceleration.
  double _accY = 0.0;

  /// Z-axis acceleration.
  double _accZ = 0.0;

  /// Pitch angle in radians.
  double _pitch = 0.0;

  /// Manages the [TabBar].
  late TabController _tabController;

  /// Initializes state and sets up listeners for sensor data.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    // Set up listeners for sensor data.
    if (widget.openEarable.bleManager.connected) {
      // Set sampling rate to maximum.
      widget.openEarable.sensorManager.writeSensorConfig(_buildSensorConfig());
      // Initialize Kalman filters.
      _initializeKalmanFilters();
      _setupListeners();
      _earableConnected = true;
    }
  }

  /// Disposes IMU data subscription when the state object is removed.
  @override
  void dispose() {
    super.dispose();
    _imuSubscription?.cancel();
  }

  /// Sets up listeners to receive sensor data from the OpenEarable device.
  void _setupListeners() {
    ///print("Setting up listeners");
    _imuSubscription = widget.openEarable.sensorManager
        .subscribeToSensorData(0)
        .listen((data) {
      // Only process sensor data if the game is ongoing.
      if (!_gameActive) {
        return;
      }
      setState(() {
      });
      ///print("calling to process Sensor Data");
      _processSensorData(data);
    });
  }

  /// Starts the jump height measurement process.
  /// It sets the sampling rate, initializes or resets variables, and begins listening to sensor data.
  void _startGame() {
    print("Starting game");

    gameState.initializeTimer();
    gameState.startGameState();

    setState(() {
      // Clear data from previous jump.
      _gameActive = true;
      _currentHeight = 0.0;
      _velocity = 0.0;
    });
  }

  /// Ends the game
  void stopGame() {
    print("Stopping game");
    if (_gameActive) {
      gameState.stopGameState();
      setState(() {
        _gameActive = false;
        gameState.stopGameState();
      });
    }
  }

  /// Initializes Kalman filters for accelerometer data.
  void _initializeKalmanFilters() {
    ///print("Initializing Kalman filters");
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
  }

  /// Processes incoming sensor data and updates jump height.
  void _processSensorData(Map<String, dynamic> data) {
    ///print("Processing sensor data");
    /// Kalman filtered accelerometer data for X.
    _accX = _kalmanX.filtered(data["ACC"]["X"]);

    /// Kalman filtered accelerometer data for Y.
    _accY = _kalmanY.filtered(data["ACC"]["Y"]);

    /// Kalman filtered accelerometer data for Z.
    _accZ = _kalmanZ.filtered(data["ACC"]["Z"]);

    /// Pitch angle in radians.
    _pitch = data["EULER"]["PITCH"];

    // current vertical acceleration.
    // It adjusts the Z-axis acceleration with the pitch angle to account for the device's orientation.
    double currentAcc = _accZ * cos(_pitch) + _accX * sin(_pitch);
    // Subtract gravity to get acceleration due to movement.
    currentAcc -= _gravity;

    _updateHeight(currentAcc);
  }

  /// Checks if the device is stationary based on acceleration magnitude.
  bool _deviceIsStationary(double threshold) {
    double accMagnitude = sqrt(_accX * _accX + _accY * _accY + _accZ * _accZ);
    bool isStationary = (accMagnitude > _gravity - threshold) &&
        (accMagnitude < _gravity + threshold);
    return isStationary;
  }

  /// Updates the current height based on the current acceleration.
  /// If the device is stationary, the velocity is reset to 0.
  /// Otherwise, it integrates the current acceleration to update velocity and height.
  void _updateHeight(double currentAcc) {
    ///print("Updating height");
    if (_deviceIsStationary(0.3)) {
      _velocity = 0.0;
      _currentHeight = 0.0;
    } else {
      // Integrate acceleration to get velocity.
      _velocity += currentAcc * _timeSlice;

      // Integrate velocity to get height.
      _currentHeight += _velocity * _timeSlice;
    }

    // Prevent height from going negative.
    _currentHeight = max(0, _currentHeight);

    // Update maximum height if the current height is greater.
    if (_currentHeight > _maxHeight) {
      _maxHeight = _currentHeight;
    }
  }

  /// Builds the UI for the Parcour game.
  @override
  Widget build(BuildContext context) {
    ///print("wir builden in parcour.dart");
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Parcour'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            // Color of the underline indicator
            indicatorColor: Colors.white,
            // Color of the active tab label
            labelColor: Colors.white,
            // Color of the inactive tab labels
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Parcour'),
              Tab(text: 'Height'),
            ],
          ),
        Expanded(
          child: (!widget.openEarable.bleManager.connected)
              ? EarableNotConnectedWarning()
              : _buildParcourDataTabs(),
        ),
          SizedBox(height: 20), // Margin between chart and button
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildButtons(),
        ),
          Visibility(
            // Show error message if no OpenEarable device is connected.
            visible: !_earableConnected,
            maintainState: true,
            maintainAnimation: true,
            child: Text(
              "No Earable Connected",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 20), // Margin between button and text
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildText(),
          ),
          SizedBox(height: 60), // Margin between button and text
        ],
      ),
    );
  }

  Widget _buildParcourDataTabs() {
    return TabBarView(
      controller: _tabController,
      children: [
        ParcourChart(this, gameState, widget.openEarable, "Parcour"),
        ParcourChart(this, gameState, widget.openEarable, "Height Data"),
      ],
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        Text(
          'Obstacles overcome: ${gameState.obstaclesOvercome}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Current High Score: ${gameState.highScore}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  /// Builds buttons to start and stop the jump height measurement process.
  Widget _buildButtons() {
    return ElevatedButton(
        onPressed: _earableConnected
            ? () {
                _gameActive ? stopGame() : _startGame();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: !_gameActive ? Colors.greenAccent : Colors.red,
          foregroundColor: Colors.black,
        ),
        child: Text(_gameActive ? 'Stop Jump' : 'Set Baseline & Start Game'),
      );
  }

  /// Builds a sensor configuration for the OpenEarable device.
  /// Sets the sensor ID, sampling rate, and latency.
  OpenEarableSensorConfig _buildSensorConfig() {
    return OpenEarableSensorConfig(
      sensorId: 0,
      samplingRate: 30,
      latency: 0,
    );
  }
}
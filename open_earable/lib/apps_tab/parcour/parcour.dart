import 'package:flutter/material.dart';
import 'package:open_earable/apps_tab/parcour/parcour_chart.dart';
import 'dart:async';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'dart:math';
import 'package:open_earable/shared/earable_not_connected_warning.dart';

/// An app that lets you test your jump height using an OpenEarable device.
class Parcour extends StatefulWidget {
  /// Instance of OpenEarable device.
  final OpenEarable openEarable;

  /// Constructs a JumpHeightTest widget with a given OpenEarable device.
  const Parcour(this.openEarable, {super.key});

  /// Creates a state for JumpHeightTest widget.
  @override
  State<Parcour> createState() => _ParcourState();
}

class GameState {

  late Timer timer;
  bool isGameRunning = false;
  double lastUpdateTime = 0.0;
  double currentTime = 0.0;
  int obstaclesOvercome = 0;

  void initializeTimer() {
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      currentTime = timer.tick * 0.016;
    });
    print("lastUpdateTime: $lastUpdateTime");
    print("Game State Time: $currentTime");
  }

  void startGame() {
    print("starten das Game");
    isGameRunning = true;
    print("lastUpdateTime: $lastUpdateTime");
    print("Game State Timer: $timer");
  }

  void stopGame() {
    isGameRunning = false;
    timer.cancel();
  }
}

/// State class for JumpHeightTest widget.
class _ParcourState extends State<Parcour>
    with SingleTickerProviderStateMixin {
  /// Manages the game state.
  final GameState gameState = GameState();



  /// Current height calculated from sensor data.
  double _height = 0.0;

  // List to store each jump's data.
  final List<Jump> _jumpData = [];

  // Flag to indicate if jump measurement is ongoing.
  bool _isJumping = false;

  /// Flag to indicate if an OpenEarable device is connected.
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
      // Only process sensor data if jump measurement is ongoing.
      if (!_isJumping) {
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
  void _startJump() {
    print("Starting jump");
    gameState.initializeTimer();
    gameState.startGame();

    setState(() {
      // Clear data from previous jump.
      _jumpData.clear();
      _isJumping = true;
      _height = 0.0;
      _velocity = 0.0;
      // Reset max height on starting a new jump
      _maxHeight = 0.0;
    });
  }

  /// Stops the jump height measurement process.
  void _stopJump() {
    if (_isJumping) {
      setState(() {
        _isJumping = false;
        gameState.stopGame();
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
    // Calculates the current vertical acceleration.
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
      _height = 0.0;
    } else {
      // Integrate acceleration to get velocity.
      _velocity += currentAcc * _timeSlice;

      // Integrate velocity to get height.
      _height += _velocity * _timeSlice;
    }

    // Prevent height from going negative.
    _height = max(0, _height);

    // Update maximum height if the current height is greater.
    if (_height > _maxHeight) {
      _maxHeight = _height;
    }

    setState(() {
      _jumpData.add(Jump(DateTime.now(), _height));
    });
  }


  /// Builds the UI for the Parcour game.
  /// It displays a line chart of jump height over time and the maximum jump height achieved.
  // This build function is getting a little too big. Consider refactoring.
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
                : _buildJumpHeightDataTabs(),
          ),
          SizedBox(height: 20), // Margin between chart and button
          _buildButtons(),
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
          _buildText(),
        ],
      ),
    );
  }

  Widget _buildJumpHeightDataTabs() {
    return TabBarView(
      controller: _tabController,
      children: [
        ParcourChart(gameState, widget.openEarable, "Parcour"),
        ParcourChart(gameState, widget.openEarable, "Height Data"),
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
      ],
    );
  }

  /// Builds buttons to start and stop the jump height measurement process.
  Widget _buildButtons() {
    return Flexible(
      child: ElevatedButton(
        onPressed: _earableConnected
            ? () {
                _isJumping ? _stopJump() : _startJump();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: !_isJumping ? Colors.greenAccent : Colors.red,
          foregroundColor: Colors.black,
        ),
        child: Text(_isJumping ? 'Stop Jump' : 'Set Baseline & Start Game'),
      ),
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

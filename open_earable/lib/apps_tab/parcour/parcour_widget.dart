// FILE: lib/apps_tab/parcour/parcour_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';

class Player {
  double x;
  double y;
  double width;
  double height;
  bool isJumping;
  double jumpVelocity;
  double gravity;
  double groundLevel;

  Player({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isJumping = false,
    this.jumpVelocity = 0.0,
    this.gravity = 9.8,
    required this.groundLevel,
  });

  void update(double dt) {
    if (isJumping) {
      y -= jumpVelocity * dt;
      jumpVelocity -= gravity * dt;
      if (y >= groundLevel) {
        y = groundLevel;
        isJumping = false;
        jumpVelocity = 0.0;
      }
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      jumpVelocity = 2 * height * gravity; // Sprunghöhe basierend auf der Höhe des Spielers
      print('Jump initiated with velocity: $jumpVelocity'); // Debug-Ausgabe der Sprunggeschwindigkeit
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
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class ParcourWidget extends StatefulWidget {
  @override
  _ParcourWidgetState createState() => _ParcourWidgetState();
}

class _ParcourWidgetState extends State<ParcourWidget> {
  late Player player;
  List<Obstacle> obstacles = [];
  late Timer timer;
  double lastUpdateTime = 0.0;

  @override
  void initState() {
    super.initState();
    player = Player(
      x: 50,
      y: 300,
      width: 50,
      height: 50,
      groundLevel: 300,
    );
    timer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      double currentTime = timer.tick * 0.016;
      double dt = currentTime - lastUpdateTime;
      lastUpdateTime = currentTime;
      updateGame(dt);
    });
  }

  void updateGame(double dt) {
    setState(() {
      player.update(dt);
      for (var obstacle in obstacles) {
        obstacle.update(dt);
      }
      obstacles.removeWhere((obstacle) => obstacle.x < -obstacle.width);
      if (obstacles.isEmpty || obstacles.last.x < 200) {
        obstacles.add(Obstacle(
          x: MediaQuery.of(context).size.width,
          y: 300,
          width: 50,
          height: 50,
        ));
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
    return GestureDetector(
      onTap: () {
        player.jump();
      },
      child: CustomPaint(
        painter: GamePainter(player: player, obstacles: obstacles),
        child: Container(),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final Player player;
  final List<Obstacle> obstacles;

  GamePainter({required this.player, required this.obstacles});

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund zeichnen (Debug-Test)
    final backgroundPaint = Paint()..color = Colors.green;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
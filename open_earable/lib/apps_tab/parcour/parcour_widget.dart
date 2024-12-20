// FILE: lib/apps_tab/parcour/parcour_widget.dart
import 'package:flutter/material.dart';
import 'dart:async';

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
      print('Current height: $y'); // Debug-Ausgabe der aktuellen Höhe
    } else {
      if (y < groundLevel) {
        y += (targetHeight) * dt; // Bewege den Spieler zurück zum Boden
        if (y > groundLevel) {
          y = groundLevel;
        }
      }
    }
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
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

class ParcourWidget extends StatefulWidget {
  const ParcourWidget({super.key});

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


    // 0-Linie zeichnen
    final zeroLinePaint = Paint()..color = Colors.black;
    canvas.drawLine(Offset(0, player.groundLevel), Offset(size.width, player.groundLevel), zeroLinePaint);

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
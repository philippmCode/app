import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/player.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';

// CustomPainter for the Parcour game
class ParcourPainter extends CustomPainter {

  final Player player;
  final List<Obstacle> obstacles;
  final List<Platform> platforms;
  final List<Gap> gaps;
  final Color color;
  final ui.Image playerImage;
  final ui.Image obstacleImage;
  final ui.Image backgroundImage;
  double backgroundOffset = 0;

  ParcourPainter({
    required this.player,
    required this.obstacles,
    required this.platforms,
    required this.gaps,
    required this.color,
    required this.playerImage,
    required this.obstacleImage,
    required this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {

    print("painting");

    final double backgroundHeight = 350;
    final double backgroundWidth = size.width;
    final backgroundRect = Rect.fromLTWH(0, 0, backgroundWidth, backgroundHeight);
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
      backgroundRect,
      Paint(),
    );

    // Zeichne die Fläche unter der 0-Linie grün
    final greenPaint = Paint()..color = Colors.green;
    canvas.drawRect(
      Rect.fromLTRB(0, 350, size.width, size.height),
      greenPaint,
    );

    // draw obstacles
    for (var obstacle in obstacles) {
      final obstacleRect = obstacle.getRect();
      canvas.drawImageRect(
        obstacleImage,
        Rect.fromLTWH(0, 0, obstacleImage.width.toDouble(), obstacleImage.height.toDouble()),
        obstacleRect,
        Paint(),
      );
    }

    //draw gaps
    final gapPaint = Paint()..color = Colors.white;
    for (var gap in gaps) {
      canvas.drawRect(gap.getRect(), gapPaint); 
    }

    //draw platforms
    final platformPaint = Paint()..color = Colors.green;
    for (var platform in platforms) {
      canvas.drawRect(platform.getRect(), platformPaint);
    }

    // Spieler zeichnen
    final playerRect = player.getRect();
    canvas.drawImageRect(
      playerImage,
      Rect.fromLTWH(0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
      playerRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

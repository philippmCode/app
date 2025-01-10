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
  final ui.Image groundImage;
  final ui.Image gapImage;
  final ui.Image platformImage;
  final double backgroundOffset;

  ParcourPainter({
    required this.player,
    required this.obstacles,
    required this.platforms,
    required this.gaps,
    required this.color,
    required this.playerImage,
    required this.obstacleImage,
    required this.backgroundImage,
    required this.groundImage,
    required this.gapImage,
    required this.platformImage,
    required this.backgroundOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {

    final double backgroundHeight = 351;
    final double backgroundWidth = size.width;
    final backgroundRect = Rect.fromLTWH(backgroundOffset, 0, backgroundWidth, backgroundHeight);
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
      backgroundRect,
      Paint(),
    );

    // draw second background image
    final backgroundRect2 = Rect.fromLTWH(backgroundOffset + backgroundWidth, 0, backgroundWidth, backgroundHeight);
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
      backgroundRect2,
      Paint(),
    );

    final double groundHeight = size.height - 345;
    final groundRect = Rect.fromLTWH(backgroundOffset, 350, backgroundWidth, groundHeight);
    canvas.drawImageRect(
      groundImage,
      Rect.fromLTWH(0, 0, groundImage.width.toDouble(), groundImage.height.toDouble()),
      groundRect,
      Paint(),
    );

    // draw second ground image
    final groundRect2 = Rect.fromLTWH(backgroundOffset + backgroundWidth, 350, backgroundWidth, groundHeight);
    canvas.drawImageRect(
      groundImage,
      Rect.fromLTWH(0, 0, groundImage.width.toDouble(), groundImage.height.toDouble()),
      groundRect2,
      Paint(),
    );

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTRB(0, 400, size.width, size.height),
      whitePaint,
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
    for (var gap in gaps) {
      final gapRect = gap.getRect();
      canvas.drawImageRect(
        gapImage,
        Rect.fromLTWH(0, 0, gapImage.width.toDouble(), gapImage.height.toDouble()),
        gapRect,
        Paint(),
      );
    }

    //draw platforms
    for (var platform in platforms) {
      final platformRect = platform.getRect();
      canvas.drawImageRect(
        platformImage,
        Rect.fromLTWH(0, 0, platformImage.width.toDouble(), platformImage.height.toDouble()),
        platformRect,
        Paint(),
      );
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

  bool backgroundReachedEnd() {
    return backgroundOffset <= -backgroundImage.width;
  }
}

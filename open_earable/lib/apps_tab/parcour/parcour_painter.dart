import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/player.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';

class ParcourPainter extends CustomPainter {

  final Player player;
  final List<Obstacle> obstacles;
  final List<Platform> platforms;
  final List<Gap> gaps;
  final Color color;
  final ui.Image playerImage;

  ParcourPainter({
    required this.player,
    required this.obstacles,
    required this.platforms,
    required this.gaps,
    required this.color,
    required this.playerImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 0-Linie zeichnen
    print("painting");
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

    // Spieler zeichnen
    final playerRect = player.getRect();
    canvas.drawImageRect(
      playerImage,
      Rect.fromLTWH(0, 0, playerImage.width.toDouble(), playerImage.height.toDouble()),
      playerRect,
      Paint(),
    );

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



import 'package:flutter/material.dart';
import 'package:open_earable/apps_tab/parcour/parcour_chart.dart';

class Level {
  final String name;
  final int length;
  final List<Obstacle> obstacles;
  final double screenWidth;
  Level({required this.name, required this.length, required this.obstacles, required this.screenWidth});
}

List<Level> predefinedLevels(BuildContext context) => [
  Level(
    name: 'Level 1',
    length: 2000,
    obstacles: [
      Obstacle(
          x: MediaQuery.of(context).size.width, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
        ),
      Obstacle(
          x: MediaQuery.of(context).size.width + 10, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
    // screenWidth is now set in the constructor
      ),
    ],
    screenWidth: MediaQuery.of(context).size.width,
  ),
  Level(
    name: 'Level 2',
    length: 3000,
    obstacles: [
      Obstacle(
          x: MediaQuery.of(context).size.width, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
        ),
      Obstacle(
          x: MediaQuery.of(context).size.width, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
      ),
    ],
    screenWidth: MediaQuery.of(context).size.width,
  ),
];

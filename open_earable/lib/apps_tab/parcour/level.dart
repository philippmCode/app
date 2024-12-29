import 'package:open_earable/apps_tab/parcour/parcour_chart.dart';

class LevelManager {

  List<Level> levels = [];
  final double screenWidth;

  LevelManager({
    required this.screenWidth,
  }) {
    // Rufe die Methode auf, um Hindernisse zu initialisieren
    fillLevels();
  }

  Level getLevel(int levelId) {
    return levels[levelId];
  }

  void fillLevels() {
    levels = predefinedLevels(screenWidth);
  }
}

class Level {
  final String name;
  final int length;
  final List<Obstacle> obstacles;
  final double screenWidth;
  Level({required this.name, required this.length, required this.obstacles, required this.screenWidth});
}

List<Level> predefinedLevels(double screenWidth) => [

  Level(
    name: 'Level 1',
    length: 2000,
    obstacles: [
      Obstacle(
          x: screenWidth, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
        ),
      Obstacle(
          x: screenWidth + 100,
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
      ),
    ],
    screenWidth: screenWidth,
  ),
  Level(
    name: 'Level 2',
    length: 3000,
    obstacles: [
      Obstacle(
          x: screenWidth, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
        ),
      Obstacle(
          x: screenWidth, // Setze die x-Position auf die Breite des Bildschirms
          y: 200,
          width: 50,
          height: 50,
          speed: 300,
      ),
    ],
    screenWidth: screenWidth,
  ),
];

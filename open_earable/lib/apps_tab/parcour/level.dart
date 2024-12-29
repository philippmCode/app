import 'package:open_earable/apps_tab/parcour/parcour_chart.dart';

class LevelManager {

  List<Level> levels = [];
  final double screenWidth;
  int levelId = 0;

  LevelManager({
    required this.screenWidth,
  }) {
    // Rufe die Methode auf, um Hindernisse zu initialisieren
    fillLevels();
  }

  Level getLevel() {
    print("levelId: $levelId");
    if (levelId >= levels.length) {
      levelId = 0;
    }
    return levels[levelId++];
  }

  void fillLevels() {
    levels = _predefinedLevels(screenWidth);
  }

  void reset() {
    levelId = 0;
  }
}

class Level {
  final String name;
  final int length;
  final List<Obstacle> obstacles;
  final List<Platform> platforms;
  final List<Gap> gaps;
  final double screenWidth;
  Level({required this.name, required this.length, required this.obstacles, required this.platforms, required this.gaps, required this.screenWidth});
}

List<Level> _predefinedLevels(double screenWidth) => [

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
    platforms: [],
    gaps: [],
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
    ],
    platforms: [],
    gaps: [],
    screenWidth: screenWidth,
  ),
    Level(
    name: 'Level 3',
    length: 3000,
    obstacles: [],
    platforms: [],
    gaps: [
      Gap(x: screenWidth, y: 250, width: 400, height: 50, speed: 300),
    ],
    screenWidth: screenWidth,
  ),
      Level(
    name: 'Level 3',
    length: 3000,
    obstacles: [],
    platforms: [
      Platform(x: screenWidth, y: 100, width: 300, height: 25, speed: 300),
    ],
    gaps: [],
    screenWidth: screenWidth,
  ),
];

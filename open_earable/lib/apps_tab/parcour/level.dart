import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';
import 'package:open_earable/apps_tab/parcour/scenario.dart';

class LevelManager {

  List<Level> levels = [];
  final double screenWidth;
  int levelId = 0;
  int scenarioId = 0;
  bool newLevel = false;

  LevelManager({
    required this.screenWidth,
  }) {
    // Rufe die Methode auf, um Hindernisse zu initialisieren
    fillList();
  }

  Scenario getScenario() {
    
    if (scenarioId >= levels[levelId].scenarios.length) {
      levelId++;
      newLevel = true;
      
      if (levelId >= levels.length) {
        levelId = 0;
      }
      scenarioId = 0;
    }
    else if (scenarioId == 0) {
      newLevel = true;
    }
    else {
      newLevel = false;
    }
    print("Level: $levelId, Scenario: $scenarioId");
    return levels[levelId].scenarios[scenarioId++];
  }

  bool getNewLevel() {
    return newLevel;
  }

  void fillList() {
    levels = _predefinedLevels(screenWidth);
  }

  int getLevelSpeed() {
    return levels[levelId].speed;
  }

  void reset() {
    // so that the player restarts in his actual level
    scenarioId = 0;
  }
}

class Level {
  final int id;
  final List<Scenario> scenarios;
  final int speed;

  Level({
    required this.id,
    required this.scenarios,
    required this.speed,
  });
}

List<Level> _predefinedLevels(double screenWidth) => [
  Level(
    id: 1,
    scenarios: [_predefinedScenarios(screenWidth)[0], _predefinedScenarios(screenWidth)[1]],
    speed: 300,
  ),
  Level(
    id: 2,
    scenarios: [_predefinedScenarios(screenWidth)[2], _predefinedScenarios(screenWidth)[3]],
    speed: 300,
    ),
];

List<Scenario> _predefinedScenarios(double screenWidth) => [

  Scenario(
    name: 'Two close obstacles',
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
  Scenario(
    name: 'Single Obstacle',
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
  Scenario(
    name: 'Singe gap',
    length: 3000,
    obstacles: [],
    platforms: [],
    gaps: [
      Gap(x: screenWidth, y: 250, width: 400, height: 50, speed: 300),
  ],
  screenWidth: screenWidth,
  ),
  Scenario(
    name: 'Single platform',
    length: 3000,
    obstacles: [],
    platforms: [
      Platform(x: screenWidth, y: 100, width: 300, height: 25, speed: 300),
  ],
  gaps: [],
  screenWidth: screenWidth,
  ),
];

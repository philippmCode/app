import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';
import 'package:open_earable/apps_tab/parcour/scenario.dart';

// manages which level and scenario is currently active
class LevelManager {

  List<Level> levels = [];
  final double screenWidth;
  int levelId = 0;
  int roundtTrips = 0;
  int scenarioId = 0;
  bool newLevel = false;

  LevelManager({
    // the game elements are spwaned directly next to the screen
    required this.screenWidth,
  }) {
    // fill the list with predefined levels
    fillList();
  }

  Scenario getScenario() {
    
    // if the scenarioId is bigger than the number of scenarios in the level, the level is finished
    if (scenarioId >= levels[levelId].scenarios.length) {
      levelId++;
      newLevel = true;
      
      // continuous loop through the levels
      if (levelId >= levels.length) {
        levelId = 0;
        roundtTrips++;
      }
      scenarioId = 0;
    }
    else if (scenarioId == 0) {
      newLevel = true;
    }
    else {
      newLevel = false;
    }
    return levels[levelId].scenarios[scenarioId++];
  }

  // if a new level was started
  bool getNewLevel() {
    return newLevel;
  }

  // fill the list with predefined levels
  void fillList() {
    levels = _predefinedLevels(screenWidth);
  }

  // the speed for all scenarios in the level used then to calculate the distance the player has covered
  int getLevelSpeed() {
    return levels[levelId].speed;
  }

  void reset() {
    // so that the player restarts in his actual level
    scenarioId = 0;
  }
}

// Class representing a level in the game
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

// returns a list of predefined levels
List<Level> _predefinedLevels(double screenWidth) => [
  Level(
    id: 0,
    scenarios: [_predefinedScenarios(screenWidth)[0], _predefinedScenarios(screenWidth)[1]],
    speed: 300,
  ),
  Level(
    id: 1,
    scenarios: [_predefinedScenarios(screenWidth)[2], _predefinedScenarios(screenWidth)[3]],
    speed: 300,
  ),
  Level(
    id: 2,
    scenarios: [_predefinedScenarios(screenWidth)[4], _predefinedScenarios(screenWidth)[5]],
    speed: 300,
  ),
  Level(
    id: 2,
    scenarios: [_predefinedScenarios(screenWidth)[6]],
    speed: 300,
  ),
];

// returns a list of predefined scenarios
List<Scenario> _predefinedScenarios(double screenWidth) => [

  Scenario(
    name: 'Two close obstacles',
    length: 2000,
    obstacles: [
      Obstacle(
          x: screenWidth,
          y: 300,
          width: 50,
          height: 50,
          speed: 300,
        ),
      Obstacle(
          x: screenWidth + 100,
          y: 300,
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
          x: screenWidth,
          y: 300,
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
    name: 'Single gap',
    length: 3000,
    obstacles: [],
    platforms: [],
    gaps: [
      Gap(x: screenWidth, y: 350, width: 400, height: 50, speed: 300),
  ],
  screenWidth: screenWidth,
  ),
  Scenario(
    name: 'Single platform',
    length: 3000,
    obstacles: [],
    platforms: [
      Platform(x: screenWidth, y: 200, width: 300, height: 25, speed: 300),
  ],
  gaps: [],
  screenWidth: screenWidth,
  ),
  Scenario(
  name: 'Obstacles between platforms 300',
  length: 3000,
  obstacles: [   
      Obstacle(
      x: screenWidth, 
      y: 300,
      width: 50,
      height: 50,
      speed: 300,
    ),   
    Obstacle(
        x: screenWidth + 250, 
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),
            Obstacle(
        x: screenWidth + 350, 
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),
      Obstacle(
        x: screenWidth + 450,
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),],
  platforms: [
    Platform(x: screenWidth, y: 200, width: 300, height: 25, speed: 300),
    Platform(x: screenWidth + 450, y: 200, width: 300, height: 25, speed: 300),
  ],
  gaps: [],
  screenWidth: screenWidth,
  ),
  Scenario(
    name: 'Obstacle after Gap',
    length: 3000,
    obstacles: [      
      Obstacle(
        x: screenWidth + 400,
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),],
    platforms: [],
    gaps: [
      Gap(x: screenWidth, y: 350, width: 400, height: 50, speed: 300),
  ],
  screenWidth: screenWidth,
  ),
  Scenario(
    name: 'Obstacles surrouding Gap',
    length: 3000,
    obstacles: [      
      Obstacle(
        x: screenWidth,
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),
      Obstacle(
        x: screenWidth + 550,
        y: 300,
        width: 50,
        height: 50,
        speed: 300,
      ),],
    platforms: [],
    gaps: [
      Gap(x: screenWidth + 50, y: 350, width: 500, height: 50, speed: 300),
  ],
  screenWidth: screenWidth,
  ),
];

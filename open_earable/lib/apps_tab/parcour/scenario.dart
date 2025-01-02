import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/obstacle.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';

class Scenario {
  final String name;
  final int length;
  final List<Obstacle> obstacles;
  final List<Platform> platforms;
  final List<Gap> gaps;
  final double screenWidth;
  Scenario({required this.name, required this.length, required this.obstacles, required this.platforms, required this.gaps, required this.screenWidth});
}

List<Scenario> _predefinedScenarios(double screenWidth) => [

  Scenario(
    name: 'Scenario 1',
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
    name: 'Scenario 2',
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
    name: 'Scenario 3',
    length: 3000,
    obstacles: [],
    platforms: [],
    gaps: [
      Gap(x: screenWidth, y: 250, width: 400, height: 50, speed: 300),
  ],
  screenWidth: screenWidth,
  ),
  Scenario(
    name: 'Scenario 4',
    length: 3000,
    obstacles: [],
    platforms: [
      Platform(x: screenWidth, y: 100, width: 300, height: 25, speed: 300),
  ],
  gaps: [],
  screenWidth: screenWidth,
  ),
];

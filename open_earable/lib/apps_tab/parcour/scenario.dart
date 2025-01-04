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

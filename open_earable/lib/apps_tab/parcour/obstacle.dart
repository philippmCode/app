import 'dart:ui';

class Obstacle {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.speed = 200.0,
  });

  void update(double dt) {
    x -= speed * dt;
    ///print("Obstacle updated: x = $x, speed = $speed, dt = $dt"); // Debug-Ausgabe
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

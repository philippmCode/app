import 'dart:ui';

// Class representing a platform in the game
class Platform {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  void update(double dt) {
    x -= speed * dt;
  }

  // returns the rectangle of the platform
  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

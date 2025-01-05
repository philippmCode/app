import 'dart:ui';

/// Class representing an obstacle in the game
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

  // moves the obstacle to the left
  void update(double dt) {
    x -= speed * dt;
  }

  // returns the rectangle of the obstacle used for collision detection
  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

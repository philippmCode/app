import 'dart:ui';

// Class representing a gap in the game
class Gap {
  double x;
  double y;
  double width;
  double height;
  double speed;

  Gap({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });

  // moves the gap to the left
  void update(double dt) {
    x -= speed * dt;
  }

  // returns the rectangle of the gap used for collision detection
  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

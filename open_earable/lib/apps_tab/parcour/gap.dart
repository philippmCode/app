import 'dart:ui';

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

  void update(double dt) {
    x -= speed * dt;
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

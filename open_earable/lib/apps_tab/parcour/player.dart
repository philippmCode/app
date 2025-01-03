import 'dart:ui';

import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';

class Player {
  double x;
  double y;
  double width;
  double height;
  bool isJumping;
  double gravity;
  double groundLevel;
  double jumpHeight;
  double startingHeight = 250;
  bool enteredPlatform = false;
  Platform? platform;
  bool enteredGap = false;
  Gap? gap;

  Player({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isJumping = false,
    this.jumpHeight = 0.0,
    this.gravity = 9.8,
    required this.groundLevel,
  });

  void enterGap(Gap gap) {
    print("player entered gap");
    enteredGap = true;
    this.gap = gap;
  }

  void leaveGap() {
    print("player left gap");
    enteredGap = false;
    gap = null;
  }

  void enterPlatform(Platform platform) {
    print("player entered platform");
    enteredPlatform = true;
    this.platform = platform;
    isJumping = false;
  }

  void leavePlatform() {
    print("player left platform");
    enteredPlatform = false;
    platform = null;
  }

  void sinkdown(double dt, double targetHeight) {

    print("targetHeight: $targetHeight");
    double movement = targetHeight * dt;
    if (y + movement < targetHeight) {
      y += movement; // move player back towards the ground
    }
    else {
      y = targetHeight;
    }
  }

  void riseUp(double dt) {

    y -= (jumpHeight) * dt; // move player towards target height

    // check if player reached target height
    if (y <= startingHeight - jumpHeight) {
      y = startingHeight - jumpHeight;
      isJumping = false;
    }
  }

  void update(double dt) {

    if (isJumping) {
      
      riseUp(dt);
    } 
    else if (enteredPlatform) {

        print("platform height: ${platform!.y}");
        print("rechnung: ${platform!.y - height}");
        double movement = jumpHeight * dt;
        if (y + movement < platform!.y - height) {
          print("move player back to platform");
          y += movement; // move player back towards the ground
        } 
        else {
          y = platform!.y - height;
          print("auf plattform gelandet");
        }
    }
    else if (enteredGap) {

      if (!isJumping && y < gap!.y) {
        print("move player down in the gap");
        sinkdown(dt, groundLevel + gap!.height);
      }

    }
    else if (y < groundLevel) {
      print("sinkdown");
      sinkdown(dt, groundLevel);
    }
  }

  void jump() {
    print("calling jump");
    if (!isJumping) {
      isJumping = true;
      jumpHeight = 3.5 * height;
      startingHeight = y;
      ///print('Jump initiated to height: $targetHeight'); // Debug-Ausgabe der Sprunggeschwindigkeit
    }
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

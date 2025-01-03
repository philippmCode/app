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
  double startingHeight = 300;
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
    enteredGap = true;
    this.gap = gap;
  }

  void leaveGap() {
    enteredGap = false;
    gap = null;
  }

  void enterPlatform(Platform platform) {
    enteredPlatform = true;
    this.platform = platform;
    isJumping = false;
  }

  void leavePlatform() {
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

    // check if player has jumped as hight as he can
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
      jumpHeight = 3 * height;
      startingHeight = y;
      print("startingHeight: $startingHeight");
      ///print('Jump initiated to height: $targetHeight'); // Debug-Ausgabe der Sprunggeschwindigkeit
    }
  }

  // check if player is in contact with the ground to prevent double jumps
  bool hasGroundContanct() {

    print("enteredGap: $enteredGap, y: $y, groundLevel: $groundLevel, gapHeight: ${gap?.height}");
    print(enteredGap && y == groundLevel + (gap?.height ?? 0));
    if (y == groundLevel || (enteredGap && y == groundLevel + (gap?.height ?? 0)) || enteredPlatform) {
      return true;
    }
    return false;
  }

  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

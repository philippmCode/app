import 'dart:ui';

import 'package:open_earable/apps_tab/parcour/gap.dart';
import 'package:open_earable/apps_tab/parcour/platform.dart';

// Class representing the player in the game
class Player {

  // player position and size
  double x;
  double y;
  double width;
  double height;

  // player movement
  bool isJumping;
  double jumpHeight;

  // environment variables
  double gravity;
  double groundLevel;
  double startingHeight = 300;

  // interaction with game elements
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

  // move player back to the ground after jump
  void sinkdown(double dt, double targetHeight) {

    double movement = targetHeight * dt;
    if (y + movement < targetHeight) {
      y += movement; // move player back towards the ground
    }
    else {
      y = targetHeight;
    }
  }

  // move player up in the air when jumping
  void riseUp(double dt) {

    y -= (jumpHeight) * dt; // move player towards target height

    // check if player has jumped as hight as he can
    if (y <= startingHeight - jumpHeight) {
      y = startingHeight - jumpHeight;
      isJumping = false;
    }
  }

  // update player position
  void update(double dt) {

    if (isJumping) {
      
      riseUp(dt);
    } 
    else if (enteredPlatform) {

        double movement = jumpHeight * dt;
        if (y + movement < platform!.y - height) {
          y += movement; // move player back towards the ground
        } 
        else {
          y = platform!.y - height;
        }
    }
    else if (enteredGap) {

      if (!isJumping && y < gap!.y) {
        sinkdown(dt, groundLevel + gap!.height);
      }

    }
    else if (y < groundLevel) {
      sinkdown(dt, groundLevel);
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      jumpHeight = 3 * height;
      startingHeight = y;
    }
  }

  // check if player is in contact with the ground to prevent double jumps
  bool hasGroundContact() {

    if (y == groundLevel || (enteredGap && y == groundLevel + (gap?.height ?? 0)) || (enteredPlatform && y == (platform?.y ?? 0) - height)) {
      return true;
    }
    return false;
  }

  // returns the rectangle of the player used for collision detection
  Rect getRect() {
    return Rect.fromLTWH(x, y, width, height);
  }
}

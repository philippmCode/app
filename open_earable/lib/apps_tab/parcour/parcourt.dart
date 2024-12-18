import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jump Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JumpGame(),
    );
  }
}

class JumpGame extends StatefulWidget {
  const JumpGame({super.key});

  @override
  _JumpGameState createState() => _JumpGameState();
}

class _JumpGameState extends State<JumpGame> {
  double playerY = 0;
  bool isJumping = false;
  double obstacleX = 1;
  int score = 0;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    gameTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        obstacleX -= 0.05;
        if (obstacleX < -1) {
          obstacleX = 1;
          score++;
        }
        if (isJumping) {
          playerY -= 0.1;
          if (playerY <= -1) {
            isJumping = false;
          }
        } else {
          playerY += 0.1;
          if (playerY >= 0) {
            playerY = 0;
          }
        }
      });
    });
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
    }
  }

  bool checkJump() {
    // Simulate earable input
    return Random().nextBool();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jump Game'),
      ),
      body: GestureDetector(
        onTap: () {
          if (checkJump()) {
            jump();
          }
        },
        child: Stack(
          children: [
            AnimatedContainer(
              alignment: Alignment(0, playerY),
              duration: Duration(milliseconds: 0),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.blue,
              ),
            ),
            AnimatedContainer(
              alignment: Alignment(obstacleX, 1),
              duration: Duration(milliseconds: 0),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.red,
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Score: $score',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
}
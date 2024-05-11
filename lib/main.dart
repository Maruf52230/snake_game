import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/gestures.dart'; // For handling swipe gestures

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  runApp(GameWidget(game: MyGame()));
}

enum Direction { up, down, left, right }

extension DirectionExtension on Direction {
  Vector2 toVector() {
    switch (this) {
      case Direction.up:
        return Vector2(0, -1);
      case Direction.down:
        return Vector2(0, 1);
      case Direction.left:
        return Vector2(-1, 0);
      case Direction.right:
        return Vector2(1, 0);
    }
  }

  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }
}

class Snake extends PositionComponent with HasGameRef<MyGame> {
  List<Vector2> body = [];
  Direction direction = Direction.up;
  double speed = 100; // Adjust speed as needed

  Snake(Vector2 position, Vector2 size) : super(position: position, size: size) {
    body.add(position); // Start with a single segment
  }

  @override
  void render(Canvas c) {
    super.render(c);
    for (final segment in body) {
      c.drawRect(Rect.fromLTWH(segment.x, segment.y, size.x, size.y), Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    move();
    checkCollision();
  }

  void move() {
    body.insert(0, body.first + direction.toVector()); // Add a new segment at the head
    body.removeLast(); // Remove the tail segment
  }

  void checkCollision() {
    // Check for collisions with walls and the snake's body
    if (body.first.x < 0 || body.first.x + size.x > gameRef.size.x ||
        body.first.y < 0 || body.first.y + size.y > gameRef.size.y ||
        body.skip(1).contains(body.first)) {
      gameRef.over(); // Game over
    }
  }
}

class MyGame extends BaseGame with TapDetector {
  late Snake snake;
  late Food food; // Add a class for food

  @override
  Future<void> onLoad() async {
    snake = Snake(Vector2(100, 100), Vector2(20, 20)); // Adjust initial position and size
    add(snake);
    addFood();
  }

  void addFood() {
    food = Food(Vector2(randomDouble(0, size.x - 20), randomDouble(0, size.y - 20)), Vector2(20, 20));
    add(food);
  }

  @override
  void onTapUp(TapUpDetails details) {
    final direction = Direction.values[details.globalPosition.direction];
    if (direction != snake.direction.opposite) {
      snake.direction = direction;
    }
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    final direction = details.primaryDelta!.direction;
    if (direction != snake.direction.opposite) {
      snake.direction = direction;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    snake.update(dt);

    if (snake.body.first == food.position) {
      snake.body.add(snake.body.last); // Grow the snake
      addFood();
      addScore();
    }
  }

  void over() {
    // Handle game over logic (e.g., display a game over message)
    print('Game Over! Your Score: $score');
  }

  int score = 0;

  void addScore() {
    score++;
  }
}

class Food extends PositionComponent {
  Food(Vector2 position, Vector2 size) : super(position: position, size: size);

  @override
  void render(Canvas c) {
    super.render(c);
    c.drawRect(rect, Paint()..color = const Color(0xFF00FF00)); // Green color for food
  }
}

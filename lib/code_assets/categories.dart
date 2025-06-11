import 'package:flutter/material.dart';

class Categories {
  static String todo = "todo";
  static String complete = "complete";
  static String archive = "archive";
  static String message = "message";
  static String promotion = "promotion";
  static String empty = "empty";
}

Map<String, Gradient> categoriesAndGradients = {
  "todo": LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE0E0E0), // light gray
      Color.fromARGB(255, 219, 25, 25), // bluish gradient
    ],
  ),
  "complete": LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE0E0E0), // light gray
      Color.fromARGB(255, 0, 115, 255), // bluish gradient
    ],
  ),
  "archive": LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE0E0E0), // light gray
      Color.fromARGB(255, 0, 255, 64), // bluish gradient
    ],
  ),
  "message": LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE0E0E0), // light gray
      Color.fromARGB(255, 225, 0, 255), // bluish gradient
    ],
  ),
  "promotion": LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE0E0E0), // light gray
      Color.fromARGB(255, 133, 80, 10), // bluish gradient
    ],
  ),
};

List<String> categories = [
  Categories.todo,
  Categories.complete,
  Categories.archive,
  Categories.message,
  Categories.promotion,
];

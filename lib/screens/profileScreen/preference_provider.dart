import 'package:flutter/material.dart';

class PreferenceProvider with ChangeNotifier {
  List<String> likes = [];
  List<String> dislikes = [];

  void toggleLike(String item) {
    if (likes.contains(item)) {
      likes.remove(item);
    } else {
      likes.add(item);
    }
    notifyListeners();
  }

  void toggleDislike(String item) {
    if (dislikes.contains(item)) {
      dislikes.remove(item);
    } else {
      dislikes.add(item);
    }
    notifyListeners();
  }

  bool isLiked(String item) {
    return likes.contains(item);
  }

  bool isDisliked(String item) {
    return dislikes.contains(item);
  }
}

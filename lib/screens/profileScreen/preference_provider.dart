import 'package:flutter/material.dart';

class PreferenceProvider with ChangeNotifier {
  List<String> likes = [];
  List<String> dislikes = [];

  void addLike(String item) {
    if (!likes.contains(item)) {
      likes.add(item);
      notifyListeners();
    }
  }

  void addDislike(String item) {
    if (!dislikes.contains(item)) {
      dislikes.add(item);
      notifyListeners();
    }
  }

  void removeLike(String item) {
    if (likes.contains(item)) {
      likes.remove(item);
      notifyListeners();
    }
  }

  void removeDislike(String item) {
    if (dislikes.contains(item)) {
      dislikes.remove(item);
      notifyListeners();
    }
  }

  void toggleLike(String item) {
    if (likes.contains(item)) {
      removeLike(item);
    } else {
      addLike(item);
    }
  }

  void toggleDislike(String item) {
    if (dislikes.contains(item)) {
      removeDislike(item);
    } else {
      addDislike(item);
    }
  }

  bool isLiked(String item) {
    return likes.contains(item);
  }

  bool isDisliked(String item) {
    return dislikes.contains(item);
  }
}

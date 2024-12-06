import 'package:flutter/material.dart';

class PreferenceProvider with ChangeNotifier {
  List<String> _likes = [];
  List<String> _dislikes = [];

  List<String> get likes => _likes;
  List<String> get dislikes => _dislikes;

  // Method to set likes
  void setLikes(List<String> likes) {
    _likes = likes;
    notifyListeners();
  }

  // Method to set dislikes
  void setDislikes(List<String> dislikes) {
    _dislikes = dislikes;
    notifyListeners();
  }

  // Method to add a single like
  void addLike(String like) {
    if (!_likes.contains(like)) {
      _likes.add(like);
      notifyListeners();
    }
  }

  // Method to remove a single like
  void removeLike(String like) {
    _likes.remove(like);
    notifyListeners();
  }

  // Method to add a single dislike
  void addDislike(String dislike) {
    if (!_dislikes.contains(dislike)) {
      _dislikes.add(dislike);
      notifyListeners();
    }
  }

  // Method to remove a single dislike
  void removeDislike(String dislike) {
    _dislikes.remove(dislike);
    notifyListeners();
  }
}

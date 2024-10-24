import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'preference_provider.dart';

class Profile extends StatelessWidget {
  final List<String> likeOptions = ['풍경', '최단거리', '자전거 전용도로'];
  final List<String> dislikeOptions = ['오르막길', '차도', '인도'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('선호도 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '좋아요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...likeOptions.map((option) => PreferenceButton(option: option, type: 'like')),
            SizedBox(height: 20),
            Text(
              '싫어요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...dislikeOptions.map((option) => PreferenceButton(option: option, type: 'dislike')),
          ],
        ),
      ),
    );
  }
}

class PreferenceButton extends StatelessWidget {
  final String option;
  final String type;

  PreferenceButton({required this.option, required this.type});

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);

    bool isSelected = (type == 'like')
        ? preferenceProvider.isLiked(option)
        : preferenceProvider.isDisliked(option);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.white54,
      ),
        onPressed: () {
          if (type == 'like') {
            preferenceProvider.toggleLike(option);
          } else {
            preferenceProvider.toggleDislike(option);
          }
        },
        child: Text(option),
      ),
    );
  }
}

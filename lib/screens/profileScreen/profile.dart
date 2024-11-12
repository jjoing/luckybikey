import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'preference_provider.dart';

class Profile extends StatelessWidget {
  final List<String> likeOptions = ['풍경', '최단거리', '자전거 전용도로'];
  final List<String> dislikeOptions = ['오르막길', '차도', '인도', '통행량'];

  Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 프로필 이미지와 닉네임
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/images/profile_image.jpg'), // 임의의 프로필 이미지 경로
            ),
            const SizedBox(height: 10),
            Text(
              'yoonbin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.lightGreen[800],
              ),
            ),
            TextButton(
              onPressed: () {
                // 로그아웃 로직 추가
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // 선호도 설정
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                      thickness: 1, height: 1, color: Colors.lightGreen),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    '선호도 설정',
                    style: TextStyle(
                      color: Colors.lightGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 좋아요 옵션 가로 배치
                  const Text(
                    '좋아요!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0, // 가로 간격
                    runSpacing: 8.0, // 세로 간격
                    children: likeOptions
                        .map((option) =>
                            PreferenceButton(option: option, type: 'like'))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // 싫어요 옵션 가로 배치
                  const Text(
                    '싫어요!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: dislikeOptions
                        .map((option) =>
                            PreferenceButton(option: option, type: 'dislike'))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceButton extends StatelessWidget {
  final String option;
  final String type;

  const PreferenceButton({super.key, required this.option, required this.type});

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);

    bool isSelected = (type == 'like')
        ? preferenceProvider.isLiked(option)
        : preferenceProvider.isDisliked(option);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white54,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        if (type == 'like') {
          preferenceProvider.toggleLike(option);
        } else {
          preferenceProvider.toggleDislike(option);
        }
      },
      child: Text(
        option,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

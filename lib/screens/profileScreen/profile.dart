import 'package:flutter/material.dart';
import 'package:luckybiky/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preference_provider.dart';
import 'preferenceSurvey.dart';

class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 프로필 이미지와 닉네임
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/profile_image.jpg'),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(thickness: 1, height: 1, color: Colors.lightGreen),
                  const SizedBox(height: 20),
                  const Text(
                    '선호도 설정 결과',
                    style: TextStyle(
                      color: Colors.lightGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 좋아요 옵션
                  const Text(
                    '좋아요!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: preferenceProvider.likes
                        .map((option) => _buildOptionChip(option, Colors.green))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // 싫어요 옵션
                  const Text(
                    '싫어요!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: preferenceProvider.dislikes
                        .map((option) => _buildOptionChip(option, Colors.redAccent))
                        .toList(),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IntroToSurveyPage(
                              onContinue: () async {
                                // 여기서 첫 접속 완료 상태를 업데이트하는 작업
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.setBool('isFirstTimeUser', false);
                              },
                            ),
                          ),
                        );// 명시적으로 'return' 추가
                      },
                      child: const Text(
                        '다시 설문조사 참여하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}

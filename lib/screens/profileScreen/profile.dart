import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import '../../utils/providers/page_provider.dart';
import '../../utils/providers/preference_provider.dart';
import '../../utils/providers/kakao_login_provider.dart';

import 'preference_survey/intro.dart';
import '../../components/bottomNaviBar.dart';

import '../../utils/login/login.dart';
import '../../utils/login/social_login.dart';
import '../../utils/login/kakao_login.dart';


class Profile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);
    final pageProvider = Provider.of<PageProvider>(context, listen: false);
    final kakaoLoginProvider = Provider.of<KakaoLoginProvider>(context);

    final viewModel = MainViewModel(KakaoLogin());

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 프로필 이미지
            if (kakaoLoginProvider.user?.kakaoAccount?.profile?.profileImageUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  kakaoLoginProvider.user?.kakaoAccount?.profile?.profileImageUrl ?? '',
                ),
              ),
            const SizedBox(height: 20),
            // 닉네임
            Center(
              child: Text(
                kakaoLoginProvider.user?.kakaoAccount?.profile?.nickname ?? '로그인이 필요합니다.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightGreen[800],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 로그인/로그아웃 버튼
            TextButton(
              onPressed: () async {
                if (kakaoLoginProvider.isLogined) {
                  // 로그아웃 실행
                  await kakaoLoginProvider.logout();
                } else {
                  // 로그인 실행
                  await kakaoLoginProvider.login();
                }
              },
              child: Text(
                kakaoLoginProvider.isLogined ? '로그아웃' : '로그인',
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
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
                        );
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
      bottomNavigationBar: BottomNavigation(),
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
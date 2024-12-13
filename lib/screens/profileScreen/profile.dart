import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/providers/page_provider.dart';
import '../../utils/providers/preference_provider.dart';
import '../../utils/providers/kakao_login_provider.dart';

import 'preference_survey/intro.dart';
import '../../components/bottomNaviBar.dart';

import '../searchScreen/retention/ranking_card.dart';
import '../searchScreen/retention/top_10.dart';


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      PreferenceProvider preferenceProvider =
          context.read<PreferenceProvider>();
      preferenceProvider.getPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);
    final pageProvider = Provider.of<PageProvider>(context, listen: false);
    final kakaoLoginProvider = Provider.of<KakaoLoginProvider>(context);

    //final viewModel = MainViewModel(KakaoLogin());

    return Scaffold(
      body: Container(decoration: BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 프로필 이미지
              if (kakaoLoginProvider
                      .user?.kakaoAccount?.profile?.profileImageUrl !=
                  null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    kakaoLoginProvider
                            .user?.kakaoAccount?.profile?.profileImageUrl ??
                        '',
                  ),
                ),
              const SizedBox(height: 10),
              // 닉네임
              Center(
                child: Text(
                  kakaoLoginProvider.user?.kakaoAccount?.profile?.nickname ??
                      '로그인이 필요합니다.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen[800],
                  ),
                ),
              ),
              SizedBox(height: 10,),
              IconButton(
                onPressed: () {
                  // Dialog를 띄우는 코드
                  showDialog(
                    context: context,
                    builder: (context) {
                      return RankingCard();
                    },
                  );
                },
                visualDensity: VisualDensity(vertical: -4),
                padding: EdgeInsets.all(0),
                icon: const Text(
                  '내 순위 카드 보기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Dialog를 띄우는 코드
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Top10();
                    },
                  );
                },
                visualDensity: VisualDensity(vertical: -4),
                padding: EdgeInsets.all(0),
                icon: Text(
                  'TOP 10 라이더 보기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 5,),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(thickness: 1, height: 1, color: Colors.lightGreen),
                    const SizedBox(height: 20),
                    const Text(
                      '당신의 선호는?',
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
                    const SizedBox(height: 7),
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
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: preferenceProvider.dislikes
                          .map((option) =>
                              _buildOptionChip(option, Colors.redAccent))
                          .toList(),
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
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
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
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
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

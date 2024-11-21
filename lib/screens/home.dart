import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'searchScreen/search.dart';
import 'profileScreen/profile.dart';
import 'profileScreen/preferenceSurvey.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스
  final List<Widget> _pages = [const HomeContent(), const Search(), Profile()]; // 페이지 리스트

  // 첫 접속 여부를 확인하는 함수
  Future<bool> checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstTimeUser') ?? true;
  }

  // 첫 접속 완료로 표시하는 함수
  Future<void> setFirstTimeUserCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimeUser', false);
  }

  // 탭 변경 핸들러
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkFirstTimeUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // 첫 접속이면 안내 페이지를 표시
        if (snapshot.data == true) {
          return IntroToSurveyPage(onContinue: () async {
            await setFirstTimeUserCompleted();
            setState(() {});
          });
        }

        // 첫 접속이 아니라면 기존 정보 화면 표시
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              "luckybikey",
              style: TextStyle(
                color: Colors.lightGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.0,
          ),
          body: _pages[_selectedIndex], // 현재 선택된 페이지를 표시
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: Colors.lightGreen,
            unselectedItemColor: Colors.lightGreenAccent,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onItemTapped,
            currentIndex: _selectedIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

// 첫 접속 시 안내 페이지 구성
class IntroToSurveyPage extends StatelessWidget {
  final Future<void> Function()? onContinue;

  // onContinue를 선택적 매개변수로 설정
  IntroToSurveyPage({this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "나의 자전거 주행 취향 찾기!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightGreen[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "사용자님의 주행 스타일에 맞춘 경로를 추천하기 위해 간단한 설문조사를 진행하고자 합니다.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.lightGreen[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () async {
                  // onContinue가 null이 아닐 때만 실행
                  if (onContinue != null) {
                    await onContinue!();
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => preferenceSurvey(),
                    ),
                  );
                },
                child: const Text(
                  "지금 테스트하기",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// 기존 Home의 컨텐츠를 분리한 위젯 (HomeContent)
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.lightGreen[100],
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Want to find a way?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Click here to move to the map.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.lightGreen[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  onPressed: () {
                    final parentState = context.findAncestorStateOfType<_HomeState>();
                    parentState?._onItemTapped(1); // Search 페이지로 이동
                  },
                  child: const Text(
                    "Go to Search",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.lightGreen[50],
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Want to choose your preference while riding?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreen[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Click here to move to your profile.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.lightGreen[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  onPressed: () {
                    final parentState = context.findAncestorStateOfType<_HomeState>();
                    parentState?._onItemTapped(2); // Profile 페이지로 이동
                  },
                  child: const Text(
                    "Go to Profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

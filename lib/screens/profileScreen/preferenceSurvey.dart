import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'preference_provider.dart';

class preferenceSurvey extends StatefulWidget {
  @override
  _preferenceSurveyState createState() => _preferenceSurveyState();
}

class _preferenceSurveyState extends State<preferenceSurvey> {
  final List<Map<String, dynamic>> surveyQuestions = [
    // 설문 질문 목록 그대로 유지
  ];

  int currentQuestionIndex = 0;

  void _selectOption(String type, String keyword, bool isLiked) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context, listen: false);
    if (type == "like") {
      isLiked ? preferenceProvider.addLike(keyword) : preferenceProvider.removeLike(keyword);
    } else {
      isLiked ? preferenceProvider.addDislike(keyword) : preferenceProvider.removeDislike(keyword);
    }
  }

  void _nextQuestion() {
    setState(() {
      currentQuestionIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestionIndex >= surveyQuestions.length) {
      // 설문이 완료되면 결과 페이지로 이동
      return SurveyResultPage();
    }

    final questionData = surveyQuestions[currentQuestionIndex];
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              questionData["question"],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.lightGreen[900]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Column(
              children: List.generate(2, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _selectOption(
                        questionData["type"],
                        questionData["keyword"],
                        index == 0, // 0번 옵션은 "네", 1번 옵션은 "아니요"
                      );
                      _nextQuestion();
                    },
                    child: Text(
                      questionData["options"][index],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// 결과 페이지는 그대로 유지
class SurveyResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("설문조사 결과")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("설문조사 결과", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("좋아하는 요소:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: preferenceProvider.likes.map((like) => Chip(label: Text(like))).toList(),
            ),
            const SizedBox(height: 20),
            Text("피하는 요소:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: preferenceProvider.dislikes.map((dislike) => Chip(label: Text(dislike))).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("홈으로 돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}

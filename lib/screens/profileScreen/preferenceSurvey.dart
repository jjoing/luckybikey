import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'preference_provider.dart';
import 'package:luckybiky/screens/searchScreen/search.dart';

class preferenceSurvey extends StatefulWidget {
  @override
  _preferenceSurveyState createState() => _preferenceSurveyState();
}

class _preferenceSurveyState extends State<preferenceSurvey> {
  final List<Map<String, dynamic>> surveyQuestions = [
    {
      "question": "친구와 자전거 여행을 떠날 때 당신은?",
      "type": "like",
      "keyword": "Scenery",
      "options": ["길가에 있는 카페에서 휴식을 즐긴다", "목적지까지 최대한 빨리 간다"]
    },
    {
      "question": "자전거 도로에서 큰 길로 이어질 때",
      "type": "like",
      "keyword": "Bike-only roads",
      "options": ["빠르고 직선인 큰 길을 택한다", "안전한 자전거 전용 도로로 우회한다"]
    },
    {
      "question": "평화로운 산길을 달릴 때",
      "type": "like",
      "keyword": "Fast paths",
      "options": ["경치를 즐기며 천천히 주행한다", "속도를 내며 도착 시간을 줄인다"]
    },
    {
      "question": "신호등이 많은 길을 지날 때",
      "type": "dislike",
      "keyword": "Signals",
      "options": ["신호가 싫어 다른 경로를 찾는다", "신호가 있어도 괜찮아 그대로 간다"]
    },
  ];

  final ScreenshotController screenshotController = ScreenshotController();

  int currentQuestionIndex = 0;

  void _selectOption(String type, String keyword, bool isLiked) {
    final preferenceProvider =
        Provider.of<PreferenceProvider>(context, listen: false);
    if (type == "like") {
      isLiked
          ? preferenceProvider.addLike(keyword)
          : preferenceProvider.removeLike(keyword);
    } else {
      isLiked
          ? preferenceProvider.addDislike(keyword)
          : preferenceProvider.removeDislike(keyword);
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
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / surveyQuestions.length,
            minHeight: 5,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    questionData["question"],
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightGreen[900]),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
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
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurveyResultPage extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _saveImage(BuildContext context) async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/survey_result.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(image);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved to $imagePath')),
    );
  }

  void _shareImage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미지 공유 기능 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          children: [
            Screenshot(
              controller: screenshotController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '이런 주행 취향이 있어요!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            children: preferenceProvider.likes
                                .map((like) => Chip(label: Text(like)))
                                .toList(),
                          ),
                          Wrap(
                            spacing: 10,
                            children: preferenceProvider.dislikes
                                .map((dislike) => Chip(label: Text(dislike)))
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.download, color: Colors.blue),
                                onPressed: () async {
                                  await screenshotController
                                      .capture(
                                          delay: Duration(milliseconds: 10),
                                          pixelRatio: MediaQuery.of(context)
                                              .devicePixelRatio)
                                      .then((Uint8List? image) async {
                                    if (image != null) {
                                      final directory =
                                          await getApplicationDocumentsDirectory();
                                      final imagePath = await File(
                                              '${directory.path}/image.png')
                                          .create();
                                      await imagePath.writeAsBytes(image);
                                      await ImageGallerySaver.saveFile(
                                          imagePath.path,
                                          name: 'screenshot');
                                    }
                                  });
                                },
                                tooltip: '다운로드',
                              ),
                              IconButton(
                                icon: Icon(Icons.share, color: Colors.blue),
                                onPressed: () => _shareImage(context),
                                tooltip: '공유',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Search(),
                      ),
                    );
                  },
                  child: const Text(
                    '경로 검색하러 가기',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

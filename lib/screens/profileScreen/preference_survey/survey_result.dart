import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:provider/provider.dart';

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../../../utils/providers/page_provider.dart';
import '../../../utils/providers/preference_provider.dart';
import '../../../utils/providers/kakao_login_provider.dart';

import 'kakao_share.dart';
import 'edit_keyword.dart';

class SurveyResultPage extends StatelessWidget {
  final ScreenshotController fullScreenshotController = ScreenshotController();
  final ScreenshotController kakaoScreenshotController = ScreenshotController();
  final String resultType;

  SurveyResultPage({required this.resultType});

  @override
  Widget build(BuildContext context) {
    final preferenceProvider = Provider.of<PreferenceProvider>(context);
    final pageProvider = Provider.of<PageProvider>(context, listen: false);
    final kakaoLoginProvider = Provider.of<KakaoLoginProvider>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // 전체 스크린샷 영역
          Screenshot(
            controller: fullScreenshotController,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
                padding: EdgeInsets.symmetric(vertical: 16),
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
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // 카카오톡 공유 스크린샷 영역
                  Screenshot(
                    controller: kakaoScreenshotController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // 카카오 로그인 닉네임
                          Text(
                            '${kakaoLoginProvider.user?.kakaoAccount?.profile?.nickname} 님의 주행 취향은?',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 10),

                          // 결과 위젯
                          resultWidget(resultType: resultType),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // "취향 키워드 모아보기" 영역 (전체 스크린샷에는 포함되지만, 카카오톡에는 포함되지 않음)
                  Text(
                    "취향 키워드 모아보기",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreen,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 좋아요 키워드
                  Wrap(
                    spacing: 10,
                    children: preferenceProvider.likes
                        .map((like) => Chip(
                      label: Text(
                        like,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // 싫어요 키워드
                  Wrap(
                    spacing: 10,
                    children: preferenceProvider.dislikes
                        .map((dislike) => Chip(
                      label: Text(
                        dislike,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ))
                        .toList(),
                  ),
                  TextButton(
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return EditKeywordsPage();
                          },
                        ),
                      )
                    },
                    child: Text(
                      '취향 키워드 수정하기',
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 12),
                    ),
                  ),
                  // 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download, color: Colors.green),
                        onPressed: () async {
                          await fullScreenshotController
                              .capture(
                              delay: Duration(milliseconds: 10),
                              pixelRatio: MediaQuery.of(context).devicePixelRatio)
                              .then((Uint8List? image) async {
                            if (image != null) {
                              final directory =
                              await getApplicationDocumentsDirectory();
                              final imagePath =
                              await File('${directory.path}/image.png').create();
                              await imagePath.writeAsBytes(image);
                              await ImageGallerySaver.saveFile(imagePath.path,
                                  name: 'screenshot');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Image saved to $imagePath')),
                              );
                            }
                          });
                        },
                        tooltip: '다운로드',
                      ),
                      SizedBox(width: 50),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.green),
                        onPressed: () async {
                          try {
                            Uint8List? capturedImage =
                            await kakaoScreenshotController.capture();
                            if (capturedImage != null) {
                              await kakaoShareWithImage(capturedImage);
                            } else {
                              throw '이미지를 캡처하지 못했습니다.';
                            }
                          } catch (error) {
                            print('공유 실패: $error');
                          }
                        },
                        tooltip: '공유',
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 경로 검색 버튼
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    ),
                    onPressed: () {
                      pageProvider.setPage(1);
                      Navigator.popAndPushNamed(context, '/Search');
                    },
                    child: const Text(
                      '경로 검색하러 가기',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20)
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// 결과 위젯
class resultWidget extends StatelessWidget {
  final String resultType;

  resultWidget({required this.resultType});

  final Map<String, Map<String, String>> resultData = {
    "scenery": {
      "title": "자유로운 영혼의 낭만파!",
      "description": "빨리 목적지를 향해 가기보다는 주변을 둘러보기를 좋아하는 당신은 자유로운 영혼의 낭만파 라이더입니다!",
      "imagePath": "assets/images/survey_result/scenery.webp",
    },
    "health": {
      "title": "헛둘헛둘! 나는야 운동 매니아",
      "description":
      "자전거를 이동 수단으로만 생각하지 않는 당신은 운동을 즐기는 멋진 스포츠인! 스피드와 험난한 코스를 즐겨보세요:)",
      "imagePath": "assets/images/survey_result/health.webp",
    },
    "safety": {
      "title": "안!전! 나는야 신호지킴이, 안전제일주의자",
      "description": "자전거 전용도로를 좋아하는 당신은 도로 위 안전 지킴이! 자전거 길과 함께 안전한 주행을 즐겨요!",
      "imagePath": "assets/images/survey_result/safety.webp",
    },
    "fast": {
      "title": "최단속도, 최대효율! 난 오로지 목적지를 향한다",
      "description": "산도 신호도, 나를 막을 수 없다! 오로지 가장 빠른 길만을 추구하는 당신은 혹시 ISTJ..?",
      "imagePath": "assets/images/survey_result/fast.webp",
    },
  };

  @override
  Widget build(BuildContext context) {
    final data = resultData[resultType] ??
        {
          "title": "알 수 없는 결과",
          "description": "결과 데이터를 불러올 수 없습니다.",
          "imagePath": "assets/images/survey_result/default.png",
        };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          data["title"]!,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.lightGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Image.asset(
          data["imagePath"]!,
          height: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          data["description"]!,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

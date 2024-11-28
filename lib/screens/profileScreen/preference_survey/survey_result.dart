import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'kakao_share.dart';

import '../../../utils/providers/page_provider.dart';
import '../../../utils/providers/preference_provider.dart';

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
    final pageProvider = Provider.of<PageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Image saved to $imagePath')),
                                    );
                                  }
                                });
                              },
                              tooltip: '다운로드',
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: Colors.blue),
                              onPressed: () => kakaoShare(),
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
                  pageProvider.setPage(1); // search 페이지로 이동
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
    );
  }
}
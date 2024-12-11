import 'dart:math';

import 'package:flutter/material.dart';
import 'feedback_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class tapWidget extends StatefulWidget {
  const tapWidget({
    super.key,
    required this.navState,
    required this.firestore,
    required this.authentication,
    required this.tts,
  });

  final Map<String, dynamic> navState;
  final FirebaseFirestore firestore;
  final FirebaseAuth authentication;
  final FlutterTts tts;

  @override
  State<tapWidget> createState() => _tapWidgetState();
}

class _tapWidgetState extends State<tapWidget> {
  String userGroup = '';
  int featureIndex = 0;

  final List<String> featureTexts = [
    '이 길의 풍경이 만족스럽다면 더블탭 해주세요!',
    '이 길이 안전하다면 더블탭 해주세요!',
    '이 길의 현재 통행량이 많으면 더블탭 해주세요!',
    '이 길이 빠르다고 생각하신다면 더블탭 해주세요!.',
    '주행 중인 길에 신호등이 많이 없다면 더블탭 해주세요!',
    '이 길의 오르막이 심하면 더블탭 해주세요!',
    '이 길이 안전하다고 생각되면 더블탭 해주세요!',
    '이 길이 자전거길이라면 더블탭 해주세요!'
  ];

  @override
  void initState() {
    super.initState();
    widget.firestore
        .collection('users')
        .doc(widget.authentication.currentUser?.uid)
        .get()
        .then((value) {
      userGroup = value.data()!['label'].toString();
      print('userGroup : $userGroup');
    });
  }

  @override
  Widget build(BuildContext context) {
    featureIndex = Random().nextInt(8);
    widget.tts.speak(featureTexts[featureIndex]);
    print('tts : ${featureTexts[featureIndex]}');

    return GestureDetector(
        // 피드백으로 더블탭 감지 시 feedback 함수 실행
        onDoubleTap: () {
          feedback(widget.navState, userGroup, featureIndex);
        },

        // 피드백을 감지하기 위한 double tap 영역
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.lightGreen.withOpacity(0.25),
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
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                // featureIndex에 맞는 텍스트를 featureTexts 리스트에서 선택하여 표시
                featureIndex < featureTexts.length
                    ? featureTexts[featureIndex]
                    : 'Double Tap here if you are satisfied with your road!!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ));
  }
}

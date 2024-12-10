import 'package:flutter/material.dart';
import 'feedback_function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class tapWidget extends StatefulWidget {
  const tapWidget({
    super.key,
    required this.navState,
    required this.firestore,
    required this.authentication,
  });

  final Map<String, dynamic> navState;
  final FirebaseFirestore firestore;
  final FirebaseAuth authentication;

  @override
  State<tapWidget> createState() => _tapWidgetState();
}

class _tapWidgetState extends State<tapWidget> {
  String userGroup = '';

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
    return GestureDetector(

        // 피드백으로 더블탭 감지 시 feedback 함수 실행
        onDoubleTap: () {
          feedback(widget.navState, userGroup);
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
                'Double Tap here if you are satisfied with your road!!',
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

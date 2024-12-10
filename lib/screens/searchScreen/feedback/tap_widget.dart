import 'package:flutter/material.dart';
import 'feedback_function.dart';

class tapWidget extends StatefulWidget {
  const tapWidget({super.key});

  @override
  State<tapWidget> createState() => _tapWidgetState();
}

class _tapWidgetState extends State<tapWidget> {


  @override
  Widget build(BuildContext context) {
    return GestureDetector(

      // 피드백으로 더블탭 감지 시 feedback 함수 실행
      onDoubleTap: feedback,

      // 피드백을 감지하기 위한 double tap 영역
      child: Container(
        width: MediaQuery.of(context).size.width*0.9,
        height: MediaQuery.of(context).size.height*0.4,
        decoration: BoxDecoration(
          color: Colors.lightGreen.withOpacity(0.3),
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
        child: Center(
          child: Text(
            'Double Tap Here if you are satisfied with your road!!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
    );
  }
}

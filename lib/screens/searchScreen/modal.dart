import 'package:flutter/material.dart';

class ModalContent extends StatefulWidget {
  const ModalContent({super.key});

  @override
  State<ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<ModalContent> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('당신의 순위 보기'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
            ),
            builder: (BuildContext context) {
              return Container(
                height: 200,
                color: Colors.transparent,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('@@님은 현재 ##km 주행 중!'),
                      SizedBox(height: 20,),
                      ElevatedButton(
                        child: const Text('지도 보기'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );;
  }
}

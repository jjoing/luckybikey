import 'dart:async';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'package:url_launcher/url_launcher.dart';

Future<void> kakaoShare() async {
  // 사용자 정의 템플릿 ID
  int templateId = 114642; // 실제 템플릿 ID로 교체
  String url = "https://github.com/jjoing/luckybikey"; // 공유할 웹 페이지 URL

  // 카카오톡 실행 가능 여부 확인
  bool isKakaoTalkSharingAvailable = await ShareClient.instance.isKakaoTalkSharingAvailable();

  if (isKakaoTalkSharingAvailable) {
    try {
      // 카카오톡으로 공유
      Uri uri = await ShareClient.instance.shareScrap(url: url, templateId: templateId);
      await ShareClient.instance.launchKakaoTalk(uri);
      print('카카오톡 공유 완료');
    } catch (error) {
      print('카카오톡 공유 실패: $error');
    }
  } else {
    try {
      // 웹 공유 링크 생성
      Uri shareUrl = await WebSharerClient.instance.makeScrapUrl(
        url: url,
        templateId: templateId,
        templateArgs: {'key1': 'value1'},
      );
      // 브라우저에서 공유 링크 열기
      if (await canLaunch(shareUrl.toString())) {
        await launch(shareUrl.toString());
        print('웹 공유 완료');
      } else {
        throw '웹 공유 링크를 열 수 없습니다: ${shareUrl.toString()}';
      }
    } catch (error) {
      print('웹 공유 실패: $error');
    }
  }
}

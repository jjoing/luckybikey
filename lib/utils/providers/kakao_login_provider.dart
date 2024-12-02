import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginProvider with ChangeNotifier {
  bool isLogined = false;
  User? user;

  Future<void> login() async {
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공');
        } catch(e) {
          print('카카오톡 로그인 실패: $e');
        }
      } else {
        try {
          await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
        } catch(e) {
          print('카카오계정으로 로그인 실패: $e');
        }
      }
      isLogined = true;
      user = await UserApi.instance.me();
      notifyListeners();
    } catch (e) {
      print('카카오 로그인 실패: $e');
      isLogined = false;
      user = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      isLogined = false;
      user = null;
      notifyListeners();
    } catch (e) {
      print('카카오 로그아웃 실패: $e');
    }
  }
}
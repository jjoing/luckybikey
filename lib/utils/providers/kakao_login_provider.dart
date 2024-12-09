import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class KakaoLoginProvider with ChangeNotifier {
  bool isLogined = false;
  User? user;
  OAuthToken? kakaoToken;
  final _firestore = FirebaseFirestore.instance;
  final _authentication = auth.FirebaseAuth.instance;

  Future<void> login() async {
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          kakaoToken = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공');
        } catch (e) {
          print('카카오톡 로그인 실패: $e');
        }
      } else {
        try {
          kakaoToken = await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
        } catch (e) {
          print('카카오계정으로 로그인 실패: $e');
        }
      }
      isLogined = true;
      user = await UserApi.instance.me();

      // await checkUserExist(user, kakaoToken);
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

  Future<void> checkUserExist(user, token) async {
    final userRef = _firestore.collection('users').doc(user!.id);

    if ((await userRef.get()).exists) {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generate_custom_token')
          .call({"token": token});
      await _authentication.signInWithCustomToken(result.data['token']);
    } else {
      await _firestore.collection('users').doc(user!.id).set({
        'uid': user!.id,
        'email': user!.kakaoAccount?.emailNeedsAgreement
            ? user!.kakaoAccount?.email
            : "", // newUser.user!.email 대신 userEmail 사용 가능
        'fullname': user.kakaoAccount?.profile?.nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'attributes': {
          "scenery": 0,
          "safety": 0,
          "traffic": 0,
          "fast": 0,
          "signal": 0,
          "uphill": 0,
          "bigRoad": 0,
          "bikePath": 0,
        }
      });
      final result = await FirebaseFunctions.instance
          .httpsCallable('generate_custom_token')
          .call({"token": token});
      await _authentication.signInWithCustomToken(result.data['token']);
    }
  }
}

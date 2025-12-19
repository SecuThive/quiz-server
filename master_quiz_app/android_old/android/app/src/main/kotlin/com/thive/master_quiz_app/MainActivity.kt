package com.thive.master_quiz_app

// 구버전(io.flutter.app.FlutterActivity)을 쓰면 에러가 납니다.
// 아래처럼 embedding.android 패키지를 써야 합니다.
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
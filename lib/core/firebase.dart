import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class FirebaseInit {

  firebaseInitialize() async {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyADKhMidfXWkQ0Hnn7_lVW_6xuGkonzsv8',
            appId: '1:141581174318:android:1f53349aeee89ec1a1c1bf',
            messagingSenderId: '',
            projectId: 'com.softradix.echosyncapp',
            storageBucket: 'gs://audio-watch.appspot.com'
          ));
    } else {
      print("Ios");
      await Firebase.initializeApp();


    }
  }
}

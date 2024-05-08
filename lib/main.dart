import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_echo_sync_app/android_audio_recorder_login/screen/android_audio_recorder_screen.dart';
import 'package:flutter_echo_sync_app/android_watch/screen/reacord_audio_watch_screen.dart';
import 'package:flutter_echo_sync_app/core/firebase.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ios_audio_recorder_login/screen/audio_recorder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
    await FirebaseInit().firebaseInitialize();


  await SharedPreferences.getInstance();

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home:  Platform.isIOS
          ? AudioRecorderScreen(): FutureBuilder<bool>(
        future: _getIsWatch(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          } else {
            bool isWatch = snapshot.data!;
            return Scaffold(
              body:
              isWatch
                  ? RecordAudioWatchScreen()
                  : AndroidAudioRecorderScreen(),
            );
          }
        },
      ),
    );
  }

  Future<bool> _getIsWatch() async {
    const MethodChannel channel = MethodChannel('flutter_echo_sync_app/isWatch');
    try {
      bool result = await channel.invokeMethod('updateIsWatch', {});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get isWatch: '${e.message}'.");
      return false;
    }
  }
}
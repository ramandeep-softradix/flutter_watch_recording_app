import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../../local_storage/local_storage.dart';

class RecordAudioWatchController extends GetxController {
  RxBool isRecording = false.obs;
  final AudioPlayer audioPlayer = AudioPlayer();
  RxString recordAudio = "".obs;
  late FlutterSoundRecorder recorder;
  Rx<Duration> duration = Duration(seconds: 0).obs;
  late Timer timer;
  RxBool isPlaying = false.obs;
  RxBool isLoggedIn = false.obs;
  RxList<String> audioNameList = <String>[].obs;
  late WatchConnectivity watchConnectivity;
  RxString recordAudioName = "".obs;
  RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    watchConnectivity = WatchConnectivity();
    super.onInit();
    initializeRecorder();
    getUserLogged();
    getLocalList();
    receiveMessageFromAndroid();
    checkIfUserLogged();
  }

  getUserLogged() async {
    bool isLogged = await Prefs().getBoolFromLocalStorage(Prefs.isLogin);
    if (isLogged != null) {
      isLoggedIn.value = isLogged;
    } else {}
  }

  getLocalList() async {
    var list = await Prefs().getAudioListFromLocalStorage(Prefs.audioList);
    audioNameList.value = list.toList();
    if(audioNameList.value.isNotEmpty){
      recordAudioName.value = audioNameList.last;
    }
    print(list);
  }

  Future<void> checkIfUserLogged() async {
    try {
      await watchConnectivity.sendMessage({'checkLogged': isLoggedIn.value});
      print('check Logged sent successfully');
    } catch (e) {
      print('Failed to send message: $e');
    }
  }
// Function to convert audio file to base64 string
  Future<String> audioFileToBase64(String filePath) async {
    File audioFile = File(filePath);
    List<int> audioBytes = await audioFile.readAsBytes();
    String base64String = base64Encode(audioBytes);
    return base64String;
  }
  Future<void> sendAudioPathToAndroid(String path) async {
    try {
      final baseString=await audioFileToBase64(path);
      await watchConnectivity.sendMessage({'audioPath': baseString});
      await watchConnectivity.sendMessage({'audioName': recordAudioName.value});

      print('Audio path sent successfully');
    } catch (e) {
      print('Failed to send message: $e');
    }
  }




  Future<void> receiveMessageFromAndroid() async {
    watchConnectivity.messageStream.listen((message) async {
      if (message['isLogin'] != null) {
        isLoggedIn.value = message["isLogin"];
        Prefs().saveBoolToLocalStorage(isLoggedIn.value, Prefs.isLogin);
      }

      if (message['audioNameList'] != null) {
        audioNameList.value = List<String>.from(message['audioNameList']);
        if(audioNameList.value.isNotEmpty){
          recordAudioName.value = audioNameList.last;
          print( "recordAudioName >>>>>>> ${ recordAudioName.value}");
        }
        print('event list >>>>>>> ,${audioNameList.value}');
        Prefs()
            .saveAudioListToLocalStorage(audioNameList.value, Prefs.audioList);

      }
    });
  }

  void initializeRecorder() {
    recorder = FlutterSoundRecorder();
  }

  Future<void> checkAndStartRecording() async {
    if (audioNameList.isNotEmpty){
      if (await _checkPermission()) {
        await startRecording();
      } else {
        print('Permission denied');
      }
    }else {
      Get.snackbar("Alert", "Please first add your recording name in android App.",snackPosition: SnackPosition.BOTTOM);
    }
 
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      return await Permission.microphone.request().isGranted;
    } else {
      return status.isGranted;
    }
  }

  startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        await recorder.openRecorder();
        String randomPath = await generateRandomPath('wav');
        await recorder.startRecorder(toFile: randomPath);
        print('Recording started successfully with path: $randomPath');
        recordAudio.value = randomPath;
        isRecording.value = true;
        timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
          duration.value = Duration(seconds: duration.value.inSeconds + 1);
        });
      } else {
        print('Microphone permission not granted');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  stopRecording() async {
    try {
      await recorder.stopRecorder();
      timer.cancel();
      if (recordAudio.value != null && recordAudio.value.isNotEmpty) {
        isRecording.value = false;
        sendAudioPathToAndroid(recordAudio.value);
      } else {
        print('No recording found.');
      }
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  playRecording() async {
    try {
      if (recordAudio != null) {
        // isPlaying.value = true;

        await audioPlayer.play(DeviceFileSource(recordAudio.value));
      }
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

  stopAndClearPlayback() async {
    try {
      await audioPlayer.stop();
      isPlaying.value = false;
      recordAudio.value = "";
    } catch (e) {
      print('Error stopping and clearing playback: $e');
    }
  }

  Future<String> generateRandomPath(String extension) async {
    Directory tempDir = await getTemporaryDirectory();
    String uuid = const Uuid().v4();
    String filePath = '${tempDir.path}/$uuid.$extension';
    return filePath;
  }
}

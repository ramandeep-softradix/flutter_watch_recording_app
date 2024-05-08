import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_echo_sync_app/local_storage/local_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class AndroidAudioRecorderController extends GetxController {
  RxString recordAudio = "".obs;
  RxBool isLoading = false.obs;
  RxBool isLoggedIn = false.obs;
  TextEditingController audioName = TextEditingController();
  RxList<String> audioNameList = <String>[].obs;
  RxString recordAudioName = "".obs;
  RxBool isWearableApiAvailable = false.obs;
  final WatchConnectivity watchConnectivity = WatchConnectivity();
  RxBool isUpload = false.obs;

  @override
  onInit() {
    getUserLogged();
    getLocalList();
    checkWearableApiAvailability();
    receivedDataFromWatch();
  }

  receivedDataFromWatch() {
    watchConnectivity.messageStream.listen((message) {
      print("audio path ${message['audioPath']} ${message['checkLogged']}");
      if (message['checkLogged'] != null) {
        sendMessageToWatchOS(isLoggedIn.value);
      }
      if (message['audioPath'] != null) {
        base64ToAudioFile(message['audioPath'], 'Audio').then((value) {
          print("GENERATED FILE PATH ${value.path} ");
          recordAudio.value = value.path;
          if (isUpload.isFalse) {
            getRecordAudio();
          }
        });
      }
      if (message['audioName'] != null) {
       recordAudioName.value = message['audioName'];
      }
    });
  }

// Function to convert base64 string to audio file
  Future<File> base64ToAudioFile(String base64String, String fileName) async {
    Uint8List bytes = base64Decode(base64String);
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String filePath = '${appDocumentsDirectory.path}/$fileName';
    File audioFile = File(filePath);
    return await audioFile.writeAsBytes(bytes);
  }

  Future<void> sendMessageToWatchOS(bool isLogin) async {
    try {
      await watchConnectivity.sendMessage({'isLogin': isLogin});
      print('isLogin sent successfully');
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  Future<void> sendNameListToWatchOS(List audioList) async {
    try {
      await watchConnectivity.sendMessage({'audioNameList': audioList});
      print('Audio Name List  sent successfully');
      sendMessageToWatchOS(isLoggedIn.value);
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  getUserLogged() async {
    bool isLogged = await Prefs().getBoolFromLocalStorage(Prefs.isLogin);
    if (isLogged != null) {
      isLoggedIn.value = isLogged;
    } else {}
  }

  Future<void> checkWearableApiAvailability() async {
    watchConnectivity.isPaired.then((value) {
      sendNameListToWatchOS(audioNameList.value);
      sendMessageToWatchOS(isLoggedIn.value);
      receivedDataFromWatch();
      print(value);
      isWearableApiAvailable.value = value;
    });
  }

  getLocalList() async {
    var list = await Prefs().getAudioListFromLocalStorage(Prefs.audioList);
    audioNameList.value = list.reversed.toList();
    print(list);
  }

  addAudioTextInList() {
    if (audioName.text.isNotEmpty) {
      audioNameList.add(audioName.text);
      Prefs().saveAudioListToLocalStorage(audioNameList.value, Prefs.audioList);
      audioName.text = "";
    } else {
      Get.snackbar("Alert!", "Please enter audio name.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueAccent);
    }
  }

  removeAllList() {
    audioNameList.clear();
    Prefs().removeKeyFromLocalStorage(Prefs.audioList);
  }

  Future<void> getRecordAudio() async {
    isUpload.value = true;
    log(recordAudio.value);
    isLoading.value = true;
    File file = File(recordAudio.value);
    log("absolute path: ${file.absolute}");
    String? downloadURL = await uploadFile(file);
    Get.snackbar("Upload Done", "Record Audio File uploaded successfully!",
        backgroundColor: Colors.blue);

    log('File uploaded successfully. Download URL: $downloadURL');
    isLoading.value = false;
  }

  Future<String?> uploadFile(File file) async {
    if (recordAudio.value.isNotEmpty) {
      try {
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'uploads/android/${recordAudioName.value}_${DateTime.now().millisecondsSinceEpoch}.wav');
        UploadTask uploadTask = storageReference.putFile(file);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        String downloadURL = await taskSnapshot.ref.getDownloadURL();
        recordAudio.value = "";
        isUpload.value = false;
        return downloadURL;
      } catch (e) {
        log('Error uploading file: $e');
        return null;
      }
    }
  }

  playAudio() {
    final player = AudioPlayer();
    player.play(DeviceFileSource(recordAudio.value));
  }
}

import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_echo_sync_app/local_storage/local_storage.dart';
import 'package:get/get.dart';

class AudioRecorderController extends GetxController {
  RxString recordAudio = "".obs;
  final channel = const MethodChannel('com.example.flutter_echo_sync_app');
  RxBool isLoading = false.obs;
  RxBool isLoggedIn = false.obs;
  TextEditingController audioName = TextEditingController();
  RxList<String> audioNameList = <String>[].obs;
  RxString recordAudioName = "".obs;

  @override
  onInit() {
      sendAudioListToWatch();
      getLocalList();
      _initFlutterChannel();
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
      sendAudioListToWatch();
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
    sendAudioListToWatch();
  }

  Future<void> getRecordAudio() async {
    log(recordAudio.value);
    isLoading.value = true;
    File file = File(recordAudio.replaceAll("file://", ""));

    log("absolute path: ${file.absolute}");
    String? downloadURL = await uploadFile(file);

    bool deleted = deleteFile(file);
    if (deleted) {
      log('File deleted successfully.');
      recordAudio.value = "";
    } else {
      log('Failed to delete the file.');
    }

    Get.snackbar("Upload Done", "Record Audio File uploaded successfully!",
        backgroundColor: Colors.blue);

    log('File uploaded successfully. Download URL: $downloadURL');
    isLoading.value = false;
  }

  sendDataToWatch(bool data) async {
    try {
      await channel.invokeMethod(
          "flutterToWatch", {"method": "sendLoggedToWatch", "data": data});
      log("send Logged To Watch Successfully!");
    } on PlatformException catch (e) {
      log("Failed to send data to watch: '${e.message}'.");
    }
  }

  sendAudioListToWatch() async {

    try {
      await channel.invokeMethod("flutterToWatch",
          {"method": "sendAudioListToWatch", "data": audioNameList.value.reversed.toList()});
      getUserLogged();
      log("send list To Watch Successfully!");
    } on PlatformException catch (e) {
      log("Failed to send data to watch: '${e.message}'.");
    }
  }

  Future<void> _initFlutterChannel() async {
    channel.setMethodCallHandler((call) async {
      log("call : ${call.method}, ${call.arguments}");
      switch (call.method) {
        case "sendLoggedToWatch":
          await sendDataToWatch(isLoggedIn.value);
          sendAudioListToWatch();
        case "sendAudioNameToFlutter":
          recordAudioName.value  = call.arguments["data"]["audioName"];
          print("Here is name ${recordAudioName.value}");
        case "sendCounterToFlutter":
          recordAudio.value = call.arguments["recordAudio"];
          getRecordAudio();
          print("Here is recordAudio ${recordAudio.value}");

          break;
        default:
          break;
      }
    });
  }

  getUserLogged() async {
    bool isLogged = await Prefs().getBoolFromLocalStorage(Prefs.isLogin);
    if (isLogged != null) {
      sendDataToWatch(isLogged);
      isLoggedIn.value = isLogged;

    } else {
      sendDataToWatch(false);
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('uploads/${recordAudioName.value}_${DateTime.now().millisecondsSinceEpoch}.m4a');

      UploadTask uploadTask = storageReference.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await taskSnapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      log('Error uploading file: $e');
      return null;
    }
  }

  playAudio() {
    final player = AudioPlayer();
    player.play(DeviceFileSource(recordAudio.value));
  }

  bool deleteFile(File filePath) {
    try {
      filePath.deleteSync();
      return true;
    } catch (e) {
      log('Error deleting file: $e');
      return false;
    }
  }

}

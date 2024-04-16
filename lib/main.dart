import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:toggle_switch/toggle_switch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Record Audio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Record Audio',
        key: UniqueKey(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required Key key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String recordAudio = "";
  int isLogin = 1;

  final channel = const MethodChannel('com.example.flutter_echo_sync_app');

  bool isLoading = false;
  bool isLogout = false;

  Future<void> getRecordAudio() async {
    print(recordAudio);
    setState(() {
      isLoading = true;
    });

    File file = File(recordAudio.replaceAll("file://", ""));
    print("absolute path: ${file.absolute}");
    String? downloadURL = await uploadFile(file);

    setState(() {
      bool deleted = deleteFile(file);
      if (deleted) {
        print('File deleted successfully.');
        recordAudio = "";
      } else {
        print('Failed to delete the file.');
      }
    });
    isLogin = 0;

    Get.snackbar("Upload Done", "Record Audio File uploaded successfully!",
        backgroundColor: Colors.blue);

    print('File uploaded successfully. Download URL: $downloadURL');

    setState(() {
      isLoading = false;
    });
  }

  sendDataToWatch(bool data) async {
    try {
      await channel.invokeMethod(
          "flutterToWatch", {"method": "sendLoggedToWatch", "data": data});
      print("send Logged To Watch Successfully!!!");
    } on PlatformException catch (e) {
      print("Failed to send data to watch: '${e.message}'.");
    }
  }


  Future<void> _initFlutterChannel() async {
    channel.setMethodCallHandler((call) async {
      // Receive data from Native
      print("call : ${call.method}, ${call.arguments}");

      switch (call.method) {
        case "sendCounterToFlutter":
          isLogout = call.arguments["data"]["isLogout"];
          if (!isLogout) {
            isLogin = 1;
          }
          setState(() {});

          recordAudio = call.arguments["recordAudio"];
          print("recordAudio >>> $recordAudio");

          //     isLogin =

          getRecordAudio();
          setState(() {});
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
    sendDataToWatch(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          recordAudio.isNotEmpty
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Here is the recorded audio path',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  textAlign: TextAlign.center,
                  '$recordAudio',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.all(20),
              )
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textAlign: TextAlign.left,
                  '''Follow below steps to record audio using apple watch:''',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  textAlign: TextAlign.left,
                  '''
                        
 1. Make sure your Apple Watch is connected to your iPhone.
 2. Open TestFlight on your iPhone and install the app.
 3. When prompted, allow the Flutter app to access your Apple Watch.
 4. Tap the play button to start recording.
 5. Grant permission for the microphone if asked.
 6. Speak while the recording is playing.
 7. Tap the stop button to finish recording.
 8. Choose to either play the recorded video or reset to record again.
 9. In the iPhone app, find the recorded video with an option to upload.
 10. Tap upload to send the recording to Firebase storage.
                    ''',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.normal),
                ),
                toggleSwitch()
              ],
            ),
          ),
          isLoading
              ? CircularProgressIndicator(
            color: Colors.blue,
          )
              : SizedBox()
        ],
      ),
    );
  }

  Widget toggleSwitch() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          textAlign: TextAlign.left,
          'Login',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ).paddingOnly(right: 10),
        ToggleSwitch(
            minWidth: 90.0,
            cornerRadius: 20.0,
            activeBgColors: [
              [Colors.blue[800]!],
              [Colors.red[800]!]
            ],
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey,
            inactiveFgColor: Colors.white,
            initialLabelIndex: isLogin,
            totalSwitches: 2,
            labels: const ['On', 'Off'],
            radiusStyle: true,
            onToggle: (index) {
              sendDataToWatch(index == 0 ? true : false);
            }),
      ],
    );
  }

  Future<String?> uploadFile(File file) async {
    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('uploads/${DateTime.now().millisecondsSinceEpoch}');

      UploadTask uploadTask = storageReference.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await taskSnapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  playAudio() {
    final player = AudioPlayer();
    player.play(DeviceFileSource(recordAudio));
  }

  bool deleteFile(File filePath) {
    try {
      filePath.deleteSync();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}

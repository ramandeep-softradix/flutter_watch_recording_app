import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wear/wear.dart';

import '../controller/reacord_audio_watch_controller.dart';

class RecordAudioWatchScreen extends StatelessWidget {
  final RecordAudioWatchController controller =
      Get.put(RecordAudioWatchController());

  RecordAudioWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Obx(() {
              return controller.isLoggedIn.value
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!controller.isRecording.value &&
                            controller.recordAudio.value.isEmpty)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 5),
                              const Text('Record Audio'),
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () {

                                  controller.checkAndStartRecording();
                                },
                                child: const Text('Start Recording'),
                              ),
                              audioTitleListView(),
                            ],
                          ),
                        if (controller.isRecording.value)
                          Column(
                            children: [
                              Text(controller.recordAudioName.value,style: const TextStyle(fontWeight: FontWeight.w600),),
                              const SizedBox(height: 10,),
                              Text(
                                  'Record Time:- ${controller.duration.value.inSeconds}',style: const TextStyle(fontWeight: FontWeight.w700,fontSize: 15)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  controller.stopRecording();
                                },
                                child: Text('Stop Recording'),
                              ),
                            ],
                          ),
                        if (!controller.isRecording.value &&
                            controller.recordAudio.value.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  controller.playRecording();
                                },
                                child: Text(controller.isPlaying.value
                                    ? 'Pause'
                                    : 'Play'),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // Reset recording if needed
                                  controller.duration.value =
                                      Duration(seconds: 0);
                                  controller.stopAndClearPlayback();
                                },
                                child: Text('Reset'),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Center(
                      child: const Text(
                              "To start the recording you have to login through mobile app")
                          .paddingSymmetric(horizontal: 10));
            }),
          ),
        );
      },
    );
  }

  Widget audioTitleListView() {
    print(controller.audioNameList.length);
    return controller.audioNameList.isNotEmpty
        ? SizedBox(
            height: 100,
            child:ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 15),
                shrinkWrap: true,
                itemCount: controller.audioNameList.length,
                physics: const RangeMaintainingScrollPhysics(),
                itemBuilder: (context, index) {
                  var item = controller.audioNameList.reversed.toList();
                  return  Obx(() => InkWell(
                    onTap: () {
                      controller.selectedIndex.value = index;
                      controller.recordAudioName.value = item[index];

                      print(controller.recordAudioName.value);
                    },
                    child: Card(
                      color: Colors.white,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(item[index]),
                          ),
                          const Spacer(),
                           controller.selectedIndex.value != index ? SizedBox():Icon(Icons.check_circle_outline).paddingOnly(right: 10)
                        ],
                      ),
                    ),
                  ));
                }),
             )
        : Container(
            alignment: Alignment.center,
            child: const Text(
              'No Data Found.',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ));
  }
}

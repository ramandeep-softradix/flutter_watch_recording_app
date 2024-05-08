import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_echo_sync_app/ios_audio_recorder_login/controller/audio_recorder_controller.dart';
import 'package:flutter_echo_sync_app/local_storage/local_storage.dart';
import 'package:get/get.dart';
import 'package:toggle_switch/toggle_switch.dart';

class AudioRecorderScreen extends GetView<AudioRecorderController> {
  AudioRecorderController controller = Get.put(AudioRecorderController());

  AudioRecorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (controller.recordAudio.isNotEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                       Text(
                        'Recorded audio by ${controller.recordAudioName.value}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          textAlign: TextAlign.center,
                          controller.recordAudio.value,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.all(20),
                      )
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        toggleSwitch(),
                        const SizedBox(
                          height: 20,
                        ),
                        TextField(
                          controller: controller.audioName,
                          decoration: const InputDecoration(
                              hintText: "Enter audio name here...."),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  controller.addAudioTextInList();
                                },
                                child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.blueAccent,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Submit',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    )),
                              ),
                            ),
                            Spacer(),
                          controller.audioNameList.isNotEmpty ?  Expanded(
                              child: InkWell(
                                onTap: () {
                                  controller.removeAllList();
                                },
                                child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.red,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    )),
                              ),
                            ): Container(),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        audioTitleListView()
                      ],
                    ),
                  ),
                controller.isLoading.value
                    ? const CircularProgressIndicator(
                        color: Colors.blue,
                      )
                    : const SizedBox()
              ],
            ),
          ),
        ));
  }

  Widget audioTitleListView() {
    return Expanded(
      child: controller.audioNameList.isNotEmpty
          ? ListView.builder(
              itemCount: controller.audioNameList.length,

              physics: const RangeMaintainingScrollPhysics(),
              itemBuilder: (context, index) {
                var item = controller.audioNameList.reversed.toList();
                return Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(item[index]),
                  ),
                );
              })
          : Container(
        alignment: Alignment.center,
              child: const Text(
            'No Data Found.',
            style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          )),
    );
  }

  Widget toggleSwitch() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          textAlign: TextAlign.left,
          'Login',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ).paddingOnly(right: 10),
        ToggleSwitch(
            minWidth: 90.0,
            cornerRadius: 20.0,
            activeBgColors: [
              const [Colors.blueAccent],
              [Colors.red[800]!]
            ],
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey.shade300,
            inactiveFgColor: Colors.white,
            initialLabelIndex: controller.isLoggedIn.value ? 0 : 1,
            totalSwitches: 2,
            labels: const ['On', 'Off'],
            radiusStyle: true,
            onToggle: (index) {
              Prefs().saveBoolToLocalStorage(
                  index == 0 ? true : false, Prefs.isLogin);
              controller.sendDataToWatch(index == 0 ? true : false);
            }),
      ],
    );
  }
}

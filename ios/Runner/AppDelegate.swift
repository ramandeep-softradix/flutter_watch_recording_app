import UIKit
import Flutter
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var session: WCSession?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("is Suported \(WCSession.isSupported())");
        initFlutterChannel()

        if WCSession.isSupported() {
            session = WCSession.default;
            session?.delegate = self;
            session?.activate();
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initFlutterChannel() {
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.flutter_echo_sync_app",
                binaryMessenger: controller.binaryMessenger)

            channel.setMethodCallHandler({ [weak self] (
                call: FlutterMethodCall,
                result: @escaping FlutterResult) -> Void in
                switch call.method {
                case "flutterToWatch":
                    guard let watchSession = self?.session, watchSession.isPaired, watchSession.isReachable, let methodData = call.arguments as? [String: Any], let method = methodData["method"], let data = methodData["data"] else {
                        result(false)
                        return
                    }

                    let watchData: [String: Any] = ["method": method, "data": data]
                    // Pass the receiving message to Apple Watch
                    watchSession.sendMessage(watchData, replyHandler: nil, errorHandler: nil)
                    result(true)

                    default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }
    }
}

extension AppDelegate: WCSessionDelegate {

        func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error {
                print("session activation failed with error: \(error.localizedDescription)")
            }
        }

        func sessionDidBecomeInactive(_ session: WCSession) {
        }

        func sessionDidDeactivate(_ session: WCSession) {
        }


    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let method = message["method"] as? String, let controller = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "com.example.flutter_echo_sync_app",
                    binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod(method, arguments: message)
            }
        }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        if let error = error {
              print("Error during file transfer: \(error.localizedDescription)")

            if let controller = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "com.example.flutter_echo_sync_app",
                    binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("sendCounterToFlutter", arguments: ["recordAudio" : error])
            }
              // Handle error (e.g., display error message, retry transfer)
            } else {
              print("File transfer completed successfully")
              // Handle successful transfer (e.g., notify Flutter app, perform further actions)

                if let controller = self.window?.rootViewController as? FlutterViewController {
                    let channel = FlutterMethodChannel(
                        name: "com.example.flutter_echo_sync_app",
                        binaryMessenger: controller.binaryMessenger)
                    channel.invokeMethod("sendCounterToFlutter", arguments: ["recordAudio" : fileTransfer.file.fileURL])
                }

            }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("Received File with URL: \(file.fileURL)")

        DispatchQueue.main.async(execute: {

            guard let fileData = try? Data(contentsOf: file.fileURL) else {
                  print("Error reading file data")
                  return
                }

    //            // 1. Get new destination directory:
    //            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    //
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

            // Create temporary recording file URL
            var newFilePath = URL(fileURLWithPath: documentsPath, isDirectory: true)
                  .appendingPathComponent("recording.m4a")





    //            // 2. Generate unique filename (optional):
    //            let filename = UUID().uuidString + ".mp" // Replace with your desired extension (e.g., .m4a, .txt)

    //            // 3. Create new file path:
    //            let newFilePath = documentsDirectory.appendingPathComponent(filename)

                // 4. Move the file:
                do {
                    try FileManager.default.moveItem(at: file.fileURL, to: newFilePath)
                  print("File moved successfully to: \(newFilePath)")

                  // 5. (Optional) Process the file content using fileData
                } catch {
                  print("Error moving file: \(error.localizedDescription)")
                }
        })
    
    }
 

}

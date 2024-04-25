//
//  ContentView.swift
//  flutter_echo_sync_app Watch App
//
//  Created by Jaskaran Softradix on 10/04/24.
//

import SwiftUI
import AVFoundation

enum RecordingState {
    case idle
    case recording
    case stopped
}

@available(watchOS 8.0, *)
struct ContentView: View {
    @State private var recordingState: RecordingState = .idle
    @State private var audioRecorder: AVAudioRecorder!
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordedAudioURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showWaveform = false
    @State private var isLoading = false
    @State private var isAPICalling = false
    @StateObject var playerManager = AudioPlayerManager()
    @State private var isRecordingPermissionGranted = false
    @ObservedObject var viewModel: WatchViewModel = WatchViewModel()
    @State var temporaryAudioFileURL: URL!
    @State private var selectedIndex = 0
    @State private var selectedTitle: String?
    @State private var isAudioListEmpty = false

    
    var body: some View {
        VStack {
            if !viewModel.isUserLoggedIn {
                
                Text("To start the recording you have to login through mobile app").bold()
                    .frame(maxWidth: .infinity)
            } else {
                if recordingState == .idle {
                    Text("Record Audio").bold().padding(.bottom,5)
                    Button(action: {
                        if !viewModel.audioNameList.isEmpty {
                            selectedTitle = viewModel.audioNameList[selectedIndex]
                            isAudioListEmpty = false
                            self.isLoading = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.isLoading = false
                                requestRecordingPermission()
                            }
                        }else{
                            isAudioListEmpty = true
                            
                        }
                       
                    }) {
                        Text("Start")
                    }.frame(height: 30)
                    .padding()
                    .opacity(isLoading ? 0 : 1)
                    .disabled(isLoading)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                    )
                
                    VStack {
                        if !viewModel.audioNameList.isEmpty {
                            List {
                            let items =  viewModel.audioNameList
                                ForEach(items.indices, id: \.self) { index in
                                    HStack(spacing:0) {
                                        Text(items[index]).frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading,10)
                                        Button(action: {
                                            self.selectedIndex = index
                                        }) {
                                            Image(systemName: selectedIndex == index ? "checkmark.circle.fill" :"plus.circle")
                                                .foregroundColor(.white)
                                                .frame(maxWidth: 20, alignment: .leading)
                                        }
                                    }

                                }
                                
                        }.environment(\.defaultMinListRowHeight, 10)

                        .listStyle(PlainListStyle())
                    .padding(.top)
                        } else {
                            EmptyView()
                        }
                    }
                    
                } else if recordingState == .recording {
                    Text(selectedTitle ?? "").bold().frame(maxWidth: .infinity)
                    if showWaveform {
                        Wave2View()
                            .frame(height: 70)
                            .padding()
                    }

                    Text(String(format: "%.1f", recordingDuration))

                    Button(action: {
                        self.stopRecording()
                    }) {
                        Text("Stop").bold()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                } else if recordingState == .stopped {
                    HStack {
                        Button(action: {
                            if playerManager.isPlaying {
                                playerManager.stopAudio()
                            } else {
                                guard let recordedAudioURL = self.recordedAudioURL else {
                                    print("No recorded audio found.")
                                    return
                                }
                                playerManager.playAudio(from: recordedAudioURL)
                            }
                        }) {
                            if playerManager.isPlaying {
                                Image(systemName: "pause")
                            } else {
                                Image(systemName: "play")
                            }
                        }
                        .disabled(isLoading)

                        Button(action: {
                            self.resetRecording()
                        }) {
                            Text("Reset")
                        }
                        .disabled(isLoading)
                    }
                }
            }
        } 
      
        .alert(isPresented: $isRecordingPermissionGranted) {
            Alert(
                title: Text("Permission denied"),
                message: Text("Permission to record audio was denied. Please open the Settings app to enable audio recording permissions. Some privacy settings are shared between Apple Watch and iPhone. You can manage these settings in the Privacy section of iPhone settings."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.isUserLoggedIn) { isLogged in
            if !isLogged {
                resetRecording()
            }
        }
        .alert(isPresented: $isAudioListEmpty) {
            Alert(
                title: Text("Alert!"),
                message: Text("Please first add your recording name in ios App."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func requestRecordingPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    self.isRecordingPermissionGranted = false
                    self.startRecording()
                    self.startTimer() // Call startTimer() here
                }
            } else {
                DispatchQueue.main.async {
                    self.isRecordingPermissionGranted = true
                }
            }
        }
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)

            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

            // Create temporary recording file URL
            self.temporaryAudioFileURL = URL(fileURLWithPath: documentsPath, isDirectory: true)
                .appendingPathComponent("recording.m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            self.audioRecorder = try AVAudioRecorder(url: temporaryAudioFileURL, settings: settings)
            self.audioRecorder.record()
            self.recordingState = .recording
            self.showWaveform = true

        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder.stop()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            self.recordedAudioURL = audioRecorder.url
            print(recordedAudioURL)

            viewModel.sendDataMessage(for: .sendAudioNameToFlutter, data: ["audioName": self.selectedTitle ?? ""])
            let metadata = ["contentType": "public.aac"] //
            
            viewModel.session.transferFile(recordedAudioURL!, metadata: metadata)

            audioRecorder = nil
            self.recordingState = .stopped
            self.stopTimer()
            self.showWaveform = false
        } catch {
            print("Error stopping recording: \(error.localizedDescription)")
        }
    }

    func resetRecording() {
        // Delete recorded audio file
        if let recordedAudioURL = self.recordedAudioURL {
            do {
                try FileManager.default.removeItem(at: recordedAudioURL)
            } catch {
                print("Error deleting recorded audio file: \(error.localizedDescription)")
            }
        }
        // Reset variables
        self.recordingState = .idle
        self.recordedAudioURL = nil
        self.recordingDuration = 0
        playerManager.stopAudio()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.recordingDuration += 0.1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        recordingDuration = 0
    }
    
    func AudioWaveView(audioSamples: [CGFloat], offsetY: CGFloat) -> some View {
        return GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height / 2))
                for (index, sample) in audioSamples.enumerated() {
                    let x = CGFloat(index) * (width / CGFloat(audioSamples.count))
                    let y = height / 2 + sample * height / 2 * offsetY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: width, y: height / 2))
            }
            .stroke(Color.blue, lineWidth: 2)
            .animation(Animation.easeInOut(duration: 0.1).repeatForever())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(watchOS 8.0, *) {
            ContentView()
        } else {
            // Fallback on earlier versions
        }
    }
}

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false

    func playAudio(from url: URL) {
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.delegate = self
            guard let player = self.audioPlayer else {
                print("Audio player is nil.")
                return
            }

            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            player.play()

            self.isPlaying = true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
            self.isPlaying = false
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            isPlaying = false
        } else {
            print("Audio playback finished unsuccessfully.")
        }
    }
}

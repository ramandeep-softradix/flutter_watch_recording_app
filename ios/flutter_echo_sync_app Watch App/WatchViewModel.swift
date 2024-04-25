import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject {
    var session: WCSession
    
    @Published var recordAudio: String = ""
    @Published  var isUserLoggedIn = false
    @Published var audioNameList = [String]()

    enum WatchReceiveMethod: String {
        case sendCounterToNative
        case sendLoggedToWatch
        case sendAudioListToWatch

    }

    enum WatchSendMethod: String {
        case sendCounterToFlutter
        case sendLoggedToWatch
        case sendAudioNameToFlutter

        
    }

    override init() {
        self.session = WCSession.default
        super.init()
        self.session.delegate = self
        self.session.activate()
    }

    func sendDataMessage(for method: WatchSendMethod, data: [String: Any] = [:]) {
        sendMessage(for: method.rawValue, data: data)
    }
}

extension WatchViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            print("WCSession activated successfully")
            let isUserLogged = getBoolFromUserDefaults(forKey: "isUserLoggedIn")
            isUserLoggedIn = isUserLogged
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendDataMessage(for: .sendLoggedToWatch, data: ["isLogout": self.isUserLoggedIn])
            }
            

        case .inactive:
            print("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")
   
        case .notActivated:
            print("Unexpected .notActivated state received after trying to activate the WCSession")

        @unknown default:
            print("Unexpected state received after trying to activate the WCSession")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage called")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let method = message["method"] as? String,
                  let enumMethod = WatchReceiveMethod(rawValue: method) else {
                return
            }
            
            switch enumMethod {
            case .sendAudioListToWatch:
                audioNameList = message["data"] as! [String]
                saveAudioNameList(value: audioNameList, forKey: "audioNameList")
                print(audioNameList)
            case .sendCounterToNative:
                self.recordAudio = message["data"] as? String ?? ""
            case .sendLoggedToWatch:
    
                 saveBoolToUserDefaults(value: message["data"] as? Bool ?? false, forKey: "isUserLoggedIn")
                let isUserLogged = getBoolFromUserDefaults(forKey: "isUserLoggedIn")
                isUserLoggedIn = isUserLogged
                

            }
        }
    }
    
    func sendMessage(for method: String, data: [String: Any] = [:]) {
        guard session.isReachable else {
            print("Watch app is not reachable.")
            return
        }
        
        let messageData: [String: Any] = ["method": method, "data": data]
        session.sendMessage(messageData, replyHandler: nil, errorHandler: { error in
            print("Error sending message to Watch: \(error.localizedDescription)")
        })
    }
    
    func saveBoolToUserDefaults(value: Bool, forKey key: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
    }

    func getBoolFromUserDefaults(forKey key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: key)
    }
    
    func saveAudioNameList(value: [String], forKey key: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
    }
    
    func getAudioNameList(forKey key: String) -> [String]? {
        let defaults = UserDefaults.standard
        if let audioNames = defaults.object(forKey: key) as? [String] {
            return audioNames
        } else {
            return nil
        }
    }
  
}

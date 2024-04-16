import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject {
    var session: WCSession
    
    @Published var recordAudio: String = ""
    @Published  var isUserLoggedIn = false

    enum WatchReceiveMethod: String {
        case sendCounterToNative
        case sendLoggedToWatch
    }

    enum WatchSendMethod: String {
        case sendCounterToFlutter
        case sendLoggedToWatch

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
            print("Is user logged in? \(isUserLoggedIn)")
            isUserLoggedIn = isUserLogged

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendDataMessage(for: .sendLoggedToWatch, data: ["isLogout": self.isUserLoggedIn])

            }

        case .inactive:
            print("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendDataMessage(for: .sendLoggedToWatch, data: ["isLogout": self.isUserLoggedIn])

            }
        case .notActivated:
            print("Unexpected .notActivated state received after trying to activate the WCSession")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendDataMessage(for: .sendLoggedToWatch, data: ["isLogout": self.isUserLoggedIn])

            }
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
            case .sendCounterToNative:
                self.recordAudio = message["data"] as? String ?? ""
            case .sendLoggedToWatch:
                print("Received send Logged To Native message")
                 saveBoolToUserDefaults(value: message["data"] as? Bool ?? false, forKey: "isUserLoggedIn")

                let isUserLogged = getBoolFromUserDefaults(forKey: "isUserLoggedIn")
                print("Is user logged in? \(isUserLoggedIn)")
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

    // Function to retrieve boolean value from UserDefaults
    func getBoolFromUserDefaults(forKey key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: key)
    }

}

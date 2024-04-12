import Foundation
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject {
    var session: WCSession
    
    @Published var recordAudio: String = ""
    
    enum WatchReceiveMethod: String {
        case sendCounterToNative
    }
    
    enum WatchSendMethod: String {
        case sendCounterToFlutter
    }
    
    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            // Handle the case where Watch Connectivity is not supported on this device
            fatalError("Watch Connectivity is not supported on this device.")
        }
        super.init()
        session.delegate = self
        session.activate()
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
           case .inactive:
               print("Unable to activate the WCSession. Error: \(error?.localizedDescription ?? "--")")
           case .notActivated:
               print("Unexpected .notActivated state received after trying to activate the WCSession")
           @unknown default:
               print("Unexpected state received after trying to activate the WCSession")
           }
       }
   
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let method = message["method"] as? String,
                  let enumMethod = WatchReceiveMethod(rawValue: method) else {
                return
            }

            switch enumMethod {
            case .sendCounterToNative:
                self.recordAudio = message["data"] as? String ?? ""
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
    

}

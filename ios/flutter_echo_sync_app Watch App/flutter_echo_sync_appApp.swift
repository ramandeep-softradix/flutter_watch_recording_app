//
//  flutter_echo_sync_appApp.swift
//  flutter_echo_sync_app Watch App
//
//  Created by Jaskaran Softradix on 10/04/24.
//

import SwiftUI

@main
struct flutter_echo_sync_app_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(watchOS 8.0, *) {
                ContentView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

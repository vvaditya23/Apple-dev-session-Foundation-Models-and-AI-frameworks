/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App initializer
*/

import SwiftUI
import FoundationModels

@main
struct FMSampleApp: App {
    var body: some Scene {
        WindowGroup {
            switch SystemLanguageModel.default.availability {
            case .available:
                ContentView()
            case .unavailable(let reason):
                UnavailableView(reason: reason)
            }
        }
    }
}

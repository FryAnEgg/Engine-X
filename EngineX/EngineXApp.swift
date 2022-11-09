//
//  EngineXApp.swift
//  EngineX
//
//  Created by Dave Lathrop on 7/22/22.
//

import SwiftUI

@main
struct EngineXApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

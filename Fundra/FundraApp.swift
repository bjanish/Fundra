//
//  FundraApp.swift
//  Fundra
//
//  Created by Brian Janish on 6/10/26.
//

import SwiftUI
import SwiftData
import LocalAuthentication
import UIKit

@main
struct FundraApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Category.self,
            Balance.self,
        ])
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.fundra.shared")!
        let storeURL = groupURL.appending(path: "Fundra.store")
        
        // Migrate existing data to shared container on first launch
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: storeURL.path) {
            // Check for existing default store
            let defaultStoreURL = URL.applicationSupportDirectory.appending(path: "default.store")
            if fileManager.fileExists(atPath: defaultStoreURL.path) {
                try? fileManager.copyItem(at: defaultStoreURL, to: storeURL)
                // Also copy the WAL and SHM files if they exist
                let walURL = defaultStoreURL.appendingPathExtension("wal")
                let shmURL = defaultStoreURL.appendingPathExtension("shm")
                if fileManager.fileExists(atPath: walURL.path) {
                    try? fileManager.copyItem(at: walURL, to: storeURL.appendingPathExtension("wal"))
                }
                if fileManager.fileExists(atPath: shmURL.path) {
                    try? fileManager.copyItem(at: shmURL, to: storeURL.appendingPathExtension("shm"))
                }
            }
        }
        
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isUnlocked {
                ContentView()
            } else {
                LockScreenView(isUnlocked: $isUnlocked)
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                isUnlocked = false
            }
        }
    }
    
}

struct LockScreenView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isUnlocked: Bool
    @State private var authFailed = false
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(UIColor.systemBackground))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
                
                HStack(alignment: .center, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill([
                                    Color(red: 0.43, green: 0.60, blue: 0.76),
                                    Color(red: 0.54, green: 0.73, blue: 0.63),
                                    Color(red: 0.76, green: 0.68, blue: 0.58),
                                ][index])
                                .frame(width: 4, height: [6, 10, 16][index])
                        }
                    }
                    .frame(width: 16, height: 16)
                    
                    Text("Fundra")
                        .font(.system(size: 28, weight: .bold))
                        .italic()
                        .foregroundColor(Color(red: 0.43, green: 0.60, blue: 0.76))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                if authFailed {
                    Text("Authenticate to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Try Again") {
                        authenticate()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            authenticate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        #if DEBUG
        if screenshotMode || debugMode {
            isUnlocked = true
            return
        }
        #endif
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Fundra to view your savings") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        isUnlocked = true
                        authFailed = false
                    } else {
                        authFailed = true
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // Fall back to passcode
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Fundra to view your savings") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        isUnlocked = true
                        authFailed = false      
                    } else {
                        authFailed = true
                    }
                }
            }
        } else {
            // No authentication available (e.g., Simulator with no passcode) — unlock automatically
            isUnlocked = true
        }
    }
}

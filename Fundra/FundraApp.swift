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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
                
                Text("Fundra")
                    .font(.title)
                    .fontWeight(.bold)
                
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

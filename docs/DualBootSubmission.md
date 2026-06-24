# Dual-Boot Setup & App Store Submission

## Phase 1: Create Stable macOS Volume

1. Open **Disk Utility** (Applications → Utilities)
2. In the sidebar, select your main APFS container (usually "Macintosh HD")
3. Click the **+** button above "Volume" to add a new APFS volume
4. Name it **"Production Stable"**
5. Format: APFS (default)
6. Click **Add** — no size reservation needed, it shares your existing free space

## Phase 2: Install Stable macOS

1. Open the **Mac App Store** and search for the latest stable macOS (e.g., macOS Sequoia 15)
2. Download the installer (it will appear in Applications as "Install macOS Sequoia")
3. Run the installer
4. When asked to choose a destination, select **"Production Stable"**
5. Follow the setup prompts — create a user account (can be same name/password)
6. Wait for installation to complete (~30-45 minutes)

## Phase 3: Boot into Stable Volume

1. Shut down your Mac
2. Hold the **Power button** until you see "Loading startup options"
3. Select **"Production Stable"** and click Continue
4. You're now on stable macOS

## Phase 4: Install Stable Xcode

1. Open the **Mac App Store** on the stable volume
2. Download **Xcode** (the stable release, not beta)
3. Launch Xcode once to complete setup (agree to license, install components)
4. Verify: Xcode → About Xcode → should show stable version (e.g., 16.x)

## Phase 5: Open & Build Fundra

1. Navigate to your Fundra project (it's on the same disk, accessible from both volumes)
2. Open **Fundra.xcodeproj** in stable Xcode
3. Set the deployment target to iOS 17.0 (or whatever stable iOS you want to support)
4. Try building: **⌘B**
5. If errors appear — note them and I'll help fix any beta-only API usage

## Phase 6: Archive & Submit

1. Select **Any iOS Device** as the build target (not a simulator)
2. **Product → Archive**
3. Once archived, the Organizer window opens
4. Click **Distribute App**
5. Choose **App Store Connect**
6. Follow the prompts (sign with your Apple Developer account)
7. Upload completes → go to App Store Connect website to finish submission

## Phase 7: App Store Connect

1. Log into **appstoreconnect.apple.com**
2. Select Fundra
3. Fill in: description, keywords, screenshots, privacy policy URL
4. Select the uploaded build
5. Click **Submit for Review**

## Switching Back to Beta

1. Shut down
2. Hold **Power button** → select your beta volume
3. You're back in Xcode 27 beta for development

## Notes

- Both volumes share the same physical storage — no wasted space
- Your project files are accessible from both volumes (same disk)
- Keep the stable volume minimal (just Xcode + essentials)
- After Xcode 27 goes GM in September, you can delete the stable volume

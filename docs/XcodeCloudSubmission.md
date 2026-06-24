# Xcode Cloud — App Store Submission

## Overview
Use Apple's Xcode Cloud CI/CD to build and submit Fundra from Apple's servers using stable Xcode, bypassing your local macOS 27 beta limitation.

## Prerequisites
- Apple Developer Program membership (you already have this)
- Code in a Git repository (GitHub, GitLab, or Bitbucket)
- App Store Connect app record created for Fundra

## Phase 1: Push Code to GitHub

1. Create a GitHub account if you don't have one (github.com)
2. Create a new **private** repository named "Fundra"
3. In Terminal, navigate to your Fundra project folder:
   ```
   cd /Users/brianjanish/Documents/repo/0-payload/Fundra
   ```
4. Connect your local repo to GitHub:
   ```
   git remote add origin https://github.com/YOUR_USERNAME/Fundra.git
   ```
5. Push your code:
   ```
   git push -u origin main
   ```
   (or `0-payload` — whatever your branch is called)

## Phase 2: Set Up App in App Store Connect

1. Go to **appstoreconnect.apple.com**
2. Click **My Apps → +** to create a new app
3. Fill in:
   - Platform: iOS
   - Name: Fundra
   - Primary Language: English
   - Bundle ID: (must match your Xcode project's bundle identifier)
   - SKU: fundra-001 (or any unique string)
4. Save — don't worry about filling everything else yet

## Phase 3: Configure Xcode Cloud

1. Open your Fundra project in **Xcode 27** (your local beta is fine for configuration)
2. Go to **Product → Xcode Cloud → Create Workflow**
3. Sign in with your Apple ID if prompted
4. Connect your GitHub repository when asked
5. Configure the workflow:
   - **Start Condition:** Manual (so you control when it runs)
   - **Environment:**
     - Xcode Version: **Release** (not beta — this is the key)
     - macOS Version: Latest Release
   - **Actions:**
     - Archive → iOS
     - Post-Action: Upload to App Store Connect
6. Save the workflow

## Phase 4: Run the Build

1. In Xcode, go to **Report Navigator** (the last tab in the left sidebar)
2. Find your Xcode Cloud workflow
3. Click **Start Build** (or push a commit if you set it to trigger on push)
4. Wait for Apple's servers to build your app (~5-15 minutes)
5. Check the build log for success or errors

## Phase 5: Handle Build Errors (If Any)

If the build fails because of beta-only APIs:
- Read the error log in Xcode Cloud
- Fix the offending code locally
- Push the fix to GitHub
- Re-run the workflow

Common fixes:
- Replace new SwiftUI modifiers with iOS 17/18 equivalents
- Adjust deployment target to match stable SDK

## Phase 6: Submit from App Store Connect

1. Once the build succeeds, go to **appstoreconnect.apple.com**
2. Select Fundra
3. Under **Build**, select the uploaded build from Xcode Cloud
4. Fill in all required metadata:
   - Description (from AppStoreListing.md)
   - Keywords (from AppStoreListing.md)
   - Screenshots (light + dark mode)
   - Privacy Policy URL
   - App Review notes: "No login required. Face ID unlocks the app."
5. Click **Submit for Review**

## Phase 7: Wait for Review

- Typical review time: 24-48 hours
- If rejected, read the rejection reason and fix
- Re-submit as needed

## Notes
- Xcode Cloud free tier: 25 compute hours/month (plenty for this)
- Your local Xcode 27 beta is fine for day-to-day development
- Only the Xcode Cloud build needs to use stable Xcode
- Your code stays private in your GitHub repo
- Re-add the date restriction before submitting (currently removed for testing)

## Before Submitting Checklist
- [ ] Date restriction re-enabled (`in: ...Date()`)
- [ ] App Store description and keywords finalized
- [ ] Privacy policy hosted at a URL
- [ ] Screenshots taken (light + dark)
- [ ] Bundle ID matches App Store Connect
- [ ] Version number set to 1.0.0
- [ ] Build number incremented

## Releasing an Update (1.1+)

Since everything is already set up, future releases are just:

1. Bump version number in Xcode (target → General)
2. Turn off screenshot mode → test as a real user in Simulator
3. Turn screenshot mode back on (for future screenshot sessions)
4. Commit and push to GitHub
5. Run Xcode Cloud workflow
6. In App Store Connect: select new build, add "What's New" text, submit

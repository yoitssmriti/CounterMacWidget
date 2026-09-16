# Job Counter

A macOS SwiftUI app and desktop widget for tracking job-application counts together, with local App Group storage and optional Firebase Firestore sync.

---
## For App Creator

### 1. Firebase Backend Setup

Set up a shared database so application counts sync across both Macs in real time.

1. Go to the [Firebase Console](https://console.firebase.google.com/) and click **Add Project**.
2. Name the project `JobCounter` and disable Google Analytics.
3. Under **Build**, select **Firestore Database** and click **Create Database**.
4. Choose **Start in test mode** so read/write rules are open during setup.
5. In Firestore, create a collection named `counters` with a single document ID `competition`:
   * Field: `smriti` (Number) = `0`
   * Field: `roshan` (Number) = `0`
6. Click the gear icon next to **Project Overview** → **Project settings**.
7. Under *Your apps*, click the **iOS/macOS** icon to register an app (Bundle ID e.g., `com.yourname.JobCounter`).
8. Download the `GoogleService-Info.plist` file and keep it ready for Xcode.

### 2. Project Setup (Xcode)

1. Open `JobCounter.xcodeproj` in Xcode.
2. Drag `GoogleService-Info.plist` into your Xcode project navigator (ensure it is checked for all targets).
3. Under **Signing & Capabilities** for both **JobCounter** and **JobCounterWidget**:
   * Enable **Automatically manage signing** under your free Personal Team.
   * Enable **App Groups** and check `group.com.jobcounter.app`.
   * Click **`+ Capability`**, search for **Hardened Runtime**, and add it to both targets.
4. Set the run destination in the top toolbar to **My Mac** and press `⌘R` to build and verify local execution.
5. Add it as you would any widget to your desktop.
6. Open a terminal, navigate to your JobCounter project root directory, and run
```bash
   chmod +x installer.sh
```
then run
```bash
   ./installer.sh
```
Your Mac will now automatically re-sign your widget in the background every 5 days so it never expires!

### 3. Distribute app

1. In the Xcode toolbar, set the run destination to **Any Mac** (or your Mac if “Any Mac” isn’t listed).
2. Choose **Product → Archive**. Wait for the archive to finish; the **Organizer** window should open.
3. In **Organizer**, select the new archive → **Distribute App**.
4. Choose **Copy App** (or **Custom** → option that exports a local macOS app, depending on your Xcode version).
5. Finish the wizard and pick an export folder.
6. You should get a folder containing **`JobCounter.app`**.

### 4. Zip the app and send it

1. In Finder, locate `JobCounter.app`.
2. Right‑click → **Compress “JobCounter.app”** to create `JobCounter.app.zip`.
3. Right-click your JobCounter project folder (the whole folder containing JobCounter.xcodeproj and installer.sh) → Compress.
4. Send him the two files:
   * JobCounter.app.zip (the standalone app you already exported)
   * JobCounter-Project.zip (the project folder containing installer.sh)

---

## For App Receiver

### 1. Receive and Install App
1. Download both the archives.
2. Drag **`JobCounter.app`** into `/Applications`.
3. Run the quarantine bypass command below in your terminal before opening the app:

```bash
xattr -cr /Applications/JobCounter.app
```

Then open **Job Counter** from Applications.

### 2. Add the Desktop Widget
1. Right-click anywhere on your empty desktop background and select Edit Widgets...
2. Search for JobCounter in the left sidebar.
3. Drag the Medium widget onto your desktop and click Done.

### 3. One-Time Auto-Refresher Setup (Keeps Widget Active Forever)
1. Unzip `JobCounter-Project.zip` and place the folder anywhere you like (e.g., your home folder or Documents).
2. Open Xcode on your Mac, go to Xcode → Settings… → Accounts, click +, and sign in with your Apple ID.
3. Open Terminal, drag and drop the unzipped project folder into Terminal after typing cd  (e.g., cd /path/to/JobCounter-Project), and hit Enter.
4. Run this single installation command:
```bash
./installer.sh
```

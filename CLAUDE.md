# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Job Counter is a macOS (14.0+) SwiftUI app plus a desktop widget for tracking job-application counts for two people ("Smriti" / "Roshan"), stored locally in App Group UserDefaults and optionally synced through Firebase Firestore (`counters/competition` document with `smriti` / `roshan` fields; legacy `myCount` / `partnerCount` fields are still read as a fallback).

## Commands

The Xcode project is generated from `project.yml` with XcodeGen. After editing `project.yml`, regenerate:

```bash
xcodegen generate
```

Build (Firebase SPM packages resolve on first build; may take a while):

```bash
xcodebuild -project JobCounter.xcodeproj -scheme JobCounter -configuration Release build
```

There are no tests (`testTargets: []` in project.yml) and no linter configured.

`installer.sh` is an end-user script that installs a launchd agent (`com.jobcounter.refresh`) to rebuild and re-sign the app every 5 days so free-Apple-ID signing doesn't expire. It rewrites `/Applications/JobCounter.app` — don't run it as part of development.

## Architecture

Two targets defined in `project.yml`:

- **JobCounter** (app): SwiftUI app with Firebase sync. Embeds the widget extension.
- **JobCounterWidget** (app-extension): systemMedium desktop widget. Deliberately has **no Firebase dependency** — Firebase in the appex bloats it ~20MB and can knock it out of the macOS widget gallery. It compiles a subset of app sources (`AppGroup.swift`, `LocalCounterManager.swift`, `CounterIntents.swift`) with the `JOBCOUNTER_WIDGET` compilation condition; code shared into the widget must guard Firebase usage with `#if !JOBCOUNTER_WIDGET` (see `CounterIntents.swift`).

Data flow:

1. `LocalCounterManager` is the single source of truth, persisting `CounterData` as JSON in App Group UserDefaults (`AppGroup.shared`, which probes the suite and falls back to `.standard` if the group isn't provisioned).
2. App UI (`ContentView`) and widget buttons (AppIntents in `CounterIntents.swift`) mutate through `LocalCounterManager`, then push both counts to Firestore (app builds only) and call `WidgetCenter.shared.reloadAllTimelines()`.
3. `FirestoreSyncService` (app only) listens to `counters/competition`, mirrors remote snapshots into `LocalCounterManager`, reloads widget timelines, and posts `FirestoreSyncService.didUpdateNotification` which `ContentView` observes.
4. The widget's `JobCounterTimelineProvider` just reads `LocalCounterManager` — it never talks to the network; it sees cloud updates only because the app writes them into the App Group.
5. Widget button clicks only write to the App Group (no Firebase in the appex), so `FirestoreSyncService` KVO-observes the shared `counterData` key cross-process and forwards widget-made changes to Firestore. `lastCloudData` guards against echoing the service's own cloud-snapshot writes back to the cloud — keep that ordering (`lastCloudData` set before `localManager.data`). This forwarding only works while the app is running.

Firebase specifics:

- `FirebaseBootstrap.configureIfPossible()` is safe to call from anywhere and no-ops when `GoogleService-Info.plist` is absent — the app must keep working locally without Firebase.
- Firestore is forced to `MemoryCacheSettings()`: LevelDB persistence crashes under the App Sandbox when it can't take an exclusive lock. Don't re-enable disk persistence.
- `FirestoreSyncService.intValue` exists because Firestore boxes numbers as Int/Int64/Double/NSNumber; don't replace it with a plain `as? Int` cast.

The App Group suite is `M385RN2SR8.com.jobcounter.app` — it must match in `AppGroup.swift`, both `.entitlements` files, and both targets' entitlements in `project.yml`. The Team-ID prefix is required on macOS: iOS-style `group.*` IDs trigger a user-consent prompt that the widget process can never show, so its App Group access gets silently denied (widget buttons appear dead).

Free-Apple-ID provisioning profiles expire after 7 days; when they do, macOS silently drops the widget from the widget gallery. The fix is rebuilding (fresh profile) and reinstalling to `/Applications` — that's what the `installer.sh` launchd job automates.

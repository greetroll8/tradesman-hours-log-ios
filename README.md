# Tradesman Hours Log

An iPhone time- and materials-tracking app for tradespeople. Track jobs per client,
run a persistent job timer, log materials and notes, and export weekly PDF/CSV reports.
Fully localized into English, Russian, German, Spanish, and French.

## Stack

- SwiftUI, iOS 16+, iPhone-only.
- State: `Codable` model structs + an `ObservableObject` store (`AppStore`) with
  `@Published` arrays, persisted as a single JSON document in the app-support directory.
  No SwiftData / CoreData.
- PDFKit (report PDFs), StoreKit (paywall stub), UserNotifications (long-timer reminder),
  PhotosUI (photo import).
- Project is generated with **XcodeGen** from `project.yml` (no committed `.xcodeproj`).
- CI via `codemagic.yaml`.

## Prerequisites

- macOS with Xcode 15+ (iOS 16 SDK or newer).
- [XcodeGen](https://github.com/yonyz/XcodeGen): `brew install xcodegen`.

## Build locally

```sh
cd "Tradesman Hours Log"
xcodegen generate
open TradesmanHoursLog.xcodeproj
```

Then select the `App` scheme and run on an iPhone simulator (iOS 16+).

Command-line simulator build (matches the `ios_simulator_build` CI workflow):

```sh
xcodegen generate
xcodebuild build \
  -project TradesmanHoursLog.xcodeproj \
  -scheme App \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

## CI / TestFlight

`codemagic.yaml` defines two workflows:

- **ios_simulator_build** — generates the project and builds for the iOS Simulator
  with code signing disabled. Use for PR validation.
- **ios_testflight** — uses the Codemagic `app_store_connect` integration for signing,
  builds an IPA with `xcode-project build-ipa`, and publishes to TestFlight.
  Set up an App Store Connect API key integration named `AppStoreConnectKey` and replace
  the placeholder `APP_STORE_APPLE_ID` with the real app's Apple ID.

## Project structure

```
project.yml                     XcodeGen spec (bundle id, Info.plist, build settings)
codemagic.yaml                  CI workflows
Resources/
  Info.plist                    CFBundleLocalizations + usage strings
  Localizable.xcstrings         String Catalog (en base + ru/de/es/fr, with plurals)
  Assets.xcassets/              AppIcon (1024 PNG, #0F6B5F) + AccentColor
Sources/
  App.swift                     @main entry, wires AppStore / TimerController / SubscriptionManager
  Models/Models.swift           Codable structs (Client, Job, TimeBlock, Material, ...)
  Store/AppStore.swift          ObservableObject persistence + CRUD
  Store/TimerController.swift   Persistent timer (elapsed derived from startAt)
  Paywall/                      SubscriptionManager (gating) + PaywallView
  Export/                       ReportBuilder, CSVExporter, PDFExporter
  Util/                         Formatting, NotificationManager, ShareSheet, PhotoPicker
  Views/                        TabView + Today / Jobs / Clients / Reports / Settings / forms
```

## Notes on behavior

- **Persistent timer**: the running time block stores `startAt`; elapsed time is always
  computed as `now - startAt`, so it is correct across backgrounding and relaunch.
- **Rounding**: raw `durationMinutes` is stored on every time block. Reports apply the
  Settings rounding rule (none / 5 / 10 / 15 min, rounded up) to billed time only.
- **Free tier**: 2 active clients and 3 PDF exports. The paywall unlock is a StoreKit
  stub that records the entitlement locally; gating limits are fully enforced.
- **Localization**: all user-facing text uses `LocalizedStringKey` / `String(localized:)`
  resolved from `Localizable.xcstrings`. Dates, numbers, and currency use locale-aware
  `FormatStyle`.

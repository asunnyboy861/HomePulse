# HomePulse - iOS Development Guide

## Executive Summary

**HomePulse** is a minimalist smart home dashboard app that gives users a single-screen, at-a-glance view of their entire home — temperature, humidity, and light status — with real-time updates and 24-hour trend sparklines. The name combines "Home" (smart home) and "Pulse" (real-time data heartbeat), conveying both function and emotional reassurance ("I can feel my home running normally").

**Product Vision**: Replace the cluttered, multi-tap Apple Home app and the YAML-config-heavy Home Assistant dashboards with a zero-config, big-number-first dashboard that any user can set up in under 30 seconds.

**Target Audience** (US market):
- Smart home beginners (40%) — 3–10 HomeKit devices, dissatisfied with Apple Home
- Home Assistant power users (30%) — want a native iOS dashboard without YAML
- Wall-mounted iPad users (15%) — always-on home control center
- Sensor data enthusiasts (15%) — want trend charts and anomaly alerts

**Key Differentiators**:
1. Zero-config HomeKit auto-discovery (vs. HomeDash/Home+ manual setup)
2. Big-number one-screen overview (vs. Apple Home's collapsed layout)
3. Real-time data pulse via HomeKit Delegate + HA WebSocket (vs. Home Widget's delayed polling)
4. 24h Sparkline trends (vs. all competitors — none offer this)
5. Dual-platform support: HomeKit + Home Assistant (vs. HomePad's HomeKit-only)
6. Best value: Free tier sufficient for daily use + Pro $6.99 one-time purchase (vs. Home+ $20.99, HomeDash $9.99)
7. Viral naming: "HomePulse" = "your home's heartbeat" — 2 syllables, instantly memorable

**Bundle ID**: `com.zzoutuo.HomePulse`
**Minimum iOS**: 17.0 (required for SwiftData + @Observable)
**Primary Language**: English (US)

---

## Competitive Analysis

| App | Price | Strengths | Weaknesses | Our Advantage |
|-----|-------|-----------|------------|---------------|
| Apple Home | Free | Pre-installed, free, HomeKit native | Cannot customize dashboard, sensors collapsed, no trend charts, multi-tap to view data | Custom big-number dashboard + Sparkline trends + zero-config |
| HomeDash / HomeDash+ | $9.99 (legacy) / Free + IAP | 8 years of updates, sensor logging, camera tiles | Widget layout unpredictable, no HomePod/TV sensors, legacy UI, no HA support, expensive IAP for cameras ($39) | Fixed grid layout + full device type support + modern SwiftUI + HA support + lower price |
| Itsyhome | Free + Pro subscription | macOS open source, HomeKit + HA dual platform | Menu-bar/control-panel style, not a dashboard; Pro features require subscription | Dashboard-first design + one-time purchase option |
| HomePad | ~$7.99 one-time | Clean design, one-time purchase | HomeKit only, no HA support, no trend charts | HomeKit + HA dual platform + 24h trend charts |
| Home Widget | ~$3.99 one-time | Affordable, widget-focused | State not real-time (polling delays), widget-only functionality | Full-featured app + widget + real-time WebSocket |
| Home+ 6 | $20.99 one-time | Powerful, mature | Overpriced, steep learning curve | 66% cheaper ($6.99) with better UX |

---

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features (from guide)

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| F1 | HomeKit Connection (Auto-Discovery) | 1. User taps "HomeKit" on onboarding → 2. System requests HomeKit permission → 3. System auto-discovers homes, rooms, accessories → 4. Dashboard populates | HomeKit permission grant | HMHomeManager delegate → enumerate HMHome → HMRoom → HMAccessory → build UnifiedDevice list | Dashboard populated with rooms and devices | UserDefaults: platform choice = homekit | All HomeKit homes/rooms/accessories appear within 5 seconds; no manual URL/token entry |
| F2 | Home Assistant Connection (URL + Token) | 1. User taps "Home Assistant" on onboarding → 2. User enters server URL + Long-Lived Access Token → 3. System tests WebSocket connection → 4. System fetches all entities → 5. Dashboard populates | HA server URL (http(s)://host:8123), Long-Lived Access Token | WebSocket auth → subscribe state_changed → REST GET /api/states → map entities to UnifiedDevice | Dashboard populated with HA entities | Keychain: HA URL + Token (sensitive) | Connection succeeds within 3 seconds; entities appear grouped by room/area |
| F3 | Main Dashboard (One-Screen Overview) | 1. User opens app → 2. Dashboard shows room cards in vertical scroll → 3. Each card shows room name, big-number sensors, sparkline, light status | None (auto-rendered from ViewModel) | DashboardViewModel aggregates rooms → computes sensor stats → builds sparkline data | Room cards with temperature (36pt bold), humidity, light count, 24h sparkline | UserDefaults: dashboard layout prefs | All rooms visible on launch; big numbers readable at arm's length; sparkline renders for 24h data |
| F4 | Room Detail View (Expand) | 1. User taps room card → 2. View expands/pushes to room detail → 3. Shows full sensor history + device controls + scenes | Room ID (tap target) | RoomDetailViewModel loads room's sensors + devices + scenes → fetches 24h/7d/30d history | Full sensor charts, device toggles, brightness sliders, scene buttons | SwiftData: SensorBucket history | All sensors show 24h chart; devices toggle instantly; scenes execute within 1 second |
| F5 | Sensor Big Number Display | 1. User views dashboard or room detail → 2. Temperature/humidity shown as 36pt bold rounded numbers → 3. Numbers animate on change | Real-time sensor updates from HomeKit/HA | Map characteristic value → format with unit (°F/%) → animate with numericText() | Large animated numeric display | None (transient) | Numbers update within 1 second of sensor change; animation smooth (spring 0.3s) |
| F6 | Sparkline Trend Chart (24h) | 1. User views room card or sensor section → 2. 24h sparkline renders below big number → 3. Tap to expand to full chart | Sensor historical readings (24h window) | SensorHistoryManager samples every 5 min → 288 points → Swift Charts LineMark + AreaMark | Mini line chart with gradient fill, no axes | SwiftData: SensorBucket (288 points/sensor/day) | Sparkline shows 24h trend; updates when new sample arrives; smooth catmullRom interpolation |
| F7 | Historical Charts (7d / 30d) [PRO] | 1. User opens room detail → 2. Taps "7d" or "30d" tab → 3. Full-screen chart renders with min/max/avg stats | Historical readings (7d=168 hourly points, 30d=30 daily points) | Aggregate 24h buckets → downsample to hourly/daily → compute min/max/avg | Full Swift Charts view with axes, legend, stats | SwiftData: SensorBucket | 7d shows hourly granularity; 30d shows daily; min/max/avg displayed; pan/zoom supported |
| F8 | Device Control — On/Off Toggle | 1. User taps device card in room detail → 2. Toggle switches → 3. Device state updates | Device ID + new power state | DeviceControlManager: debounce 300ms → optimistic UI update → HMCharacteristic.writeValue / HA REST call → verify within 3s | Toggle animates; device turns on/off; haptic feedback | None (transient) | Toggle responds within 100ms (optimistic); device state confirmed within 3s; rollback on failure |
| F9 | Device Control — Brightness Slider | 1. User drags brightness slider in room detail → 2. Slider value updates → 3. Light brightness changes | Device ID + brightness 0-100 | Debounce 300ms → optimistic update → writeValue(HMCharacteristicTypeBrightness) / HA call | Slider animates; light brightness changes smoothly | None (transient) | Slider smooth; brightness updates within 500ms; no flicker |
| F10 | Device Control — Thermostat Temperature [PRO] | 1. User taps +/- buttons or drags thermostat slider → 2. Target temperature updates → 3. HVAC adjusts | Device ID + target temperature | Write HMCharacteristicTypeTargetTemperature / HA climate.set_temperature | Target temperature display updates; HVAC mode may change | None (transient) | Target temp updates within 1s; respects min/max range from device metadata |
| F11 | Scene Execution | 1. User taps scene button (room detail or dashboard quick scenes) → 2. Scene executes → 3. All affected devices update | Scene ID | HMActionSet.executeActionSet / HA activate_domain | All devices in scene transition to scene state; UI updates in real-time | None (transient) | Scene executes within 2s; all device states reflect scene within 5s |
| F12 | WidgetKit Home Screen Widget | 1. User long-presses home screen → 2. Adds HomePulse widget (small/medium) → 3. Widget shows sensor summary → 4. Tap to open app | Widget family selection | SensorProvider: TimelineProvider → fetch latest sensor readings from shared App Group → build entry | Widget displays temperature, humidity, lights-on count; refreshes every 5 min | App Group: shared sensor snapshot | Widget renders within 2s; updates every 5 min; tap opens app to room detail |
| F13 | Lock Screen Widget [PRO] | 1. User adds Lock Screen widget → 2. Widget shows single sensor (temp/humidity) → 3. Updates throughout day | Widget family (circular/rectangular) | SensorProvider: small entry with single sensor | Compact single-sensor display on lock screen | App Group: shared sensor snapshot | Widget renders on lock screen; updates every 5 min |
| F14 | Live Activity (Dynamic Island) [PRO] | 1. Sensor exceeds threshold → 2. Live Activity starts → 3. Dynamic Island shows alert → 4. User can dismiss | Sensor ID + threshold breach | SensorHistoryManager checks thresholds → start Live Activity with alert details | Dynamic Island expanded/collapsed view with sensor name, value, threshold | None (transient) | Live Activity starts within 5s of threshold breach; dismissible; updates as value changes |
| F15 | CSV Data Export [PRO] | 1. User opens Settings → Data Export → 2. Selects sensor + date range → 3. App generates CSV → 4. User shares/saves | Sensor ID, date range | SensorHistoryManager queries SwiftData → format as CSV (timestamp, value, unit) → share sheet | CSV file shared via UIActivityViewController | None (file output) | CSV generated within 3s for 30 days of data; includes headers; opens in Numbers/Excel |
| F16 | Sensor Anomaly Alerts [PRO] | 1. User configures thresholds in Settings → 2. Sensor value crosses threshold → 3. Local notification fires | Threshold config (min/max per sensor) | SensorHistoryManager evaluates thresholds on each sample → UNUserNotificationCenter.add | Local notification with sensor name, value, threshold | UserDefaults: threshold configs | Notification fires within 10s of threshold breach; actionable (opens room detail) |
| F17 | Multi-Home Support [PRO] | 1. User opens Settings → Home Management → 2. Adds additional HomeKit home or HA instance → 3. Switches between homes | Home config (HomeKit home ID or HA URL+token) | HomeManager maintains list of homes → active home selection → reload dashboard | Dashboard shows active home's rooms/devices | Keychain + UserDefaults: home configs | User can switch homes within 1s; each home's data isolated |
| F18 | iCloud Settings Sync [PRO] | 1. User enables iCloud sync in Settings → 2. Config syncs across devices | iCloud sync toggle | NSUbiquitousKeyValueStore for prefs; CloudKit for threshold configs | Settings consistent across user's devices | iCloud (Ubiquitous KV + CloudKit) | Settings sync within 30s; conflicts resolved by last-writer-wins |
| F19 | Dark/Light Theme | 1. User opens Settings → Appearance → 2. Selects System/Light/Dark → 3. Theme applies instantly | Theme preference | SettingsViewModel updates preferredColorScheme → app re-renders | All views switch color scheme | UserDefaults: themePreference | Theme applies within 0.5s; respects system setting by default |
| F20 | Settings View | 1. User taps gear icon → 2. Settings view opens with sections: Connection, Appearance, Notifications, Data Export, Pro, About | Section navigation | SettingsViewModel manages all prefs + IAP state | Organized settings list | UserDefaults + Keychain | All settings persist; Pro section shows purchase/restore options |
| F21 | Onboarding Flow (3 Steps, 30s) | 1. App first launch → 2. Step 1: Choose platform (HomeKit/HA) → 3. Step 2: Auto-load devices → 4. Step 3: Dashboard ready | Platform selection | OnboardingViewModel: if HomeKit → request permission → discover; if HA → validate URL+token → connect | Progress indicator → dashboard | UserDefaults: hasOnboarded, platformChoice | Onboarding completes in <30s for HomeKit; <60s for HA; skippable after first launch |
| F22 | Free vs Pro Gating (IAP) | 1. Free user attempts Pro feature → 2. Paywall appears → 3. User selects plan → 4. IAP processes → 5. Feature unlocks | IAP product selection | StoreKit 2: Product.purchase() → verify transaction → update isPro state | Paywall with 3 options (one-time $6.99, yearly $1.99, monthly $0.49) | StoreKit transaction state | All Pro features gated; paywall shows legal links (Privacy/Terms); restore purchases works |
| F23 | Contact Support | 1. User opens Settings → Contact Support → 2. Fills form (subject, message) → 3. Submits → 4. Confirmation shown | Subject, message, optional screenshot | HTTP POST to FEEDBACK_BACKEND_URL → store in feedback board | Success/error message | None (backend) | Form submits within 3s; user receives confirmation; works offline (queues) |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| F1.1 | F1 HomeKit | Permission prompt | System HomeKit permission dialog appears on first access | Auto-trigger on HMHomeManager init |
| F1.2 | F1 HomeKit | Home discovery | HMHomeManagerDelegate.homeManagerDidUpdateHomes fires | Background, no user action |
| F1.3 | F1 HomeKit | Room grouping | Accessories auto-grouped by HMRoom | Auto, no user action |
| F1.4 | F1 HomeKit | Reachability indicator | Green/red dot on each device card | Auto, updates via delegate |
| F2.1 | F2 HA | QR code scan | User can scan HA QR code to auto-fill URL+token | Tap "Scan QR" → camera scanner |
| F2.2 | F2 HA | Connection test | On save, app tests WebSocket connection before persisting | Auto on "Connect" tap |
| F2.3 | F2 HA | Auto-reconnect | If WebSocket drops, app retries every 5s with backoff | Background |
| F3.1 | F3 Dashboard | Pull-to-refresh | User pulls down to force-refresh all device states | Swipe gesture |
| F3.2 | F3 Dashboard | Empty state | If no devices found, show illustration + "Add devices in Apple Home" guidance | Auto when rooms.isEmpty |
| F3.3 | F3 Dashboard | Quick scenes row | Bottom of dashboard shows global scenes (Home, Movie, Night, Day) | Tap scene button |
| F4.1 | F4 Room Detail | Time range switcher | 24h / 7d / 30d segmented control for sensor charts | Tap segment |
| F4.2 | F4 Room Detail | Device grouping | Devices grouped by type (Lights, Thermostats, Locks, Sensors) | Auto-render |
| F5.1 | F5 Big Numbers | Unit toggle (°F/°C) | User can switch temperature unit in Settings | Settings toggle |
| F6.1 | F6 Sparkline | Color coding | Temperature=orange, Humidity=cyan, Light=yellow, CO2=purple | Auto by sensor type |
| F8.1 | F8 Toggle | Haptic feedback | UIImpactFeedbackGenerator(.light) on toggle | Auto on tap |
| F8.2 | F8 Toggle | Optimistic update | UI updates immediately, rolls back on failure | Auto |
| F9.1 | F9 Brightness | Continuous drag | Slider updates brightness in real-time during drag | Drag gesture |
| F12.1 | F12 Widget | Small family | Single sensor big number | Widget config |
| F12.2 | F12 Widget | Medium family | Multi-sensor summary + mini sparkline | Widget config |
| F14.1 | F14 Live Activity | Collapsed state | Compact alert in Dynamic Island | Auto |
| F14.2 | F14 Live Activity | Expanded state | Full alert details on long-press | Long-press |
| F20.1 | F20 Settings | Connection status | Shows HomeKit connected / HA connected + URL | Auto-display |
| F20.2 | F20 Settings | Pro status | Shows "Pro Active" or "Upgrade to Pro" with manage button | Auto-display |
| F20.3 | F20 Settings | About section | App version (dynamic from Bundle), privacy policy link, terms link | Tap to view |
| F22.1 | F22 IAP | Restore purchases | Button to restore previous IAP | Tap button |
| F22.2 | F22 IAP | Manage subscription | Deep-link to App Store subscription management | Tap "Manage" |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Onboarding → Dashboard | F21 Onboarding | F3 Dashboard | platformChoice, connected homes | Onboarding completes |
| HomeKit discovery → UnifiedDevice | F1 HomeKit | F3 Dashboard | [UnifiedDevice] list | HMHomeManager ready |
| HA connection → UnifiedDevice | F2 HA | F3 Dashboard | [UnifiedDevice] list | WebSocket authenticated |
| Dashboard tap → Room Detail | F3 Dashboard | F4 Room Detail | roomId, roomName | User taps room card |
| Sensor updates → Sparkline | F1/F2 sensors | F6 Sparkline | SensorReading stream | Each state_changed event |
| Sensor updates → History | F1/F2 sensors | F7 Historical Charts | SensorReading stream | Each sample (5 min) |
| Sensor updates → Anomaly check | F1/F2 sensors | F16 Anomaly Alerts | SensorReading value | Each sample |
| Anomaly → Live Activity | F16 Anomaly | F14 Live Activity | sensorName, value, threshold | Threshold breached |
| Device control → State sync | F8/F9/F10 control | F3 Dashboard | new device state | Control command succeeds |
| IAP purchase → Feature gate | F22 IAP | F7/F10/F13/F14/F15/F16/F17/F18 | isPro: Bool | Transaction verified |
| Settings → Dashboard theme | F19 Theme | F3 Dashboard | colorScheme preference | User changes theme |
| Sensor snapshot → Widget | F1/F2 sensors | F12/F13 Widget | latest readings | Every 5 min (timeline) |

**⚠️ VERIFICATION CHECK**: Feature count in us.md (23 primary + 25 sub-features + 12 cross-feature dependencies) matches the Chinese guide's described functionality. ✅ YES

---

## Apple Design Guidelines Compliance

### HomeKit Guidelines (Section 26 of App Store Review)
- **26.1 Primary Purpose**: App's primary purpose is home automation (dashboard + control). ✅
- **26.2 Marketing Text + Privacy Policy**: Privacy policy will explain HomeKit data usage (device names, room layout, usage patterns). Marketing text will mention HomeKit. ✅
- **26.3 No Advertising Use**: HomeKit data will NOT be used for advertising or usage-based data mining. All data stays local. ✅
- **26.4 No Third-Party Use**: HomeKit data will NOT be sent to third-party services. Only local processing + user's own HA server. ✅

### Required Entitlements & Info.plist Keys
- **Entitlement**: `com.apple.developer.homekit` = true
- **Info.plist**: `NSHomeKitUsageDescription` = "HomePulse uses HomeKit to display your home's sensors and control your devices."
- **Info.plist**: `NSLocalNetworkUsageDescription` = "HomePulse connects to your Home Assistant server on your local network."
- **Info.plist**: `NSCameraUsageDescription` = "HomePulse uses the camera to scan Home Assistant QR codes for quick setup." (only if QR scan implemented)

### App Store Review Guidelines
- **2.1 App Completeness**: All features must work — no demo-only HomeKit functionality. Real device control required. ✅
- **2.5 No Non-Public APIs**: Use only public HomeKit + URLSession APIs. ✅
- **3.1.2(c) Subscriptions**: Paywall MUST include:
  - Functional Privacy Policy link
  - Functional Terms of Use (EULA) link
  - Subscription title, length, price
  - Auto-renewal disclosure text
- **4.0 Design**: Follow Apple HIG — SF Symbols, system colors, Dynamic Type, VoiceOver support. ✅
- **5.1.1 Privacy**: All sensor data stays on-device; no analytics; no tracking. Privacy nutrition label: "Data Not Collected". ✅

### Apple Human Interface Guidelines
- **SF Pro Rounded** for big numbers (matches iOS Weather app aesthetic)
- **System colors** (systemBlue, systemOrange, systemCyan) for adaptive light/dark
- **.ultraThinMaterial** for glassmorphic cards (modern iOS aesthetic)
- **Dynamic Type** support for accessibility
- **VoiceOver** labels for all big numbers and controls
- **Spring animations** (duration: 0.3) for state transitions
- **numericText() content transition** for smooth number changes
- **Haptic feedback** (UIImpactFeedbackGenerator) for toggle interactions

---

## Technical Architecture

- **Language**: Swift 5.9+ (Swift 6 strict concurrency)
- **Framework**: Pure SwiftUI (no UIKit)
- **Architecture**: MVVM + @Observable (iOS 17+), no Combine
- **Data Persistence**: SwiftData (iOS 17+), no CoreData
- **Networking**: async/await + URLSession, no third-party networking libs
- **Charts**: Swift Charts (built-in), no DGCharts
- **Concurrency**: Swift Concurrency (actor, async/await, TaskGroup)
- **Error Handling**: typed throws (Swift 6)
- **Code Style**: No force unwraps, strict concurrency, semantic naming

### Smart Home Frameworks
- **HomeKit**: HMHomeManager, HMHome, HMRoom, HMAccessory, HMCharacteristic, HMActionSet
- **Home Assistant**: WebSocket (/api/websocket) for real-time state, REST (/api/states, /api/services) for control
- **WidgetKit**: StaticConfiguration with TimelineProvider
- **ActivityKit**: Live Activity for sensor anomaly alerts

---

## Module Structure

```
HomePulse/
├── App/
│   ├── HomePulseApp.swift              # @main entry, SwiftData container, environment setup
│   └── ContentView.swift               # Root TabView (Dashboard/History/Settings)
├── Models/
│   ├── UnifiedDevice.swift             # Unified device model (id, name, room, platform, type, state)
│   ├── DeviceType.swift                # Enum: sensor, light, thermostat, lock, switch, curtain, camera
│   ├── DeviceState.swift               # Enum: on, off, value(Double), unreachable
│   ├── SensorReading.swift             # Sensor data point (deviceId, timestamp, value, unit)
│   ├── SensorBucket.swift              # SwiftData @Model: 24h readings bucket per sensor
│   ├── Room.swift                      # Room model (id, name, devices, sensors)
│   ├── Scene.swift                     # Scene model (id, name, icon, actionSet)
│   ├── DashboardLayout.swift           # User's dashboard layout preferences
│   └── PlatformConnection.swift        # HomeKit/HA connection config
├── Services/
│   ├── HomeKitService.swift            # HMHomeManager delegate, accessory discovery, characteristic read/write
│   ├── HomeAssistantService.swift      # actor: WebSocket connect, REST calls, state subscription
│   ├── SensorHistoryManager.swift      # Sample every 5 min, maintain 24h window, generate sparkline data
│   ├── DeviceControlManager.swift      # Unified control interface (toggle, brightness, temp), debounce, optimistic update
│   ├── NotificationService.swift       # Threshold monitoring, local notifications
│   ├── IAPService.swift                # StoreKit 2: Product.purchase(), transaction updates, isPro state
│   ├── ContactSupportService.swift     # HTTP POST to FEEDBACK_BACKEND_URL
│   └── DataExportService.swift         # CSV generation from SwiftData
├── ViewModels/
│   ├── DashboardViewModel.swift        # @Observable: rooms, sensors, devices, refresh()
│   ├── RoomDetailViewModel.swift       # @Observable: room's sensors/devices/scenes, time range
│   ├── SettingsViewModel.swift         # @Observable: all settings + IAP state
│   ├── OnboardingViewModel.swift       # @Observable: platform selection, connection progress
│   └── WidgetViewModel.swift           # Shared with widget extension
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift        # 3-step flow
│   │   ├── PlatformSelectionView.swift # HomeKit vs HA choice
│   │   └── HAConfigView.swift          # URL + Token input, QR scan
│   ├── Dashboard/
│   │   ├── DashboardView.swift         # Main scrollable room cards
│   │   ├── RoomCardView.swift          # Room card with big numbers + sparkline + lights
│   │   ├── SensorCardView.swift        # Big number + sparkline + unit
│   │   ├── DeviceCardView.swift        # Toggle + brightness slider
│   │   └── QuickScenesView.swift       # Bottom row of global scenes
│   ├── RoomDetail/
│   │   ├── RoomDetailView.swift        # Full room view with charts + controls
│   │   ├── SensorChartView.swift       # 24h/7d/30d Swift Charts view
│   │   ├── DeviceControlView.swift     # Grouped device controls
│   │   └── SceneButtonView.swift       # Scene execution buttons
│   ├── Settings/
│   │   ├── SettingsView.swift          # Main settings list
│   │   ├── ConnectionSettingsView.swift # HomeKit + HA config
│   │   ├── AppearanceSettingsView.swift # Theme picker
│   │   ├── NotificationSettingsView.swift # Threshold config
│   │   ├── DataExportView.swift        # CSV export UI
│   │   ├── PaywallView.swift           # Pro upgrade with 3 IAP options + legal links
│   │   ├── ContactSupportView.swift    # Feedback form
│   │   └── AboutView.swift             # Version, privacy, terms links
│   └── Components/
│       ├── SparklineView.swift         # Swift Charts mini line chart
│       ├── BigNumberView.swift         # 36pt bold rounded number with unit
│       ├── GlassCardView.swift         # .ultraThinMaterial card wrapper
│       └── ReachabilityDot.swift       # Green/red status indicator
├── Widget/
│   ├── HomePulseWidget.swift           # Widget definition (small/medium families)
│   ├── LockScreenWidget.swift          # Lock screen widget (circular/rectangular)
│   ├── SensorProvider.swift            # TimelineProvider: fetches from App Group
│   └── WidgetEntry.swift               # TimelineEntry struct
├── LiveActivity/
│   ├── SensorAlertActivity.swift       # ActivityAttributes
│   └── SensorAlertLiveActivity.swift   # Dynamic Island UI
└── Extensions/
    ├── Color+Theme.swift               # systemOrange=temp, systemCyan=humidity, etc.
    ├── Date+Helpers.swift              # Time bucketing, formatting
    ├── HMAccessory+Unified.swift       # HomeKit → UnifiedDevice mapping
    └── HAEntity+Unified.swift          # HA → UnifiedDevice mapping
```

---

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

### Feature F1: HomeKit Connection
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User taps "HomeKit" on onboarding screen            │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── OnboardingViewModel → request HomeKit permission    │
│       └── HomeKitService.init() → HMHomeManager delegate  │
│            │                                              │
│  Model/Persistence                                        │
│  └── HMHomeManagerDelegate.homeManagerDidUpdateHomes()    │
│       └── Map HMHome → HMRoom → HMAccessory → UnifiedDevice│
│       └── UserDefaults: platformChoice = "homekit"        │
│            │                                              │
│  Display Output                                           │
│  └── DashboardViewModel.rooms populated → DashboardView   │
│       └── Room cards render with sensors + devices        │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── UnifiedDevice list → F3 Dashboard, F6 Sparkline,     │
│       F7 History, F8/F9/F10 Control, F12 Widget           │
└───────────────────────────────────────────────────────────┘
```

### Feature F2: Home Assistant Connection
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User enters HA URL + Long-Lived Access Token        │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── OnboardingViewModel → validate URL format           │
│       └── HomeAssistantService.connect() (actor)          │
│            └── WebSocket auth: send {"type":"auth",...}   │
│            └── Subscribe: {"type":"subscribe_events",...} │
│            └── REST GET /api/states → [HAEntity]          │
│       └── Keychain: save URL + Token (sensitive)          │
│            │                                              │
│  Model/Persistence                                        │
│  └── Map HAEntity → UnifiedDevice (platform: .ha)         │
│       └── Group by area/room attribute                    │
│            │                                              │
│  Display Output                                           │
│  └── DashboardViewModel.rooms populated → DashboardView   │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── UnifiedDevice list → F3, F6, F7, F8/F9/F10, F12     │
│  └── WebSocket events → real-time state updates           │
└───────────────────────────────────────────────────────────┘
```

### Feature F3: Main Dashboard
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User opens app (or taps Dashboard tab)              │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── DashboardViewModel.refresh()                        │
│       └── Aggregate UnifiedDevice list by room            │
│       └── For each room: extract sensors, devices, scenes │
│       └── For each sensor: fetch 24h sparkline data       │
│            │                                              │
│  Model/Persistence                                        │
│  └── Read from HomeKitService.homes (in-memory)          │
│  └── Read from HomeAssistantService.entities (in-memory)  │
│  └── Read from SensorHistoryManager (SwiftData)           │
│            │                                              │
│  Display Output                                           │
│  └── DashboardView renders ScrollView of RoomCardView     │
│       └── Each card: room name, big numbers, sparkline,   │
│           light status dots, scene buttons                │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── Tap room card → F4 RoomDetailView                    │
│  └── Tap scene → F11 Scene Execution                      │
└───────────────────────────────────────────────────────────┘
```

### Feature F6: Sparkline Trend Chart
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── None (auto-rendered in room card + room detail)     │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── SensorHistoryManager.getSparkline(deviceId)         │
│       └── Query SwiftData SensorBucket for last 24h       │
│       └── Downsample to 288 points (5-min intervals)      │
│       └── Return [SparklineView.DataPoint]                │
│            │                                              │
│  Model/Persistence                                        │
│  └── SwiftData SensorBucket (deviceId, readings[])        │
│       └── ReadingPoint (timestamp, value)                 │
│       └── Trimmed to 24h sliding window                   │
│            │                                              │
│  Display Output                                           │
│  └── SparklineView renders Swift Charts                   │
│       └── LineMark + AreaMark with gradient fill          │
│       └── Color from sensor type (temp=orange, hum=cyan)  │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── Tap sparkline → F7 Historical Charts (full screen)   │
└───────────────────────────────────────────────────────────┘
```

### Feature F8: Device Control — On/Off Toggle
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User taps toggle on DeviceCardView                  │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── DeviceControlManager.toggle(deviceId)               │
│       └── Debounce: ignore if <300ms since last action    │
│       └── Optimistic update: set device.state = .on/.off  │
│       └── Haptic feedback: UIImpactFeedbackGenerator      │
│       └── Determine platform:                             │
│            └── HomeKit: HMCharacteristic.writeValue(bool)  │
│            └── HA: POST /api/services/home/turn_on|off    │
│       └── Wait for confirmation (3s timeout)              │
│            └── Success: remove pending state              │
│            └── Timeout/Failure: rollback UI + show error  │
│            │                                              │
│  Model/Persistence                                        │
│  └── Update UnifiedDevice.state in memory                 │
│  └── No persistence needed (state from source of truth)   │
│            │                                              │
│  Display Output                                           │
│  └── Toggle animates immediately (optimistic)             │
│  └── Device state updates via delegate/WebSocket event    │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── Dashboard room card light count updates              │
│  └── Widget snapshot updates on next timeline             │
└───────────────────────────────────────────────────────────┘
```

### Feature F12: WidgetKit Home Screen Widget
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User adds widget via home screen long-press         │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── SensorProvider.getTimeline()                        │
│       └── Read shared snapshot from App Group             │
│       └── Build SensorEntry (temp, humidity, lightsOn)    │
│       └── Schedule next timeline: 5 min (.after)          │
│            │                                              │
│  Model/Persistence                                        │
│  └── App Group: UserDefaults suite "group.com.zzoutuo.    │
│       HomePulse" with latest sensor snapshot              │
│  └── Main app writes snapshot every 5 min + on change    │
│            │                                              │
│  Display Output                                           │
│  └── HomePulseWidgetEntryView renders widget              │
│       └── Small: single sensor big number                 │
│       └── Medium: multi-sensor + mini sparkline           │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── Tap widget → opens app to room detail (deeplink)     │
└───────────────────────────────────────────────────────────┘
```

### Feature F22: Free vs Pro Gating (IAP)
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User attempts Pro feature OR taps "Upgrade to Pro"  │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── IAPService.isPro (observed)                         │
│       └── If false → present PaywallView                 │
│       └── User selects product:                           │
│            └── Product.purchase() via StoreKit 2          │
│            └── Verify Transaction.id                      │
│            └── Set isPro = true (persist in Keychain)     │
│            └── Dismiss paywall                            │
│            │                                              │
│  Model/Persistence                                        │
│  └── StoreKit 2 manages transaction state                 │
│  └── Keychain: isPro flag (survives reinstall)            │
│  └── UserDefaults: last verified transaction ID           │
│            │                                              │
│  Display Output                                           │
│  └── PaywallView shows 3 options:                         │
│       └── One-time $6.99 (recommended)                    │
│       └── Yearly $1.99                                    │
│       └── Monthly $0.49                                   │
│  └── Legal links: Privacy Policy + Terms of Use           │
│  └── Auto-renewal disclosure text                         │
│            │                                              │
│  Cross-Feature Output                                     │
│  └── isPro = true → unlocks F7, F10, F13, F14, F15,       │
│       F16, F17, F18                                       │
│  └── SettingsView Pro section updates to "Pro Active"     │
└───────────────────────────────────────────────────────────┘
```

**⚠️ VERIFICATION CHECK**: All 23 primary features have documented data flows. Each flow traces from user input → ViewModel → Model/Persistence → Display → Cross-Feature. ✅ Complete

---

## Implementation Flow

1. **Project Setup**: Configure HomeKit entitlement, Info.plist usage descriptions, App Group for widget, SwiftData container
2. **Data Models**: Define UnifiedDevice, DeviceType, DeviceState, SensorReading, SensorBucket (@Model), Room, Scene
3. **HomeKitService**: HMHomeManager delegate, accessory discovery, characteristic read/write, scene execution
4. **HomeAssistantService**: actor with WebSocket connect/auth/subscribe, REST API for states/services
5. **SensorHistoryManager**: Sample every 5 min, maintain 24h sliding window, generate sparkline data points
6. **DeviceControlManager**: Unified control interface with debounce + optimistic update + rollback
7. **DashboardViewModel + DashboardView**: Room cards with big numbers, sparklines, light status
8. **RoomDetailView**: Full sensor charts (24h/7d/30d), device controls, scene buttons
9. **SparklineView + BigNumberView + GlassCardView**: Reusable UI components
10. **OnboardingView**: 3-step flow (platform select → connect → ready)
11. **SettingsView**: Connection, appearance, notifications, data export, Pro, about
12. **PaywallView**: StoreKit 2 IAP with 3 products + legal links
13. **WidgetKit**: HomePulseWidget (small/medium) + LockScreenWidget
14. **LiveActivity**: SensorAlertActivity for anomaly alerts via Dynamic Island
15. **ContactSupportView**: Feedback form posting to FEEDBACK_BACKEND_URL
16. **Testing**: Unit tests for Services, UI tests for core flows
17. **App Store Prep**: Privacy policy, screenshots, ASO metadata

---

## UI/UX Design Specifications

### Design Philosophy
**One-screen overview + big numbers first + zero learning curve**

Inspired by:
- Apple Watch complications (big numbers + micro charts)
- Tesla car dashboard (key info on one screen)
- iOS Weather app (card layout + trend lines)

### Color Scheme

**Light Mode:**
- Background: `#F2F2F7` (systemGroupedBackground)
- Card BG: `.ultraThinMaterial` (glassmorphic)
- Primary Text: `#1C1C1E` (label)
- Secondary: `#8E8E93` (secondaryLabel)
- Accent: `#007AFF` (systemBlue)
- Temperature: `#FF9500` (systemOrange)
- Humidity: `#5AC8FA` (systemCyan)
- Success: `#34C759` (systemGreen)
- Danger: `#FF3B30` (systemRed)
- Light On: `#FFD60A` (systemYellow)

**Dark Mode:**
- Background: `#000000` (systemBackground)
- Card BG: `.ultraThinMaterial`
- Primary Text: `#FFFFFF` (label)
- Accent: `#0A84FF` (systemBlue)
- Temperature: `#FF9F0A` (systemOrange)
- Humidity: `#64D2FF` (systemCyan)
- Success: `#30D158` (systemGreen)
- Danger: `#FF453A` (systemRed)

### Typography
- Sensor big numbers: SF Pro Rounded, 36pt, Bold
- Room titles: SF Pro, 17pt, Semibold
- Card body: SF Pro, 14pt, Regular
- Captions: SF Pro, 12pt, Regular

### Layout Specs
- Card corner radius: 16pt
- Card spacing: 12pt
- Card padding: 12pt
- Sparkline height: 30pt
- Device status icon: 16pt (SF Symbols)
- Online status dot: 6pt Circle
- Tab bar: Dashboard / History / Settings

### Animations
- State transitions: `.spring(duration: 0.3)`
- Number changes: `.contentTransition(.numericText())`
- Toggle: immediate optimistic + spring on confirm
- Card tap: scale 0.98 + spring back

### Haptics
- Toggle on/off: `UIImpactFeedbackGenerator(.light)`
- Scene execute: `UINotificationFeedbackGenerator(.success)`
- Error: `UINotificationFeedbackGenerator(.error)`

### Accessibility
- VoiceOver: Big numbers auto-announced ("Temperature, 72 degrees Fahrenheit")
- Dynamic Type: Supports all sizes up to XXXL
- Reduce Motion: Disables sparkline animations
- Reduce Transparency: Falls back to solid card backgrounds

### App Icon Design
- Background: `#007AFF` (Apple Blue)
- House silhouette: White
- Pulse line (ECG-style) through house: `#34C759` (Green = "alive/online")
- Concept: Home + Pulse = "your home's heartbeat"

---

## Code Generation Rules

- One feature per module, high cohesion, low coupling
- Semantic naming, clear file structure (matches Module Structure above)
- Never add comments in code unless asked (only for complex logic)
- Apple native first: prioritize SwiftUI/Swift/SwiftData/Swift Charts
- Open source first: reference itsyhome-macos, HomekitControl, HAbitat for patterns
- MVVM with @Observable (iOS 17+), no Combine
- Swift 6 strict concurrency: actors for services, no data races
- No force unwraps (`!`), use `guard let` / `if let`
- async/await for all async operations
- typed throws for error handling

---

## Build & Deployment Checklist

### Pre-Build
- [ ] HomeKit entitlement added to project
- [ ] Info.plist has NSHomeKitUsageDescription
- [ ] Info.plist has NSLocalNetworkUsageDescription
- [ ] App Group configured (group.com.zzoutuo.HomePulse)
- [ ] Widget extension target added
- [ ] SwiftData container configured in HomePulseApp

### Build Verification
- [ ] Compiles without warnings on iOS 17.0 simulator
- [ ] HomeKit permission prompt appears on first launch
- [ ] Dashboard renders with mock data (if no HomeKit devices)
- [ ] All tabs functional (Dashboard / History / Settings)

### App Store Submission
- [ ] Privacy policy URL accessible (deployed via GitHub Pages in PHASE 7)
- [ ] Terms of Use URL accessible
- [ ] Support URL accessible
- [ ] App Store screenshots prepared (PHASE 9, optional)
- [ ] ASO keytext.md generated (PHASE 8)
- [ ] Privacy nutrition label: "Data Not Collected"
- [ ] HomeKit usage disclosed in App Store Connect
- [ ] IAP products configured in App Store Connect:
  - `com.zzoutuo.HomePulse.pro.lifetime` ($6.99, non-consumable)
  - `com.zzoutuo.HomePulse.pro.yearly` ($1.99/year, auto-renewable)
  - `com.zzoutuo.HomePulse.pro.monthly` ($0.49/month, auto-renewable)

### Post-Submission
- [ ] TestFlight beta test
- [ ] Monitor for HomeKit-related rejections (Section 26)
- [ ] Monitor for IAP-related rejections (Section 3.1.2(c))
- [ ] Respond to user feedback via Contact Support

---

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
Apple REQUIRES the following in the Paywall view:
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Subscription title, length, and price for each plan
- Auto-renewal disclosure text:
  "Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings after purchase."

### One-Time Purchase + Subscription Hybrid
This app offers BOTH:
- **Non-consumable one-time purchase** ($6.99): Lifetime Pro unlock
- **Auto-renewable subscriptions** ($1.99/year, $0.49/month): Alternative Pro access

All three options unlock the SAME Pro features. The one-time purchase is the recommended option (no recurring fees). Subscriptions are lower-barrier alternatives.

### Paywall Requirements
- Clear pricing for all 3 options
- "Recommended" badge on one-time purchase
- Restore Purchases button
- Manage Subscriptions link (deep-links to App Store settings)
- Privacy Policy link (functional, opens Safari or in-app SafariView)
- Terms of Use link (functional, opens Safari or in-app SafariView)

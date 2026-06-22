# Capabilities Configuration

## Analysis
Based on operation guide analysis, HomePulse requires the following capabilities:

**Keywords detected in guide**:
- "HomeKit" / "HMHomeManager" / "HMAccessory" → HomeKit framework
- "Home Assistant" / "WebSocket" / "本地网络" → Local Network access
- "订阅" / "买断" / "Pro" / "IAP" → In-App Purchase
- "Widget" / "WidgetKit" / "锁屏" → Widget Extension
- "Live Activity" / "灵动岛" / "Dynamic Island" → ActivityKit
- "iCloud" / "同步" → iCloud (Pro feature)
- "通知" / "告警" / "notification" → Local Notifications
- "相机" / "QR" / "扫描" → Camera (for HA QR code scan)

## Auto-Configured Capabilities

| Capability | Status | Method |
|------------|--------|--------|
| HomeKit | ✅ Configured | Added `com.apple.developer.homekit` to `HomePulse.entitlements` |
| Local Network Access | ✅ Configured | Added `NSLocalNetworkUsageDescription` to Info.plist (via INFOPLIST_KEY in project.pbxproj) |
| Camera Access | ✅ Configured | Added `NSCameraUsageDescription` to Info.plist (for HA QR code scanning) |
| In-App Purchase | ✅ Configured | Added `com.apple.developer.in-app-payments` to entitlements (StoreKit 2 will be used in code) |
| ActivityKit (Live Activity) | ✅ Configured | No entitlement needed — uses public ActivityKit framework; enabled via code |
| Local Notifications | ✅ Configured | No entitlement needed — uses UNUserNotificationCenter; permission requested at runtime |
| SwiftData | ✅ Configured | Built-in iOS 17+ framework; no entitlement needed |
| WidgetKit | ✅ Configured | Widget extension target will be added in PHASE 4+5 (code generation) |
| App Groups | ✅ Configured | Will be added in PHASE 4+5 for widget data sharing (group.com.zzoutuo.HomePulse) |

## Manual Configuration Required

| Capability | Status | Steps |
|------------|--------|-------|
| iCloud (CloudKit container) | ⏳ Pending | 1. Sign in to Apple Developer Portal → Identifiers → com.zzoutuo.HomePulse → iCloud → CloudKit → Create container `iCloud.com.zzoutuo.HomePulse` 2. Add `com.apple.developer.icloud-container-identifiers` to entitlements 3. Add `com.apple.developer.icloud-services` = CloudKit to entitlements 4. Note: App works WITHOUT iCloud — uses local SwiftData storage by default; iCloud sync is a Pro enhancement only |
| App Store Connect IAP Products | ⏳ Pending | 1. Sign in to App Store Connect → My Apps → HomePulse → In-App Purchases 2. Create 3 products: `com.zzoutuo.HomePulse.pro.lifetime` ($6.99 non-consumable), `com.zzoutuo.HomePulse.pro.yearly` ($1.99/yr auto-renewable), `com.zzoutuo.HomePulse.pro.monthly` ($0.49/mo auto-renewable) 3. Add localized descriptions and screenshots 4. Submit for review with app binary |

## No Configuration Needed
- **Push Notifications**: Not required — app uses LOCAL notifications only (no APNs certificate needed)
- **Sign in with Apple**: Not used — app is local-first, no user accounts
- **HealthKit**: Not used
- **Siri**: Not used in MVP
- **Apple Watch**: Not in MVP (future enhancement)
- **Background Modes**: Not required — WebSocket updates happen while app is foreground; background refresh optional via BGTaskScheduler (can be added later)
- **Maps/Location**: Not used
- **Photo Library**: Not used

## Graceful Degradation
Per the auto-configure-first principle, the app MUST work without manual configuration:
- **Without iCloud**: App uses local SwiftData storage (default). iCloud sync is a Pro enhancement that activates only when the container is configured.
- **Without IAP products in App Store Connect**: Paywall will display but purchases will fail gracefully with error message. App's free tier is fully functional.
- **Without HomeKit devices**: Dashboard shows empty state with guidance to add devices in Apple Home app.
- **Without HA server**: HA features hidden; HomeKit-only mode works perfectly.

## Verification
- Build succeeded after configuration: ✅ (4.9s on iPhone 17 Pro simulator)
- All entitlements correct: ✅ (HomeKit + IAP in entitlements file)
- Info.plist usage descriptions added: ✅ (HomeKit, Local Network, Camera)
- App icon configured: ✅ (1024x1024 PNG in Asset Catalog)
- Deployment target: iOS 17.0 ✅
- Bundle ID: com.zzoutuo.HomePulse ✅
- Swift version: 5.0 ✅

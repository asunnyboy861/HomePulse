# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | HomePulse |
| **Git URL** | git@github.com:asunnyboy861/HomePulse.git |
| **Repo URL** | https://github.com/asunnyboy861/HomePulse |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/HomePulse/ | ✅ Active |
| Support | https://asunnyboy861.github.io/HomePulse/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/HomePulse/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/HomePulse/terms.html | ✅ Active |

## Repository Structure

```
HomePulse/
├── HomePulse/                      # iOS App Source Code
│   ├── HomePulse.xcodeproj/        # Xcode Project
│   └── HomePulse/                  # Swift Source Files
│       ├── Views/
│       │   ├── Dashboard/
│       │   ├── RoomDetail/
│       │   ├── Settings/
│       │   └── Onboarding/
│       ├── Models/
│       ├── Services/
│       ├── ViewModels/
│       ├── Assets.xcassets/
│       └── HomePulse.entitlements
├── docs/                           # Policy Pages (GitHub Pages source)
│   ├── index.html
│   ├── support.html
│   ├── privacy.html
│   └── terms.html
├── .github/workflows/
│   └── deploy.yml
├── us.md
├── capabilities.md
├── icon.md
├── price.md
└── nowgit.md
```

## Build Verification

| Platform | Build Status | Run Test |
|----------|--------------|----------|
| iPhone 16 Pro Max | ✅ Succeeded | ✅ Verified |
| iPad Pro 13-inch (M4) | ✅ Succeeded | ✅ Verified |

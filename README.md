# Joghd iOS app

Native iPhone app (Swift, SwiftUI, iOS 17+) for reading imported books.
See the project's product plan and glossary in [`../docs`](../docs).

## Prerequisites

- Xcode 16 or later (for the app build; iOS 17 deployment target).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

The `.xcodeproj` is **generated** and not committed. `project.yml` is the source
of truth.

## Generate and open

```sh
cd ios
xcodegen generate
open Joghd.xcodeproj
```

Add Swift files by creating them under `Joghd/` (or `JoghdTests/`); regenerate
the project to pick them up.

## Layout

```
ios/
├── project.yml          XcodeGen manifest (targets, settings, bundle id)
├── Joghd/
│   ├── App/             App entry point
│   ├── Domain/          Domain types (see ../GLOSSARY.md)
│   ├── Features/        Feature modules (Library, …)
│   └── Resources/       Asset catalog
├── JoghdTests/          Unit tests (Swift Testing)
└── docs/                iOS-specific design notes
```

Bundle identifier: `dev.djawadi.joghd.ios`. Scheme: `Joghd`.

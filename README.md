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

## License

MPL-2.0 (Mozilla Public License 2.0). See [`LICENSE`](LICENSE).

We chose a **file-level (weak) copyleft** license: modified files stay open,
but new files can be proprietary, so the app can ship on the App Store. The
GPL family is generally incompatible with App Store distribution because its
whole-program copyleft and anti-DRM terms conflict with Apple's App Store
requirements; MPL-2.0 has no such clauses and adds a patent grant.

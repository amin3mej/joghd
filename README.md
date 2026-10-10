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

We chose a **file-level (weak) copyleft** license: distributed modifications
to MPL-covered source files must remain under MPL. New files can use another
license only if they contain no MPL-covered code; private modifications do not
need to be published.

A permissive license such as MIT is not copyleft — it lets others close the
source — so it does not meet the copyleft requirement.

GPLv3 permits DRM, but its anti-circumvention rules limit legal protection
for measures that restrict GPL rights, and Apple's App Store terms separately
restrict interference with Apple's DRM and security mechanisms. Whether a
GPL-licensed app can ship on the App Store therefore depends on the app;
MPL-2.0 sidesteps this with file-level copyleft and adds a patent grant.

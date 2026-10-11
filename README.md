# Joghd iOS app

Native iPhone app (Swift, SwiftUI, iOS 17+) for reading imported books.
See the project's product plan and glossary in [`../docs`](../docs).

## Prerequisites

- Xcode 26 or later (Icon Composer compilation; iOS 17 deployment target).
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

## Library persistence

`LibraryStore.add` is idempotent: it reads the repository, adds the entry only
when its ID is not already present, and then reloads the displayed entries.
Errors from either step propagate — if saving succeeds but reloading fails, the
entry is already persisted even though `add` throws — so callers must not assume
an error means nothing was saved. A caller may retry `add` with the same entry
without creating a duplicate.

`FileLibraryRepository` assumes a single writer per document URL. Its
read-modify-write operation runs synchronously on the main actor, but it does
not coordinate writes across processes; concurrent writers can lose updates.

The JSON document is replaced atomically, not durably flushed. Normal app
relaunches preserve entries, but a power loss can lose the latest replacement.
V1 accepts this metadata durability risk; there is no existing platform
abstraction for flushing both a temporary file and its parent directory.

V1 keeps library data local. It does not use an account, server upload, or
cloud processing.

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

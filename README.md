# String Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Null-terminated platform string storage for Swift — a `String` namespace of `~Copyable` owned strings, non-escapable borrowed views, and platform-native code units, with zero Foundation dependency.

---

## Quick Start

`String_Primitives.String` is an *owned*, null-terminated platform string. It owns a single heap allocation and frees it exactly once on `deinit`; being `~Copyable`, the compiler rejects accidental double-ownership at compile time rather than at run time. The code unit is platform-native — `UInt8` (UTF-8) on POSIX, `UInt16` (UTF-16) on Windows — so one type spans every target without `Foundation.String` or C string bridging.

```swift
import String_Primitives

// An owned, null-terminated platform string — UTF-8 on POSIX, UTF-16 on Windows.
// `~Copyable` means the heap buffer is owned by exactly one value and freed once.
let greeting = String_Primitives.String(ascii: "hello")

print(greeting.count)         // 5  — code units, excluding the null terminator
print(greeting.view.length)   // 5  — a non-escapable borrowed view, no copy
```

`String.Borrowed` is the non-escapable (`~Escapable`) view returned by `view`: it carries a pointer and a length but owns nothing, and the compiler forbids it from outliving the `String` it borrows. Because the storage is `~Copyable` and tag-neutral, a `Tagged` phantom type can distinguish two platform strings that share a representation but not a meaning — a filesystem path versus an environment-variable name, for instance:

```swift
import String_Primitives
import Tagged_Primitives

// A path and an env-var name share a representation but not a meaning.
// A phantom `Tagged` tag keeps the two from being confused at compile time.
enum PathTag {}

let path = Tagged<PathTag, String_Primitives.String>(ascii: "/usr/local/bin")
print(path.count)   // 14
```

Storage can be created by `adopting:` an existing allocation, `copying:` a borrowed view, from a `Swift.Span` of code units, or from an `ascii:` literal; ownership is handed back out with the consuming `take()`. The module name is `String_Primitives` and the type is `String`, so qualify as `String_Primitives.String` where it would shadow `Swift.String`.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-string-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "String Primitives", package: "swift-string-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Two library products. Depends only on the `Memory.Heap`, `Span.Protocol`, `Tagged`, and `Ownership.Borrow` primitives.

| Product | Target | Purpose |
|---------|--------|---------|
| `String Primitives` | `Sources/String Primitives/` | The `String` namespace: owned `~Copyable` `String`, the non-escapable `String.Borrowed` view, platform `Char` / `CodeUnit` code units, `String.length(of:)`, and `Tagged` integration for phantom-typed platform strings. |
| `String Primitives Test Support` | `Tests/Support/` | Re-exports the main target (and the Tagged test support) for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).

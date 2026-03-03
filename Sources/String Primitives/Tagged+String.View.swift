// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-string-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-string-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if STRING_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

public import Identity_Primitives

// MARK: - View Access

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// Returns a view of this tagged string.
    ///
    /// The lifetime of the returned `View` is tied to `self`.
    ///
    /// Two-level `@_lifetime` chain:
    /// 1. `rawValue.view` borrows from `rawValue` (stored property)
    /// 2. `_overrideLifetime` re-parents the View's lifetime to `self`
    @inlinable
    public var view: String.View {
        @_lifetime(borrow self) borrowing get {
            let v = rawValue.view
            return unsafe _overrideLifetime(v, borrowing: self)
        }
    }
}

#endif

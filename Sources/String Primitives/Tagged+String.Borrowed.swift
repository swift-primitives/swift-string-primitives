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

    public import Tagged_Primitives

    // MARK: - Borrowed View Access

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// Returns a borrowed view of this tagged string.
        ///
        /// The lifetime of the returned `Borrowed` is tied to `self`.
        ///
        /// Reads `underlying.unsafeBaseAddress` and `underlying.count` (both
        /// `Copyable` `Int` / `UnsafePointer` returns from the `_read`-yielded
        /// underlying), rebuilds the `Borrowed` via its public init, and
        /// re-parents its lifetime to `self`. The base-address detour is needed
        /// because `Tagged.underlying.view` would tie the `Borrowed` to a
        /// coroutine borrow scope that does not survive the `let` binding.
        @inlinable
        public var view: String.Borrowed {
            @_lifetime(borrow self) borrowing get {
                let pointer = unsafe underlying.unsafeBaseAddress
                let count = underlying.count
                let borrowed = unsafe String.Borrowed(pointer, count: count)
                return unsafe _overrideLifetime(borrowed, borrowing: self)
            }
        }
    }

#endif

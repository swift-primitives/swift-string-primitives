// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-string-primitives open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-string-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if STRING_PRIMITIVES_AVAILABLE && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux) || os(Android) || os(OpenBSD) || os(Windows))

extension String {
    /// Computes the length of a null-terminated string, excluding the terminator.
    ///
    /// Implemented without platform-specific `strlen`/`wcslen` dependencies.
    @inlinable
    public static func length(of pointer: UnsafePointer<Char>) -> Int {
        var current = pointer
        while current.pointee != terminator {
            current = current.successor()
        }
        return current - pointer
    }
}

#endif

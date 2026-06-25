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
        // `Char` is a pure Swift integer code unit. C interop projections
        // (`CChar`, `WCHAR`) belong at syscall boundaries, not in primitives.
        #if STRING_PRIMITIVES_AVAILABLE && os(Windows)
            /// Platform-native code unit for OS strings — `UInt16` (UTF-16) on Windows.
            public typealias Char = UInt16
        #else
            /// Platform-native code unit for OS strings — `UInt8` (UTF-8) on POSIX (macOS, Linux).
            public typealias Char = UInt8
        #endif

        /// Semantic alias for `Char`.
        ///
        /// Prefer `CodeUnit` in new code for clarity.
        public typealias CodeUnit = Char

        /// The null terminator value.
        @inlinable
        public static var terminator: Char { 0 }
    }

#endif

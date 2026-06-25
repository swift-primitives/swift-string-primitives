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

    public import Ownership_Primitives

    // MARK: - Ownership.Borrow.`Protocol` Conformance

    extension String: Ownership.Borrow.`Protocol` {}

    // MARK: - Borrowed

    extension String {
        // WHY: Category D (SP-5) — pointer-backed value type; storage is
        // WHY: private/internal; the type's safe API never lets the raw pointer
        // WHY: escape, and lifetime invariants are enforced by init/deinit pairing.
        /// Non-escapable borrowed view of a null-terminated platform string.
        ///
        /// Does not own storage. Valid only for the duration of the borrowing scope.
        /// The referenced memory must remain valid and unmodified while borrowed.
        ///
        /// `~Escapable` enforces at compile time that this value cannot escape
        /// the scope where it was created — preventing use-after-free bugs.
        ///
        /// Invariant: Points to a null-terminated sequence.
        @safe
        public struct Borrowed: ~Copyable, ~Escapable {
            /// The underlying pointer to the null-terminated sequence.
            public let pointer: UnsafePointer<Char>

            /// The length in code units, excluding the null terminator.
            public let count: Int

            /// Creates a borrowed view from a pointer and count.
            ///
            /// The lifetime of this `Borrowed` value is tied to the lifetime of `pointer`.
            ///
            /// - Precondition: `pointer` must point to a null-terminated sequence.
            @inlinable
            @_lifetime(borrow pointer)
            public init(_ pointer: UnsafePointer<String.Char>, count: Int) {
                #if DEBUG
                    unsafe Self.debugValidateTermination(pointer)
                #endif
                unsafe (self.pointer = pointer)
                self.count = count
            }
        }
    }

    // MARK: - Debug Validation

    #if DEBUG
        extension String.Borrowed {
            /// Maximum bytes to scan when validating termination in debug builds.
            @usableFromInline
            internal static let maxDebugScanLength = 16 * 1024 * 1024  // 16 MiB

            @unsafe
            @usableFromInline
            internal static func debugValidateTermination(_ pointer: UnsafePointer<String.Char>) {
                var current = unsafe pointer
                var scanned = 0
                while scanned < maxDebugScanLength {
                    if unsafe current.pointee == String.terminator {
                        return  // Valid: found terminator
                    }
                    unsafe (current = current.successor())
                    scanned += 1
                }
                assertionFailure("String.Borrowed: pointer does not appear to be null-terminated within \(maxDebugScanLength) bytes")
            }
        }
    #endif

    // MARK: - Access

    extension String.Borrowed {
        /// Executes a closure with the underlying pointer.
        @unsafe
        @inlinable
        public borrowing func withUnsafePointer<R: ~Copyable, E: Swift.Error>(
            _ body: (UnsafePointer<String.Char>) throws(E) -> R
        ) throws(E) -> R {
            try unsafe body(pointer)
        }

        /// The length in code units, excluding the null terminator.
        @inlinable
        public var length: Int { count }

        /// Returns a `Span` view of the string content, excluding the null terminator.
        @inlinable
        public var span: Swift.Span<String.Char> {
            @_lifetime(copy self) borrowing get {
                let span = unsafe Span(_unsafeStart: pointer, count: count)
                return unsafe _overrideLifetime(span, copying: self)
            }
        }
    }

#endif

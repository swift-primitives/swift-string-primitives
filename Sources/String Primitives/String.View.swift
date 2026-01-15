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
    /// Non-escapable view of a null-terminated platform string.
    ///
    /// Does not own storage. Valid only for the duration of the borrowing scope.
    /// The referenced memory must remain valid and unmodified while borrowed.
    ///
    /// `~Escapable` enforces at compile time that this value cannot escape
    /// the scope where it was created — preventing use-after-free bugs.
    ///
    /// Invariant: Points to a null-terminated sequence.
    public struct View: ~Copyable, ~Escapable {
        /// The underlying pointer to the null-terminated sequence.
        public let pointer: UnsafePointer<Char>
    }
}

// MARK: - Initialization

extension String.View {
    /// Creates a view from a pointer.
    ///
    /// The lifetime of this `View` value is tied to the lifetime of `pointer`.
    ///
    /// - Precondition: `pointer` must point to a null-terminated sequence.
    @inlinable
    @_lifetime(borrow pointer)
    public init(_ pointer: UnsafePointer<String.Char>) {
        #if DEBUG
        Self.debugValidateTermination(pointer)
        #endif
        self.pointer = pointer
    }
}

// MARK: - Debug Validation

#if DEBUG
extension String.View {
    /// Maximum bytes to scan when validating termination in debug builds.
    @usableFromInline
    internal static let maxDebugScanLength = 16 * 1024 * 1024 // 16 MiB

    @usableFromInline
    internal static func debugValidateTermination(_ pointer: UnsafePointer<String.Char>) {
        var current = pointer
        var scanned = 0
        while scanned < maxDebugScanLength {
            if current.pointee == String.terminator {
                return // Valid: found terminator
            }
            current = current.successor()
            scanned += 1
        }
        assertionFailure("String.View: pointer does not appear to be null-terminated within \(maxDebugScanLength) bytes")
    }
}
#endif

// MARK: - Access

extension String.View {
    /// Executes a closure with the underlying pointer.
    @inlinable
    public borrowing func withUnsafePointer<R: ~Copyable, E: Error>(
        _ body: (UnsafePointer<String.Char>) throws(E) -> R
    ) throws(E) -> R {
        try body(pointer)
    }

    /// The length in code units, excluding the null terminator.
    @inlinable
    public var length: Int {
        String.length(of: pointer)
    }

    /// Returns a `Span` view of the string content, excluding the null terminator.
    @inlinable
    public var span: Span<String.Char> {
        @_lifetime(copy self) borrowing get {
            let span = unsafe Span(_unsafeStart: pointer, count: length)
            return unsafe _overrideLifetime(span, copying: self)
        }
    }
}

#endif

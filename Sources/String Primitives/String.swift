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

/// Owned, null-terminated platform string.
///
/// Owns its storage and deallocates on deinit.
/// The stored sequence is always null-terminated.
///
/// `~Copyable` enforces unique ownership — preventing double-free bugs.
///
/// Invariant: `pointer` points to `count + 1` allocated code units,
/// where the final code unit is the null terminator.
///
/// ## Platform Encoding
///
/// - **POSIX (macOS, Linux)**: UTF-8 (`CChar`)
/// - **Windows**: UTF-16 (`UInt16`)
public struct String: ~Copyable {
    /// The underlying pointer to the null-terminated sequence.
    @usableFromInline
    internal let pointer: UnsafeMutablePointer<Char>

    /// The length in code units, excluding the null terminator.
    public let count: Int

    @inlinable
    deinit {
        pointer.deallocate()
    }
}

// MARK: - Initialization

extension String {
    /// Creates an owned string by adopting an existing allocation.
    ///
    /// Takes ownership of `pointer`. The caller must not deallocate it.
    ///
    /// - Parameters:
    ///   - pointer: A pointer to a null-terminated sequence. Ownership is transferred.
    ///   - count: The length in code units, excluding the null terminator.
    ///
    /// - Precondition: `pointer` must point to at least `count + 1` allocated code units.
    /// - Precondition: `pointer[count]` must be the null terminator.
    @inlinable
    public init(adopting pointer: UnsafeMutablePointer<String.Char>, count: Int) {
        #if DEBUG
        precondition(pointer[count] == String.terminator, "String: adopted buffer must be null-terminated")
        #endif
        self.pointer = pointer
        self.count = count
    }

    /// Creates an owned string by copying from a view.
    ///
    /// Allocates new storage and copies the content.
    @inlinable
    public init(copying view: borrowing String.View) {
        let length = view.length
        let buffer = UnsafeMutablePointer<String.Char>.allocate(capacity: length + 1)
        buffer.initialize(from: view.pointer, count: length)
        buffer[length] = String.terminator
        self.pointer = buffer
        self.count = length
    }
}

// MARK: - Access

extension String {
    /// Executes a closure with the underlying pointer.
    @inlinable
    public borrowing func withUnsafePointer<R: ~Copyable, E: Error>(
        _ body: (UnsafePointer<String.Char>) throws(E) -> R
    ) throws(E) -> R {
        try body(pointer)
    }

    /// Executes a closure with the underlying mutable pointer.
    @inlinable
    public mutating func withUnsafeMutablePointer<R: ~Copyable, E: Error>(
        _ body: (UnsafeMutablePointer<String.Char>) throws(E) -> R
    ) throws(E) -> R {
        try body(pointer)
    }

    /// Returns a view of this string.
    ///
    /// The lifetime of the returned `View` is tied to `self`.
    @inlinable
    public var view: String.View {
        @_lifetime(borrow self) borrowing get {
            let view = unsafe String.View(UnsafePointer(pointer))
            return unsafe _overrideLifetime(view, borrowing: self)
        }
    }

    /// Returns a `Span` view of the string content, excluding the null terminator.
    @inlinable
    public var span: Span<String.Char> {
        @_lifetime(borrow self) borrowing get {
            let span = unsafe Span(_unsafeStart: UnsafePointer(pointer), count: count)
            return unsafe _overrideLifetime(span, borrowing: self)
        }
    }
}

// MARK: - Ownership Transfer

extension String {
    /// Transfers ownership of the underlying buffer to the caller.
    ///
    /// Returns the pointer and count. The caller is responsible for deallocation.
    /// This instance is consumed and will not deallocate the buffer.
    ///
    /// - Returns: A tuple of (pointer, count) where count excludes the null terminator.
    @inlinable
    public consuming func take() -> (pointer: UnsafeMutablePointer<String.Char>, count: Int) {
        let result = (pointer, count)
        discard self
        return result
    }
}

#endif

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

public import Memory_Primitives_Core

/// Owned, null-terminated platform string.
///
/// Owns its storage and deallocates on deinit.
/// The stored sequence is always null-terminated.
///
/// `~Copyable` enforces unique ownership — preventing double-free bugs.
///
/// Invariant: the underlying allocation contains `count + 1` code units,
/// where the final code unit is the null terminator.
///
/// ## Platform Encoding
///
/// - **POSIX (macOS, Linux)**: UTF-8 (`UInt8`)
/// - **Windows**: UTF-16 (`UInt16`)
///
/// ## Sendability
///
/// ## Safety Invariant
///
/// `String` is `~Copyable` and owns an immutable `Memory.Contiguous` buffer.
/// The buffer is uniquely owned and immutable after initialization.
/// Cross-thread transfer via move relinquishes the sender's access.
///
/// ## Intended Use
///
/// - Moving a string across isolation boundaries.
///
/// ## Non-Goals
///
/// - Not shareable; single-owner semantics.
@safe
public struct String: ~Copyable, @unsafe @unchecked Sendable {
    /// The underlying contiguous memory region.
    ///
    /// `Memory.Contiguous<Char>` owns the allocation and deallocates on destruction.
    /// The tracked `count` is the string length (excluding null terminator).
    /// The null terminator sits at `pointer[count]` — in the allocation but
    /// outside the tracked region.
    @usableFromInline
    internal let _storage: Memory.Contiguous<Char>

    /// The length in code units, excluding the null terminator.
    @inlinable
    public var count: Int { _storage.count }
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
        precondition(unsafe pointer[count] == String.terminator, "String: adopted buffer must be null-terminated")
        #endif
        unsafe self._storage = Memory.Contiguous(adopting: pointer, count: count)
    }

    /// Creates an owned string by copying from a view.
    ///
    /// Allocates new storage and copies the content.
    @inlinable
    public init(copying view: borrowing String.View) {
        let length = view.count
        let buffer = UnsafeMutablePointer<String.Char>.allocate(capacity: length + 1)
        unsafe buffer.initialize(from: view.pointer, count: length)
        (unsafe buffer)[length] = String.terminator
        unsafe self._storage = Memory.Contiguous(adopting: buffer, count: length)
    }

    /// Creates an owned string by copying from a span of platform code units.
    ///
    /// Allocates new storage, copies the content, and null-terminates.
    @inlinable
    public init(_ span: Span<Char>) {
        let length = span.count
        let buffer = UnsafeMutablePointer<Char>.allocate(capacity: length + 1)
        for i in 0..<length { (unsafe buffer)[i] = span[i] }
        (unsafe buffer)[length] = String.terminator
        unsafe self._storage = Memory.Contiguous(adopting: buffer, count: length)
    }

    /// Creates an owned string from an ASCII literal.
    ///
    /// Allocates new storage and copies the ASCII bytes, widening to UTF-16 on Windows.
    ///
    /// - Parameter literal: A compile-time string containing only ASCII characters (≤ 0x7F).
    ///
    /// - Precondition: All bytes in `literal` MUST be ASCII (< 0x80). Non-ASCII
    ///   bytes would silently widen to invalid UTF-16 code units on Windows; the
    ///   precondition prevents that latent corruption at the cost of one byte
    ///   comparison per code unit.
    @inlinable
    public init(ascii literal: StaticString) {
        let length = literal.utf8CodeUnitCount
        let buffer = UnsafeMutablePointer<String.Char>.allocate(capacity: length + 1)
        literal.withUTF8Buffer { utf8 in
            for i in 0..<length {
                let byte = unsafe utf8[i]
                precondition(byte < 0x80, "String.init(ascii:): literal contains non-ASCII byte 0x\(Swift.String(byte, radix: 16, uppercase: true)) at index \(i)")
                (unsafe buffer)[i] = String.Char(byte)
            }
        }
        (unsafe buffer)[length] = String.terminator
        unsafe self._storage = Memory.Contiguous(adopting: buffer, count: length)
    }

}

// MARK: - Access

extension String {
    /// Executes a closure with the underlying pointer.
    @unsafe
    @inlinable
    public borrowing func withUnsafePointer<R: ~Copyable, E: Error>(
        _ body: (UnsafePointer<String.Char>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe body(_storage.unsafeBaseAddress)
    }

    /// Returns a view of this string.
    ///
    /// The lifetime of the returned `View` is tied to `self`.
    @inlinable
    public var view: String.View {
        @_lifetime(borrow self) borrowing get {
            let view = unsafe String.View(_storage.unsafeBaseAddress, count: _storage.count)
            return unsafe _overrideLifetime(view, borrowing: self)
        }
    }

    /// Returns a `Span` view of the string content, excluding the null terminator.
    @inlinable
    public var span: Span<String.Char> {
        @_lifetime(borrow self) borrowing get {
            let s = _storage.span
            return unsafe _overrideLifetime(s, borrowing: self)
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
    @unsafe
    @inlinable
    public consuming func take() -> (pointer: UnsafeMutablePointer<String.Char>, count: Int) {
        unsafe _storage.take()
    }
}

// MARK: - Memory.Contiguous.Protocol

extension String: Memory.Contiguous.`Protocol` {
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Char>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe _storage.withUnsafeBufferPointer(body)
    }
}

#endif

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
public import Memory_Primitives_Core

// MARK: - Nested Type Aliases

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// Semantic alias for `Char`.
    public typealias CodeUnit = String.CodeUnit
}

// MARK: - Static Members

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// The null terminator value.
    @inlinable
    public static var terminator: String.Char { String.terminator }

    /// Computes the length of a null-terminated string, excluding the terminator.
    @unsafe
    @inlinable
    public static func length(of pointer: UnsafePointer<String.Char>) -> Int {
        unsafe String.length(of: pointer)
    }
}

// MARK: - Initialization

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// Creates a tagged string by adopting an existing allocation.
    ///
    /// Takes ownership of `pointer`. The caller must not deallocate it.
    @inlinable
    public init(adopting pointer: UnsafeMutablePointer<String.Char>, count: Int) {
        unsafe self.init(__unchecked: (), String(adopting: pointer, count: count))
    }

    /// Creates a tagged string by copying from a view.
    @inlinable
    public init(copying view: borrowing String.View) {
        self.init(__unchecked: (), String(copying: view))
    }

    /// Creates a tagged string from an ASCII literal.
    @inlinable
    public init(ascii literal: StaticString) {
        self.init(__unchecked: (), String(ascii: literal))
    }
}

// MARK: - Properties

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// The length in code units, excluding the null terminator.
    @inlinable
    public var count: Int { rawValue.count }

    /// Returns a `Span` view of the string content, excluding the null terminator.
    ///
    /// Two-level `@_lifetime` chain:
    /// 1. `rawValue.span` borrows from `rawValue` (stored property)
    /// 2. `_overrideLifetime` re-parents the Span's lifetime to `self`
    @inlinable
    public var span: Span<String.Char> {
        @_lifetime(borrow self) borrowing get {
            let s = rawValue.span
            return unsafe _overrideLifetime(s, borrowing: self)
        }
    }
}

// MARK: - Ownership Transfer

extension Tagged where RawValue == String, Tag: ~Copyable {
    /// Transfers ownership of the underlying buffer to the caller.
    ///
    /// Returns the pointer and count. The caller is responsible for deallocation.
    /// This instance is consumed and will not deallocate the buffer.
    @unsafe
    @inlinable
    public consuming func take() -> (pointer: UnsafeMutablePointer<String.Char>, count: Int) {
        unsafe rawValue.take()
    }
}

// MARK: - Memory.Contiguous.Protocol

extension Tagged: @retroactive Memory.Contiguous.`Protocol`
where RawValue == String, Tag: ~Copyable {
    @inlinable
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<String.Char>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe rawValue.withUnsafeBufferPointer(body)
    }
}

#endif

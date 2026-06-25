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
    public import Span_Protocol_Primitives

    // MARK: - Nested Type Aliases

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// Semantic alias for `Char`.
        public typealias CodeUnit = String.CodeUnit
    }

    // MARK: - Static Members

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
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

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// Creates a tagged string by adopting an existing allocation.
        ///
        /// Takes ownership of `pointer`. The caller must not deallocate it.
        @inlinable
        public init(adopting pointer: UnsafeMutablePointer<String.Char>, count: Int) {
            unsafe self.init(_unchecked: String(adopting: pointer, count: count))
        }

        /// Creates a tagged string by copying from a borrowed view.
        @inlinable
        public init(copying view: borrowing String.Borrowed) {
            self.init(_unchecked: String(copying: view))
        }

        /// Creates a tagged string from an ASCII literal.
        @inlinable
        public init(ascii literal: StaticString) {
            self.init(_unchecked: String(ascii: literal))
        }
    }

    // MARK: - Properties

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// The length in code units, excluding the null terminator.
        @inlinable
        public var count: Int { underlying.count }

        /// Returns a `Span` view of the string content, excluding the null terminator.
        ///
        /// Reads `underlying.unsafeBaseAddress` and `underlying.count` (both
        /// `Copyable` `Int` / `UnsafePointer` returns from the `_read`-yielded
        /// underlying), rebuilds the `Span` via `Span(_unsafeStart:count:)`, and
        /// re-parents its lifetime to `self`. The base-address detour is needed
        /// because `Tagged.underlying.span` would tie the `Span` to a coroutine
        /// borrow scope that does not survive the `let` binding.
        @inlinable
        public var span: Swift.Span<String.Char> {
            @_lifetime(borrow self) borrowing get {
                let pointer = unsafe underlying.unsafeBaseAddress
                let count = underlying.count
                let span = unsafe Swift.Span(_unsafeStart: pointer, count: count)
                return unsafe _overrideLifetime(span, borrowing: self)
            }
        }
    }

    // MARK: - Ownership Transfer

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// Transfers ownership of the underlying buffer to the caller.
        ///
        /// Returns the pointer and count. The caller is responsible for deallocation.
        /// This instance is consumed and will not deallocate the buffer.
        ///
        /// Implementation routes through `Tagged.map` for consuming access to the
        /// `Underlying` (`String`). The Carrier `_read` accessor on `underlying`
        /// only yields a borrow, so it cannot drive a `consuming` extraction;
        /// `Tagged.map` is the public consuming path Tagged exposes.
        @unsafe
        @inlinable
        public consuming func take() -> (pointer: UnsafeMutablePointer<String.Char>, count: Int) {
            var captured: (pointer: UnsafeMutablePointer<String.Char>, count: Int)? = nil
            _ = Self.map(self) { (str: consuming String) -> Bool in
                unsafe (captured = unsafe str.take())
                return true
            }
            guard let result = unsafe captured else {
                fatalError("Tagged<_, String>.take(): map did not invoke its transform")
            }
            return unsafe result
        }
    }

    // MARK: - Span.Protocol

    /// Tower reconform: the retired closure-borrow seam is replaced by
    /// `Span.\`Protocol\``, the namespace-neutral read capability (CLCPM §12).
    ///
    /// The `span` witness is the pre-existing property-form accessor above
    /// (Properties section — the coroutine-borrow detour via the stable base
    /// address).
    extension Tagged: @retroactive Span.`Protocol`
    where Underlying == String, Tag: ~Copyable & ~Escapable {}

    extension Tagged where Underlying == String, Tag: ~Copyable & ~Escapable {
        /// Concrete buffer-pointer access (the former protocol witness, kept as
        /// a concrete convenience; the protocol-level read seam is ``span``).
        @inlinable
        public func withUnsafeBufferPointer<R, E: Swift.Error>(
            _ body: (UnsafeBufferPointer<String.Char>) throws(E) -> R
        ) throws(E) -> R {
            try unsafe underlying.withUnsafeBufferPointer(body)
        }
    }

#endif

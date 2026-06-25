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

    public import Memory_Heap_Primitives
    public import Span_Protocol_Primitives

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
    /// `String` is `~Copyable` and owns an immutable `Memory.Heap` byte region.
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
        /// The underlying owned byte region.
        ///
        /// `Memory.Heap` owns the raw allocation and deallocates on destruction. Its byte
        /// `capacity` is the *tracked content length* in bytes — `count * stride(Char)` — so the
        /// string length is `capacity / stride(Char)`. `Char` is `BitwiseCopyable`, so `String`
        /// provides the typed `Char` view itself by reinterpreting the raw base
        /// (`assumingMemoryBound(to: Char.self)`). The null terminator sits at `base[count]` — in
        /// the real allocation but one `Char` beyond the tracked capacity, exactly as before.
        @usableFromInline
        internal let _storage: Memory.Heap

        /// The length in code units, excluding the null terminator.
        @inlinable
        public var count: Int {
            let byteCount = Int(bitPattern: _storage.capacity)
            return byteCount / MemoryLayout<Char>.stride
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
                precondition(unsafe pointer[count] == Self.terminator, "String: adopted buffer must be null-terminated")
            #endif
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(pointer),
                capacity: Memory.Address.Count(UInt(count) * UInt(MemoryLayout<Char>.stride))
            )
        }

        /// Creates an owned string by copying from a borrowed view.
        ///
        /// Allocates new storage and copies the content.
        @inlinable
        public init(copying view: borrowing String.Borrowed) {
            let length = view.count
            let buffer = UnsafeMutablePointer<String.Char>.allocate(capacity: length + 1)
            unsafe buffer.initialize(from: view.pointer, count: length)
            (unsafe buffer)[length] = Self.terminator
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(buffer),
                capacity: Memory.Address.Count(UInt(length) * UInt(MemoryLayout<Char>.stride))
            )
        }

        /// Creates an owned string by copying from a span of platform code units.
        ///
        /// Allocates new storage, copies the content, and null-terminates.
        @inlinable
        public init(_ span: Swift.Span<Char>) {
            let length = span.count
            let buffer = UnsafeMutablePointer<Char>.allocate(capacity: length + 1)
            for i in 0..<length { (unsafe buffer)[i] = span[i] }
            (unsafe buffer)[length] = Self.terminator
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(buffer),
                capacity: Memory.Address.Count(UInt(length) * UInt(MemoryLayout<Char>.stride))
            )
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
                    (unsafe buffer)[i] = Self.Char(byte)
                }
            }
            (unsafe buffer)[length] = Self.terminator
            unsafe self._storage = Memory.Heap(
                adopting: UnsafeMutableRawPointer(buffer),
                capacity: Memory.Address.Count(UInt(length) * UInt(MemoryLayout<Char>.stride))
            )
        }

    }

    // MARK: - Access

    extension String {
        /// The typed `Char` base of the owned region — the REAL origin pointer reinterpreted.
        ///
        /// Reads `_storage.unsafeBaseAddress` (the real, provenance-carrying origin pointer of the
        /// `Memory.Heap` region — never a pointer reconstituted from `Memory.Address`,
        /// [MEM-OWN-015]/[MEM-SAFE-029]) and reinterprets it as `Char`. Sound: `Char` is
        /// `BitwiseCopyable` and the region is `Char`-sized / `Char`-aligned by construction.
        @unsafe
        @inlinable
        internal var _base: UnsafePointer<Char> {
            // SAFETY: reinterprets the REAL origin pointer (intact provenance) as `Char`; the region
            // SAFETY: was allocated `Char`-sized/aligned, so the bound is valid. No `Memory.Address`
            // SAFETY: round-trip ([MEM-OWN-015]/[MEM-SAFE-029]). Lifetime tied to `self` via `_storage`.
            unsafe UnsafePointer(_storage.unsafeBaseAddress.assumingMemoryBound(to: Char.self))
        }

        /// Executes a closure with the underlying pointer.
        @unsafe
        @inlinable
        public borrowing func withUnsafePointer<R: ~Copyable, E: Swift.Error>(
            _ body: (UnsafePointer<String.Char>) throws(E) -> R
        ) throws(E) -> R {
            try unsafe body(_base)
        }

        /// Returns the unsafe base address of the underlying buffer.
        ///
        /// The pointer's lifetime is tied to `self` via `@_lifetime(borrow self)`.
        /// Callers wrapping `~Escapable` views (`Swift.Span<Char>`, `String.Borrowed`)
        /// constructed from this pointer must re-parent the resulting view's
        /// lifetime to their own logical owner via `_overrideLifetime`.
        ///
        /// Required because `Tagged.underlying` is yielded via a `_read`
        /// coroutine (post the `RawValue` → `Underlying` rename). Coroutine
        /// borrow scopes do not propagate across `let` bindings, so consumers
        /// like `Tagged<Tag, String>.view` and `.span` cannot use
        /// `underlying.span` / `underlying.view` directly. They take a stable
        /// pointer here and rebuild the view inline.
        @unsafe
        @inlinable
        public var unsafeBaseAddress: UnsafePointer<String.Char> {
            unsafe _base
        }

        /// Returns a borrowed view of this string.
        ///
        /// The lifetime of the returned `Borrowed` is tied to `self`.
        @inlinable
        public var view: String.Borrowed {
            @_lifetime(borrow self) borrowing get {
                let view = unsafe Self.Borrowed(_base, count: count)
                return unsafe _overrideLifetime(view, borrowing: self)
            }
        }

        /// Returns a `Span` view of the string content, excluding the null terminator.
        @inlinable
        public var span: Swift.Span<String.Char> {
            @_lifetime(borrow self) borrowing get {
                let s = unsafe Swift.Span(_unsafeStart: _base, count: count)
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
            // `Memory.Heap.take()` hands back the REAL origin pointer + byte capacity and suppresses
            // its free; reinterpret the raw base as `Char` (provenance intact — no `Memory.Address`
            // round-trip, [MEM-OWN-015]/[MEM-SAFE-029]) and recover the length from the byte capacity.
            let (raw, byteCapacity) = unsafe _storage.take()
            let byteCount = Int(bitPattern: byteCapacity)
            return unsafe (
                raw.assumingMemoryBound(to: Char.self),
                byteCount / MemoryLayout<Char>.stride
            )
        }
    }

    // MARK: - Span.Protocol

    /// Tower reconform: the retired closure-borrow seam is replaced by
    /// `Span.\`Protocol\``, the namespace-neutral read capability — the `span`
    /// witness is the property-form accessor above (CLCPM §12).
    extension String: Span.`Protocol` {}

    extension String {
        /// Concrete buffer-pointer access (the former protocol witness, kept as
        /// a concrete convenience; the protocol-level read seam is ``span``).
        @inlinable
        public func withUnsafeBufferPointer<R, E: Swift.Error>(
            _ body: (UnsafeBufferPointer<Char>) throws(E) -> R
        ) throws(E) -> R {
            try unsafe body(UnsafeBufferPointer(start: _base, count: count))
        }
    }

#endif

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

import Testing
@testable import String_Primitives

@Suite
struct StringPrimitivesTests {
    @Test
    func lengthOfEmptyString() {
        let empty: [String_Primitives.String.Char] = [String_Primitives.String.terminator]
        empty.withUnsafeBufferPointer { buffer in
            let length = String_Primitives.String.length(of: buffer.baseAddress!)
            #expect(length == 0)
        }
    }

    @Test
    func lengthOfNonEmptyString() {
        // "hello" = [104, 101, 108, 108, 111, 0]
        let hello: [String_Primitives.String.Char] = [104, 101, 108, 108, 111, String_Primitives.String.terminator]
        hello.withUnsafeBufferPointer { buffer in
            let length = String_Primitives.String.length(of: buffer.baseAddress!)
            #expect(length == 5)
        }
    }
}

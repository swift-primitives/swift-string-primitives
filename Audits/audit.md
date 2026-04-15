# Audit: swift-string-primitives

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/audits/implementation-naming-2026-03-20/swift-small-packages-batch.md (2026-03-20)

**Implementation + naming audit**

CLEAN - no findings

---

### From: swift-institute/Research/platform-compliance-audit.md (2026-03-19)

**Skill**: platform — [PLAT-ARCH-001-010], [PATTERN-001], [PATTERN-004a], [PATTERN-005]

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| H-49 | HIGH | [PLAT-ARCH-008] | String.Char.swift:22 | `#if os(Windows)` -> `UInt16`, else `UInt8` for native character width. This is a fundamental vocabulary type. Design decision: should `Kernel.Char` exist, or should string-primitives own this? | OPEN — Design decision pending |
| H-50 | HIGH | [PLAT-ARCH-008] | String.swift:99 | `#if os(Windows)` for ASCII literal initialization. | OPEN |

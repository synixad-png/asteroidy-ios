# ASTEROIDY iOS v568 — W3 menu GPU on both Apple simulators

**Date:** 2026-11-06. **Stage:** A — open, pending real touch UI tests and full visual parity. **No IPA.**

## Two independently successful real simulator executions

[GitHub Actions run 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
— job **IPHONE SUCCESS** and job **IPAD SUCCESS**.

The workflow:
1. Verified all original v568 archive/manifests, the separately uploaded source
   W3 background/logo, original `home290.mesh.gz` H290, source base JPEG and lava
   glow PNG. It fails on mismatched SHA256, including inside the Xcode-built app.
2. Successfully generated and compiled native Swift/Metal for the iPhone/iPad
   simulator without signing or building an IPA.
3. Booted and installed the **actual ASTEROIDY iOS application** on iPhone/iPad
   simulators, used `simctl io screenshot` to capture real screenshots.
4. Validated actual SwiftUI menu appearance; required the original source
   background and logo and active source NewHome290 3D preview.
5. Required a **completed Metal command buffer** for source H290 render:
   **172208 triangles / 516624 vertices**, two material groups, exact base and
   glow image checksums, rather than accepting a static image of a planet.

**Actual screenshots and GPU proofs, downloadable from GitHub Actions artifacts:**

- [iPhone artifact #13493952002](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493952002)
  — `ASTEROIDY-v568-W3-NATIVE-IPHONE-real-screen-NO-IPA`.
- [iPad artifact #13493651804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493651804)
  — `ASTEROIDY-v568-W3-NATIVE-IPAD-real-screen-NO-IPA`.

No third-party game screenshots, mockups or graphic substitutions are
presented as application results.

## Important limits

- A GPU-completed source image does not prove **pixel-perfect match**
  of lighting and shaders with Windows v568. Shader fidelity remains open.
- The source W3 home globe is real, but the original 26-planet campaign and
  actual mission launch are **not implemented by this test**.
- Real seven-button navigation **not proven by this screenshot workflow**.
  Separate native XCTest UI automation has been added:
  [run 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528),
  with iPhone and iPad jobs. Only update PASS after both jobs complete.
- Results are on Apple simulators, not physical devices.
- Stage A remains in progress; stage B (real mission selection) has not started.

**Recorded progress reference**: task 14 **10% (+0 pp)**,
overall **27% done / 73% remaining**. No IPA generated.

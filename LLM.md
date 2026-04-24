# LLM.md

This project is a native macOS menu bar app built with Xcode.

## Canonical local run flow

Build the Debug app:

```bash
xcodebuild -project tex.xcodeproj -scheme tex -configuration Debug build
```

The built app must live at the stable path:

```text
dist/Debug/tex.app
```

Launch the built app from that stable path:

```bash
./scripts/run-installed-debug.sh
```

That script opens:

```text
/Users/raza/Projects/tex/dist/Debug/tex.app
```

## Important project invariants

- Do not move the debug app back to DerivedData.
- Keep `CONFIGURATION_BUILD_DIR = "$(PROJECT_DIR)/dist/$(CONFIGURATION)"`.
- Keep local development builds using a stable signed app bundle path so macOS privacy permissions can attach to one consistent app identity.
- Do not reintroduce Keychain-backed storage for the Gemini API key.
- The Gemini API key is intentionally stored in app preferences, not Keychain.

## Signing expectations

- Local development builds should be code signed.
- The project is configured for automatic signing with team `V5W4LV96XX`.
- If the machine prompts for key access during signing, approving persistent access for Xcode / `codesign` is acceptable for local development.
- Verify the built app signature with:

```bash
codesign -dv --verbose=4 dist/Debug/tex.app
```

Useful things to check in the output:

- `TeamIdentifier=V5W4LV96XX`
- The app is not ad hoc signed

## Privacy / permissions behavior

- This app uses direct screen capture for arbitrary region selection.
- On recent macOS versions, first launch or first capture may show the warning about bypassing the system private window picker and directly accessing screen and audio.
- That warning is currently expected with this capture approach.
- Avoiding that warning would require switching to Apple's system content-sharing picker, which changes the UX from freeform region capture to window/app/display picking.

## What to verify after rebuilding

1. Build with `xcodebuild`.
2. Inspect signing with `codesign -dv --verbose=4 dist/Debug/tex.app`.
3. Launch `dist/Debug/tex.app` via `./scripts/run-installed-debug.sh`.
4. Trigger a capture.
5. Confirm Screen Recording permission does not churn across rebuilds of the same stable app path.

## Relevant files

- `tex.xcodeproj/project.pbxproj`
- `README.md`
- `scripts/run-installed-debug.sh`
- `tex/Services/SecretsStore.swift`

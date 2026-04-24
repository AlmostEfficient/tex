# tex

Native macOS menu bar app that captures a screen region, sends the image to Gemini, and shows formatted translated text in a floating corner window.

## What it does

- Runs as a menu bar app with no Dock icon
- Global shortcut: `Control + Option + Command + T` (customizable)
- Lets you drag a capture area with the system screenshot selector
- Sends the selected image directly to Gemini for formatted translation
- Shows the translated result in a bottom-right popup
- Persists translation history in the menu bar window
- Lets the user set their own Gemini API key in Settings
- **Customizable screenshot shortcut** - click the pencil icon next to the shortcut display in the menu bar window

## Build

```bash
xcodebuild -project tex.xcodeproj -scheme tex -configuration Debug build
```

Built app:

```text
dist/Debug/tex.app
```

## Signing

- The target is configured for a stable app path at `dist/<Configuration>/tex.app`.
- The target is also configured to use `Apple Development` signing when a development identity is available locally.
- If Xcode says the target requires a team, select your personal team in the Signing settings once. After that, the same signed app bundle path should be reused across rebuilds.

## Distribution

- For local development, build and run the stable signed app bundle from `dist/Debug/tex.app`.
- For external distribution, archive the app with Developer ID signing and notarize it before packaging it in a DMG or ZIP.

## First run notes

- macOS will likely ask for Screen Recording permission the first time you capture.
- Cancelling the area selection simply aborts the capture.

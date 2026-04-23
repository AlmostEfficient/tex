# QuickTranslate

Native macOS menu bar app for translating text from an arbitrary screen region into English.

## What it does

- Runs as a menu bar app with no Dock icon
- Global shortcut: `Control + Option + Command + T` (customizable)
- Lets you drag a capture area with the system screenshot selector
- OCRs the selected region with Vision
- Translates detected text asynchronously with Apple's Translation framework
- Shows the translated result in a dismissible bottom-right popup
- Auto-dismisses the popup after 10 seconds
- Persists translation history in the menu bar window
- **Customizable screenshot shortcut** - click the pencil icon next to the shortcut display in the menu bar window

## Build

```bash
xcodebuild -project QuickTranslate.xcodeproj -scheme QuickTranslate -configuration Debug -derivedDataPath .deriveddata build
```

Built app:

```text
.deriveddata/Build/Products/Debug/QuickTranslate.app
```

## First run notes

- macOS will likely ask for Screen Recording permission the first time you capture.
- The Translation framework may prompt to download language models if English translation resources are not already installed.
- Cancelling the area selection simply aborts the capture.

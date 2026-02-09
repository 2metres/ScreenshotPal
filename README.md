<p align="center">
  <img src="ScreenshotPal/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" height="128" alt="ScreenshotPal icon">
</p>

# ScreenshotPal

A lightweight macOS menubar app for browsing, previewing, and managing your screenshots and screen recordings.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

<p align="center">
  <img src="screenshot.png" width="390" alt="ScreenshotPal screenshot">
</p>

## Features

- **Menubar access** — Lives in your menubar for instant access. No dock icon.
- **Auto-detection** — Reads your macOS screenshot location from system preferences, or lets you pick a custom folder.
- **Live updating** — Watches your screenshot directory and refreshes automatically when new files appear.
- **Screenshots & videos** — Supports `.png` screenshots and `.mov` screen recordings with video thumbnail generation and a frosted play indicator.
- **QuickLook preview** — Select a tile and press **Space** to preview. Press **Space** again to dismiss.
- **Keyboard navigation** — Arrow keys navigate the grid. QuickLook updates as you move.
- **Context menu** — Right-click any tile for Open, Open With, Show in Finder, Copy, and Move to Trash.
- **Drag & drop** — Drag thumbnails directly into other apps.
- **Configurable directory** — Choose any folder via the settings pane; persists across launches.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Space** | Toggle QuickLook preview for selected item |
| **Arrow keys** | Navigate the thumbnail grid |
| **Double-click** | Open with default app |
| **Right-click** | Context menu (Open, Open With, Finder, Copy, Trash) |

## Architecture

ScreenshotPal is a hybrid SwiftUI + AppKit app:

- **AppKit** handles system integration — `NSStatusBar` for the menubar icon, `NSPopover` for the floating panel, `NSEvent` monitors for keyboard/mouse handling.
- **SwiftUI** provides all user-facing views — the screenshot grid, thumbnails, settings pane, and empty states.
- **DispatchSource** watches the screenshot directory at the file-descriptor level for real-time updates.
- **AVAssetImageGenerator** extracts first-frame thumbnails from screen recordings.
- **QLPreviewView** in a non-activating `NSPanel` provides QuickLook without stealing focus from the popover.

```
ScreenshotPal/
├── AppDelegate.swift                  # Menubar icon, popover, click monitoring
├── ScreenshotPalApp.swift                 # SwiftUI entry point
├── Models/
│   ├── Screenshot.swift               # Data model (image or video)
│   ├── ScreenshotStore.swift          # State, file loading, directory watching
│   └── ScreenshotDirectoryManager.swift  # OS detection, custom path persistence
├── Views/
│   ├── MenubarPopover.swift           # Main UI, QuickLook, keyboard handling
│   ├── ScreenshotGrid.swift           # 3-column LazyVGrid
│   ├── ScreenshotThumbnail.swift      # Tile with hover, selection, context menu
│   └── SettingsView.swift             # Directory picker
└── Resources/
    └── Assets.xcassets/               # App icon
```

## Building

Open `ScreenshotPal.xcodeproj` in Xcode and build, or from the command line:

```bash
xcodebuild build -project ScreenshotPal.xcodeproj -scheme ScreenshotPal -configuration Debug
```

Requires macOS 14+ and Xcode 15+.

## Usage

1. Launch the app — an icon appears in your menubar.
2. **Left-click** the icon to open the screenshot browser.
3. **Right-click** the icon to quit.
4. Click the gear icon to change the screenshot directory.

## Credits

Inspired by [Shotty](https://meetshotty.com/), a fantastic screenshot manager for macOS. ScreenshotPal is a free, open-source alternative built as a learning project.

App icon by [bloxxk](https://macosicons.com/#/u/bloxxk) via [macOS Icons](https://macosicons.com).

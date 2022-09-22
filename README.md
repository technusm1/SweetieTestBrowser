# SweetieTestBrowser
A barebones working browser, created as part of a recruitment challenge that meets the following criteria:
- Works on macOS 10.14+.
- The app will recreate browser “compact” tabs, similar to Safari 15.
- Created using Swift / AppKit.

## Features
- Tab support: Open links in tabs via context menu, Cmd + click to open a background tab etc.
- Compact tabs as given in spec.
- Just a barebones browser that works.
- `target=_blank` hyperlinks supported.
- File selection and upload supported.
- Toolbar customization supported.
- Multi-window support, including dragging a tab from one window to another (rudimentary for now).
- Dark mode supported (already works from day 1, just forgot mentioning).

## Limitations
- Content downloading is not yet implemented.

## Installation
- Download the latest version of the app (DMG) from this link: https://github.com/technusm1/SweetieTestBrowser/releases/download/1.0-alpha1/SweetieTestBrowser.dmg
- Open the DMG.
- Drag the app into `Applications` folder (shortcut provided in DMG).

## Demo
Demo can be watched on the following youtube link (please see description and chapters in video for the features being demoed):

[![Watch the video](https://img.youtube.com/vi/MwlMwmiVcAs/default.jpg)](https://youtu.be/MwlMwmiVcAs)

## Implemention details and credits
- The app components are laid out using Auto Layout for most part, because it simplifies things. Almost all views have `translatesAutoresizingMaskIntoConstraints` set to `false`, and constraints are properly defined for each one. This allows to handle things like window resizing properly, out of the box and reliably handles UI adjustment, including animations.
- [FaviconFinder](https://github.com/will-lumley/FaviconFinder/) library is used to asynchronously fetch FavIcon for a website and display it on tab. The app uses v3.3.0 of this library since it is compatible with macOS 10.14.
- [Customize the contextual menu of WKWebView on macOS - iCab Blog](https://icab.de/blog/2022/06/12/customize-the-contextual-menu-of-wkwebview-on-macos/)

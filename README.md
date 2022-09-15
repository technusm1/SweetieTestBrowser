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

## Limitations
- Toolbar is not customizable.
- Basically any features one would expect from a modern web browser, including downloading, multi-window support and tab shifting, haven't been implemented yet. I have a mind to incorporate the downloading part using another one of my projects: MK-Downloader, but its written in SwiftUI (the challenge required AppKit).

## Demo
[![Watch the video](https://img.youtube.com/vi/MwlMwmiVcAs/default.jpg)](https://youtu.be/MwlMwmiVcAs)

## Implemention details
- The app components are laid out using Auto Layout for most part, because it simplifies things. All views have `translatesAutoresizingMaskIntoConstraints` set to `false`, and constraints are properly defined for each one. This allows to handle things like window resizing properly, out of the box and reliably handles all UI adjustment, including animations.

## Credits
- [FaviconFinder](https://github.com/will-lumley/FaviconFinder/) library is used to asynchronously fetch FavIcon for a website and display it on tab. The app uses v3.3.0 of this library since it is compatible with macOS 10.14.
- [Customize the contextual menu of WKWebView on macOS - iCab Blog](https://icab.de/blog/2022/06/12/customize-the-contextual-menu-of-wkwebview-on-macos/)

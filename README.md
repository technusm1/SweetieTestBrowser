# SweetieTestBrowser
A barebones working browser, created as part of a recruitment challenge that meets the following criteria:
- Works on macOS 10.14+.
- The app will recreate browser “compact” tabs, similar to Safari 15.
- Created using Swift / AppKit.

## Features
- Customizable toolbar.

## Implemention details
- The app components are laid out using Auto Layout, because doing UI development without it is a recipe for a headache. In the words of Paul Hudson, there are only two kinds of people - those who use auto-layout, and those who waste time. So, keeping that in mind, all views have `translatesAutoresizingMaskIntoConstraints` set to `false`, and constraints are properly defined for each one. This allows to handle things like window resizing properly, out of the box and reliably handles all UI adjustment.

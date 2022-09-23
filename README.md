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
- Toolbar customization supported. Basic functionality like browsing and tab adding and switching works even user has removed the Compact Tabs + Address bar. Though you can't really enter any URLs, so I guess it doesn't serve much as a browser.
- Dark mode supported (already works from day 1, just forgot mentioning it before).
- Offline content supported.
- Multi-window support, including dragging and dropping a tab within the window or from one window to another.

## Limitations
- Content downloading is not yet implemented.
- Tab drag-and-drop requires more features (possibly scrolling on hovering around edges of scrollview) and minor bug fixes (drop indicator arrow is not shown at correct position sometimes) to be fully usable.

## Installation
- Download the latest version of the app (DMG) from this link: https://github.com/technusm1/SweetieTestBrowser/releases/download/1.0-alpha2/SweetieTestBrowser.1.0-alpha2.dmg
- Open the DMG.
- Drag the app into `Applications` folder (shortcut provided in DMG).

## Demo
Demo can be watched on the following youtube link (please see description and chapters in video for the features being demoed):

[![Watch the video](https://img.youtube.com/vi/MwlMwmiVcAs/default.jpg)](https://youtu.be/MwlMwmiVcAs)

## Implemention details and credits
- The app components are laid out using Auto Layout for most part, because it simplifies things. Almost all views have `translatesAutoresizingMaskIntoConstraints` set to `false`, and constraints are properly defined for each one. This allows to handle things like window resizing properly, out of the box and reliably handles UI adjustment, including animations.
- The app employs a data-driven architecture. There is one data container (WebViewContainer) per window, containing one WebView per tab. All method calls on the container generate notifications, which can be subscribed to by components like compact tab view (if they are present) and delegate calls which update the contentview (i.e. displaying the selected webview, hiding unselected ones). Adopting this approach allows us to keep functioning even with minimal UI components. As more components are added to UI, they can both drive the UI and get updates from UI, thereby requiring minimal changes in the future.
- [FaviconFinder](https://github.com/will-lumley/FaviconFinder/) library is used to asynchronously fetch FavIcon for a website and display it on tab. The app uses v3.3.0 of this library since it is compatible with macOS 10.14.
- [Customize the contextual menu of WKWebView on macOS - iCab Blog](https://icab.de/blog/2022/06/12/customize-the-contextual-menu-of-wkwebview-on-macos/)

//
//  MKWindowController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

class MKWindowController: NSWindowController {
    var titlebarAccessoryViewController: ProgressIndicatorTitlebarAccessoryViewController?
    var webViewContainer: WebViewContainer = WebViewContainer()
    
    override func windowDidLoad() {
        print("Setting window title...")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            // window is being set up currently, so appDelegate wcList won't have it yet
            let winTitle = "Window \(appDelegate.wcList.count + 1)"
            self.window?.title = winTitle
            self.window?.setFrameAutosaveName("MKMain" + winTitle.replacingOccurrences(of: " ", with: ""))
        }
        self.window?.backgroundColor = .windowBackgroundColor
        self.window?.animationBehavior = .documentWindow
        super.windowDidLoad()
        let minSize = NSSize(width: 570, height: 220)
        self.window?.minSize = minSize
        
        if let mainWindow = self.window, mainWindow.frame.width < minSize.width || mainWindow.frame.height < minSize.height {
            var frameRect = mainWindow.frame
            frameRect.size = CGSize(width: minSize.width, height: minSize.height)
            self.window?.setFrame(frameRect, display: true, animate: true)
        }
        configureToolbar()
        webViewContainer.delegate = self.window?.contentViewController as? ViewController
//        self.window?.makeFirstResponder(
//            self.window?.toolbar?.items.first { item in
//                item.itemIdentifier == .searchBarAndTabStripIdentifier
//            }?.view?.subviews.first { subView in
//                subView is NSSearchField
//            }
//        )
        configureTitlebarAccessoryView()
    }
    
    func configureToolbar() {
        guard let window = self.window else { return }
        
        let toolbar = MKToolbar(identifier: .mainWindowToolbarIdentifier)
        toolbar.delegate = self
        
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.centeredItemIdentifier = .searchBarAndTabStripIdentifier
        
        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unified
        }
        window.titleVisibility = .hidden
        
        window.toolbar = toolbar
        window.toolbar?.validateVisibleItems()
        window.toolbar?.displayMode = .iconOnly
    }
    
}

extension MKWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.windowsListMenuItemIdentifier, .backForwardBtnItemIdentifier, .flexibleSpace, .searchBarAndTabStripIdentifier, .flexibleSpace, .newTabButtonIdentifier]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.windowsListMenuItemIdentifier, .backForwardBtnItemIdentifier, .searchBarAndTabStripIdentifier, .newTabButtonIdentifier, .flexibleSpace]
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        print("will add to toolbar")
        guard let userInfo = notification.userInfo as? [String : Any] else { return }
        guard let toolbarItem = userInfo["item"] as? NSToolbarItem else { return }
        if toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier {
            toolbarItem.minSize.width = self.window!.frame.width / 1.7
            (toolbarItem.view as? CompactAddressBarAndTabsView)?.reloadData()
        }
    }
    
    func toolbarDidRemoveItem(_ notification: Notification) {
        print("did remove from toolbar")
    }
    
    @objc func toolbarPickerDidSelectItem(_ sender: Any) {
        print("Hit detect")
    }
    
    @objc func toolbarNavigationPressed(_ sender: Any) {
        guard let sender = sender as? NSToolbarItem else { return }
        print("Hit detect toolbar")
        guard webViewContainer.currentTabIndex >= 0 else { return }
        if sender.label == "Back" {
            // Back button pressed
            webViewContainer.tabs[webViewContainer.currentTabIndex].goBack(sender)
        } else if sender.label == "Forward" {
            // Forward button pressed
            webViewContainer.tabs[webViewContainer.currentTabIndex].goForward(sender)
        }
    }
    
    @objc func newTabBtnPressed(_ sender: Any) {
        print("Adding New Tab")
        webViewContainer.appendTab(shouldSwitch: true)
    }
    
    @objc func bringWindowFromWCAtIndex(_ sender: NSMenuItem) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            let wc = appDelegate.wcList[sender.tag]
            wc.showWindow(nil)
        }
    }
    
    @objc func popupWindowsListMenu(_ sender: NSButton) {
        let btnMenu = {
            let menu = NSMenu()
            var menuItems = [NSMenuItem]()
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                for (idx, wc) in appDelegate.wcList.enumerated() {
                    if wc == self { continue }
                    let menuItem = NSMenuItem(title: wc.window?.title ?? "Untitled Window", action: nil, keyEquivalent: "")
                    menuItem.tag = idx
                    menuItem.action = #selector(bringWindowFromWCAtIndex)
                    menuItems.append(menuItem)
                }
            }
            let menuItem3 = NSMenuItem.separator()
            let menuItem4 = NSMenuItem(title: "Close This Window", action: #selector(self.window?.close), keyEquivalent: "W")
            menu.items = menuItems + [menuItem3, menuItem4]
            return menu
        }()
        let p = NSPoint(x: sender.frame.origin.x, y: sender.frame.origin.y)
        btnMenu.popUp(positioning: nil, at: p, in: sender.superview)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .backForwardBtnItemIdentifier:
            let titles = ["Back", "Forward"]
            let images = [NSImage(named: NSImage.goBackTemplateName)!,
                          NSImage(named: NSImage.goForwardTemplateName)!]
            
            let toolbarItemGroup: NSToolbarItemGroup
            if #available(macOS 10.15, *) {
                toolbarItemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: images, selectionMode: .momentary, labels: titles, target: nil, action: nil)
                for item in toolbarItemGroup.subitems {
                    item.target = self
                    item.action = #selector(toolbarNavigationPressed(_:))
                }
                toolbarItemGroup.controlRepresentation = .automatic
                toolbarItemGroup.selectionMode = .momentary
            } else {
                toolbarItemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                toolbarItemGroup.subitems = zip(images, titles).map({ image, title in
                    let item = NSToolbarItem()
                    item.image = image
                    item.label = title
                    item.target = self
                    item.action = #selector(toolbarNavigationPressed(_:))
                    return item
                })
            }
            toolbarItemGroup.visibilityPriority = .high
            toolbarItemGroup.label = "Back/Forward"
            toolbarItemGroup.paletteLabel = "Navigation controls"
            toolbarItemGroup.toolTip = "Go to the previous or the next page"
            return toolbarItemGroup
            
        case .windowsListMenuItemIdentifier:
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            
            let popupBtn = NSButton()
            popupBtn.title = self.window?.title ?? "Untitled Window"
            popupBtn.target = self
            popupBtn.action = #selector(popupWindowsListMenu)
            popupBtn.bezelStyle = .texturedRounded
            popupBtn.imagePosition = .imageTrailing
            let mkNSImage = NSImage(size: NSSize(width: 12, height: 6), flipped: false, drawingHandler: { destinationRect in
                let img = NSImage(named: NSImage.touchBarGoDownTemplateName)!.tint(color: .controlTextColor)
                img.draw(in: destinationRect)
                return true
            })
            mkNSImage.cacheMode = .never
            popupBtn.image = mkNSImage
            
            toolbarItem.view = popupBtn
            toolbarItem.label = "Windows"
            toolbarItem.paletteLabel = "Windows List"
            toolbarItem.toolTip = "Displays all the open windows in the browser"
            toolbarItem.visibilityPriority = .low
            return toolbarItem
            
        case .searchBarAndTabStripIdentifier:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.visibilityPriority = .user
            let compactAddressBarAndTabsView = CompactAddressBarAndTabsView(frame: CGRect(x: 0, y: 0, width: self.window!.frame.width / 1.7, height: 30), webViewContainer: self.webViewContainer)
            compactAddressBarAndTabsView.autoresizingMask = [.width]
            compactAddressBarAndTabsView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            item.view = compactAddressBarAndTabsView
            item.minSize.width = self.window!.frame.width / 1.7
            return item
            
        case .newTabButtonIdentifier:
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.target = self
            toolbarItem.action = #selector(newTabBtnPressed(_:))
            toolbarItem.label = "New Tab"
            toolbarItem.toolTip = "Opens a new tab"
            toolbarItem.image = NSImage(named: NSImage.addTemplateName)
            if #available(macOS 10.15, *) {
                toolbarItem.isBordered = true
            }
            return toolbarItem
        default:
            let toolbarItem = NSToolbarItem()
            return toolbarItem
        }
    }
}

extension NSToolbar.Identifier {
    static let mainWindowToolbarIdentifier = NSToolbar.Identifier("MainWindowToolbar")
}

extension NSToolbarItem.Identifier {
    static let backForwardBtnItemIdentifier = NSToolbarItem.Identifier("BackForwardBtnItem")
    static let searchBarAndTabStripIdentifier = NSToolbarItem.Identifier("SearchBarItem")
    static let newTabButtonIdentifier = NSToolbarItem.Identifier("NewTabButton")
    static let windowsListMenuItemIdentifier = NSToolbarItem.Identifier("WindowsListMenuItem")
}

extension String {
    var isValidURL: Bool {
        if self == "about:blank" { return true }
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    var isFileURL: Bool {
        if self.hasPrefix("file://") {
            if let url = URL(string: self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                if FileManager.default.fileExists(atPath: url.path) {
                    return true
                }
            }
        }
        return false
    }
}

extension MKWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        print("window close received: old size =", appDelegate.wcList.count)
        appDelegate.wcList.removeAll { windowController in
            windowController == self
        }
        print(appDelegate.wcList.count)
    }
    
    func windowDidResize(_ notification: Notification) {
        for item in self.window?.toolbar?.items ?? [] {
            if item.itemIdentifier == .searchBarAndTabStripIdentifier {
                item.minSize.width = self.window!.frame.width / 1.7
            }
        }
    }
}

extension MKWindowController {
    private func configureTitlebarAccessoryView()
    {
        if  let titlebarController = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ProgressIndicatorTitlebarAccessoryViewController")) as? ProgressIndicatorTitlebarAccessoryViewController {
            titlebarController.layoutAttribute = .bottom
            titlebarController.fullScreenMinHeight = titlebarController.view.bounds.height
            self.window?.addTitlebarAccessoryViewController(titlebarController)
            self.titlebarAccessoryViewController = titlebarController
            self.titlebarAccessoryViewController?.isHidden = true
        }
    }
}

extension NSImage {
    // Remember, works for template images only
    func tint(color: NSColor) -> NSImage {
        return NSImage(size: size, flipped: false) { (rect) -> Bool in
            color.set()
            rect.fill()
            self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .destinationIn, fraction: 1.0)
            return true
        }
    }
}

//
//  MKWindowController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

class MKWindowController: NSWindowController {
    
    var addressBarToolbarItem: NSToolbarItem?
    var titlebarAccessoryViewController: ProgressIndicatorTitlebarAccessoryViewController?
    var stupidCounter: Int = 0
    var addressBarToolbarItemSizeConstraint: NSLayoutConstraint?
    
    var actionsMenu: NSMenu = {
        var menu = NSMenu(title: "")
        let menuItem1 = NSMenuItem(title: "Get info", action: nil, keyEquivalent: "")
        let menuItem2 = NSMenuItem(title: "Quick Look", action: nil, keyEquivalent: "")
        let menuItem3 = NSMenuItem.separator()
        let menuItem4 = NSMenuItem(title: "Move to trash...", action: nil, keyEquivalent: "")
        menu.items = [menuItem1, menuItem2, menuItem3, menuItem4]
        return menu
    }()

    override func windowDidLoad() {
        self.window?.setFrameAutosaveName("MKMainWindow")
        self.window?.backgroundColor = .windowBackgroundColor
        super.windowDidLoad()
        let minSize = NSSize(width: 570, height: 220)
        self.window?.minSize = minSize
        
        if let mainWindow = self.window, mainWindow.frame.width < minSize.width || mainWindow.frame.height < minSize.height {
            var frameRect = mainWindow.frame
            frameRect.size = CGSize(width: minSize.width, height: minSize.height)
            self.window?.setFrame(frameRect, display: true, animate: true)
        }
        configureToolbar()
        self.window?.makeFirstResponder(
            self.window?.toolbar?.items.first { item in
                item.itemIdentifier == .searchBarAndTabStripIdentifier
            }?.view?.subviews.first { subView in
                subView is NSSearchField
            }
        )
        configureTitlebarAccessoryView()
    }
    
    func configureToolbar() {
        guard let window = self.window else { return }
        
        let toolbar = MKToolbar(identifier: .mainWindowToolbarIdentifier)
        toolbar.delegate = self
        
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.centeredItemIdentifier = .searchBarAndTabStripIdentifier
        
        window.title = "Sweet Browser"
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
        if sender.label == "Back" {
            // Back button pressed
            (self.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView)?.goBack()
        } else if sender.label == "Forward" {
            // Forward button pressed
            (self.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView)?.goForward()
        }
    }
    
    @objc func newTabBtnPressed(_ sender: Any) {
        print("Adding New Tab")
        (self.window?.toolbar?.items.first(where: { toolbarItem in
            toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
        })?.view as? CompactAddressBarAndTabsView)?.createNewTab(url: nil)
//        self.addressBarAndTabsView?.createNewTab(url: nil)
//        (self.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView)?.createNewTab(url: nil)
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
            toolbarItemGroup.label = "Back/Forward"
            toolbarItemGroup.paletteLabel = "Navigation controls"
            toolbarItemGroup.toolTip = "Go to the previous or the next page"
            return toolbarItemGroup
            
        case .windowsListMenuItemIdentifier:
            let toolbarItem: NSToolbarItem
            if #available(macOS 10.15, *) {
                let toolbarMenuItem = NSMenuToolbarItem(itemIdentifier: itemIdentifier)
                toolbarMenuItem.showsIndicator = true
                toolbarMenuItem.menu = self.actionsMenu
                toolbarMenuItem.isBordered = false
                toolbarMenuItem.title = "Window 1"
                toolbarItem = toolbarMenuItem
            } else {
                toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            }
            toolbarItem.label = "Windows"
            toolbarItem.paletteLabel = "Windows List"
            toolbarItem.toolTip = "Displays all the open windows in the browser"
            toolbarItem.visibilityPriority = .low
            return toolbarItem
        
        case .searchBarAndTabStripIdentifier:
            print("item requested")
            print((toolbar as! MKToolbar).isCustomizing, toolbar.customizationPaletteIsRunning)
            print("nil = \(addressBarToolbarItem == nil)")
            print((addressBarToolbarItem?.view as? CompactAddressBarAndTabsView)?.tabs.count)
            
            if (toolbar as! MKToolbar).isCustomizing || addressBarToolbarItem == nil {
                print("IF CASE")
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                let compactAddressBarAndTabsView = CompactAddressBarAndTabsView(frame: CGRect(x: 0, y: 0, width: self.window!.frame.width / 1.5, height: 40))
                compactAddressBarAndTabsView.delegate = self.contentViewController as? CompactAddressBarAndTabsViewDelegate
                item.view = compactAddressBarAndTabsView
                item.view?.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
                self.addressBarToolbarItemSizeConstraint?.isActive = false
                self.addressBarToolbarItemSizeConstraint = item.view?.widthAnchor.constraint(equalToConstant: self.window!.frame.width / 1.5)
                self.addressBarToolbarItemSizeConstraint?.isActive = true
                addressBarToolbarItem = ((toolbar as! MKToolbar).isCustomizing) ? addressBarToolbarItem : item
                return item
            } else if toolbar.customizationPaletteIsRunning {
                return addressBarToolbarItem
            } else {
                return addressBarToolbarItem
            }
            
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
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

extension MKWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        for item in self.window?.toolbar?.items ?? [] {
            if item.itemIdentifier == .searchBarAndTabStripIdentifier {
                self.addressBarToolbarItemSizeConstraint?.isActive = false
                self.addressBarToolbarItemSizeConstraint = item.view?.widthAnchor.constraint(equalToConstant: self.window!.frame.width / 1.5)
                self.addressBarToolbarItemSizeConstraint?.isActive = true
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

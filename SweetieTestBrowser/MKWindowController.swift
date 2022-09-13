//
//  MKWindowController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

class MKWindowController: NSWindowController {
    
    var addressBarAndTabsView: CompactAddressBarAndTabsView?

    override func windowDidLoad() {
        self.window?.setFrameAutosaveName("MKMainWindow")
        self.window?.backgroundColor = .windowBackgroundColor
        super.windowDidLoad()
        let minSize = NSSize(width: 570, height: 220)
        
        if let mainWindow = self.window, mainWindow.frame.width < minSize.width || mainWindow.frame.height < minSize.height {
            var frameRect = mainWindow.frame
            frameRect.size = CGSize(width: minSize.width, height: minSize.height)
            self.window?.setFrame(frameRect, display: true, animate: true)
        }
        configureToolbar()
    }
    
    func configureToolbar() {
        guard let window = self.window else { return }
        
        let toolbar = NSToolbar(identifier: .mainWindowToolbarIdentifier)
        toolbar.delegate = self
        
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        toolbar.centeredItemIdentifier = .searchBarAndTabStripIdentifier
        
        window.title = "Sweet Browser"
        if #available(macOS 11.0, *) {
            window.subtitle = "by Maheep Kumar Kathuria"
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
        return [.backForwardBtnItemIdentifier, .flexibleSpace, .searchBarAndTabStripIdentifier, .flexibleSpace, .newTabButtonIdentifier]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.backForwardBtnItemIdentifier, .searchBarAndTabStripIdentifier, .newTabButtonIdentifier, .flexibleSpace]
    }
    
    @objc func toolbarPickerDidSelectItem(_ sender: Any) {
        print("Hit detect")
    }
    
    @objc func newTabBtnPressed(_ sender: Any) {
        print("Adding New Tab")
        self.addressBarAndTabsView?.addressBarAndSearchField.stringValue = ""
        self.addressBarAndTabsView?.createNewTab(url: nil)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .backForwardBtnItemIdentifier:
            let titles = ["Back", "Forward"]
            let images = [NSImage(named: NSImage.goBackTemplateName)!,
                          NSImage(named: NSImage.goForwardTemplateName)!]
            
            let toolbarItemGroup: NSToolbarItemGroup
            if #available(macOS 10.15, *) {
                toolbarItemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: images, selectionMode: .momentary, labels: titles, target: self, action: #selector(toolbarPickerDidSelectItem(_:)))
                toolbarItemGroup.controlRepresentation = .automatic
                toolbarItemGroup.selectionMode = .momentary
            } else {
                toolbarItemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
                toolbarItemGroup.subitems = zip(images, titles).map({ image, title in
                    let item = NSToolbarItem()
                    item.image = image
                    item.label = title
                    item.target = self
                    item.action = #selector(toolbarPickerDidSelectItem(_:))
                    return item
                })
            }
            toolbarItemGroup.label = "Back/Forward"
            toolbarItemGroup.paletteLabel = "Navigation controls"
            toolbarItemGroup.toolTip = "Go to the previous or the next page"
            return toolbarItemGroup
        
        case .searchBarAndTabStripIdentifier:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let compactAddressBarAndTabsView = CompactAddressBarAndTabsView(frame: CGRect(x: 0, y: 0, width: self.window!.frame.width / 2.5, height: 40))
            compactAddressBarAndTabsView.delegate = self.contentViewController as? CompactAddressBarAndTabsViewDelegate
            item.view = compactAddressBarAndTabsView
            item.view?.heightAnchor.constraint(equalToConstant: 30).isActive = true
            let widthConst = item.view?.widthAnchor.constraint(equalToConstant: self.window!.frame.width / 2.5)
            widthConst?.isActive = true
            widthConst?.identifier = "SearchbarWidthConst"
            addressBarAndTabsView = compactAddressBarAndTabsView
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
                if let constraintToRemove = item.view?.constraints.first(where: { constraint in
                    constraint.identifier == "SearchbarWidthConst"
                }) {
                    item.view?.removeConstraint(constraintToRemove)
                }
                let widthConst = item.view?.widthAnchor.constraint(equalToConstant: self.window!.frame.width / 2.5)
                widthConst?.isActive = true
                widthConst?.identifier = "SearchbarWidthConst"
            }
        }
    }
}

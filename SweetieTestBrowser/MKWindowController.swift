//
//  MKWindowController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

class MKWindowController: NSWindowController {
    
    var searchField: NSSearchField?

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.zoom(self)
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
    
    @objc func toolbarPickerDidSelectItem(_ sender: Any)
    {
        print("Hit detect")
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
            let field = NSSearchField()
            field.placeholderString = "Enter a URL, or search something..."
            field.delegate = self
            item.view = field
            item.minSize = CGSize(width: 1000, height: 0)
            item.maxSize = CGSize(width: (self.window?.frame.width ?? 100)/2, height: 0)
            self.searchField = field
            return item
        case .newTabButtonIdentifier:
            let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            toolbarItem.target = self
            toolbarItem.action = #selector(toolbarPickerDidSelectItem(_:))
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

extension MKWindowController: NSSearchFieldDelegate {
    //something here
}

extension NSToolbar.Identifier {
    static let mainWindowToolbarIdentifier = NSToolbar.Identifier("MainWindowToolbar")
}

extension NSToolbarItem.Identifier {
    static let backForwardBtnItemIdentifier = NSToolbarItem.Identifier("BackForwardBtnItem")
    static let searchBarAndTabStripIdentifier = NSToolbarItem.Identifier("SearchBarItem")
    static let newTabButtonIdentifier = NSToolbarItem.Identifier("NewTabButton")
}

extension MKWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        print(self.window?.frame)
        
    }
}

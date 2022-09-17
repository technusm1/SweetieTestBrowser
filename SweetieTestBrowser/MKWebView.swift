//
//  MKWebView.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 15/09/22.
//

import Cocoa
import WebKit

class MKWebView: WKWebView {
    var contextMenuAction: MKWebViewContextMenuAction?
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        var items = menu.items
        
        let itemsToRemove = Set(["WKMenuItemIdentifierDownloadLinkedFile", "WKMenuItemIdentifierDownloadImage", "WKMenuItemIdentifierDownloadMedia"])
        for menuId in (0..<menu.items.count).reversed() {
            if let id = menu.items[menuId].identifier?.rawValue, itemsToRemove.contains(id) {
                items.remove(at: menuId)
            }
        }
        
        // For all menu default items which open a new Window, we add custom menu items
        // to open the object in a new Tab and to add them to the bookmarks.
        for idx in (0..<items.count).reversed() {
            if let id = items[idx].identifier?.rawValue {
                if id == "WKMenuItemIdentifierOpenLinkInNewWindow" ||
                    id == "WKMenuItemIdentifierOpenImageInNewWindow" ||
                    id == "WKMenuItemIdentifierOpenMediaInNewWindow" ||
                    id == "WKMenuItemIdentifierOpenFrameInNewWindow" {
                    
                    let object:String
                    if id == "WKMenuItemIdentifierOpenLinkInNewWindow" {
                        object = "Link"
                    } else if id == "WKMenuItemIdentifierOpenImageInNewWindow" {
                        object = "Image"
                    } else if id == "WKMenuItemIdentifierOpenMediaInNewWindow" {
                        object = "Video"
                    } else {
                        object = "Frame"
                    }
                    
                    let action = #selector(processMenuItem(_:))
                    
                    let title = "Open \(object) in New Tab"
                    let tabMenuItem = NSMenuItem(title:title, action:action, keyEquivalent:"")
                    tabMenuItem.identifier = NSUserInterfaceItemIdentifier("openInNewTab")
                    tabMenuItem.target = self
                    tabMenuItem.representedObject = items[idx]
                    items.insert(tabMenuItem, at: idx+1)
                }
            }
        }
        
        menu.items = items
    }
    
    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        // code here
        super.didCloseMenu(menu, with: event)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.contextMenuAction = nil
        }
    }
    
    @objc func processMenuItem(_ menuItem: NSMenuItem) {
        self.contextMenuAction = nil
        if let originalMenu = menuItem.representedObject as? NSMenuItem {
            if menuItem.identifier?.rawValue == "openInNewTab" {
                self.contextMenuAction = .openInNewTab
            }
            
            if let action = originalMenu.action {
                _ = originalMenu.target?.perform(action, with: originalMenu)
            }
        }
    }
}

enum MKWebViewContextMenuAction {
    case openInNewTab
}

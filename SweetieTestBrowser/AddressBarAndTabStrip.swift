//
//  AddressBarAndTabStrip.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

class AddressBarAndTabStripToolbarItem: NSToolbarItemGroup {
    var searchField: NSSearchField
    var tabsBtnList: [NSToolbarItem] = []
    
    init(itemIdentifier: NSToolbarItem.Identifier, searchField: NSSearchField) {
        self.searchField = searchField
        super.init(itemIdentifier: itemIdentifier)
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = self.searchField
        item.visibilityPriority = .user
        self.subitems = [item]
    }
    
    
}

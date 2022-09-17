//
//  TabContainer.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 17/09/22.
//

import Foundation

// Plan is to have one container per window, so per window tabbing support can be implemented
class TabContainer {
    var tabs: [MKTabView] = []
    var currentTabIndex: Int = -1
    var delegate: TabContainerDelegate?
    
    func addTab(_ tab: MKTabView, shouldSwitch: Bool = true) {
        tabs.append(tab)
        if shouldSwitch {
            currentTabIndex = tabs.count - 1
        }
    }
    
    func removeTab(_ tab: MKTabView, at index: Int) {
        self.delegate?.tabContainer(tabRemoved: tabs.remove(at: index), atIndex: index)
    }
}

protocol TabContainerDelegate {
    // This method is called when a tab switch happens, or when user enters a new URL in a tab
    func tabContainer(didSelectTab tab: MKTabView, atIndex index: Int, fromIndex previousIndex: Int)
    // This method is called when a tab is removed, i.e. when tab is closed by the user
    func tabContainer(tabRemoved tab: MKTabView, atIndex index: Int)
}

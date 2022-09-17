//
//  AppDelegate.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func newTabMenuItemPressed(_ sender: NSMenuItem) {
        print("New tab action")
        guard let activeWindow = NSApplication.shared.keyWindow else { return }
        guard let wc = activeWindow.windowController as? MKWindowController else { return }
        wc.newTabBtnPressed(sender)
    }
    
    @IBAction func closeTabMenuItemPressed(_ sender: NSMenuItem) {
        print("Close tab action")
        guard let activeWindow = NSApplication.shared.keyWindow else { return }
        guard let wc = activeWindow.windowController as? MKWindowController else { return }
        guard let addressBarView = wc.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView else { return }
        addressBarView.closeTab(atIndex: addressBarView.currentTabIndex)
    }
    
    @IBAction func switchToNextTabMenuItemPressed(_ sender: NSMenuItem) {
        guard let activeWindow = NSApplication.shared.keyWindow else { return }
        guard let wc = activeWindow.windowController as? MKWindowController else { return }
        guard let addressBarView = wc.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView else { return }
        
        let tabCount = addressBarView.tabs.count
        guard tabCount != 0 else { return }
        
        addressBarView.currentTabIndex = (addressBarView.currentTabIndex + 1) % tabCount
    }
    
    @IBAction func switchToPreviousTabMenuItemPressed(_ sender: Any) {
        guard let activeWindow = NSApplication.shared.keyWindow else { return }
        guard let wc = activeWindow.windowController as? MKWindowController else { return }
        guard let addressBarView = wc.addressBarToolbarItem?.view as? CompactAddressBarAndTabsView else { return }
        
        let tabCount = addressBarView.tabs.count
        guard tabCount != 0 else { return }
        addressBarView.currentTabIndex = (addressBarView.currentTabIndex - 1 + tabCount) % tabCount
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}


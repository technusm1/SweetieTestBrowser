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
        wc.addressBarAndTabsView?.closeTab(atIndex: wc.addressBarAndTabsView?.currentTabIndex ?? -1)
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


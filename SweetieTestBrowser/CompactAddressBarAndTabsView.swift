//
//  CompactAddressBarAndTabsView.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 10/09/22.
//

import Cocoa

class CompactAddressBarAndTabsView: NSView {
    var addressBarAndSearchField: NSSearchField
    
    var btnReloadOrStop: NSButton?
    
    var tabContainerScrollView: NSScrollView?
    var tabs: [TabView]
    
    required init?(coder: NSCoder) {
        self.addressBarAndSearchField = NSSearchField()
        self.tabs = []
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        self.addressBarAndSearchField = NSSearchField(frame: frameRect)
        self.tabs = []
        super.init(frame: frameRect)
    }
    
    func setupView() {
        self.addressBarAndSearchField.placeholderString = "Enter a URL, or search something..."
        self.addressBarAndSearchField.delegate = self
        self.addressBarAndSearchField.target = self
        self.addressBarAndSearchField.action = #selector(loadURL)
        self.addSubview(self.addressBarAndSearchField)
        
        let reloadButton = NSButton(image: NSImage(named: NSImage.refreshTemplateName)!, target: self, action: #selector(reloadCurrentURL))
        reloadButton.isBordered = false
        reloadButton.bezelStyle = .regularSquare
//        self.btnReloadOrStop = reloadButton
        addSubview(reloadButton)
        
        let stopLoadButton = NSButton(image: NSImage(named: NSImage.stopProgressTemplateName)!, target: self, action: #selector(disableLoadingForCurrentURL))
        stopLoadButton.isBordered = false
        stopLoadButton.bezelStyle = .regularSquare
//        self.btnReloadOrStop = stopLoadButton
        addSubview(stopLoadButton)
        
        
        
    }
    
    @objc func loadURL() {}
    
    @objc func reloadCurrentURL() {}
    
    @objc func disableLoadingForCurrentURL() {}
}

extension CompactAddressBarAndTabsView: NSSearchFieldDelegate {
    // here
}

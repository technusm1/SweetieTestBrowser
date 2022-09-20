//
//  CompactAddressBarAndTabsView.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 10/09/22.
//

import Cocoa
import WebKit

class CompactAddressBarAndTabsView: NSView {
    var webViewContainer: WebViewContainer
    
    var addressBarAndSearchField: NSSearchField
    
    var btnReload: NSButton!
    var btnStopLoad: NSButton!
    
    var tabContainerScrollView: NSScrollView?
    var tabs: [MKTabView]
    var tabAnimationDuration: TimeInterval = 0.4
    
    var temporaryConstraintsStorage: [NSLayoutConstraint] = []
    var persistentConstraintsStorage: [NSLayoutConstraint] = []
    var zeroTabsConstraintsStorage: [NSLayoutConstraint] = []
    var oneOrMoreTabsConstraintsStorage: [NSLayoutConstraint] = []
    var lessThan12TabsConstraintsStorage: [NSLayoutConstraint] = []
    var moreThan12TabsConstraintsStorage: [NSLayoutConstraint] = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame frameRect: NSRect, webViewContainer: WebViewContainer) {
        self.addressBarAndSearchField = NSSearchField(frame: frameRect)
        self.webViewContainer = webViewContainer
        self.tabs = []
        super.init(frame: frameRect)
        for (idx, webView) in webViewContainer.tabs.enumerated() {
            let tab = makeTabView(from: webView)
            if webViewContainer.currentTabIndex == idx {
                tab.isSelected = true
            }
            self.tabs.append(tab)
        }
        setupView()
        setupViewConstraints()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            layoutTabs()
            self.layoutSubtreeIfNeeded()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabAppendedNotification(_:)), name: .tabAppended, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabDeletedNotification(_:)), name: .tabDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabSwitchedNotification(_:)), name: .tabSwitched, object: nil)
    }
    
    private func makeTabView(from webView: MKWebView) -> MKTabView {
        let tabView = MKTabView(frame: .zero, webView: webView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.onSelect = {
            self.webViewContainer.currentTabIndex = tabView.webView.tag
        }
        tabView.onClose = {
            print("on close action = ", tabView.webView.tag)
            self.webViewContainer.deleteTab(atIndex: tabView.webView.tag)
        }
        return tabView
    }
    
    func reloadData() {
        // Cleanup first
        self.tabContainerScrollView?.documentView?.subviews.removeAll()
        self.tabs.removeAll()
        NSLayoutConstraint.deactivate(self.temporaryConstraintsStorage)
        self.temporaryConstraintsStorage.removeAll()
        NSLayoutConstraint.deactivate(self.persistentConstraintsStorage)
        self.persistentConstraintsStorage.removeAll()
        NSLayoutConstraint.deactivate(self.zeroTabsConstraintsStorage)
        self.zeroTabsConstraintsStorage.removeAll()
        NSLayoutConstraint.deactivate(self.oneOrMoreTabsConstraintsStorage)
        self.oneOrMoreTabsConstraintsStorage.removeAll()
        NSLayoutConstraint.deactivate(self.lessThan12TabsConstraintsStorage)
        self.lessThan12TabsConstraintsStorage.removeAll()
        NSLayoutConstraint.deactivate(self.moreThan12TabsConstraintsStorage)
        self.moreThan12TabsConstraintsStorage.removeAll()
        
        
        for (idx, webView) in webViewContainer.tabs.enumerated() {
            let tab = makeTabView(from: webView)
            if webViewContainer.currentTabIndex == idx {
                tab.isSelected = true
            }
            self.tabs.append(tab)
        }
        self.tabs.forEach { tabview in
            self.tabContainerScrollView?.documentView?.addSubview(tabview)
        }
        setupViewConstraints()
        layoutTabs()
    }
    
    private func setupView() {
        self.wantsLayer = true
        
        self.addressBarAndSearchField.placeholderString = "Enter a URL, or search something..."
        self.addressBarAndSearchField.target = self
        self.addressBarAndSearchField.action = #selector(loadURL(_:))
        self.addressBarAndSearchField.translatesAutoresizingMaskIntoConstraints = false
        self.addressBarAndSearchField.maximumRecents = 10
        self.addressBarAndSearchField.sendsWholeSearchString = true
        self.addressBarAndSearchField.sendsSearchStringImmediately = false
        self.addressBarAndSearchField.wantsLayer = true
        
        addSubview(self.addressBarAndSearchField)
        
        let reloadButton = NSButton(image: NSImage(named: NSImage.refreshTemplateName)!, target: self, action: #selector(reloadCurrentURL))
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.isBordered = false
        reloadButton.bezelStyle = .regularSquare
        self.btnReload = reloadButton
        self.btnReload.isHidden = true
        addSubview(self.btnReload)
        
        let stopLoadButton = NSButton(image: NSImage(named: NSImage.stopProgressTemplateName)!, target: self, action: #selector(disableLoadingForCurrentURL))
        stopLoadButton.translatesAutoresizingMaskIntoConstraints = false
        stopLoadButton.isBordered = false
        stopLoadButton.bezelStyle = .regularSquare
        self.btnStopLoad = stopLoadButton
        self.btnStopLoad.isHidden = true
        addSubview(self.btnStopLoad)
        
        // init the scroll view
        self.tabContainerScrollView = NSScrollView()
        self.tabContainerScrollView?.wantsLayer = true
        self.tabContainerScrollView?.translatesAutoresizingMaskIntoConstraints = false
        self.tabContainerScrollView?.borderType = .noBorder
        self.tabContainerScrollView?.drawsBackground = false
        self.tabContainerScrollView?.hasHorizontalScroller = true
        self.tabContainerScrollView?.horizontalScroller?.alphaValue = 0
        self.tabContainerScrollView?.horizontalScroller?.scrollerStyle = .overlay
        addSubview(self.tabContainerScrollView!)
        
        let clipView = NSClipView()
        clipView.wantsLayer = true
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        self.tabContainerScrollView?.contentView = clipView
        
        let documentView = NSView()
        documentView.wantsLayer = true
        documentView.translatesAutoresizingMaskIntoConstraints = false
        // Add tabs to documentView
        self.tabs.forEach(documentView.addSubview(_:))
        
        self.tabContainerScrollView?.documentView = documentView
    }
    
    private func setupViewConstraints() {
        // By here, we assume that subviews have been constructed
        self.translatesAutoresizingMaskIntoConstraints = true
        
        self.persistentConstraintsStorage = [
            // Height constraints first
            self.addressBarAndSearchField.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.tabContainerScrollView!.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.tabContainerScrollView!.contentView.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.tabContainerScrollView!.documentView!.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.btnReload.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.btnStopLoad.heightAnchor.constraint(equalTo: self.heightAnchor),
            
            // Scrollview constraints
            self.tabContainerScrollView!.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tabContainerScrollView!.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            // Setup reload and stopLoad buttons
            self.btnReload.centerYAnchor.constraint(equalTo: self.addressBarAndSearchField.centerYAnchor),
            self.btnReload.trailingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: -24),
            self.btnStopLoad.centerYAnchor.constraint(equalTo: self.btnReload.centerYAnchor),
            self.btnStopLoad.centerXAnchor.constraint(equalTo: self.btnReload.centerXAnchor)
        ]
        NSLayoutConstraint.activate(self.persistentConstraintsStorage)
        
        self.zeroTabsConstraintsStorage = [
            self.addressBarAndSearchField.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.addressBarAndSearchField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.addressBarAndSearchField.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5)
        ]
        
        self.oneOrMoreTabsConstraintsStorage = [
            self.addressBarAndSearchField.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.5),
            self.addressBarAndSearchField.widthAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor, multiplier: 0.4),
            self.addressBarAndSearchField.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            
            // Scrollview constraints
            self.tabContainerScrollView!.leadingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: 10),
            self.tabContainerScrollView!.contentView.leadingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: 10),
            self.tabContainerScrollView!.documentView!.leadingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: 10)
        ]
        
        self.lessThan12TabsConstraintsStorage = [
            self.tabContainerScrollView!.documentView!.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ]
        
        // For more than or equal to 12, we'll simply deactivate less than 12 constraints
    }
    
    func layoutTabs() {
        print("Laying out \(self.tabs.count) tabs")
        var compactMode = false
        NSLayoutConstraint.deactivate(self.temporaryConstraintsStorage)
        self.temporaryConstraintsStorage.removeAll()
        if self.tabs.isEmpty {
            NSLayoutConstraint.deactivate(oneOrMoreTabsConstraintsStorage)
            NSLayoutConstraint.activate(zeroTabsConstraintsStorage)
        } else {
            NSLayoutConstraint.deactivate(zeroTabsConstraintsStorage)
        }
        if self.tabs.count >= 1 {
            NSLayoutConstraint.activate(oneOrMoreTabsConstraintsStorage)
        } else {
            NSLayoutConstraint.deactivate(oneOrMoreTabsConstraintsStorage)
        }
        if self.tabs.count >= 6 {
            compactMode = true
        } else {
            compactMode = false
        }
        // The if-else statement below covers both less than, equal to and more than 12 cases
        if self.tabs.count < 12 {
            NSLayoutConstraint.activate(lessThan12TabsConstraintsStorage)
        } else {
            NSLayoutConstraint.deactivate(lessThan12TabsConstraintsStorage)
        }
        var previousTab: MKTabView?
        for (idx, currentTab) in self.tabs.enumerated() {
            currentTab.compactMode = compactMode
            self.temporaryConstraintsStorage.append(contentsOf: [
                currentTab.heightAnchor.constraint(equalTo: self.heightAnchor),
                currentTab.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
            if self.tabs.count < 12 {
                if idx != self.webViewContainer.currentTabIndex {
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(lessThanOrEqualToConstant: 140),
                        // The hope is that we'll never reach this size, even if window resizes
                        currentTab.widthAnchor.constraint(greaterThanOrEqualTo: self.tabContainerScrollView!.widthAnchor, multiplier: 1.0/20)
                    ])
                } else {
                    currentTab.compactMode = false
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalToConstant: 140)
                    ])
                }
            } else {
                if idx != self.webViewContainer.currentTabIndex {
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalTo: self.tabContainerScrollView!.contentView.widthAnchor, multiplier: 1.0/11)
                    ])
                } else {
                    currentTab.compactMode = false
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalToConstant: 140)
                    ])
                }
            }
            if let previousTab = previousTab {
                self.temporaryConstraintsStorage.append(contentsOf: [
                    currentTab.leadingAnchor.constraint(equalTo: previousTab.trailingAnchor, constant: 5)
                ])
                if idx != self.webViewContainer.currentTabIndex && idx != self.webViewContainer.currentTabIndex + 1 {
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalTo: previousTab.widthAnchor)
                    ])
                } else if idx == self.webViewContainer.currentTabIndex + 1 && idx >= 2 {
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalTo: self.tabs[idx - 2].widthAnchor)
                    ])
                }
            } else {
                self.temporaryConstraintsStorage.append(contentsOf: [
                    currentTab.leadingAnchor.constraint(equalTo: self.tabContainerScrollView!.documentView!.leadingAnchor, constant: 5)
                ])
            }
            previousTab = currentTab
            NSLayoutConstraint.activate(temporaryConstraintsStorage)
        }
        if let previousTab = previousTab {
            if self.tabs.count < 6 {
                self.temporaryConstraintsStorage.append(contentsOf: [
                    self.tabContainerScrollView!.documentView!.trailingAnchor.constraint(greaterThanOrEqualTo: previousTab.trailingAnchor, constant: 5)
                ])
            } else {
                self.temporaryConstraintsStorage.append(contentsOf: [
                    self.tabContainerScrollView!.documentView!.trailingAnchor.constraint(equalTo: previousTab.trailingAnchor, constant: 5)
                ])
            }
            
        }
        NSLayoutConstraint.activate(self.temporaryConstraintsStorage)
    }
    
    @objc func tabAppendedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : AnyObject] else { return }
        guard let webView = userInfo["webView"] as? MKWebView else { return }
        guard let shouldSwitch = userInfo["shouldSwitch"] as? Bool else { return }
        let tab = makeTabView(from: webView)
        self.tabs.append(tab)
        self.tabContainerScrollView?.documentView?.addSubview(tab)
        // This may not switch to a new tab automatically, so we need to call layoutTabs
        if !shouldSwitch {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                layoutTabs()
                self.layoutSubtreeIfNeeded()
            }
        }
//        scrollToTabInScrollView()
    }
    
    @objc func tabDeletedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : AnyObject] else { return }
        guard let webView = userInfo["webView"] as? MKWebView else { return }
        let tab = self.tabs.remove(at: webView.tag)
        self.tabContainerScrollView?.documentView?.subviews.remove(at: webView.tag)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            layoutTabs()
            self.layoutSubtreeIfNeeded()
        }
    }
    
    @objc func tabSwitchedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : Int] else { return }
        let oldValue = userInfo["oldIndex"] ?? -1
        if oldValue >= 0 {
            self.tabs[oldValue].isSelected = false
        }
        if self.webViewContainer.currentTabIndex >= 0 {
            self.tabs[self.webViewContainer.currentTabIndex].isSelected = true
        } else {
            // we're back to empty state
            self.addressBarAndSearchField.stringValue = ""
            self.btnReload.isHidden = true
            self.btnStopLoad.isHidden = true
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            layoutTabs()
            self.layoutSubtreeIfNeeded()
        }
    }
    
    func scrollToTabInScrollView() {
        guard let width = tabContainerScrollView?.frame.size.width else { return }
        tabContainerScrollView?.contentView.scroll(NSPoint(x: width, y: 0))
    }
    
    @objc func loadURL(_ sender: NSSearchField) {
        guard !self.addressBarAndSearchField.stringValue.isEmpty else { return }
        if !self.addressBarAndSearchField.stringValue.hasPrefix("http://") &&
            !self.addressBarAndSearchField.stringValue.hasPrefix("https://") &&
            self.addressBarAndSearchField.stringValue != "about:blank" &&
            !self.addressBarAndSearchField.stringValue.hasPrefix("file://") {
            self.addressBarAndSearchField.stringValue = "https://" + self.addressBarAndSearchField.stringValue
        }
        print("load url: \(self.addressBarAndSearchField.stringValue)")
        let url = self.addressBarAndSearchField.stringValue
        guard !url.isEmpty && (url.isValidURL || url.isFileURL) else { return }
        
        if self.webViewContainer.currentTabIndex < 0 {
            // we're in an empty state
            self.webViewContainer.appendTab(shouldSwitch: true)
            self.webViewContainer.tabs[self.webViewContainer.currentTabIndex].isHidden = false
            self.webViewContainer.tabs[self.webViewContainer.currentTabIndex].navigateTo(url)
        } else {
            // A tab is already selected. We just have to change its url
            self.webViewContainer.tabs[self.webViewContainer.currentTabIndex].isHidden = false
            self.webViewContainer.tabs[self.webViewContainer.currentTabIndex].navigateTo(url)
        }
    }
    
    @objc func reloadCurrentURL() {
        print("reload called")
        if !self.tabs[self.webViewContainer.currentTabIndex].webView.isLoading {
            self.tabs[self.webViewContainer.currentTabIndex].webView.reload()
        }
    }
    
    @objc func disableLoadingForCurrentURL() {
        print("stop load called")
        if self.tabs[self.webViewContainer.currentTabIndex].webView.isLoading {
            self.tabs[self.webViewContainer.currentTabIndex].webView.stopLoading()
        }
    }
}

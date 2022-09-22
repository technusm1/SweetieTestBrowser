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
    
    var scrollViewGradientLayer: CAGradientLayer?
    
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    var arrowIconUICtrl: NSButton?
    var dragIndicatorPositions: [CGFloat]
    var dragIndicatorSelectedIndex: Int = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame frameRect: NSRect, webViewContainer: WebViewContainer) {
        self.addressBarAndSearchField = NSSearchField(frame: frameRect)
        self.webViewContainer = webViewContainer
        self.tabs = []
        self.dragIndicatorPositions = []
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
        setupDragIndicatorPositions()
        // Drag operation code (This view is a dragging destination for receiving tabs)
        registerForDraggedTypes([.string])
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabAppendedNotification(_:)), name: .tabAppended, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabDeletedNotification(_:)), name: .tabDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabSwitchedNotification(_:)), name: .tabSwitched, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tabInsertedNotification(_:)), name: .tabInserted, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("drag entered")
        isReceivingDrag = true
        self.arrowIconUICtrl = self.arrowIconUICtrl ?? NSButton()
        self.arrowIconUICtrl?.title = "⬆"
        self.arrowIconUICtrl?.isHidden = false
        self.arrowIconUICtrl?.isBordered = false
        self.superview?.addSubview(self.arrowIconUICtrl!, positioned: .above, relativeTo: self)
        self.arrowIconUICtrl?.isHidden = false
        
        return .copy
    }
    
    private func setupDragIndicatorPositions() {
        print("Setup drag indicator positions")
        self.dragIndicatorPositions.removeAll()
        self.dragIndicatorPositions = [self.addressBarAndSearchField.frame.width]
        for i in 0..<tabs.count {
            let result = (tabs[0].frame.width + 5.0)*Double(i + 1) + self.addressBarAndSearchField.frame.width
            self.dragIndicatorPositions.append(result)
        }
        
        // self.arrowIconUICtrl?.frame = NSRect(origin: CGPoint(x: xPoint, y: -8), size: CGSize(width: 30, height: 30))
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let dragCoordinates = convert(sender.draggingLocation, from: self.window?.contentView)
        print(dragCoordinates, self.dragIndicatorPositions)
        if let index = self.dragIndicatorPositions.firstIndex(where: { position in
            dragCoordinates.x < position
        }) {
            self.arrowIconUICtrl?.frame = NSRect(origin: CGPoint(x: self.dragIndicatorPositions[index], y: -8), size: CGSize(width: 30, height: 30))
            self.dragIndicatorSelectedIndex = index
        } else {
            self.arrowIconUICtrl?.frame = NSRect(origin: CGPoint(x: self.dragIndicatorPositions.last!, y: -8), size: CGSize(width: 30, height: 30))
            self.dragIndicatorSelectedIndex = tabs.count
        }
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("drag exit")
        isReceivingDrag = false
        self.arrowIconUICtrl?.isHidden = true
        self.arrowIconUICtrl?.removeFromSuperview()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("performing drag operation. will not be accepting any drags for the time being")
        self.arrowIconUICtrl?.isHidden = true
        isReceivingDrag = false
        let pasteboard = sender.draggingPasteboard
        if let destinationStrArray = pasteboard.readObjects(forClasses: [NSString.self]) as? [NSString], !destinationStrArray.isEmpty {
            // processing for received data should be done here
            let result = destinationStrArray[0] as String
            let groups = result.groups(for: #"([\d+])"#)
            if groups.count != 2 { return false }
            guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return false }
            guard let sourceWCIndex = Int(groups[0][0]), let sourceWebviewIndex = Int(groups[1][0]) else { return false }
            let sourceWC = appDelegate.wcList[sourceWCIndex].webViewContainer
            
            let webView = sourceWC.tabs[sourceWebviewIndex]
            
            if sourceWC.id != self.webViewContainer.id {
                // Different source and destination windows, no problem
                sourceWC.deleteTab(atIndex: sourceWebviewIndex, shouldCloseTab: false)
                if dragIndicatorSelectedIndex == tabs.count {
                    self.webViewContainer.appendTab(webView: webView, shouldSwitch: true)
                } else {
                    self.webViewContainer.insertTab(webView: webView, atIndex: dragIndicatorSelectedIndex)
                }
            } else {
                // Same source and destination
                if dragIndicatorSelectedIndex == tabs.count {
                    self.webViewContainer.deleteTab(atIndex: sourceWebviewIndex, shouldCloseTab: false)
                    self.webViewContainer.appendTab(webView: webView, shouldSwitch: true)
                } else if dragIndicatorSelectedIndex <= sourceWebviewIndex - 1 {
                    self.webViewContainer.deleteTab(atIndex: sourceWebviewIndex, shouldCloseTab: false)
                    self.webViewContainer.insertTab(webView: webView, atIndex: dragIndicatorSelectedIndex)
                } else if dragIndicatorSelectedIndex > sourceWebviewIndex + 1 {
                    self.webViewContainer.deleteTab(atIndex: sourceWebviewIndex, shouldCloseTab: false)
                    self.webViewContainer.insertTab(webView: webView, atIndex: dragIndicatorSelectedIndex - 1)
                }
            }
            
            return true
        }
        return false // otherwise, we have rejected the drag operation
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isReceivingDrag {
            NSColor.selectedControlColor.set()
            let path = NSBezierPath(rect:bounds)
            path.lineWidth = 5.0
            path.stroke()
        }
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
        setupDragIndicatorPositions()
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
        
        // Hide the cancel button
        if let cell = self.addressBarAndSearchField.cell as? NSSearchFieldCell {
            cell.cancelButtonCell = nil
        }
        
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
        
        self.scrollViewGradientLayer = CAGradientLayer()
        self.scrollViewGradientLayer?.startPoint = CGPoint(x: 0.0, y: 0.0)
        self.scrollViewGradientLayer?.endPoint = CGPoint(x: 1.0, y: 0.0)
        self.scrollViewGradientLayer?.colors = [NSColor.clear.cgColor, NSColor.black.cgColor, NSColor.black.cgColor, NSColor.clear.cgColor]
        
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
            self.btnReload.trailingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: -6),
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
            self.addressBarAndSearchField.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.4),
            self.addressBarAndSearchField.widthAnchor.constraint(greaterThanOrEqualTo: self.widthAnchor, multiplier: 0.25),
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
            if let win = self.window {
                win.toolbar?.centeredItemIdentifier = .searchBarAndTabStripIdentifier
                win.toolbar?.items.first { toolbarItem in
                    toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
                }?.minSize.width = win.frame.width / 1.65
            }
        } else {
            NSLayoutConstraint.deactivate(zeroTabsConstraintsStorage)
            if let win = self.window {
                win.toolbar?.centeredItemIdentifier = nil
                var compactBarWidth = win.frame.width / 1.15
                for item in win.toolbar?.items ?? [] {
                    if item.itemIdentifier != .searchBarAndTabStripIdentifier && item.itemIdentifier != .flexibleSpace {
                        compactBarWidth -= item.minSize.width
                    }
                }
                win.toolbar?.items.first { toolbarItem in
                    toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
                }?.minSize.width = compactBarWidth
            }
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
        if tabs.count >= 12 {
            self.scrollViewGradientLayer?.frame = self.tabContainerScrollView!.bounds
            self.tabContainerScrollView?.layer?.mask = self.scrollViewGradientLayer
        } else {
            self.tabContainerScrollView?.layer?.mask = nil
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
        if !shouldSwitch {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                layoutTabs()
                self.layoutSubtreeIfNeeded()
            }
            setupDragIndicatorPositions()
        }
    }
    
    @objc func tabInsertedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : AnyObject] else { return }
        guard let webView = userInfo["webView"] as? MKWebView else { return }
        guard let index = userInfo["index"] as? Int else { return }
        let tab = makeTabView(from: webView)
        self.tabs.insert(tab, at: index)
        self.tabContainerScrollView?.documentView?.subviews.insert(tab, at: index)
    }
    
    @objc func tabDeletedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : AnyObject] else { return }
        guard let webView = userInfo["webView"] as? MKWebView else { return }
        let tab = self.tabs.remove(at: webView.tag)
        tab.isSelected = false
        self.tabContainerScrollView?.documentView?.subviews.remove(at: webView.tag)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            layoutTabs()
            self.layoutSubtreeIfNeeded()
        }
        setupDragIndicatorPositions()
    }
    
    @objc func tabSwitchedNotification(_ notification: Notification) {
        guard self.webViewContainer.id == (notification.object as? WebViewContainer)?.id else { return }
        guard let userInfo = notification.userInfo as? [String : Int] else { return }
        let oldValue = userInfo["oldIndex"] ?? -1
        print("switch triggered:", oldValue, self.webViewContainer.currentTabIndex)
        if oldValue >= 0 && oldValue < tabs.count && !tabs.isEmpty {
            self.tabs[oldValue].isSelected = false
        }
        if self.webViewContainer.currentTabIndex >= 0 {
            self.tabs[self.webViewContainer.currentTabIndex].isSelected = true
        } else {
            // we're back to empty state
            self.addressBarAndSearchField.stringValue = ""
            self.btnReload.isHidden = true
            self.btnStopLoad.isHidden = true
            (self.window?.windowController as? MKWindowController)?.titlebarAccessoryViewController?.isHidden = true
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            layoutTabs()
            self.layoutSubtreeIfNeeded()
            scrollToTab(atIndex: self.webViewContainer.currentTabIndex)
        }
        setupDragIndicatorPositions()
    }
    
    func scrollToEndOfTabContainerScrollView() {
        if tabs.count >= 11 {
            guard let width = tabContainerScrollView?.documentView?.frame.size.width else { return }
            tabContainerScrollView?.contentView.scroll(NSPoint(x: width, y: 0))
        }
    }
    
    func scrollToBeginningOfTabContainerScrollView() {
        if tabs.count >= 11 {
            tabContainerScrollView?.contentView.scroll(NSPoint(x: 0, y: 0))
        }
    }
    
    func scrollToTab(atIndex index: Int) {
        guard tabs.count >= 11 else { return }
        if index == tabs.count - 1 {
            scrollToEndOfTabContainerScrollView()
            self.scrollViewGradientLayer?.locations = [0, 0.05, 1, 1]
        } else if index == 0 {
            scrollToBeginningOfTabContainerScrollView()
            self.scrollViewGradientLayer?.locations = [0, 0, 0.95, 1]
        }
        else {
            tabContainerScrollView?.contentView.scrollToVisible(tabs[index].frame)
            self.scrollViewGradientLayer?.locations = [0, 0.05, 0.95, 1]
        }
        
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

extension String {
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

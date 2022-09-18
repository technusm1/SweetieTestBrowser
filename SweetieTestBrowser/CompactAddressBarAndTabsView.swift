//
//  CompactAddressBarAndTabsView.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 10/09/22.
//

import Cocoa
import WebKit

protocol CompactAddressBarAndTabsViewDelegate {
    // This method is called when a tab switch happens, or when user enters a new URL in a tab
    func addressBarAndTabView(didSelectTab tab: MKTabView, atIndex index: Int, fromIndex previousIndex: Int)
    // This method is called when a tab is removed, i.e. when tab is closed by the user
    func addressBarAndTabView(tabRemoved tab: MKTabView, atIndex index: Int)
}

class CompactAddressBarAndTabsView: NSView {
    var addressBarAndSearchField: NSSearchField
    
    var btnReload: NSButton!
    var btnStopLoad: NSButton!
    
    var tabContainerScrollView: NSScrollView?
    var tabs: [MKTabView]
    var tabAnimationDuration: TimeInterval = 0.2
    
    var temporaryConstraintsStorage: [NSLayoutConstraint] = []
    var persistentConstraintsStorage: [NSLayoutConstraint] = []
    var zeroTabsConstraintsStorage: [NSLayoutConstraint] = []
    var oneOrMoreTabsConstraintsStorage: [NSLayoutConstraint] = []
    var lessThan12TabsConstraintsStorage: [NSLayoutConstraint] = []
    var moreThan12TabsConstraintsStorage: [NSLayoutConstraint] = []
    
    var currentTabIndex: Int = -1 {
        didSet {
            if currentTabIndex == oldValue { return }
            // Select the tab at currentTabIndex
            if currentTabIndex >= 0 && currentTabIndex < tabs.count {
                tabs[currentTabIndex].isSelected = true
                layoutTabs()
            }
            // Unselect the tab at oldValue
            if oldValue >= 0 && oldValue < tabs.count {
                tabs[oldValue].isSelected = false
            }
            guard currentTabIndex >= 0 else {
                self.addressBarAndSearchField.stringValue = ""
                return
            }
            self.addressBarAndSearchField.stringValue = tabs[currentTabIndex].currentURL
            let wc = self.window?.windowController as? MKWindowController
            wc?.titlebarAccessoryViewController?.isHidden = true
            delegate?.addressBarAndTabView(didSelectTab: tabs[currentTabIndex], atIndex: currentTabIndex, fromIndex: oldValue)
        }
    }
    
    var delegate: CompactAddressBarAndTabsViewDelegate?
    
    required init?(coder: NSCoder) {
        self.addressBarAndSearchField = NSSearchField()
        self.tabs = []
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        self.addressBarAndSearchField = NSSearchField(frame: frameRect)
        self.tabs = []
        super.init(frame: frameRect)
        setupView()
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
        self.tabContainerScrollView?.documentView = documentView
        
    }
    
    private func setupViewConstraints() {
        // By here, we assume that subviews have been constructed
        self.translatesAutoresizingMaskIntoConstraints = false
        
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
                if idx != currentTabIndex {
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
                if idx != currentTabIndex {
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
                if idx != currentTabIndex && idx != currentTabIndex + 1 {
                    self.temporaryConstraintsStorage.append(contentsOf: [
                        currentTab.widthAnchor.constraint(equalTo: previousTab.widthAnchor)
                    ])
                } else if idx == currentTabIndex + 1 && idx >= 2 {
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
    
    func goForward() {
        guard currentTabIndex >= 0 else { return }
        self.tabs[currentTabIndex].webView.goForward()
        self.addressBarAndSearchField.stringValue = self.tabs[currentTabIndex].webView.url?.absoluteString ?? ""
    }
    
    func goBack() {
        guard currentTabIndex >= 0 else { return }
        self.tabs[currentTabIndex].webView.goBack()
        self.addressBarAndSearchField.stringValue = self.tabs[currentTabIndex].webView.url?.absoluteString ?? ""
    }
    
    func createNewBackgroundTab(url: String?) {
        let callerTab = currentTabIndex
        createNewTab(url: url)
        currentTabIndex = callerTab
    }
    
    func createNewTab(url: String?) {
        print("called createNewTab")
        let view2 = MKTabView(frame: .zero)
        view2.translatesAutoresizingMaskIntoConstraints = false
        view2.tag = tabs.count
        view2.onSelect = {
            self.currentTabIndex = view2.tag
        }
        view2.onClose = {
            self.closeTab(atIndex: view2.tag)
        }
        self.tabs.append(view2)
        if let url = url {
            view2.navigateTo(url)
        }
        self.tabContainerScrollView?.documentView?.addSubview(view2)
        currentTabIndex = tabs.count - 1
    }
    
    func closeTab(atIndex index: Int) {
        guard index >= 0 else { return }
        guard let wc = self.window?.windowController as? MKWindowController else { return }
        wc.titlebarAccessoryViewController?.isHidden = true
        
        let tabToClose = self.tabs[index]
        self.tabs.remove(at: index)
        self.tabContainerScrollView?.documentView?.subviews.remove(at: index)
        for i in index..<self.tabs.count {
            self.tabs[i].tag -= 1
        }
        self.currentTabIndex -= 1
        self.delegate?.addressBarAndTabView(tabRemoved: tabToClose, atIndex: index)
        self.layoutTabs()
        if self.currentTabIndex < 0 && !self.tabs.isEmpty { self.currentTabIndex = 0 }
    }
    
    @objc func loadURL(_ sender: NSSearchField) {
        guard !self.addressBarAndSearchField.stringValue.isEmpty else { return }
        if !self.addressBarAndSearchField.stringValue.hasPrefix("http://") && !self.addressBarAndSearchField.stringValue.hasPrefix("https://") {
            self.addressBarAndSearchField.stringValue = "https://" + self.addressBarAndSearchField.stringValue
        }
        print("load url: \(self.addressBarAndSearchField.stringValue)")
        let url = self.addressBarAndSearchField.stringValue
        guard !url.isEmpty && url.isValidURL else { return }
        
        if currentTabIndex < 0 {
            // we're in an empty state
            createNewTab(url: self.addressBarAndSearchField.stringValue)
        } else {
            // A tab is already selected. We just have to change its url
            self.tabs[currentTabIndex].navigateTo(url)
            delegate?.addressBarAndTabView(didSelectTab: self.tabs[currentTabIndex], atIndex: currentTabIndex, fromIndex: currentTabIndex)
        }
    }
    
    @objc func reloadCurrentURL() {
        print("reload called")
        self.tabs[currentTabIndex].webView.reload()
    }
    
    @objc func disableLoadingForCurrentURL() {
        print("stop load called")
        self.tabs[currentTabIndex].webView.stopLoading()
    }
}

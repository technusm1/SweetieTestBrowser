//
//  CompactAddressBarAndTabsView.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 10/09/22.
//

import Cocoa

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
    var currentTabIndex: Int = -1 {
        didSet {
            if currentTabIndex == oldValue { return }
            // Select the tab at currentTabIndex
            if currentTabIndex >= 0 && currentTabIndex < tabs.count {
                tabs[currentTabIndex].isSelected = true
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
        self.addressBarAndSearchField.placeholderString = "Enter a URL, or search something..."
        self.addressBarAndSearchField.target = self
        self.addressBarAndSearchField.action = #selector(loadURL(_:))
        self.addressBarAndSearchField.translatesAutoresizingMaskIntoConstraints = false
        self.addressBarAndSearchField.maximumRecents = 10
        self.addressBarAndSearchField.sendsWholeSearchString = true
        self.addressBarAndSearchField.sendsSearchStringImmediately = false
        
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
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        self.tabContainerScrollView?.contentView = clipView
        
        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        self.tabContainerScrollView?.documentView = documentView
        
    }
    
    private func setupViewConstraints() {
        // By here, we assume that subviews have been constructed
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Height constraints first
        self.addressBarAndSearchField.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        self.tabContainerScrollView?.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        self.tabContainerScrollView?.contentView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        self.btnReload.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        // constraints on documentView will be setup in layoutTabs
        
        // Setup tabContainerScrollView
        self.tabContainerScrollView?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.tabContainerScrollView?.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        // Width of scrollbar contentview and scrollbar itself should be less than min(documentview, 0.4*self.width)
        self.tabContainerScrollView?.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.tabContainerScrollView?.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        
        self.tabContainerScrollView?.widthAnchor.constraint(lessThanOrEqualTo: self.tabContainerScrollView!.documentView!.widthAnchor).isActive = true
        self.tabContainerScrollView?.contentView.widthAnchor.constraint(lessThanOrEqualTo: self.tabContainerScrollView!.documentView!.widthAnchor).isActive = true
        self.tabContainerScrollView?.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.6).isActive = true
        self.tabContainerScrollView?.contentView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.6).isActive = true
        
        // Setup address bar
        self.addressBarAndSearchField.trailingAnchor.constraint(equalTo: self.tabContainerScrollView!.leadingAnchor, constant: -5).isActive = true
        self.addressBarAndSearchField.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        
        // Setup reload and stopLoad buttons
        self.btnReload.centerYAnchor.constraint(equalTo: self.addressBarAndSearchField.centerYAnchor).isActive = true
        self.btnReload.trailingAnchor.constraint(equalTo: self.addressBarAndSearchField.trailingAnchor, constant: -24).isActive = true
        self.btnStopLoad.centerYAnchor.constraint(equalTo: self.btnReload.centerYAnchor).isActive = true
        self.btnStopLoad.centerXAnchor.constraint(equalTo: self.btnReload.centerXAnchor).isActive = true
    }
    
    private func layoutTabs() {
        var previousTabView: MKTabView? = nil
        // Clear all previous constraints on documentView
        self.tabContainerScrollView?.documentView?.removeConstraints(self.tabContainerScrollView?.documentView?.constraints ?? [])
        
        // Init constraints - always setup
        self.tabContainerScrollView?.documentView?.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        for tabView in self.tabs {
            tabView.removeConstraints(tabView.constraints.filter {
                Set(["HeightConstraint", "CenterYConstraint", "LeadingAnchorConstraint", "WidthAnchorConstraint"]).contains($0.identifier)
            })
            self.tabContainerScrollView?.documentView?.addSubview(tabView)
            let heightConstraintForTab = tabView.heightAnchor.constraint(equalTo: self.heightAnchor)
            heightConstraintForTab.identifier = "HeightConstraint"
            heightConstraintForTab.isActive = true
            let centerYConstraintForTab = tabView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            centerYConstraintForTab.identifier = "CenterYConstraint"
            centerYConstraintForTab.isActive = true
            let leadingAnchorConstraintForTab = tabView.leadingAnchor.constraint(equalTo: previousTabView?.trailingAnchor ?? self.tabContainerScrollView!.documentView!.leadingAnchor, constant: 5)
            leadingAnchorConstraintForTab.identifier = "LeadingAnchorConstraint"
            leadingAnchorConstraintForTab.isActive = true
            let widthConstraintForTab = tabView.widthAnchor.constraint(equalToConstant: 120)
            widthConstraintForTab.identifier = "WidthAnchorConstraint"
            widthConstraintForTab.isActive = true
            previousTabView = tabView
        }
        self.tabContainerScrollView?.documentView?.trailingAnchor.constraint(equalTo: previousTabView?.trailingAnchor ?? self.tabContainerScrollView!.documentView!.leadingAnchor).isActive = true
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
        layoutTabs()
        currentTabIndex = tabs.count - 1
    }
    
    func closeTab(atIndex index: Int) {
        guard index >= 0 else { return }
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

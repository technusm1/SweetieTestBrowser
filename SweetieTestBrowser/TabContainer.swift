//
//  TabContainer.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 12/09/22.
//

import Foundation
import WebKit
import FaviconFinder

class MKTabView: NSView {
    private static var currentlyHoveredTabView: MKTabView? = nil
    
    var compactMode: Bool = false {
        didSet {
            if compactMode {
                self.favIconLeadingConstraint?.isActive = false
                self.favIconCenteringConstraint?.isActive = true
                titleLabel.removeFromSuperview()
            } else {
                self.favIconLeadingConstraint?.isActive = true
                self.favIconCenteringConstraint?.isActive = false
                addSubview(titleLabel)
                self.titleLabel.leadingAnchor.constraint(equalTo: self.closeBtn.trailingAnchor, constant: 4).isActive = true
                self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4).isActive = true
                self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            }
        }
    }
    var favIconLeadingConstraint: NSLayoutConstraint?
    var favIconCenteringConstraint: NSLayoutConstraint?
    var isMouseOverTheView: Bool = false {
        didSet {
            closeBtn.isHidden = !isMouseOverTheView
            self.favIconImageView.isHidden = isMouseOverTheView && !compactMode
            setNeedsDisplay(bounds)
        }
    }
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    private lazy var area = makeTrackingArea()
    var closeBtn: NSButton = NSButton(image: NSImage(named: NSImage.stopProgressFreestandingTemplateName)!, target: nil, action: nil)
    
    var title: String = "" {
        didSet {
            self.titleLabel.stringValue = title + String(repeating: " ", count: max(20 - title.count, 0))
        }
    }
    var titleLabel: NSTextField!
    
    var favIcon: NSImage?
    var favIconImageView: NSImageView!
    
    var onSelect: (() -> ())?
    var onClose: (() -> ())?
    
    var _tag = -1
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    // currentURL will be set by the delegate
    var currentURL: String = ""
    var _webView: WKWebView?
    var webView: WKWebView!
    
    func navigateTo(_ url: String) {
        if !url.isEmpty && url.isValidURL {
            self.currentURL = url
            let compactAddressBarAndTabsView = self.window?.toolbar?.items.first { toolbarItem in
                toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
            }?.view as? CompactAddressBarAndTabsView
            compactAddressBarAndTabsView?.btnReload.isHidden = true
            compactAddressBarAndTabsView?.btnStopLoad.isHidden = false
            
            self.webView.load(URLRequest(url: URL(string: url) ?? URL(string: "https://kagi.com")!))
            FaviconFinder(url: URL(string: url) ?? URL(string: "https://kagi.com")!).downloadFavicon { result in
                switch result {
                case .success(let favicon):
                    print("URL of Favicon: \(favicon.url)")
                    DispatchQueue.main.async {
                        self.favIconImageView.image = favicon.image
                    }

                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    @objc func closeAction() {
        onClose?()
    }
    
    public override func mouseEntered(with event: NSEvent) {
        Self.currentlyHoveredTabView?.isMouseOverTheView = false
        isMouseOverTheView = true
        Self.currentlyHoveredTabView = self
    }

    public override func mouseExited(with event: NSEvent) {
        isMouseOverTheView = false
        Self.currentlyHoveredTabView = nil
    }
    
    public override func mouseDown(with event: NSEvent) {
        isSelected = true
        onSelect?()
    }
    
    private func makeTrackingArea() -> NSTrackingArea {
        return NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
    }
    
    public override func updateTrackingAreas() {
        removeTrackingArea(area)
        area = makeTrackingArea()
        addTrackingArea(area)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" && isSelected {
            guard let wc = self.window?.windowController as? MKWindowController else { return }
            wc.titlebarAccessoryViewController?.progressIndicator.isIndeterminate = false
            if webView.estimatedProgress.isEqual(to: 1.0) {
                wc.titlebarAccessoryViewController?.isHidden = true
            } else {
                wc.titlebarAccessoryViewController?.isHidden = false
            }
            wc.titlebarAccessoryViewController?.progressIndicator.doubleValue = webView.estimatedProgress * 100
        } else if keyPath == "title" {
            if let title = webView.title, !title.isEmpty {
                self.title = title
            }
            self.toolTip = webView.title ?? self.title
        }
    }
    
    private func setupTabView() {
        // Setup an empty webview
        self.webView = self._webView ?? WKWebView()
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
        
        // Init close btn
        closeBtn.target = self
        closeBtn.action = #selector(closeAction)
        closeBtn.isHidden = true
        closeBtn.isBordered = false
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeBtn)
        
        // Init title
        self.titleLabel = NSTextField()
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.stringValue = (title == "" ? "Untitled Page" + String(repeating: " ", count: 15) : title)
        self.titleLabel.alignment = .left
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.titleLabel.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
        self.titleLabel.isEditable = false
        self.titleLabel.isSelectable = false
        self.titleLabel.isBezeled = false
        self.titleLabel.isBordered = false
        self.titleLabel.textColor = .textColor
        self.titleLabel.backgroundColor = .clear
        addSubview(titleLabel)
        
        // Init favicon
        self.favIconImageView = NSImageView()
        self.favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        self.favIconImageView.image = favIcon ?? NSImage(named: NSImage.homeTemplateName)!
        self.favIconImageView.imageScaling = .scaleProportionallyDown
        addSubview(self.favIconImageView)
        
        // Setup constraints for controls
        self.favIconLeadingConstraint = self.favIconImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4)
        self.favIconLeadingConstraint?.isActive = true
        self.favIconCenteringConstraint = self.favIconImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        self.favIconCenteringConstraint?.isActive = false
        
        self.favIconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.favIconImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        self.favIconImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        
        closeBtn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4).isActive = true
        closeBtn.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        closeBtn.widthAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        closeBtn.heightAnchor.constraint(lessThanOrEqualToConstant: 16).isActive = true
        
        self.titleLabel.leadingAnchor.constraint(equalTo: self.closeBtn.trailingAnchor, constant: 4).isActive = true
        self.titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4).isActive = true
        self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        titleLabel.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTabView()
    }
    
    init(frame frameRect: NSRect, webView: WKWebView) {
        super.init(frame: frameRect)
        self._webView = webView
        setupTabView()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderColor = NSColor.lightGray.cgColor
        layer?.borderWidth = 1
        if isSelected {
            layer?.backgroundColor = NSColor.lightGray.blended(withFraction: 0.1, of: .white)?.cgColor
        } else if isMouseOverTheView {
            layer?.backgroundColor = NSColor.lightGray.blended(withFraction: 0.5, of: .white)?.cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
        super.draw(dirtyRect)
    }
}

extension MKTabView: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.currentURL = webView.url?.absoluteString ?? ""
        print(self.currentURL, self.title)
        if isSelected {
            let searchField = self.window?.toolbar?.items.first { toolbarItem in
                toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
            }?.view?.subviews.first { subView in
                subView is NSSearchField
            } as? NSSearchField
            searchField?.stringValue = self.currentURL
            
            let compactAddressBarAndTabsView = self.window?.toolbar?.items.first { toolbarItem in
                toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
            }?.view as? CompactAddressBarAndTabsView
            compactAddressBarAndTabsView?.btnReload.isHidden = false
            compactAddressBarAndTabsView?.btnStopLoad.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web view failed navigation")
        // webView.loadFileURL(<#T##URL: URL##URL#>, allowingReadAccessTo: <#T##URL#>)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("something here", navigationAction.request)
        if navigationAction.targetFrame == nil {
            // Open in new tab
            guard let compactAddressBar = self.window?.toolbar?.items.first(where: { $0.itemIdentifier == .searchBarAndTabStripIdentifier })?.view as? CompactAddressBarAndTabsView else { return nil }
            compactAddressBar.createNewTab(url: navigationAction.request.url?.absoluteString)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        print("Open a file upload panel")
        let fpanel = NSOpenPanel()
        
        fpanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        fpanel.canChooseDirectories = parameters.allowsDirectories
        fpanel.canChooseFiles = true
        fpanel.canCreateDirectories = false
        fpanel.begin { response in
            if response == .OK {
                completionHandler(fpanel.urls)
            }
        }
        
    }
}

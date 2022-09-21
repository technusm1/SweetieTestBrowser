//
//  WebViewContainer.swift
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
            if isSelected {
                let compactAddressBarAndTabsView = self.window?.toolbar?.items.first { toolbarItem in
                    toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
                }?.view as? CompactAddressBarAndTabsView
                let wc = self.window?.windowController as? MKWindowController
                if webView.isLoading {
                    compactAddressBarAndTabsView?.btnReload.isHidden = true
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = false
                    wc?.titlebarAccessoryViewController?.isHidden = false
                } else {
                    compactAddressBarAndTabsView?.btnReload.isHidden = false
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = true
                    wc?.titlebarAccessoryViewController?.isHidden = true
                }
                compactAddressBarAndTabsView?.addressBarAndSearchField.stringValue = webView.url?.absoluteString ?? ""
                if (webView.url?.absoluteString.isEmpty ?? true) || webView.url?.absoluteString == "about:blank" {
                    compactAddressBarAndTabsView?.btnReload.isHidden = true
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = true
                    wc?.titlebarAccessoryViewController?.isHidden = true
                }
            }
        }
    }
    
    private lazy var area = makeTrackingArea()
    var closeBtn: NSButton = NSButton(image: NSImage(named: NSImage.stopProgressFreestandingTemplateName)!, target: nil, action: nil)
    
    var title: String = "" {
        didSet {
            self.titleLabel.stringValue = title + String(repeating: " ", count: max(40 - title.count, 0))
        }
    }
    var titleLabel: NSTextField!
    
    var favIcon: NSImage?
    var favIconImageView: NSImageView!
    
    var onSelect: (() -> ())?
    var onClose: (() -> ())?
    
    var currentURL: String {
        get {
            return webView.url?.absoluteString ?? ""
        }
    }
    var _webView: MKWebView?
    var webView: MKWebView!
    
    var mouseHoldingDelay: TimeInterval = 0.5
    var timer: Timer?
    
    override var mouseDownCanMoveWindow: Bool {
        get {
            return false
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
    
    @objc func mouseWasHeld(timer: Timer) {
        guard let event = timer.userInfo as? NSEvent else { return }
        let pasteboardItem = NSPasteboardItem()
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        guard let wc = self.window?.windowController as? MKWindowController else { return }
        pasteboardItem.setString("WebView[\(appDelegate.wcList.firstIndex(of: wc)!)][\(self.webView.tag)]", forType: .string)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(self.bounds, contents: self.imageRepresentation())
        self.beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    public override func mouseDown(with event: NSEvent) {
        isSelected = true
        onSelect?()
        timer = Timer.scheduledTimer(timeInterval: mouseHoldingDelay, target: self, selector: #selector(mouseWasHeld(timer:)), userInfo: event, repeats: false)
    }
    
    public override func mouseUp(with event: NSEvent) {
        timer?.invalidate()
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
        if keyPath == #keyPath(MKWebView.estimatedProgress) && isSelected {
            guard let wc = self.window?.windowController as? MKWindowController else { return }
            guard currentURL != "about:blank" else { return }
            wc.titlebarAccessoryViewController?.progressIndicator.isIndeterminate = false
            if webView.estimatedProgress.isEqual(to: 1.0) {
                wc.titlebarAccessoryViewController?.isHidden = true
            } else {
                wc.titlebarAccessoryViewController?.isHidden = false
            }
            wc.titlebarAccessoryViewController?.progressIndicator.doubleValue = webView.estimatedProgress * 100
        } else if keyPath == #keyPath(MKWebView.title) {
            if let title = webView.title, !title.isEmpty {
                self.title = title
            }
            self.toolTip = webView.title ?? self.title
        } else if keyPath == #keyPath(MKWebView.url) {
            if isSelected {
                let compactAddressBarAndTabsView = self.window?.toolbar?.items.first { toolbarItem in
                    toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
                }?.view as? CompactAddressBarAndTabsView
                compactAddressBarAndTabsView?.addressBarAndSearchField.stringValue = webView.url?.absoluteString ?? ""
                if (webView.url?.absoluteString.isEmpty ?? true) || webView.url?.absoluteString == "about:blank" {
                    compactAddressBarAndTabsView?.btnReload.isHidden = true
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = true
                }
            }
            FaviconFinder(url: webView.url ?? URL(string: "https://kagi.com")!).downloadFavicon { result in
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
        } else if keyPath == #keyPath(MKWebView.isLoading) {
            let compactAddressBarAndTabsView = self.window?.toolbar?.items.first { toolbarItem in
                toolbarItem.itemIdentifier == .searchBarAndTabStripIdentifier
            }?.view as? CompactAddressBarAndTabsView
            if isSelected {
                if webView.isLoading {
                    compactAddressBarAndTabsView?.btnReload.isHidden = true
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = false
                } else {
                    compactAddressBarAndTabsView?.btnReload.isHidden = false
                    compactAddressBarAndTabsView?.btnStopLoad.isHidden = true
                }
            }
        }
    }
    
    private func setupTabView() {
        // Setup an empty webview
        self.webView = self._webView ?? MKWebView()
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6.1 Safari/605.1.15"
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.addObserver(self, forKeyPath: #keyPath(MKWebView.estimatedProgress), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(MKWebView.title), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(MKWebView.url), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(MKWebView.isLoading), options: .new, context: nil)
        
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
        self.titleLabel.stringValue = (webView.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ? (title == "" ? "Untitled Page" + String(repeating: " ", count: 15) : title) : (webView.title! + String(repeating: " ", count: 25))
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
        
        if let webViewURL = webView.url {
            if !webViewURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.global(qos: .userInitiated).async {
                    FaviconFinder(url: webViewURL).downloadFavicon { result in
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
        }
        
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
    
    init(frame frameRect: NSRect, webView: MKWebView) {
        super.init(frame: frameRect)
        self._webView = webView
        setupTabView()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        wantsLayer = true
        layer?.cornerRadius = 6
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

extension MKTabView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if context == .withinApplication { return .generic }
        return NSDragOperation()
    }
    
    func imageRepresentation() -> NSImage? {
        let viewSize = self.bounds.size
        let imgSize = NSSize(width: viewSize.width, height: viewSize.height)
        
        guard let bitmapImgRep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else { return nil }
        bitmapImgRep.size = imgSize
        self.cacheDisplay(in: self.bounds, to: bitmapImgRep)
        
        let image = NSImage()
        image.addRepresentation(bitmapImgRep)
        return image
    }
}


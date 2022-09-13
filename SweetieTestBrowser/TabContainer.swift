//
//  TabContainer.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 12/09/22.
//

import Foundation
import WebKit

class MKTabView: NSView {
    var isMouseOverTheView: Bool = false {
        didSet {
            closeBtn.isHidden = !isMouseOverTheView
            self.favIconImageView.isHidden = isMouseOverTheView
            setNeedsDisplay(bounds)
        }
    }
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    private lazy var area = makeTrackingArea()
    var closeBtn: NSButton = NSButton(image: getCloseBtnImg(), target: nil, action: nil)
    var closeBtnTarget: AnyObject?
    var closeBtnAction: Selector?
    var title: String?
    var favIcon: NSImage?
    var favIconImageView: NSImageView!
    
    var onSelect: (()->())?
    
    var _tag = -1
    override var tag: Int {
        get {
            return _tag
        }
        set {
            _tag = newValue
        }
    }
    
    var currentURL: String = "" {
        didSet {
            if !self.currentURL.isEmpty && self.currentURL.isValidURL {
                self.webView.load(URLRequest(url: URL(string: self.currentURL) ?? URL(string: "maheepk.net")!))
            }
        }
    }
    var webView: WKWebView!
    
    public override func mouseEntered(with event: NSEvent) {
        isMouseOverTheView = true
    }

    public override func mouseExited(with event: NSEvent) {
        isMouseOverTheView = false
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
    
    static func getCloseBtnImg() -> NSImage {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "xmark.square", accessibilityDescription: nil)!
        } else {
            return NSImage(named: NSImage.bookmarksTemplateName)!
        }
    }
    
    private func setupTabView() {
        // Setup an empty webview
        self.webView = WKWebView()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        
        // Init close btn
        if let closeBtnTarget = closeBtnTarget { closeBtn.target = closeBtnTarget }
        if let closeBtnAction = closeBtnAction { closeBtn.action = closeBtnAction }
        closeBtn.isHidden = true
        closeBtn.isBordered = false
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeBtn)
        
        // Init title
        let title = title ?? "Untitled Page - No title at all..."
        let titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = title
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBezeled = false
        titleLabel.isBordered = false
        titleLabel.textColor = .textColor
        titleLabel.backgroundColor = .clear
        addSubview(titleLabel)
        
        // Init favicon
        self.favIconImageView = NSImageView()
        self.favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        self.favIconImageView.image = favIcon ?? NSImage(named: NSImage.bookmarksTemplateName)!
        addSubview(self.favIconImageView)
        
        // Setup constraints for controls
        self.favIconImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4).isActive = true
        self.favIconImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.favIconImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        self.favIconImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        
        closeBtn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4).isActive = true
        closeBtn.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        closeBtn.widthAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        closeBtn.heightAnchor.constraint(lessThanOrEqualToConstant: 32).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: self.favIconImageView.trailingAnchor, constant: 4).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
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
    
    override func draw(_ dirtyRect: NSRect) {
        layer?.cornerRadius = 4
        if isSelected {
            layer?.backgroundColor = NSColor.lightGray.blended(withFraction: 0.1, of: .white)?.cgColor
        } else if isMouseOverTheView {
            layer?.backgroundColor = NSColor.lightGray.blended(withFraction: 0.3, of: .white)?.cgColor
        } else {
            layer?.backgroundColor = NSColor.lightGray.blended(withFraction: 0.5, of: .white)?.cgColor
        }
        super.draw(dirtyRect)
    }
}

extension MKTabView: WKNavigationDelegate{}

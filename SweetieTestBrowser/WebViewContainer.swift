//
//  WebViewContainer.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 17/09/22.
//

import Foundation
import WebKit

// Plan is to have one container per window, so per window tabbing support can be implemented
class WebViewContainer: NSObject {
    
    var id: String = UUID().uuidString
    var tabs: [MKWebView] = []
    var currentTabIndex: Int = -1 {
        didSet {
            let nc = NotificationCenter.default
            let userInfo = ["newIndex" : currentTabIndex, "oldIndex" : oldValue]
            nc.post(name: .tabSwitched, object: self, userInfo: userInfo)
            if currentTabIndex < 0 || currentTabIndex >= tabs.count { return }
            delegate?.tabContainer(didSelectTab: tabs[currentTabIndex], atIndex: currentTabIndex, fromIndex: oldValue)
        }
    }
    var delegate: WebViewContainerDelegate?
    
    func insertTab(webView: MKWebView, atIndex index: Int) {
        tabs.insert(webView, at: index)
        let nc = NotificationCenter.default
        let userInfo: [String : Any] = ["webView" : webView, "index" : index]
        nc.post(name: .tabAppended, object: self, userInfo: userInfo)
        delegate?.tabContainer(tabInserted: webView, atIndex: index)
        currentTabIndex = index
    }
    
    func appendTab(webView: MKWebView? = nil, shouldSwitch: Bool = false) {
        let webView = webView ?? MKWebView()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.tag = tabs.count
        tabs.append(webView)
        let nc = NotificationCenter.default
        let userInfo: [String : Any] = ["webView" : webView, "shouldSwitch" : shouldSwitch]
        nc.post(name: .tabAppended, object: self, userInfo: userInfo)
        
        if shouldSwitch {
            currentTabIndex = tabs.count - 1
        } else if currentTabIndex < 0 {
            currentTabIndex = 0
        }
        delegate?.tabContainer(tabAdded: webView, isHidden: !shouldSwitch)
    }
    
    func deleteTab(atIndex index: Int, shouldCloseTab: Bool = true) {
        guard currentTabIndex >= 0 && index >= 0 else { return }
        let removedWebView = tabs.remove(at: index)
        if shouldCloseTab {
            removedWebView.navigateTo("about:blank")
            removedWebView.favIconImage = nil
        }
        for idx in index..<tabs.count {
            tabs[idx].tag -= 1
        }
        let nc = NotificationCenter.default
        let userInfo = ["webView" : removedWebView]
        nc.post(name: .tabDeleted, object: self, userInfo: userInfo)
        delegate?.tabContainer(tabRemoved: removedWebView, atIndex: index)
        
        if currentTabIndex > 0 {
            currentTabIndex -= 1
        } else if tabs.isEmpty {
            currentTabIndex = -1
        } else {
            currentTabIndex = 0
        }
    }
    
    func switchToTab(atIndex index: Int) {
        self.currentTabIndex = (0..<tabs.count).contains(index) ? index : -1
    }
    
    deinit {
        for i in (0..<tabs.count).reversed() {
            deleteTab(atIndex: i)
        }
        tabs.removeAll()
    }
}

extension Notification.Name {
    static let tabAppended = Notification.Name("TabAppended")
    static let tabDeleted = Notification.Name("TabDeleted")
    static let tabSwitched = Notification.Name("TabSwitched")
    static let tabInserted = Notification.Name("TabInserted")
}

protocol WebViewContainerDelegate {
    func tabContainer(didSelectTab tab: MKWebView, atIndex index: Int, fromIndex previousIndex: Int)
    func tabContainer(tabRemoved tab: MKWebView, atIndex index: Int)
    func tabContainer(tabAdded tab: MKWebView, isHidden: Bool)
    func tabContainer(tabInserted tab: MKWebView, atIndex index: Int)
}

extension WebViewContainer: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("navigation fin")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web view failed navigation")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.modifierFlags == .command {
            // user cmd + clicked a link, open in a new background tab
            self.appendTab()
            self.tabs[self.tabs.count - 1].navigateTo(navigationAction.request.url?.absoluteString ?? "")
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print("something here", navigationAction.request)
        if let customAction = (webView as? MKWebView)?.contextMenuAction {
            if customAction == .openInNewTab {
                self.appendTab(shouldSwitch: true)
                self.tabs[self.currentTabIndex].isHidden = false
                self.tabs[self.currentTabIndex].navigateTo(navigationAction.request.url?.absoluteString ?? "")
            }
            return nil
        }
        
        if navigationAction.targetFrame == nil {
            // Open in new tab
            self.appendTab(shouldSwitch: true)
            self.tabs[self.currentTabIndex].isHidden = false
            self.tabs[self.currentTabIndex].navigateTo(navigationAction.request.url?.absoluteString ?? "")
            return nil
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

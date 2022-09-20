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
            if currentTabIndex == oldValue { return }
            let nc = NotificationCenter.default
            let userInfo = ["newIndex" : currentTabIndex, "oldIndex" : oldValue]
            nc.post(name: .tabSwitched, object: self, userInfo: userInfo)
            
            if currentTabIndex < 0 || currentTabIndex >= tabs.count { return }
            delegate?.tabContainer(didSelectTab: tabs[currentTabIndex], atIndex: currentTabIndex, fromIndex: oldValue)
        }
    }
    var delegate: WebViewContainerDelegate?
    
    func appendTab(shouldSwitch: Bool = false) {
        let webView = MKWebView()
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
    
    func deleteTab(atIndex index: Int) {
        guard currentTabIndex >= 0 && index >= 0 else { return }
        let removedWebView = tabs.remove(at: index)
        for idx in index..<tabs.count {
            tabs[idx].tag -= 1
        }
        
        currentTabIndex -= 1
        if !tabs.isEmpty && currentTabIndex < 0 { currentTabIndex = 0 }
        
        let nc = NotificationCenter.default
        let userInfo = ["webView" : removedWebView]
        nc.post(name: .tabDeleted, object: self, userInfo: userInfo)
        delegate?.tabContainer(tabRemoved: removedWebView, atIndex: index)
    }
    
    func switchToTab(atIndex index: Int) {
        self.currentTabIndex = (0..<tabs.count).contains(index) ? index : -1
    }
}

extension Notification.Name {
    static let tabAppended = Notification.Name("TabAppended")
    static let tabDeleted = Notification.Name("TabDeleted")
    static let tabSwitched = Notification.Name("TabSwitched")
}

protocol WebViewContainerDelegate {
    // This method is called when a tab switch happens, or when user enters a new URL in a tab
    func tabContainer(didSelectTab tab: MKWebView, atIndex index: Int, fromIndex previousIndex: Int)
    // This method is called when a tab is removed, i.e. when tab is closed by the user
    func tabContainer(tabRemoved tab: MKWebView, atIndex index: Int)
    
    func tabContainer(tabAdded tab: MKWebView, isHidden: Bool)
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

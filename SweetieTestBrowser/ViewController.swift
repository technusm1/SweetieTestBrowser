//
//  ViewController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 09/09/22.
//

import Cocoa
import WebKit

class ViewController: NSViewController {
    
    override func loadView() {
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load called")
        let visualEffectView = NSVisualEffectView(frame: view.frame)
        // Non-semantic materials are deprecated in 10.14. So, this is now deprecated:
        // visualEffectView.material = .appearanceBased
        // Instead, we set self.window?.backgroundColor = .windowBackgroundColor
        // in MKWindowController to get the same effect.
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        view = visualEffectView
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension ViewController: CompactAddressBarAndTabsViewDelegate {
    func addressBarAndTabView(didSelectTab tab: MKTabView, atIndex index: Int, fromIndex previousIndex: Int) {
        print("IN THE DELEGATE MAN")
        guard let subView = tab.webView else { return }
        if index >= view.subviews.count {
            view.addSubview(subView)
            subView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            subView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            subView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            subView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        if previousIndex >= 0 {
            view.subviews[previousIndex].isHidden = true
        }
        if tab.currentURL.isEmpty {
            tab.webView.isHidden = true
            return
        } else {
            tab.webView.isHidden = false
        }
    }
    
    func addressBarAndTabView(tabRemoved tab: MKTabView, atIndex index: Int) {
        view.subviews.remove(at: index)
    }
}

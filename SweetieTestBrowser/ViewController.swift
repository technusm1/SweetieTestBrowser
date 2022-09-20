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
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

extension ViewController: WebViewContainerDelegate {
    func tabContainer(tabAdded tab: MKWebView, isHidden: Bool) {
        print("Adding to subview")
        let subView = tab
        subView.isHidden = isHidden || (tab.url == nil)
        view.addSubview(subView)
        subView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        subView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        subView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func tabContainer(didSelectTab tab: MKWebView, atIndex index: Int, fromIndex previousIndex: Int) {
        print("IN THE DELEGATE MAN", index, previousIndex)
        
        if previousIndex >= 0 {
            view.subviews[previousIndex].isHidden = true
        }
        if tab.isLoading || tab.url != nil {
            tab.isHidden = false
        } else {
            tab.isHidden = true
        }
    }
    
    func tabContainer(tabRemoved tab: MKWebView, atIndex index: Int) {
        view.subviews.remove(at: index)
//        self.view.window?.makeFirstResponder(
//            self.view.window?.toolbar?.items.first { item in
//                item.itemIdentifier == .searchBarAndTabStripIdentifier
//            }?.view?.subviews.first { subView in
//                subView is NSSearchField
//            }
//        )
    }
}

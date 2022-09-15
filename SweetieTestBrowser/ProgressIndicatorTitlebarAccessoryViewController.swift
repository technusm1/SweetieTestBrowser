//
//  ProgressIndicatorTitlebarAccessoryViewController.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 15/09/22.
//

import Cocoa

class ProgressIndicatorTitlebarAccessoryViewController: NSTitlebarAccessoryViewController {

    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.frame = NSRect(x: 0, y: 0, width: 450, height: 2)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer?.backgroundColor = .clear
    }
    
}

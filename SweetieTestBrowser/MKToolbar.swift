//
//  MKToolbar.swift
//  SweetieTestBrowser
//
//  Created by Maheep Kumar Kathuria on 17/09/22.
//

import Cocoa

class MKToolbar: NSToolbar {
    var isCustomizing: Bool = false {
        didSet {
            if isCustomizing {
                print("Toolbar is customizing")
            } else {
                print("Toolbar is no longer customizing")
            }
        }
    }
    
    override func runCustomizationPalette(_ sender: Any?) {
        isCustomizing = true
        super.runCustomizationPalette(sender)
        isCustomizing = false
    }

}

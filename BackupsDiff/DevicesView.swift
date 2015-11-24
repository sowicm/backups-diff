//
//  DevicesView.swift
//  BackupsDiff
//
//  Created by Sowicm Right on 14/9/22.
//  Copyright (c) 2014年 Sowicm Right. All rights reserved.
//

import Cocoa

class DevicesView: NSTableView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func viewAtColumn(column: Int, row: Int, makeIfNecessary: Bool) -> NSView! {
        var cellView = NSTableCellView()
        cellView.textField.stringValue = "abc"
        return cellView
    }
    
    //    override func viewfor
    
    override func rowForView(view: NSView!) -> Int {
        return 3
    }
}

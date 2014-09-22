//
//  ViewController.swift
//  BackupsDiff
//
//  Created by Sowicm Right on 14/9/22.
//  Copyright (c) 2014年 Sowicm Right. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        readDevices()
        loadDevices()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func readDevices() {
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        let file = paths[0].stringByAppendingPathComponent("BackupsDiff/devices.plist")
        NSLog("%@", file)
        devices = NSMutableDictionary(contentsOfFile: file)
        if devices == nil
        {
            devices = NSMutableDictionary()
        }
        devicesArray = NSMutableArray(array: ["a", "b", "c"])
    }

    @IBOutlet var devicesController: NSArrayController!

    func saveDevices() {
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        if paths == nil || paths.isEmpty
        {
            NSLog("Documents directory not found!");
            return
        }
        let file = paths[0].stringByAppendingPathComponent("BackupsDiff/devices.plist")
        devices.writeToFile(file, atomically: true)
    }
    
    func loadDevices() {
        //devicesController = devices;
    }
    
    var devices : NSMutableDictionary!
    
    var devicesArray : NSMutableArray!
    
    @IBAction func getDevices(sender: AnyObject) {
        var nm = NSFileManager()
        var error = NSError()
        let files = nm.contentsOfDirectoryAtPath("/Users/sowicm/Library/Application Support/MobileSync/Backup", error: nil)
        if files == nil {
          return
        }
        
        let prompt = "请为该设备设定一个名称："
        let defaultValue = "iPhone"
        
        
        for each in files!
        {
            var file : NSString = each as NSString
            if file.hasPrefix(".")
            {
                continue
            }
            if file.rangeOfString("-").length > 0
            {
                continue
            }
            if devices[file] != nil
            {
                continue
            }
        
            var input = NSTextField()
            input.frame = NSMakeRect(0, 0, 200, 24)
            //input.setFrameOrigin(0, 0)
            //input.setFrameSize(200, 24)
            //input.setValue(defaultValue)
            
            var alert = NSAlert()
            alert.messageText = prompt
            alert.informativeText = file
            alert.addButtonWithTitle("Save")
            alert.addButtonWithTitle("Cancel")
            alert.accessoryView = input
            if alert.runModal() == NSAlertFirstButtonReturn
            {
                input.validateEditing()
                devices[file] = input.stringValue
                //NSLog("%@", input.stringValue)
            }
            else
            {
                devices[file] = file
            }
            
            //NSLog("%@", file as NSString)
        }
        
        saveDevices()
    }

    @IBOutlet weak var devicesView: NSScrollView!
}


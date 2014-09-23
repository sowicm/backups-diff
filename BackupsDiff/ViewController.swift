//
//  ViewController.swift
//  BackupsDiff
//
//  Created by Sowicm Right on 14/9/22.
//  Copyright (c) 2014年 Sowicm Right. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        dataFolder = paths[0].stringByAppendingPathComponent("BackupsDiff/")
        
        backupFormatter = NSDateFormatter()
        backupFormatter.dateFormat = "yyyyMMdd-HHmmss"
        
        backups = NSMutableArray()

        readDevices()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func readDevices() {
        let file = dataFolder.stringByAppendingPathComponent("devices.plist")
        NSLog("%@", file)
        devices = NSMutableDictionary(contentsOfFile: file)
        if devices == nil
        {
            devices = NSMutableDictionary()
        }
    }

    func saveDevices() {
        let file = dataFolder.stringByAppendingPathComponent("devices.plist")
        devices.writeToFile(file, atomically: true)
    }
    
    var dataFolder : NSString!
    
    var devices : NSMutableDictionary!
    
    var backups : NSMutableArray!
    
    var backupFormatter : NSDateFormatter!
    
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
        
        devicesView.reloadData()
    }
    

    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        switch (tableView.tag)
        {
        case 1:
            return devices.count
            
        case 2:
            return backups.count
            
        default:
            return 0
        }
    }
    
    
    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        switch (tableView.tag)
        {
        case 1:
            var cellView = tableView.makeViewWithIdentifier("device", owner: tableView) as NSTableCellView
            cellView.textField.stringValue = devices.allValues[row] as NSString
            return cellView
        case 2:
            var cellView = tableView.makeViewWithIdentifier("backup", owner: tableView) as NSTableCellView
            cellView.textField.stringValue = backups[row] as NSString
            return cellView
            
        default:
            return NSTableCellView()
        }
    }
    
    func tableViewSelectionDidChange(notification: NSNotification!) {
        var tableView = notification.object as NSTableView
        if (tableView.tag == 1)
        {
            //NSLog("changed")
            
            backups = NSMutableArray()
            
            var nm = NSFileManager()
            let file = dataFolder.stringByAppendingPathComponent(devices.allKeys[tableView.selectedRow] as NSString)
            if !nm.fileExistsAtPath(file)
            {
                backupsView.reloadData()
                return
            }

            let files = nm.contentsOfDirectoryAtPath(
                file, error: nil)
            if files == nil {
                backupsView.reloadData()
                return
            }
            
            for each in files!
            {
                let file = each as NSString
                if file.hasPrefix(".")
                {
                    continue
                }
                if file.rangeOfString("-").length < 1
                {
                    continue
                }
                
                backups.addObject(file)
            }
            backupsView.reloadData()
        }
//        backups.sortUsingComparator(<#cmptr: NSComparator##(AnyObject!, AnyObject!) -> NSComparisonResult#>)
    }
    
    @IBAction func getBackupInfo(sender: AnyObject) {
        var nm = NSFileManager()
        if devicesView.selectedRow < 0
        {
            NSLog("未选择设备")
            return
        }
        let device = devices.allKeys[devicesView.selectedRow] as NSString
        let path = NSString(string: "/Users/sowicm/Library/Application Support/MobileSync/Backup/") + device
        if !nm.fileExistsAtPath(path)
        {
            NSLog("未找到该设备备份")
            return
        }
        
        var file = path + "/Info.plist"
        if !nm.fileExistsAtPath(file)
        {
            NSLog("备份缺失文件")
            return
        }
        let attr = nm.attributesOfItemAtPath(file, error: nil)!
        let backupDate = backupFormatter.stringFromDate(attr["NSFileModificationDate"] as NSDate)
        if backups.count > 0 && (backups.lastObject as NSString).isEqual(backupDate)
        {
            return
        }
        
        let backuppath = dataFolder.stringByAppendingPathComponent(device).stringByAppendingPathComponent(backupDate)
        
        /*if !nm.fileExistsAtPath(devicepath)
        {
            nm.createDirectoryAtPath(devicepath, withIntermediateDirectories: <#Bool#>, attributes: <#[NSObject : AnyObject]?#>, error: <#NSErrorPointer#>)
        }*/
        
        
        nm.createDirectoryAtPath(backuppath, withIntermediateDirectories: true, attributes: nil, error: nil)
        
        nm.copyItemAtPath(path + "/Info.plist", toPath: backuppath + "/Info.plist", error: nil)
        nm.copyItemAtPath(path + "/Status.plist", toPath: backuppath + "/Status.plist", error: nil)
        nm.copyItemAtPath(path + "/Manifest.plist", toPath: backuppath + "/Manifest.plist", error: nil)
        nm.copyItemAtPath(path + "/Manifest.mbdb", toPath: backuppath + "/Manifest.mbdb", error: nil)
        
        /*
        let files = nm.contentsOfDirectoryAtPath(
            path, error: nil)
        if files == nil {
            return
        }*/
        
        
        //NSLog("%@", attr["NSFileModificationDate"] as NSDate);
    }
    
    
    @IBOutlet weak var devicesView: NSTableView!
    @IBOutlet weak var backupsView: NSTableView!
}


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
        
        backupFolder = "/Users/sowicm/Library/Application Support/MobileSync/Backup"
        
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
    var backupFolder : NSString!
    
    var devices : NSMutableDictionary!
    
    var backups : NSMutableArray!
    
    var backupFormatter : NSDateFormatter!
    
    @IBAction func getDevices(sender: AnyObject) {
        var nm = NSFileManager()
        var error = NSError()
        let files = nm.contentsOfDirectoryAtPath(backupFolder, error: nil)
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
            //        backups.sortUsingComparator(<#cmptr: NSComparator##(AnyObject!, AnyObject!) -> NSComparisonResult#>)

            backupsView.reloadData()
        }
        else if tableView.tag == 2
        {
            var result = NSMutableString()
            
            if tableView.selectedRow < 1 {
                return
            }
            
            //var apps1, apps2 : NSMutableArray!
            var apps_1, apps_2 : NSMutableDictionary!
            var dict1, dict2 : NSMutableDictionary!
            
            let deviceFolder = dataFolder.stringByAppendingPathComponent(devices.allKeys[devicesView.selectedRow] as NSString)
            let path1 = deviceFolder.stringByAppendingPathComponent(backups[tableView.selectedRow - 1] as NSString).stringByAppendingPathComponent("Info.plist")
            let path2 = deviceFolder.stringByAppendingPathComponent(backups[tableView.selectedRow] as NSString).stringByAppendingPathComponent("Info.plist")

            var manifest1 = NSMutableDictionary(contentsOfFile: deviceFolder.stringByAppendingPathComponent(backups[tableView.selectedRow - 1] as NSString).stringByAppendingPathComponent("Manifest.plist"))
            
            var manifest2 = NSMutableDictionary(contentsOfFile: deviceFolder.stringByAppendingPathComponent(backups[tableView.selectedRow] as NSString).stringByAppendingPathComponent("Manifest.plist"))
            
            var nm = NSFileManager()
            
            if nm.fileExistsAtPath(path1)
            {
                dict1 = NSMutableDictionary(contentsOfFile: path1)
                //apps1 = dict1.objectForKey("Installed Applications") as NSMutableArray
                apps_1 = manifest1?.objectForKey("Applications") as NSMutableDictionary
            }
            else
            {
                result.appendString("not found path1\n")
                //NSLog("not found path1");
                return
            }
            
            if nm.fileExistsAtPath(path2)
            {
                dict2 = NSMutableDictionary(contentsOfFile: path2)
                //apps2 = dict2.objectForKey("Installed Applications") as NSMutableArray
                apps_2 = manifest2?.objectForKey("Applications") as NSMutableDictionary
            }
            else
            {
                result.appendString("not found path2\n")
                //NSLog("not found paht2");
                return
            }
            
            //NSLog("okay.");
            
            result.appendFormat("Previous has %ld applications\n", apps_1.count)
            //NSLog("Previous has %ld applications", apps1.count);
            result.appendFormat("Then has %ld applications\n", apps_2.count)
            //NSLog("Then has %ld applications", apps2.count);
            
            result.appendString("\n= 删除的Apps:\n\n")
            
            var n1 = 0, n2 = 0
            for (var i = 0; i < apps_1.count; ++i)
            {
                var found = false
                for (var j = 0; j < apps_2.count; ++j)
                {
                    //if apps1.objectAtIndex(i).isEqualToString(apps2.objectAtIndex(j) as NSString)
                    if apps_1.allKeys[i].isEqualToString(apps_2.allKeys[j] as NSString)
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                {
                    ++n1;
                    //result.appendFormat("[%@]\n", apps1.objectAtIndex(i) as NSString)
                    result.appendFormat("[%@]\n", apps_1.allKeys[i] as NSString)
                    //NSLog("the app [%@] is at iOS 7 but not at iOS 8", apps1.objectAtIndex(i) as NSString);
                }
            }
            
            result.appendFormat("\n共删除数量: %d\n", n1)
            result.appendString("-------------------------------\n")
            //NSLog("total %d items", n1);
            //NSLog("---------------");
            
            result.appendString("\n= 新装的Apps:\n\n")
            
            for (var i = 0; i < apps_2.count; ++i)
            {
                var found = false;
                for (var j = 0; j < apps_1.count; ++j)
                {
                    //if apps2.objectAtIndex(i).isEqualToString(apps1.objectAtIndex(j) as NSString)
                    if apps_2.allKeys[i].isEqualToString(apps_1.allKeys[j] as NSString)
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                {
                    n2++;
                    //result.appendFormat("[%@]\n", apps2.objectAtIndex(i) as NSString)
                    result.appendFormat("[%@]\n", apps_2.allKeys[i] as NSString)
                    //NSLog("the app [%@] is at iOS 8 but not at iOS 7", apps2.objectAtIndex(i) as NSString);
                }
            }
            result.appendFormat("\n共新装数量: %d\n", n2)
            //NSLog("total %d items", n2);
            
            resultText.string = result
        }
    }
    
    func getNormalBackup(device : NSString) {
        
    }
    
    func getMoreBackups(device : NSString) {
        
    }
    
    @IBAction func getBackupInfo(sender: AnyObject) {
        var nm = NSFileManager()
        
        for idevice in devices.allKeys {
        
        let device = idevice as NSString
        
        let files = nm.contentsOfDirectoryAtPath(backupFolder, error: nil)
        if files == nil {
            return
        }
        
        var count = 0
        for each in files!
        {
            let file = each as NSString
            if !file.hasPrefix(device)
            {
                continue
            }
            
            var path = backupFolder.stringByAppendingPathComponent(file)
            
            if !nm.fileExistsAtPath(path + "/Manifest.plist")
            {
                NSLog("%@ 中缺失文件 Manifest.plist", path)
                continue
            }
            
            /*
            let attr = nm.attributesOfItemAtPath(path + "/Info.plist", error: nil)!
            let backupDate = backupFormatter.stringFromDate(attr["NSFileModificationDate"] as NSDate)
            */
            
            let manifest : NSMutableDictionary! = NSMutableDictionary(contentsOfFile: path + "/Manifest.plist")
            let backupDate = backupFormatter.stringFromDate(manifest["Date"] as NSDate)
            
            var alreadyhas = false
            for backup in backups {
                if (backup as NSString).isEqualToString(backupDate) {
                    alreadyhas = true
                    break
                }
            }
            if alreadyhas {
                continue
            }

            let backuppath = dataFolder.stringByAppendingPathComponent(device).stringByAppendingPathComponent(backupDate)

            nm.createDirectoryAtPath(backuppath, withIntermediateDirectories: true, attributes: nil, error: nil)
            
            nm.copyItemAtPath(path + "/Info.plist", toPath: backuppath + "/Info.plist", error: nil)
            nm.copyItemAtPath(path + "/Status.plist", toPath: backuppath + "/Status.plist", error: nil)
            nm.copyItemAtPath(path + "/Manifest.plist", toPath: backuppath + "/Manifest.plist", error: nil)
            nm.copyItemAtPath(path + "/Manifest.mbdb", toPath: backuppath + "/Manifest.mbdb", error: nil)
        }
        
        }
        
    }
    
    
    @IBOutlet weak var devicesView: NSTableView!
    @IBOutlet weak var backupsView: NSTableView!
    @IBOutlet var resultText: NSTextView!
}


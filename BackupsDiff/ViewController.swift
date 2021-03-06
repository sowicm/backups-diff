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
        dataFolder = (paths[0] as NSString).stringByAppendingPathComponent("BackupsDiff/")
        
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
        let nm = NSFileManager()
        do {
            let files = try nm.contentsOfDirectoryAtPath(backupFolder as String)
            
            let prompt = "请为该设备设定一个名称："
            //let defaultValue = "iPhone"
            
            for each in files
            {
                let file : NSString = each as NSString
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
                
                let input = NSTextField()
                input.frame = NSMakeRect(0, 0, 200, 24)
                //input.setFrameOrigin(0, 0)
                //input.setFrameSize(200, 24)
                //input.setValue(defaultValue)
                
                let alert = NSAlert()
                alert.messageText = prompt
                alert.informativeText = file as String
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
            
        } catch {
            print(error)
            return
        }
        
        saveDevices()
        
        devicesView.reloadData()
    }
    

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
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
    
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch (tableView.tag)
        {
        case 1:
            let cellView = tableView.makeViewWithIdentifier("device", owner: tableView) as! NSTableCellView
            cellView.textField!.stringValue = devices.allValues[row] as! NSString as String
            return cellView
        case 2:
            let cellView = tableView.makeViewWithIdentifier("backup", owner: tableView) as! NSTableCellView
            cellView.textField!.stringValue = backups[row] as! NSString as String
            return cellView
            
        default:
            return NSTableCellView()
        }
    }
    
    func compareBackupsBetween(apps1: NSArray, apps2: NSArray, manifest1: NSDictionary, manifest2: NSDictionary) {
        
        let result = NSMutableString()
        
        //NSLog("okay.");
        
        result.appendFormat("Previous has %ld applications\n", apps1.count)
        //NSLog("Previous has %ld applications", apps1.count);
        result.appendFormat("Then has %ld applications\n", apps2.count)
        //NSLog("Then has %ld applications", apps2.count);
        
        result.appendString("\n= 删除的Apps:\n\n")
        
        var n1 = 0, n2 = 0
        for (var i = 0; i < apps1.count; ++i)
        {
            var found = false
            for (var j = 0; j < apps2.count; ++j)
            {
                if apps1.objectAtIndex(i).isEqualToString(apps2.objectAtIndex(j) as! NSString as String)
                {
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                // skip apple applications
                //if (apps1.objectAtIndex(i) as! String).hasPrefix("com.apple.")
                //{
                //    continue
                //}
                
                var hasPath = false
                let packageName = apps1.objectAtIndex(i) as! NSString
                let appdic = manifest1.objectForKey( packageName )
                if appdic != nil
                {
                    let pathString = (appdic as! NSDictionary).objectForKey("Path")
                    if pathString != nil
                    {
                        let path = NSURL(fileURLWithPath: pathString as! String)
                        //result.appendFormat("%@\n(%@)\n", path.lastPathComponent as! NSString, packageName)
                        result.appendFormat("%@\n", path.lastPathComponent as! NSString)
                        hasPath = true
                    }
                }
                if !hasPath
                {
                    result.appendFormat("[%@]\n", packageName)
                }
                
                ++n1;
                //NSLog("the app [%@] is at iOS 7 but not at iOS 8", apps1.objectAtIndex(i) as NSString);
            }
        }
        
        result.appendFormat("\n共删除数量: %d\n", n1)
        result.appendString("-------------------------------\n")
        //NSLog("total %d items", n1);
        //NSLog("---------------");
        
        result.appendString("\n= 新装的Apps:\n\n")
        
        for (var i = 0; i < apps2.count; ++i)
        {
            var found = false;
            for (var j = 0; j < apps1.count; ++j)
            {
                if apps2.objectAtIndex(i).isEqualToString(apps1.objectAtIndex(j) as! NSString as String)
                {
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                //if (apps2.objectAtIndex(i) as! String).hasPrefix("group.")
                //{
                //    continue
                //}
                
                var hasPath = false
                let packageName = apps2.objectAtIndex(i) as! NSString
                let appdic = manifest2.objectForKey( packageName )
                if appdic != nil
                {
                    let pathString = (appdic as! NSDictionary).objectForKey("Path")
                    if pathString != nil
                    {
                        let path = NSURL(fileURLWithPath: pathString as! String)
                        //result.appendFormat("%@\n(%@)\n", path.lastPathComponent as! NSString, packageName)
                        result.appendFormat("%@\n", path.lastPathComponent as! NSString)
                        hasPath = true
                    }
                }
                if !hasPath
                {
                    result.appendFormat("[%@]\n", packageName)
                }
                
                n2++;
                //NSLog("the app [%@] is at iOS 8 but not at iOS 7", apps2.objectAtIndex(i) as NSString);
            }
        }
        result.appendFormat("\n共新装数量: %d\n", n2)
        //NSLog("total %d items", n2);
        
        resultText.string = result as String
    }
    
    func reloadCompare() {
        
        resultText.string = ""
        
        let tableView = backupsView
        
        if tableView.selectedRow < 1 {
            return
        }
        
        let deviceFolder = dataFolder.stringByAppendingPathComponent(devices.allKeys[devicesView.selectedRow] as! NSString as String)
        
        
        /*
        var nm = NSFileManager()
        
        if nm.fileExistsAtPath(path1)
        {
        
        }
        else
        {
        result.appendString("not found path1\n")
        //NSLog("not found path1");
        return
        }
        
        if nm.fileExistsAtPath(path2)
        {
        
        }
        else
        {
        result.appendString("not found path2\n")
        //NSLog("not found paht2");
        return
        }
        */
        
        let manifest1 = NSMutableDictionary(contentsOfURL: (NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow - 1] as! String).URLByAppendingPathComponent("Manifest.plist")))// as String)
        
        let manifest2 = NSMutableDictionary(contentsOfURL: (NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow] as! String).URLByAppendingPathComponent("Manifest.plist")))
        
        let info1 = NSMutableDictionary(contentsOfURL: NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow - 1] as! String).URLByAppendingPathComponent("Info.plist"))
        
        let info2 = NSMutableDictionary(contentsOfURL: NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow] as! String).URLByAppendingPathComponent("Info.plist"))
        
        let apps1: AnyObject? = info1?.objectForKey("Installed Applications")
        let apps2: AnyObject? = info2?.objectForKey("Installed Applications")

        if apps1 == nil || apps2 == nil
        {
            return
        }
        
        compareBackupsBetween(apps1 as! NSArray, apps2: apps2 as! NSArray, manifest1: manifest1!.objectForKey("Applications") as! NSDictionary, manifest2: manifest2!.objectForKey("Applications") as! NSDictionary)
        
        /*
        switch sourceRadio.selectedColumn
        {
        case 0:

            
            let apps1 : NSDictionary! = manifest1?.objectForKey("Applications") as! NSMutableDictionary
            let apps2 : NSDictionary! = manifest2?.objectForKey("Applications") as! NSMutableDictionary
            
            compareBackupsBetween(apps1.allKeys, apps2: apps2.allKeys)
            
            break;
            
        case 1:

            
            

            
            
            
            break
            
        case 2:
            let manifest = NSMutableDictionary(contentsOfURL: (NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow] as! String).URLByAppendingPathComponent("Manifest.plist")))
            let info = NSMutableDictionary(contentsOfURL: NSURL(fileURLWithPath: deviceFolder).URLByAppendingPathComponent(backups[tableView.selectedRow] as! String).URLByAppendingPathComponent("Info.plist"))
            
            let apps1 : NSDictionary! = manifest?.objectForKey("Applications") as! NSMutableDictionary
            let apps2: AnyObject? = info?.objectForKey("Installed Applications")
            
            if apps1 == nil || apps2 == nil
            {
                return
            }

            compareBackupsBetween(apps1.allKeys, apps2: apps2 as! NSArray)
            
            break
            
        default:
            break
        }
*/

    }
    
    func tableViewSelectionDidChange(notification: NSNotification!) {
        var tableView = notification.object as! NSTableView
        if (tableView.tag == 1)
        {
            //NSLog("changed")
            
            backups = NSMutableArray()
            
            var nm = NSFileManager()
            let file = (dataFolder as! NSString).stringByAppendingPathComponent(devices.allKeys[tableView.selectedRow] as! String)
            if !nm.fileExistsAtPath(file)
            {
                backupsView.reloadData()
                return
            }

            do
            {
                let files = try nm.contentsOfDirectoryAtPath(
                    file)
                for each in files
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
            } catch {
                backupsView.reloadData()
                return
            }
            
            //        backups.sortUsingComparator(<#cmptr: NSComparator##(AnyObject!, AnyObject!) -> NSComparisonResult#>)

            backupsView.reloadData()
        }
        else if tableView.tag == 2
        {
            reloadCompare()
        }
    }
    
    @IBAction func getBackupInfo(sender: AnyObject) {
        var nm = NSFileManager()
        
        for idevice in devices.allKeys {
        
        let device = idevice as! NSString
        
        do {
            let files = try nm.contentsOfDirectoryAtPath(backupFolder as String)
            var count = 0
            for each in files
            {
                let file = each as NSString
                if !file.hasPrefix(device as String)
                {
                    continue
                }
                
                var path = backupFolder.stringByAppendingPathComponent(file as String)
                
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
                let backupDate = backupFormatter.stringFromDate(manifest["Date"] as! NSDate)
                
                var alreadyhas = false
                for backup in backups {
                    if (backup as! NSString).isEqualToString(backupDate) {
                        alreadyhas = true
                        break
                    }
                }
                if alreadyhas {
                    continue
                }
                
                let backuppath = (dataFolder.stringByAppendingPathComponent(device as String) as NSString).stringByAppendingPathComponent(backupDate)
                
                do
                {
                    try nm.createDirectoryAtPath(backuppath, withIntermediateDirectories: true, attributes: nil)
                
                    try nm.copyItemAtPath(path + "/Info.plist", toPath: backuppath + "/Info.plist")
                    try nm.copyItemAtPath(path + "/Status.plist", toPath: backuppath + "/Status.plist")
                    try nm.copyItemAtPath(path + "/Manifest.plist", toPath: backuppath + "/Manifest.plist")
                    try nm.copyItemAtPath(path + "/Manifest.mbdb", toPath: backuppath + "/Manifest.mbdb")
                }
                catch {
                    
                }
            }
        } catch {
            print(error)
            return
        }
        }
    }
    
    @IBAction func sourceChanged(sender: AnyObject) {
        reloadCompare()
    }
    
    @IBOutlet weak var devicesView: NSTableView!
    @IBOutlet weak var backupsView: NSTableView!
    @IBOutlet var resultText: NSTextView!
    @IBOutlet weak var sourceRadio: NSMatrix!
}


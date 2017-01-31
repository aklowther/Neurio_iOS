//
//  InterfaceController.swift
//  WatchApp Extension
//
//  Created by Adam Lowther on 1/14/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController
{

    @IBOutlet var tableView: WKInterfaceTable!
    let neurioManager = NeurioManager.sharedInstance
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if let latestEntry = neurioManager.latestEntryFromLast48Hours(completionHandler: { responseDictionary in
            if let newEntry = responseDictionary
            {
                self.reloadTable(withData: newEntry)
            }
        })
        {
            self.reloadTable(withData: latestEntry)
        }
        
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func reloadTable(withData data:[String: Any])
    {
        let tableViewRows = self.tableView.numberOfRows
        
        self.tableView.insertRows(at: NSIndexSet(index: tableViewRows) as IndexSet, withRowType: "EnergyDataRow")
        
//        for i in tableViewRows..<self.tableView.numberOfRows
//        {
//            // 1
//            let controller = self.tableView.rowController(at: i)
//            
//            // 2
//            if let controller = controller as? EnergyDataRow
//            {
//                let recipe = responseKeys[i - tableViewRows - 1]
//                controller.keyLabel.setText(recipe.name)
//                controller.valueLabel.setText("\(recipe.ingredients.count) ingredients")
//            }
//        }
        
        var i = 0
        for (key, value) in data
        {
            let controller = self.tableView.rowController(at: i)
            
            if let controller = controller as? EnergyDataRow
            {
                controller.keyLabel.setText(key)
                controller.valueLabel.setText(String(format: "%@", value as! CVarArg))
            }
            i += 1
        }
    }
}

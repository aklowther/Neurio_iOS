//
//  HomeViewController.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/13/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import UIKit

struct NeurioHistoryPartial {
    var key: String
    var value : Any
}

typealias ReturnPartials = (NeurioHistoryPartial?) -> Void

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    
    var _cellData: Array<NeurioHistoryPartial> = Array()
    
    let neurioManager : NeurioManager = NeurioManager.sharedInstance
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        getTodayHistory()
    }
    
    //MARK: Tableview
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _cellData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let partial : NeurioHistoryPartial = _cellData[indexPath.row]
        cell.textLabel!.text = partial.key
        cell.detailTextLabel!.text = String(format: "%@", partial.value as! CVarArg)
        
        return UITableViewCell()
    }
    
    //MARK:  Private
    func getTodayHistory() -> Void {
        if let sensorID : String = neurioManager.hasValidSensorID()
        {
            _cellData.removeAll()
            neurioManager.getTodaysHistory(sensorID: sensorID, completionHandler: { result in
                debugPrint(result)
                if let generationEnergy = result?["generationEnergy"]
                {
                    self._cellData.append(NeurioHistoryPartial(key: "Generation Energy", value: generationEnergy))
                }
                
                if let consumptionEnergy = result?["consumptionEnergy"]
                {
                    self._cellData.append(NeurioHistoryPartial(key: "Consumption Energy", value: consumptionEnergy))
                }
                
                if let importedEnergy = result?["importedEnergy"]
                {
                    self._cellData.append(NeurioHistoryPartial(key: "Imported Energy", value: importedEnergy))
                }
                
                if let exportedEnergy = result?["exportedEnergy"]
                {
                    self._cellData.append(NeurioHistoryPartial(key: "Exported Energy", value: exportedEnergy))
                }
                
//                if let generationPower = result?["generationPower"]
//                {
//                    self._cellData.append(NeurioHistoryPartial(key: "Generation Power", value: generationPower))
//                }
//                
//                if let consumptionPower = result?["consumptionPower"]
//                {
//                    self._cellData.append(NeurioHistoryPartial(key: "Consumption Power", value: consumptionPower))
//                }
                
                self.tableView.reloadData()
            })
        }
        else
        {
            self.performSegue(withIdentifier: "showGetSensorVC", sender: self)
        }
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        getTodayHistory()
    }
}

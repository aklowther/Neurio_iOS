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
        cell.detailTextLabel!.text = String(format: "%.02f kWh", partial.value as! Double)
        
        return cell
    }
    
    //MARK:  Private
    func getTodayHistory() -> Void {
        if neurioManager.hasValidToken()
        {
            if let sensorID : String = neurioManager.hasValidSensorID()
            {
                _cellData.removeAll()
                if let mostRecentSavedEnergy = neurioManager.getTodaysEnergyHistory(sensorID: sensorID, completionHandler: { result in
                    debugPrint(result)
                    self._cellData.removeAll()
                    if let generationEnergy = result?["generationEnergy"]
                    {
                        let generatedkWh = ((generationEnergy as! Double)/3600000.0)
                        self._cellData.append(NeurioHistoryPartial(key: "Generation Energy", value: generatedkWh))
                    }
                    
                    if let consumptionEnergy = result?["consumptionEnergy"]
                    {
                        let consumptionEnergykWh = ((consumptionEnergy as! Double)/3600000.0)
                        self._cellData.append(NeurioHistoryPartial(key: "Consumption Energy", value: consumptionEnergykWh))
                    }
                    
                    if let importedEnergy = result?["importedEnergy"]
                    {
                        let importedkWH = ((importedEnergy as! Double)/3600000.0)
                        self._cellData.append(NeurioHistoryPartial(key: "Imported Energy", value: importedkWH))
                    }
                    
                    if let exportedEnergy = result?["exportedEnergy"]
                    {
                        let exportedkWh = ((exportedEnergy as! Double)/3600000.0)
                        self._cellData.append(NeurioHistoryPartial(key: "Exported Energy", value: exportedkWh))
                    }
                    self.tableView.reloadData()
                })
                {
                    if let generationEnergy = mostRecentSavedEnergy["generationEnergy"]
                    {
                        let generatedkWh = ((generationEnergy as! Double)/3600000.0)
                        _cellData.append(NeurioHistoryPartial(key: "Generation Energy", value: generatedkWh))
                    }
                    
                    if let consumptionEnergy = mostRecentSavedEnergy["consumptionEnergy"]
                    {
                        let consumptionEnergykWh = ((consumptionEnergy as! Double)/3600000.0)
                        _cellData.append(NeurioHistoryPartial(key: "Consumption Energy", value: consumptionEnergykWh))
                    }
                    
                    if let importedEnergy = mostRecentSavedEnergy["importedEnergy"]
                    {
                        let importedkWH = ((importedEnergy as! Double)/3600000.0)
                        _cellData.append(NeurioHistoryPartial(key: "Imported Energy", value: importedkWH))
                    }
                    
                    if let exportedEnergy = mostRecentSavedEnergy["exportedEnergy"]
                    {
                        let exportedkWh = ((exportedEnergy as! Double)/3600000.0)
                        _cellData.append(NeurioHistoryPartial(key: "Exported Energy", value: exportedkWh))
                    }
                    self.tableView.reloadData()
                }
            }
            else
            {
                self.performSegue(withIdentifier: "showGetSensorVC", sender: self)
            }
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

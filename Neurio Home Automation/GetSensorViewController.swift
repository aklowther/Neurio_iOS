//
//  GetSensorViewController.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/11/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class GetSensorViewController: UIViewController, SFSafariViewControllerDelegate, AuthManagerProtocol
{
    @IBOutlet weak var mustBeOnLANLabel: UILabel!
    @IBOutlet weak var ipAddressTextField: UITextField!
    
    var webView:SFSafariViewController!
    let neurioManager = NeurioManager.sharedInstance
    
    override func viewDidLoad()
    {
        
        mustBeOnLANLabel.text = "In order to get sensorIDs of the sensors connected to your Neurio, we need the IP address of your Neurio on your LAN"
        ipAddressTextField.placeholder = "IP Address"
        
        if let neurioURL:URL = URL(string: neurioManager.getNuerioAuthorizationURL())
        {
            webView = SFSafariViewController(url: neurioURL, entersReaderIfAvailable: false)
            webView.delegate = self
            
            neurioManager.subscribeToListener(listener: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !neurioManager.hasValidToken()
        {
            if !neurioManager.hasAuthCode()
            {
                self.present(webView, animated: true, completion: nil)
            }
        }
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
    
    //MARK: AuthManagerProtocol
    func handleURL(url: URL) {
        dismiss(animated: true, completion: nil)
        
        //if state == auth_code
        neurioManager.NeurioLoginWithToken()
    }
}
 

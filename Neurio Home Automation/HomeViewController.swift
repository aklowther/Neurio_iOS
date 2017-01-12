//
//  HomeViewController.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/11/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class HomeViewController: UIViewController, SFSafariViewControllerDelegate, AuthManagerProtocol
{
    var webView:SFSafariViewController!
    let authManager = AuthManager.sharedInstance
    
    override func viewDidLoad()
    {
        self.view.backgroundColor = UIColor.blue
        
        if let neurioURL:URL = URL(string: authManager.getNuerioAuthorizationURL())
        {
            webView = SFSafariViewController(url: neurioURL, entersReaderIfAvailable: false)
            webView.delegate = self
            
            authManager.subscribeToListener(listener: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !authManager.hasValidToken()
        {
            self.present(webView, animated: true, completion: nil)
        }
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
    
    //MARK: AuthManagerProtocol
    func handleURL(url: URL) {
        dismiss(animated: true, completion: nil)
    }
}

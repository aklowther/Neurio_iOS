//
//  ViewController.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/9/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import UIKit

class NativeLoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var noticeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.placeholder = "Username"
        passwordTextField.placeholder = "Password"
        noticeLabel.text = "Authenticate using Neurio credentials"
        
        self.setupKeyboard()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //for debuggin
        self.submitLogin()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupKeyboard() -> Void {
        usernameTextField.returnKeyType = UIReturnKeyType.next
        passwordTextField.returnKeyType = UIReturnKeyType.go
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        usernameTextField.becomeFirstResponder()
    }
    
    func submitLogin() -> Void {
        let authManager = NeurioManager.sharedInstance
//        let validLogin = authManager.NeurioLoginWithCredentials(username: usernameTextField.text!, password: passwordTextField.text!)
//        debugPrint(validLogin)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(usernameTextField) {
            passwordTextField.becomeFirstResponder()
        }
        
        if textField.isEqual(passwordTextField) {
            self.submitLogin()
        }
        
        return true
    }
}


//
//  AuthManager.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/10/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol AuthManagerProtocol
{
    func handleURL(url: URL)
}


public class AuthManager : NSObject
{
    static let sharedInstance = AuthManager()
    
    private let clientID = NEURIOCLIENTID
    private let clientSecret = NEURIOCLIENTSECRET
    private var token : String!
    private var listeners : NSHashTable! = NSHashTable<AuthManagerProtocol?>.weakObjects()
    
    public func getNuerioAuthorizationURL() -> String
    {
        return "https://api.neur.io/v1/oauth2/authorize?response_type=code&client_id=s955B40sRvussLFKM-eRAg&redirect_uri=alow://x-callback-url&state=mystate"
    }
    
    public func handleOpenURL(url : URL)
    {
        debugPrint(url.absoluteString)
        
        let startIndex: Range! = url.absoluteString.range(of: "?code=")
        let endIndex: Range! = url.absoluteString.range(of: "&state")
        let tokenEnd: String! = url.absoluteString.substring(to: endIndex!.lowerBound)
        token = tokenEnd.substring(from: startIndex!.upperBound)
        debugPrint(token)
        
        for listener in listeners
        {
            listener.handleURL(url)
        }
    }
    
    public func NeurioLoginWithCredentials(username: String, password: String) -> Bool {
        var validLogin = false
        
        if self.isNeurioAPIAlive()
        {
            let neurioAuthorizationURL = "https://api.neur.io/v1/oauth2/authorize?response_type=code&client_id=\(clientID)&redirect_uri=alow://state=mystate"
//            Alamofire.request(neurioAuthorizationURL)
//                .response { response in
//                    debugPrint(response)
//                }
            let getTokenPath = "https://api.neur.io/v1/oauth2/token"
            let tokenParams = ["client_id": clientID, "client_secret": clientSecret, "grant_type" :"authorization_code", "redirect_uri": "alow://", "state": "state"/*, "code": receivedCode*/]
            Alamofire.request(getTokenPath, method: .post, parameters: tokenParams, encoding: URLEncoding.default, headers: nil)
                .response { response in
                    debugPrint(response)
            }
        }
        
        return validLogin
    }
    
    public func NeurioLoginWithToken(token:String) -> Bool {
        var validLogin = false
        
        return validLogin
    }
    
    func isNeurioAPIAlive() -> Bool {
        Alamofire.request("https://api.neur.io/v1/status")
            .response { response in
                return (response.response?.statusCode == 200)
        }
        return true
    }
    
    //MARK: Listeners
    public func subscribeToListener(listener: AnyObject)
    {
        listeners.add(listener)
    }
    
    public func unsubscribeFromListener(listener: AnyObject)
    {
        listeners.remove(listener)
    }
}

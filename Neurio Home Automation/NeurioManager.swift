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
import Strongbox

protocol AuthManagerProtocol
{
    func handleURL(url: URL)
}


public class NeurioManager : NSObject
{
    static let sharedInstance = NeurioManager()
    
    private var strongBox : Strongbox!
    private let _clientID = NEURIOCLIENTID //value come from Swift file in .gitignore
    private let _clientSecret = NEURIOCLIENTSECRET //value come from Swift file in .gitignore
    private var _token : String!
    private var _authCode : String!
    private var listeners : NSHashTable! = NSHashTable<AnyObject>.weakObjects()
    
    override init()
    {
        strongBox = Strongbox.init(keyPrefix: STRONGBOXPREFIX!)
    }
    
    //MARK: Authorization
    public func getNuerioAuthorizationURL() -> String
    {
        return "https://api.neur.io/v1/oauth2/authorize?response_type=code&client_id=\(_clientID!)&redirect_uri=alow://x-callback-url&state=auth_code"
    }
    
    public func hasValidToken() -> Bool
    {
        if (strongBox.unarchive(objectForKey: "token") as? String) != nil
        {
            _token = strongBox.unarchive(objectForKey: "token") as? String
            let expiresDate : Date = strongBox.unarchive(objectForKey: "expiresDate") as! Date
            return (expiresDate.compare(Date()) == ComparisonResult.orderedDescending)
        }
        return false
    }
    
    public func hasAuthCode() -> Bool
    {
        return (_authCode != nil)
    }
    
    public func handleOpenURL(url : URL)
    {
        debugPrint(url.absoluteString)
        
        let startIndex: Range! = url.absoluteString.range(of: "?code=")
        let endIndex: Range! = url.absoluteString.range(of: "&state")
        let tokenEnd: String! = url.absoluteString.substring(to: endIndex!.lowerBound)
        _authCode = tokenEnd.substring(from: startIndex!.upperBound)
//        strongBox.archive(_authCode, key: "authCode")
        
        for listener in listeners.objectEnumerator()
        {
            (listener as! AuthManagerProtocol).handleURL(url: url)
        }
    }
    
//    public func NeurioLoginWithCredentials(username: String, password: String) -> Bool {
//        var validLogin = false
//        
//        if self.isNeurioAPIAlive()
//        {
//            let neurioAuthorizationURL = "https://api.neur.io/v1/oauth2/authorize?response_type=code&client_id=\(clientID)&redirect_uri=alow://state=mystate"
////            Alamofire.request(neurioAuthorizationURL)
////                .response { response in
////                    debugPrint(response)
////                }
////            let getTokenPath = "https://api.neur.io/v1/oauth2/token"
////            let tokenParams = ["client_id": clientID, "client_secret": clientSecret, "grant_type" :"authorization_code", "redirect_uri": "alow://", "state": "state"/*, "code": receivedCode*/]
////            Alamofire.request(getTokenPath, method: .post, parameters: tokenParams, encoding: URLEncoding.default, headers: nil)
////                .response { response in
////                    debugPrint(response)
////            }
//        }
//        
//        return validLogin
//    }
    
    public func NeurioLoginWithToken() -> Void
    {
        let getTokenPath = "https://api.neur.io/v1/oauth2/token"
        let headers : Dictionary! = ["Content-Type" : "application/x-www-form-urlencoded"]
        let tokenParams : Dictionary! = ["grant_type" :"authorization_code", "client_id": _clientID!, "client_secret": _clientSecret!, "redirect_uri": "alow://x-callback-url", "state": "token", "code": _authCode!]
        Alamofire.request(getTokenPath, method: .post, parameters: tokenParams, encoding: URLEncoding.httpBody, headers: headers)
            .validate()
            .responseJSON { response in
                if response.result.isSuccess
                {
                    if let responseDict = response.result.value as? Dictionary<String, Any>
                    {
                        self._token = responseDict["access_token"]! as? String
                        if let createdAtString : String = responseDict["created_at"] as? String
                        {
                            let dateFormatter = self.incomingNeurioDateFormatter()
                            if let createdDate = dateFormatter.date(from: createdAtString)
                            {
                                if let expiresNumber : NSNumber = responseDict["expires_in"] as? NSNumber
                                {
                                    let expiresDate : Date = createdDate.addingTimeInterval(expiresNumber.doubleValue)
                                    self.strongBox.archive(expiresDate, key: "expiresDate")
                                }
                            }
                            else
                            {
                                debugPrint("something")
                            }
                        }
  
                        self.strongBox.archive(self._token, key: "token")
                        debugPrint(self._token)
                    }
                }
        }
        
    }
    
    func isNeurioAPIAlive() -> Bool {
        Alamofire.request("https://api.neur.io/v1/status")
            .response { response in
                return (response.response?.statusCode == 200)
        }
        return true
    }
    
    //MARK: Current User
    public func getCurrentUser() -> Void
    {
        let url = "https://api.neur.io/v1/users/current"
        let headers = ["Authorization" : String(format: "Bearer %@", _token!)]
        Alamofire.request(url, method: .get, parameters: [:], encoding: JSONEncoding.prettyPrinted, headers: headers)
            .validate()
            .responseJSON { response in
                if response.result.isSuccess
                {
                    debugPrint(response)
                }
        }
    }
    
    //MARK: 
    public func getTodaysHistory() -> Void
    {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.autoupdatingCurrent
        let dateAtMidnight = calendar.startOfDay(for: Date())
        
        let dateFormatter = self.outgoingNeurioDateFormatter()

        let startDateString : String! = dateFormatter.string(from: dateAtMidnight)
        let url = "https://api.neur.io/v1/samples?sensorId=\(ADAMSENSORID!)&start=\(startDateString!)&granularity=days"
        let headers = ["Authorization" : String(format: "Bearer %@", _token!)]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.prettyPrinted, headers: headers)
            .validate()
            .responseJSON { (response) in
                if response.result.isSuccess
                {
                    debugPrint(response)
                }
        }
    }
    
    //MARK: Private
    private func incomingNeurioDateFormatter() -> DateFormatter
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter
    }
    
    private func outgoingNeurioDateFormatter() -> DateFormatter
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return dateFormatter
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

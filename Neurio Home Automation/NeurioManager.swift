//
//  AuthManager.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/10/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import Alamofire
//import SwiftyJSON
import Strongbox

protocol AuthManagerProtocol
{
    func handleURL(url: URL)
}

typealias CompletionHandler = (Bool) -> Void
public typealias ReturnDictionary = (Dictionary<String, Any>?) -> Void


public class NeurioManager : NSObject
{
    static let sharedInstance = NeurioManager()
    
    private var strongBox : Strongbox!
    private let _clientID = NEURIOCLIENTID //value come from Swift file in .gitignore
    private let _clientSecret = NEURIOCLIENTSECRET //value come from Swift file in .gitignore
    private var _token : String!
    private var _authCode : String!
    private var _listeners : NSHashTable! = NSHashTable<AnyObject>.weakObjects()
    
    private var _last48Hours : Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>()
    
    override init()
    {
        strongBox = Strongbox.init(keyPrefix: STRONGBOXPREFIX!)
    }
    
    //MARK: Authorization
    public func getNuerioAuthorizationURL() -> String
    {
        return "https://api.neur.io/v1/oauth2/authorize?response_type=code&client_id=\(_clientID!)&redirect_uri=alow://x-callback-url&state=auth_code"
    }
    
    //MARK: Validation
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
    
    public func hasValidSensorID() -> String?
    {
        guard let sensorID = strongBox.unarchive(objectForKey: "sensorID") as? String  else {
            //TODO: make this check getCurrentUser(), if user has more than 1 Neurio, ask which they'd like to use
            return ADAMSENSORID!
        }
        
        return sensorID
    }
    
    public func handleOpenURL(url : URL)
    {
        debugPrint(url.absoluteString)
        
        let startIndex: Range! = url.absoluteString.range(of: "?code=")
        let endIndex: Range! = url.absoluteString.range(of: "&state")
        let tokenEnd: String! = url.absoluteString.substring(to: endIndex!.lowerBound)
        _authCode = tokenEnd.substring(from: startIndex!.upperBound)
        
        for listener in _listeners.objectEnumerator()
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
                                    _=self.strongBox.archive(expiresDate, key: "expiresDate")
                                }
                            }
                            else
                            {
                                debugPrint("something")
                            }
                        }
  
                        _=self.strongBox.archive(self._token, key: "token")
                        debugPrint(self._token)
                    }
                }
        }
        
    }
    
    func isNeurioAPIAlive(completionHandler : @escaping CompletionHandler) -> Void {
        Alamofire.request("https://api.neur.io/v1/status")
            .responseJSON { response in
                completionHandler(response.result.isSuccess)
        }
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
    public func getTodaysHistory(sensorID: String, completionHandler: @escaping ReturnDictionary) -> Void
    {
        if self.hasValidToken()
        {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.autoupdatingCurrent
            let dateAtMidnight = calendar.startOfDay(for: Date())
            
            let dateFormatter = self.outgoingNeurioDateFormatter()
            
            let startDateString : String! = dateFormatter.string(from: dateAtMidnight)
            let url = "https://api.neur.io/v1/samples?sensorId=\(sensorID)&start=\(startDateString!)&granularity=days"
//            let url = "https://api.neur.io/v1/samples/live?sensorId=\(sensorID)"
            let headers = ["Authorization" : String(format: "Bearer %@", _token!)]
            
            Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.prettyPrinted, headers: headers)
                .validate()
                .responseJSON { (response) in
                    if let responseResultArray = response.result.value as? Array<Any>
                    {
                        if let responseResult = responseResultArray[0] as? Dictionary<String, Any>
                        {
                            self.processNeurioHistory(withData: responseResult, forDate: dateAtMidnight)
                            completionHandler(responseResult)
                        }
                        else
                        {
                            completionHandler(nil)
                        }
                    }
                    else
                    {
                        completionHandler(nil)
                    }
            }
        }
    }
    
    public func getTodaysEnergyHistory(sensorID: String, completionHandler: @escaping ReturnDictionary) -> Void
    {
        if self.hasValidToken()
        {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.autoupdatingCurrent
            let dateAtMidnight = calendar.startOfDay(for: Date())
            
            let dateFormatter = self.outgoingNeurioDateFormatter()
            
            let startDateString : String! = dateFormatter.string(from: dateAtMidnight)
            let url = "https://api.neur.io/v1/samples/stats?sensorId=\(sensorID)&start=\(startDateString!)&granularity=days"
            let headers = ["Authorization" : String(format: "Bearer %@", _token!)]
            
            Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.prettyPrinted, headers: headers)
                .validate()
                .responseJSON { (response) in
                    if let responseResultArray = response.result.value as? Array<Any>
                    {
                        if let responseResult = responseResultArray[0] as? Dictionary<String, Any>
                        {
                            self.processNeurioEnergyQuery(withData: responseResult, forDate: dateAtMidnight)
                            completionHandler(responseResult)
                        }
                        else
                        {
                            completionHandler(nil)
                        }
                    }
                    else
                    {
                        completionHandler(nil)
                    }
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
    
    //MARK: DataStorage
    private func processNeurioHistory(withData data:Dictionary<String, Any>, forDate date:Date) -> Void
    {
        if _last48Hours.count == 0
        {
            _last48Hours = loadLast2DaysOfData()
        }
        
        let dateFormatter = incomingNeurioDateFormatter()
        if let newTimestamp = dateFormatter.date(from: data["timestamp"] as! String)
        {
            for (index, partialObject) in _last48Hours.enumerated()
            {
                if let dataDate : String = partialObject["timestamp"] as! String?
                {
                    if let dateTime = dateFormatter.date(from: dataDate)
                    {
                        if (dateTime.compare(date) == .orderedAscending)
                        {
                            _last48Hours.remove(at: index)
                        }
                        else if (dateTime.compare(newTimestamp) == .orderedSame)
                        {
                            return
                        }
                        else
                        {
                            break
                        }
                    }
                }
            }
            _last48Hours.append(data)
        }
    }
    
    private func processNeurioEnergyQuery(withData data:Dictionary<String, Any>, forDate date:Date) -> Void
    {
        if _last48Hours.count == 0
        {
            _last48Hours = loadLast2DaysOfData()
        }
        
        let dateFormatter = incomingNeurioDateFormatter()
//        if let startTimestamp = dateFormatter.date(from: data["start"] as! String),//timestamp
        if let endTimestamp = dateFormatter.date(from: data["end"] as! String)
        {
            for (index, partialObject) in _last48Hours.enumerated()
            {
                if let dataDate : String = partialObject["start"] as! String?
                {
                    if let dateTime = dateFormatter.date(from: dataDate)
                    {
                        if (dateTime.compare(date) == .orderedAscending)
                        {
                            _last48Hours.remove(at: index)
                        }
                        else if (dateTime.compare(endTimestamp) == .orderedSame)
                        {
                            return
                        }
                        else
                        {
                            break
                        }
                    }
                }
            }
            _last48Hours.append(data)
        }
    }
    
    public func saveLast2DaysOfData() -> Void
    {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        if let documents = directories.first
        {
            NSKeyedArchiver.archiveRootObject(_last48Hours, toFile: "\(documents)/past48Hours.plist")
        }
    }
    
    private func loadLast2DaysOfData() -> Array<Dictionary<String, Any>>
    {
        let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if let documents = directories.first
        {
//            if let urlDocuments = NSURL(string: documents)
//            {
                if let tempLoad = NSKeyedUnarchiver.unarchiveObject(withFile: "\(documents)/past48Hours.plist")
                {
                    return tempLoad as! [[String: Any]]
//                    debugPrint(tempLoad)
                }
                
//                if let past48HoursURL = urlDocuments.appendingPathComponent("past48Hours.plist"),
//                    let tempLoadData = try? Data(contentsOf: past48HoursURL)
//                {
////                    let tempLoadData = try? Data(contentsOf: past48HoursURL)
////                    if let tempLoad = try? PropertyListSerialization.propertyList(from: tempLoadData, options: [], format: nil) as? [[String: Any]]
//                    if let tempLoad = NSKeyedUnarchiver.unarchiveObject(withFile: "\(documents)/past48Hours.plist")
//                    {
////                        return tempLoad as Array<Dictionary<String, Any>>!
//                        debugPrint(tempLoad)
//                    }
//                    else
//                    {
//                        return self.loadOriginalPlist()
//                    }
//                }
//                else
//                {
//                    return self.loadOriginalPlist()
//                }
//            }
        }
        
        return Array()
    }
    
//    private func loadOriginalPlist() -> Array<Dictionary<String, Any>>
//    {
//        if let fileUrl = Bundle.main.url(forResource: "past48Hours", withExtension: "plist"),
//            let data = try? Data(contentsOf: fileUrl)
//        {
//            if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]]
//            {
//                return result as Array<Dictionary<String, Any>>!
//            }
//        }
//        return Array()
//    }
    
    //MARK: Listeners
    public func subscribeToListener(listener: AnyObject)
    {
        _listeners.add(listener)
    }
    
    public func unsubscribeFromListener(listener: AnyObject)
    {
        _listeners.remove(listener)
    }
}

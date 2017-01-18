//
//  NeurioComplicationManager.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/14/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation
import WatchConnectivity

class NeurioComplicationManager: NSObject {
    
    public func activateWatchSession() -> Void
    {
        if WCSession.isSupported()
        {
//            session = WCSession.defaultSession()
//            session?.delegate = self
//            session?.activateSession()
        }
    }
}

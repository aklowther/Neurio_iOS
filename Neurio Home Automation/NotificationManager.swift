//
//  NotificationManager.swift
//  Neurio Home Automation
//
//  Created by Adam Lowther on 1/14/17.
//  Copyright © 2017 Adam Lowther. All rights reserved.
//

import Foundation

class NotificationManager : NSObject
{
    public func notifyUserOfExcessEnergyUsage() -> Void
    {
        let energyNotification : Notification = Notification(name: Notification.Name(rawValue: "excessEnergy"), object: nil, userInfo: nil)
        NotificationCenter.default.post(energyNotification)
    }
}

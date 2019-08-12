//
//  SyncManager.swift
//  Umbrella
//
//  Created by Lucas Correa on 27/06/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import Foundation

class SyncManager {
    
    static let shared = SyncManager()
    
    fileprivate lazy var chatClientViewModel: ChatClientViewModel = {
        let chatClientViewModel = ChatClientViewModel()
        return chatClientViewModel
    }()
    
    fileprivate var timer: Timer?
    var syncObject: Sync?
    var invite: [[String: Invite]] = [[String: Invite]]()
    
    init() {
        self.timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(sync), userInfo: nil, repeats: true)
        sync()
    }
    
    @objc func sync() {
        self.chatClientViewModel.sync(success: { (sync) in
            
            guard let sync = sync else {
                return
            }
            
            self.syncObject = (sync as? Sync)!
            self.invite.removeAll()
            
            UserDefaults.standard.set(true, forKey: "SyncHasNewItem")
            UserDefaults.standard.set(0, forKey: "BadgeNumber")
            
            if self.syncObject?.rooms.invite.keys.count ?? 0 > 0 {
                for (key, value) in (SyncManager.shared.syncObject?.rooms.invite)! {
                    self.invite.append([key: value])
                }
                UserDefaults.standard.set(self.syncObject?.rooms.invite.keys.count, forKey: "BadgeNumber")
            }
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name("SyncMatrix"), object: sync)
            
        }, failure: { (response, object, error) in
            print(error ?? "")
        })
    }
    
}
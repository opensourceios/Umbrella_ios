//
//  DeepLinkManager.swift
//  Umbrella
//
//  Created by Lucas Correa on 11/02/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import Foundation
import UIKit

enum DeepLinkType {
    case lesson
    case form
    case feed
    case checklist
    case none
}

let deepLinkManager = DeepLinkManager()
class DeepLinkManager {
    fileprivate init() {
    }
    
    private var resultDeepLink: ResultDeepLink!
    
    @discardableResult
    func handleDeeplink(url: URL) -> Bool {
        resultDeepLink = DeepLinkParser.shared.parseDeepLink(url)
        return resultDeepLink != nil
    }
    
    // check existing deepling and perform action
    func checkDeepLink() {
        guard let resultDeepLink = resultDeepLink else {
            return
        }

        switch resultDeepLink.type {
        case .lesson?:
            let lessonNavigation = LessonNavigation(category: resultDeepLink.category, subCategory: resultDeepLink.subCategory, difficulty: resultDeepLink.difficulty, file: resultDeepLink.file, checklistId: resultDeepLink.checklistId)
            lessonNavigation.goToScreen()
        case .form?:
            let formNavigation = FormNavigation(file: resultDeepLink.file)
            formNavigation.goToScreen()
        case .feed?:
            let feedNavigation = FeedNavigation()
            feedNavigation.goToScreen()
        case .checklist?:
            let checklistNavigation = ChecklistNavigation()
            checklistNavigation.goToScreen()
        default:
            break
        }
        // reset deeplink after handling
        self.resultDeepLink = nil
    }
}

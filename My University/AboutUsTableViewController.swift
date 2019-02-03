//
//  AboutUsTableViewController.swift
//  Schedule
//
//  Created by Yura Voevodin on 15.11.17.
//  Copyright © 2017 Yura Voevodin. All rights reserved.
//

import UIKit

class AboutUsTableViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let bgColorView = UIView()
        bgColorView.backgroundColor = .cellSelectionColor
        cell.selectedBackgroundView = bgColorView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            switch row {
            case 0:
                if let facebookURL = URL(string: "fb://profile/592137607893036"), UIApplication.shared.canOpenURL(facebookURL) {
                    UIApplication.shared.open(facebookURL)
                } else if let facebookPageURL = URL(string: "https://www.facebook.com/Мій-Університет-592137607893036") {
                    UIApplication.shared.open(facebookPageURL)
                }
            case 1:
                if let telegramBotURL = URL(string: "https://telegram.me/sumdu_bot") {
                    UIApplication.shared.open(telegramBotURL)
                }
            default:
                break
            }
            
        } else if section == 1, row == 0 {
            if let appURL = URL(string: "https://itunes.apple.com/ua/app/university-schedule/id1440425058") {
                UIApplication.shared.open(appURL)
            }
            
        } else if section == 2 {
            switch row {
            case 0:
                if let privacyPolicyURL = URL(string: "https://voevodin-yura.com/privacy-policy") {
                    UIApplication.shared.open(privacyPolicyURL)
                }
            case 1:
                if let termsOfServiceURL = URL(string: "https://voevodin-yura.com/terms-of-service") {
                    UIApplication.shared.open(termsOfServiceURL)
                }
            default:
                break
            }
            
        } else if section == 3 {
            if row == 0 {
                // Clear History
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                guard let persistentContainer = appDelegate?.persistentContainer else { return }
                let cell = tableView.cellForRow(at: indexPath)
                
                let context = persistentContainer.viewContext
                AuditoriumEntity.clearHistory(on: context)
                GroupEntity.clearHistory(on: context)
                
                persistentContainer.viewContext.refreshAllObjects()
                
                cell?.isSelected = false
            }
        }
    }
}

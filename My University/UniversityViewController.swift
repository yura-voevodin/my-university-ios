//
//  UniversityViewController.swift
//  My University
//
//  Created by Yura Voevodin on 4/15/19.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//

import UIKit

class UniversityViewController: GenericTableViewController {
    
    struct Row {
        
        let kind: Kind
        
        enum Kind {
            case auditoriums
            case groups
            case teachers
        }
    }
    
    // MARK: - Properties

    var universityID: Int64?
    private var dataSource: UniversityDataSource?

    private var auditoriumsDataSource: AuditoriumDataSource?
    private var groupsDataSource: GroupsDataSource?
    private var teachersDataSource: TeacherDataSource?

    var rows: [Row] = []
    
    // MARK: - Cells
    
    @IBOutlet weak var groupsCell: UITableViewCell!
    @IBOutlet weak var teachersCell: UITableViewCell!
    @IBOutlet weak var auditoriumsCell: UITableViewCell!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch university
        dataSource = UniversityDataSource()
        if let id = universityID {
            dataSource?.fetch(id: id)
        }
        
        configureRows()
        
        // For notifications
        configureNotificationLabel()
        statusButton.customView = notificationLabel
        
        if let university = dataSource?.university {
            // Title
            title = university.shortName

            // Init all data sources
            auditoriumsDataSource = AuditoriumDataSource(universityID: university.id)
            groupsDataSource = GroupsDataSource(universityID: university.id)
            teachersDataSource = TeacherDataSource(universityID: university.id)
            
            // Start from groups,
            // And import auditoriums and teachers
            loadGroups()
        }
    }
    
    // MARK: - Table
    
    private func configureRows() {
        guard let university = dataSource?.university else { return }
        
        if university.isKPI {
            let grops = Row(kind: .groups)
            let teachers = Row(kind: .teachers)
            rows = [grops, teachers]
        } else {
            let grops = Row(kind: .groups)
            let teachers = Row(kind: .teachers)
            let auditoriums = Row(kind: .auditoriums)
            rows = [grops, teachers, auditoriums]
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        
        switch row.kind {
        case .auditoriums:
            performSegue(withIdentifier: "showAuditoriums", sender: nil)
        case .groups:
            performSegue(withIdentifier: "showGroups", sender: nil)
        case .teachers:
            performSegue(withIdentifier: "showTeachers", sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource?.university?.fullName
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
            
        case "showAuditoriums":
            let vc = segue.destination as? AuditoriumsTableViewController
            vc?.universityID = dataSource?.university?.id
            
        case "showGroups":
            let vc = segue.destination as? GroupsTableViewController
            vc?.universityID = dataSource?.university?.id
            
        case "showTeachers":
            let vc = segue.destination as? TeachersTableViewController
            vc?.universityID = dataSource?.university?.id
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        switch row.kind {
            
        case .groups:
            return groupsCell
            
        case .teachers:
            return teachersCell
            
        case .auditoriums:
            return auditoriumsCell
        }
    }
    
    // MARK: - Groups
    
    private func loadGroups() {
        guard let dataSource = groupsDataSource else { return }
        dataSource.performFetch()
        let groups = dataSource.fetchedResultsController?.fetchedObjects ?? []
        
        if groups.isEmpty {
            let text = NSLocalizedString("Loading groups ...", comment: "")
            showNotification(text: text)
            
            dataSource.importGroups { (error) in
                if let error = error {
                    self.showNotification(text: error.localizedDescription)
                } else {
                    self.loadTeachers()
                }
            }
        } else {
            loadTeachers()
        }
    }
    
    // MARK: - Teachers
    
    private func loadTeachers() {
        guard let dataSource = teachersDataSource else { return }
        dataSource.fetchTeachers()
        
        let teachers = dataSource.fetchedResultsController?.fetchedObjects ?? []
        if teachers.isEmpty {
            let text = NSLocalizedString("Loading teachers ...", comment: "")
            showNotification(text: text)
            
            dataSource.importTeachers { (error) in
                if let error = error {
                    self.showNotification(text: error.localizedDescription)
                } else {
                    if self.shouldImportAuditoriums() {
                        self.loadAuditoriums()
                    } else {
                        self.hideNotification()
                    }
                }
            }
        } else {
            if shouldImportAuditoriums() {
                loadAuditoriums()
            } else {
                hideNotification()
            }
        }
    }
    
    // MARK: - Auditoriums
    
    private func shouldImportAuditoriums() -> Bool {
        guard let university = dataSource?.university else { return false }
        if university.isKPI {
            return false
        } else {
            return true
        }
    }
    
    private func loadAuditoriums() {
        guard let dataSource = auditoriumsDataSource else { return }
        dataSource.fetchAuditoriums()
     
        let auditoriums = dataSource.fetchedResultsController?.fetchedObjects ?? []
        if auditoriums.isEmpty {
            let text = NSLocalizedString("Loading auditoriums ...", comment: "")
            showNotification(text: text)
            
            dataSource.importAuditoriums { (error) in
                if let error = error {
                    self.showNotification(text: error.localizedDescription)
                } else {
                    self.hideNotification()
                }
            }
        } else {
            self.hideNotification()
        }
    }
    
    // MARK: - Notificaion
    
    @IBOutlet weak var statusButton: UIBarButtonItem!
}

// MARK: - UIStateRestoring

extension UniversityViewController {

  override func encodeRestorableState(with coder: NSCoder) {
    if let id = universityID {
      coder.encode(id, forKey: "universityID")
    }
    super.encodeRestorableState(with: coder)
  }

  override func decodeRestorableState(with coder: NSCoder) {
    universityID = coder.decodeInt64(forKey: "universityID")
  }
}

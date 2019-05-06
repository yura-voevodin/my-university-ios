//
//  TeacherTableViewController.swift
//  My University
//
//  Created by Yura Voevodin on 2/14/19.
//  Copyright © 2019 Yura Voevodin. All rights reserved.
//

import CoreData
import UIKit

class TeacherTableViewController: GenericTableViewController {
    
    // MARK: - Properties
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter
    }()
    
    private var sectionsTitles: [String] = []
    
    @IBOutlet weak var statusButton: UIBarButtonItem!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let id = teacherID, let context = viewContext {
            teacher = TeacherEntity.fetchTeacher(id: id, context: context)
        }
        
        // For notifications
        configureNotificationLabel()
        statusButton.customView = notificationLabel

        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        
        // Mark teacher as visited
        markTeacherAsVisited()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let teacher = teacher {
            title = teacher.name
            performFetch()

            let records = fetchedResultsController?.fetchedObjects ?? []
            if records.isEmpty {
                // Import records if empty
                importRecords()
            }
        }
    }
    
    // MARK: - Pull to refresh
    
    @IBAction func refresh(_ sender: Any) {
        importRecords()
    }
    
    // MARK: - Share
    
    @IBAction func share(_ sender: Any) {
        guard let teacher = teacher else { return }
        guard let universityURL = teacher.university?.url else { return }
        let url = Settings.shared.baseURL + "/universities/\(universityURL)/teachers/\(teacher.id)"
        if let siteURL = URL(string: url) {
            let sharedItems = [siteURL]
            let vc = UIActivityViewController(activityItems: sharedItems, applicationActivities: nil)
            present(vc, animated: true)
        }
    }
    
    // MARK: - Import Records
    
    private var teacher: TeacherEntity?
    var teacherID: Int64?
    
    private var importManager: Record.ImportForTeacher?
    
    private func importRecords() {
        // Do nothing without CoreData.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let persistentContainer = appDelegate?.persistentContainer else { return }
        
        guard let teacher = teacher else { return }
        guard let university = teacher.university else { return }
        
        let text = NSLocalizedString("Loading records ...", comment: "")
        showNotification(text: text)
        
        // Download records for Teacher from backend and save to database.
        importManager = Record.ImportForTeacher(persistentContainer: persistentContainer, teacher: teacher, university: university)
        DispatchQueue.global().async {
            self.importManager?.importRecords({ (error) in
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.showNotification(text: error.localizedDescription)
                    } else {
                        self.hideNotification()
                    }
                    self.performFetch()
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = fetchedResultsController?.sections?[safe: section]
        return section?.numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailTableCell", for: indexPath)
        
        // Configure the cell
        if let record = fetchedResultsController?.object(at: indexPath) {
            // Title
            cell.textLabel?.text = record.title
            
            // Detail
            cell.detailTextLabel?.text = record.detail
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sectionsTitles.indices.contains(section) {
            return sectionsTitles[section]
        } else {
            return fetchedResultsController?.sections?[safe: section]?.name
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            let backgroundView = UIView()
            backgroundView.backgroundColor = .sectionBackgroundColor
            headerView.backgroundView = backgroundView
            headerView.textLabel?.textColor = UIColor.lightText
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let bgColorView = UIView()
        bgColorView.backgroundColor = .cellSelectionColor
        cell.selectedBackgroundView = bgColorView
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let record = fetchedResultsController?.object(at: indexPath)
        performSegue(withIdentifier: "recordDetailed", sender: record)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "recordDetailed":
            if let destination = segue.destination as? RecordDetailedTableViewController {
                destination.recordID = (sender as? RecordEntity)?.id
            }
            
        default:
            break
        }
    }
    
    // MARK: - NSFetchedResultsController
    
    private lazy var viewContext: NSManagedObjectContext? = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.persistentContainer.viewContext
    }()
    
    private lazy var fetchedResultsController: NSFetchedResultsController<RecordEntity>? = {
        guard let teacher = teacher else { return nil }
        let request: NSFetchRequest<RecordEntity> = RecordEntity.fetchRequest()
        
        let dateString = NSSortDescriptor(key: #keyPath(RecordEntity.dateString), ascending: true)
        let time = NSSortDescriptor(key: #keyPath(RecordEntity.time), ascending: true)
        
        request.sortDescriptors = [dateString, time]
        request.predicate = NSPredicate(format: "teacher == %@", teacher)
        request.fetchBatchSize = 20
        
        if let context = viewContext {
            let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(RecordEntity.dateString), cacheName: nil)
            return controller
        } else {
            return nil
        }
    }()
    
    private func performFetch() {
        do {
            try fetchedResultsController?.performFetch()
            
            // Generate title for sections
            if let controller = fetchedResultsController, let sections = controller.sections {
                var newSectionsTitles: [String] = []
                for section in sections {
                    if let firstObjectInSection = section.objects?.first as? RecordEntity {
                        if let date = firstObjectInSection.date {
                            let dateString = dateFormatter.string(from: date)
                            newSectionsTitles.append(dateString)
                        }
                    }
                }
                sectionsTitles = newSectionsTitles
            }
        } catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    // MARK: - Is visited
    
    private func markTeacherAsVisited() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext?.perform {
            if let teacher = self.teacher {
                teacher.isVisited = true
                appDelegate?.saveContext()
            }
        }
    }
}

// MARK: - UIStateRestoring

extension TeacherTableViewController {

  override func encodeRestorableState(with coder: NSCoder) {
    if let id = teacherID {
      coder.encode(id, forKey: "teacherID")
    }
    super.encodeRestorableState(with: coder)
  }

  override func decodeRestorableState(with coder: NSCoder) {
    teacherID = coder.decodeInt64(forKey: "teacherID")
  }
}
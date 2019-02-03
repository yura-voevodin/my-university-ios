//
//  AuditoriumScheduleTableViewController.swift
//  My University
//
//  Created by Yura Voevodin on 12/8/18.
//  Copyright © 2018 Yura Voevodin. All rights reserved.
//

import CoreData
import UIKit

class AuditoriumScheduleTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter
    }()
    
    private var sectionsTitles: [String] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        // Mark auditorium as visited
        markAuditoriumAsVisited()
      
        showUpdateButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let auditorium = auditorium {
            // Title
            title = auditorium.name
          
            performFetch()
          
            setTitleForUpdateButton()
        }
    }
  
  // MARK: - Update button
  
  private var updateButton: UIBarButtonItem?
  
  @objc func update(_ sender: Any) {
    importRecords()
  }
  
  private func setTitleForUpdateButton() {
    if fetchedResultsController?.fetchedObjects?.isEmpty == true {
      updateButton?.title = NSLocalizedString("Download", comment: "Title for button on the Auditorium screen")
    } else {
      updateButton?.title = NSLocalizedString("Update", comment: "Title for button on the Auditorium screen")
    }
  }
  
  private func showUpdateButton() {
    activiyIndicatior?.removeFromSuperview()
    activiyIndicatior = nil
    
    updateButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: #selector(update(_:)))
    navigationItem.rightBarButtonItem = updateButton
  }
  
  // MARK: - Activity indicatior
  
  private var activiyIndicatior: UIActivityIndicatorView?
  
  private func showActiviyIndicatior() {
    updateButton = nil

    let activiyIndicatior = UIActivityIndicatorView(style: .white)
    activiyIndicatior.color = .orange
    activiyIndicatior.hidesWhenStopped = true
    activiyIndicatior.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activiyIndicatior)
    navigationItem.rightBarButtonItem?.tintColor = .orange
    self.activiyIndicatior = activiyIndicatior
  }
  
  // MARK: - Import Records
    
    var auditorium: AuditoriumEntity?
    var auditoriumID: Int64?
    
    private var importForAuditorium: Record.ImportForAuditorium?
    
    private func importRecords() {
        // Do nothing without CoreData.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let persistentContainer = appDelegate?.persistentContainer else { return }
        
        guard let auditorium = auditorium else { return }
      
        showActiviyIndicatior()
        
        // Download records for Group from backend and save to database.
        importForAuditorium = Record.ImportForAuditorium(persistentContainer: persistentContainer, auditorium: auditorium)
        DispatchQueue.global().async {
            self.importForAuditorium?.importRecords({ (error) in
                
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true)
                    }
                    self.performFetch()
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    self.showUpdateButton()
                    self.setTitleForUpdateButton()
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
    
    // MARK: - NSFetchedResultsController
    
    private lazy var viewContext: NSManagedObjectContext? = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.persistentContainer.viewContext
    }()
    
    private lazy var fetchedResultsController: NSFetchedResultsController<RecordEntity>? = {
        guard let auditorium = auditorium else { return nil }
        let request: NSFetchRequest<RecordEntity> = RecordEntity.fetchRequest()
        
        let dateString = NSSortDescriptor(key: #keyPath(RecordEntity.dateString), ascending: true)
        let time = NSSortDescriptor(key: #keyPath(RecordEntity.time), ascending: true)
        
        request.sortDescriptors = [dateString, time]
        request.predicate = NSPredicate(format: "auditorium == %@", auditorium)
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
    
    private func markAuditoriumAsVisited() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        viewContext?.perform {
            if let auditorium = self.auditorium {
                auditorium.isVisited = true
                appDelegate?.saveContext()
            }
        }
    }
}

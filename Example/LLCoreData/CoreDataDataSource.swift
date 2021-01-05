//
//  CoreDataDataSource.swift
//  LLCoreData_Example
//
//  Created by ZHK on 2021/1/5.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import CoreData
import LLCoreData

protocol CoreDataDataSourceDelegate: class {
    
    func tableView<T>(tableView: UITableView, configCells indexPath: IndexPath, data: T) -> UITableViewCell
}

class CoreDataDataSource<T: Managed, NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate, UITableViewDataSource {

    private let tableView: UITableView
    
    private let context: NSManagedObjectContext = LLCoreData.context
    
    private var fetchController: NSFetchedResultsController<T>?
    
    public weak var delegate: CoreDataDataSourceDelegate?
    
    
    init(tableView: UITableView) {
        self.tableView = tableView
        
        super.init()
        
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.sortDescriptors = T.sortDescriptors
        request.fetchLimit = 20
        fetchController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "cache")
        fetchController?.delegate = self;
        do {
            try fetchController?.performFetch()
        } catch let error {
            print(error)
        }
    }
    
    public func object(at indexPath: IndexPath) -> T? {
        fetchController?.object(at: indexPath)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controller(_ controller: NSFetchedResultsController<CoreData.NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .left)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        default: break
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<CoreData.NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<CoreData.NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: UITableView dataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchController?.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = delegate?.tableView(tableView: tableView, configCells: indexPath, data: fetchController?.object(at: indexPath)) else {
            fatalError("")
        }
        return cell
    }
}

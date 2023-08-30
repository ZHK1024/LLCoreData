//
//  ViewController.swift
//  LLCoreData
//
//  Created by Ruris on 01/05/2021.
//  Copyright (c) 2021 Ruris. All rights reserved.
//

import UIKit
import LLCoreData
import CoreData

extension Continent: Managed {
    
    public static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(key: "updatedAt", ascending: false)]
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private lazy var dataSource = CoreDataDataSource<Continent, Continent>(tableView: tableView)

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.delegate = self
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // add async item
        let switchView = UISwitch()
        switchView.isOn = UserDefaults.standard.bool(forKey: "sync")
        switchView.addTarget(self, action: #selector(asyncAction(switchView:)), for: .valueChanged)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: switchView)
    }

    func deleteItem(indexPath: IndexPath) {
        guard let item = dataSource.object(at: indexPath) else {
            return
        }
        LLCoreData.context.delete(item)
        LLCoreData.saveOrRollback()
    }
    
    func top(indexPath: IndexPath) {
        guard let item = dataSource.object(at: indexPath) else {
            return
        }
        item.updatedAt = Date()
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = ""
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [unowned alert] _ in
            guard let name = alert.textFields?.first?.text else { return }
            
            let context = LLCoreData.context
            let continent = Continent(context: context)
            continent.name = name
            continent.countries = []
            context.saveOrRollback()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func asyncAction(switchView: UISwitch) {
        UserDefaults.standard.set(switchView.isOn, forKey: "sync")
        UserDefaults.standard.synchronize()
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let continent = dataSource.object(at: indexPath) else {
            return
        }
        let alert = UIAlertController(title: "", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = ""
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { [unowned alert] _ in
            guard let name = alert.textFields?.first?.text else { return }
            
            let context = LLCoreData.context
            let country = Country(context: context)
            country.name = name
            country.continent = continent
            continent.countries?.adding(country)
            print(context.saveOrRollback())
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let top = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, _) in
            self?.top(indexPath: indexPath)
        }
        if #available(iOS 13.0, *) {
            top.image = UIImage(systemName: "arrow.up")
        } else {
            // Fallback on earlier versions
        }
        top.backgroundColor = .systemYellow
        
        let delete = UIContextualAction(style: .destructive, title: nil, handler: { [weak self] (_, _, _) in
            self?.deleteItem(indexPath: indexPath)
        })
        if #available(iOS 13.0, *) {
            delete.image = UIImage(systemName: "trash")
        } else {
            // Fallback on earlier versions
        }
        
        return UISwipeActionsConfiguration(actions: [delete, top])
    }
}

extension ViewController: CoreDataDataSourceDelegate {
    
    func tableView<T>(tableView: UITableView, configCells indexPath: IndexPath, data: T) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let model = data as? Continent {
            cell.textLabel?.text = model.name

            cell.detailTextLabel?.text =
            model.countries?.allObjects.compactMap({ (c) -> String? in
                guard let country = c as? Country else { return nil }
                return country.name
            }).joined(separator: ",")
        }
        return cell
    }
}

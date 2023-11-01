//
//  ToDoTVC.swift
//  CoreDataApp
//
//  Created by Sofa on 25.10.23.
//

import UIKit
import CoreData

class ToDoTVC: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var selectedCategory: CategoryModel? {
        didSet {
            self.title = selectedCategory?.name
            getData()
        }
    }
    var items = [ItemModel]()

    
    @IBAction func addNewItem(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add new item", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Add new task"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let texField = alert.textFields?.first,
               let text = texField.text,
               text != "",
               let self {
                let newItem = ItemModel(context: self.context)
                newItem.title = text
                newItem.done = false
                newItem.parentCategory = self.selectedCategory
                
                self.items.append(newItem)
                self.saveItems()
                self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: .automatic)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(addAction)
        
        self.present(alert, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        return cell
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if let categoryName = selectedCategory?.name, let itemName = items[indexPath.row].title {
                
                let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
                
                let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", categoryName)
                let itemPredicate = NSPredicate(format: "title MATCHES %@", itemName)
                
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, itemPredicate])
                        
                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    items.remove(at: indexPath.row)
                    saveItems()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].done.toggle()
        self.saveItems()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    // MARK: - Core Data

    private func getData() {
        loadItems()
    }
    
    func loadItems(with request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest(),
                           predicate: NSPredicate? = nil) {
        
        guard let name = selectedCategory?.name else { return }
            
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
            
        if let predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        } else {
            request.predicate = categoryPredicate
        }
            
        do {
            items = try context.fetch(request)
        } catch {
            print("Error fetch context")
        }
        tableView.reloadData()
    }
    
    private func saveItems() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

}

//
//  CategoryTableViewController.swift
//  OrderApp
//
//  Created by Xcho on 03.02.22.
//

import UIKit

@MainActor
class CategoryTableViewController: UITableViewController {

    var categories = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            do {
                let categories = try await MenuController.shared.fetchCategories()
                updateUI(with: categories)
            } catch {
                displayError(error, title: "Failed to Fetch Categories")
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, forCategoryAt indexpath: IndexPath) {
        let category = categories[indexpath.row]

        var content = cell.defaultContentConfiguration()
        content.text = category.capitalized
        cell.contentConfiguration = content
    }

    func updateUI(with categories: [String]) {
        self.categories = categories
        self.tableView.reloadData()
    }

    func displayError(_ error: Error, title: String) {
        if viewIfLoaded?.window != nil {
            let alert = UIAlertController(
                title: title,
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Dissmiss", style: .default))
            self.present(alert, animated: true)
        }
    }

    @IBSegueAction func showMenu(_ coder: NSCoder, sender: Any?) -> MenuTableViewController? {
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell)
        else { return nil }

        let category = categories[indexPath.row]
        return MenuTableViewController(coder: coder, category: category)
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int { categories.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Category", for: indexPath)
        configureCell(cell, forCategoryAt: indexPath)

        return cell
    }
}

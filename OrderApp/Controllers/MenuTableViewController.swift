//
//  MenuTableViewController.swift
//  OrderApp
//
//  Created by Xcho on 03.02.22.
//

import UIKit

@MainActor
class MenuTableViewController: UITableViewController {

    let category: String
    var menuItems = [MenuItem]()

    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    init?(coder: NSCoder, category: String) {
        self.category = category
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = category.capitalized

        Task {
            do {
                let menuItems = try await MenuController.shared.fetchMenuItems(forCategory: category)
                updateUI(with: menuItems)
            } catch {
                displayError(error, title: "Failed to Fetch Menu Items")
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        imageLoadTasks.forEach {_, task in task.cancel() }
    }

    func updateUI(with menuItems: [MenuItem]) {
        self.menuItems = menuItems
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

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? MenuItemCell else { return }

        let menuItem = menuItems[indexPath.row]

        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil

        imageLoadTasks[indexPath] = Task {
            if let image = try? await
                MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell),
                   currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }

    @IBSegueAction func sowMenuItem(_ coder: NSCoder, sender: Any?) -> MenuItemDetailViewController? {
        guard let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell)
        else { return nil }

        let menuItem = menuItems[indexPath.row]
        return MenuItemDetailViewController(coder: coder, menuItem: menuItem)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int { menuItems.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItem", for: indexPath)
        configure(cell, forItemAt: indexPath)

        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath) {
        imageLoadTasks[indexPath]?.cancel()
    }

}

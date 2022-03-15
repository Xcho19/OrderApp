//
//  OrderTableViewController.swift
//  OrderApp
//
//  Created by Xcho on 03.02.22.
//

import UIKit

class OrderTableViewController: UITableViewController {

    var minutesToPrepareOrder = 0

    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem

        NotificationCenter.default.addObserver(
            tableView!,
            selector: #selector(UITableView.reloadData),
            name: MenuController.orderUpdateNotification,
            object: nil
        )
    }

    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }

        Task {
            do {
                let minutesToPrepare = try await MenuController.shared.submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minutesToPrepare
                performSegue(withIdentifier: "confirmOrder", sender: nil)
            } catch {
                displayError(error, title: "Order Submission Failed")
            }
        }
    }

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? MenuItemCell else { return }

        let menuItem = MenuController.shared.order.menuItems[indexPath.row]

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

    @IBSegueAction func confirmOrder(_ coder: NSCoder) -> OrderConfirmationViewController? {
        OrderConfirmationViewController(coder: coder, minutesToPrepare: minutesToPrepareOrder)

    }

    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        if segue.identifier == "dismissConfirmation" {
            MenuController.shared.order.menuItems.removeAll()
        }
    }

    @IBAction func submitTapped(_ sender: Any) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(0.0) { (result, menuItem) -> Double in
            result + menuItem.price
        }

        let formattedTotal = orderTotal.formatted(.currency(code: "usd"))

        let alertController = UIAlertController(
            title: "Confirm Order",
            message: "You are about to submit your order with total of \(formattedTotal)",
            preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(
            title: "Submit",
            style: .default
        ) { _ in
            self.uploadOrder()
        }
        )

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true)
    }

    // MARK: table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int { MenuController.shared.order.menuItems.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order", for: indexPath)
        configure(cell, forItemAt: indexPath)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath)
        -> Bool { true }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                MenuController.shared.order.menuItems.remove(at: indexPath.row)
            }
        }
}

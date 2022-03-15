//
//  MenuController.swift
//  OrderApp
//
//  Created by Xcho on 07.02.22.
//

import Foundation
import UIKit

class MenuController {

    let baseURL = URL(string: "http://localhost:8080/")!

    static let shared = MenuController()
    static let orderUpdateNotification = Notification.Name("MenuController.orderUpdate")

    typealias MinutesToPrepare = Int

    var order = Order() { didSet {
        NotificationCenter.default.post(
            name: MenuController.orderUpdateNotification,
            object: nil
        )
    }}

    enum MenuControllerError: Error, LocalizedError {
        case categoriesNotFound
        case menuItemsNotFound
        case orderRequestFailed
        case imageDataMissing
    }

    func fetchCategories() async throws -> [String] {
        let categoriesUrl = baseURL.appendingPathComponent("categories")
        let (data, response) = try await URLSession.shared.data(from: categoriesUrl)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else { throw MenuControllerError.categoriesNotFound }

        let decoder = JSONDecoder()
        let categoriesResponse = try decoder.decode(CategoriesResponse.self, from: data)

        return categoriesResponse.categories
    }

    func fetchMenuItems(forCategory categoryName: String) async throws -> [MenuItem] {
        let initialMenuURL = baseURL.appendingPathComponent("menu")
        var components = URLComponents(url: initialMenuURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "category", value: categoryName)]
        guard let menuURL = components.url else { fatalError() }
        let (data, response) = try await URLSession.shared.data(from: menuURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else { throw MenuControllerError.menuItemsNotFound }

        let decoder = JSONDecoder()
        let menuResponse = try decoder.decode(MenuResponse.self, from: data)

        return menuResponse.items
    }

    func submitOrder(forMenuIDs menuIDs: [Int]) async throws -> MinutesToPrepare {
        let orderURL = baseURL.appendingPathComponent("order")

        var request = URLRequest(url: orderURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let menuIdsDict = ["menuIds": menuIDs]
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(menuIdsDict)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else { throw MenuControllerError.orderRequestFailed }

        let decoder = JSONDecoder()
        let orderResponse = try decoder.decode(OrderResponse.self, from: data)

        return orderResponse.prepTime
    }

    func fetchImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else { throw MenuControllerError.imageDataMissing }

        guard let image = UIImage(data: data)
        else { throw MenuControllerError.imageDataMissing }

        return image
    }
}

//
//  URLRequest.swift
//  EmployeesAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 10/4/25.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}


/// An extension of `URLRequest` to simplify the creation of HTTP requests with common configurations.
extension URLRequest {
    
    /// Creates a GET request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a GET operation.
    public static func get(
        _ url: URL,
        authorizedHeader: [String: String] = [:]
    ) -> URLRequest {
        return .buildRequest(from: .get, with: url, and: authorizedHeader)
    }
    
    /// Creates a DELETE request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a DELETE operation.
    public static func delete(
        _ url: URL,
        authorizedHeader: [String: String] = [:]
    ) -> URLRequest {
        return .buildRequest(from: .delete, with: url, and: authorizedHeader)
    }
    
    /// Creates a POST or custom HTTP request with a JSON-encoded body.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - body: The JSON-encodable body to include in the request.
    ///   - method: The HTTP method to use. Defaults to `.post`.
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for the specified HTTP method with a JSON-encoded body.
    /// - Note: Sets the "Content-Type" header to `application/json; charset=utf-8`.
    public static func post<JSON>(
        url: URL,
        body: JSON,
        method: HTTPMethod = .post,
        authorizedHeader: [String: String] = [:]
    ) -> URLRequest where JSON: Encodable {
        var request: URLRequest = .buildRequest(from: method, with: url, and: authorizedHeader)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }
    
    /// A private helper method to build a general HTTP request with the specified method, URL, and headers.
    /// - Parameters:
    ///   - method: The HTTP method to use (e.g., `.get`, `.post`, `.delete`).
    ///   - url: The `URL` for the request.
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` object.
    private static func buildRequest(
        from method: HTTPMethod,
        with url: URL,
        and authorizedHeader: [String: String] = [:]
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in authorizedHeader {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

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

/// An actor that manages global authentication middleware in a concurrency-safe manner
public actor AuthMiddlewareManager {
    public static let shared = AuthMiddlewareManager()
    
    private var middleware = AuthMiddleware()
    
    public func configure(middleware: AuthMiddleware) {
        self.middleware = middleware
    }
    
    public func authenticate(_ request: URLRequest) -> URLRequest {
        return middleware.authenticate(request)
    }
}

/// An extension of `URLRequest` to simplify the creation of HTTP requests with common configurations and with support for automatic authentication
extension URLRequest {
    
    /// Configura el middleware de autenticación global
    /// - Parameter middleware: El middleware a utilizar
    static func configureAuth(middleware: AuthMiddleware) async {
        await AuthMiddlewareManager.shared.configure(middleware: middleware)
    }
    
    /// Creates a GET request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - skipAuth: Whether to bypass automatic authentication
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a GET operation.
    public static func get(
        _ url: URL,
        skipAuth: Bool = false,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest {
        let request = buildRequest(from: .get, with: url, and: authorizedHeader)
        return skipAuth ? request : await AuthMiddlewareManager.shared.authenticate(request)
    }
    
    /// Creates a DELETE request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - skipAuth: Whether to bypass automatic authentication
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a DELETE operation.
    public static func delete(
        _ url: URL,
        skipAuth: Bool = false,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest {
        let request = buildRequest(from: .get, with: url, and: authorizedHeader)
        return skipAuth ? request : await AuthMiddlewareManager.shared.authenticate(request)
    }
    
    /// Creates a POST or custom HTTP request with a JSON-encoded body.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - body: The JSON-encodable body to include in the request.
    ///   - method: The HTTP method to use. Defaults to `.post`.
    ///   - skipAuth: Whether to bypass automatic authentication
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for the specified HTTP method with a JSON-encoded body.
    /// - Note: Sets the "Content-Type" header to `application/json; charset=utf-8`.
    public static func post<JSON>(
        url: URL,
        body: JSON,
        method: HTTPMethod = .post,
        skipAuth: Bool = false,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest where JSON: Encodable {
        var request: URLRequest = .buildRequest(from: method, with: url, and: authorizedHeader)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        return skipAuth ? request : await AuthMiddlewareManager.shared.authenticate(request)
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

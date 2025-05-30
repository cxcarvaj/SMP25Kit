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
    
    /// Método de autenticación global por defecto
    private var defaultAuthMethod: AuthMethod = .bearer(tokenType: nil)
    
    /// Gestor de credenciales
    private let credentialManager = AuthCredentialManager()
    
    /// Configura el método de autenticación global por defecto
    /// - Parameter method: Método a usar como predeterminado
    public func setDefaultAuthMethod(_ method: AuthMethod) {
        defaultAuthMethod = method
    }
    
    /// Aplica autenticación a una solicitud
    /// - Parameters:
    ///   - request: Solicitud original
    ///   - method: Método específico a usar (o nil para usar el predeterminado)
    /// - Returns: Solicitud con autenticación
    public func authenticate(_ request: URLRequest, using method: AuthMethod? = nil) -> URLRequest {
        var authenticatedRequest = request
        let authMethod = method ?? defaultAuthMethod
        
        // Si ya tiene un header de autorización y el método lo usaría, respetarlo
        if authMethod.usesAuthorizationHeader && authenticatedRequest.value(forHTTPHeaderField: "Authorization") != nil {
            return authenticatedRequest
        }
        
        // Obtener y aplicar el header de autenticación
        if let (headerName, headerValue) = credentialManager.getAuthHeader(for: authMethod) {
            authenticatedRequest.setValue(headerValue, forHTTPHeaderField: headerName)
        }
        
        return authenticatedRequest
    }
    
    /// Guarda credenciales para un método específico
    /// - Parameters:
    ///   - method: Método de autenticación
    ///   - credentials: Valor de las credenciales
    public func saveCredentials(for method: AuthMethod, credentials: String) {
        credentialManager.saveCredentials(for: method, credentials: credentials)
    }
    
    /// Guarda credenciales para autenticación básica
    /// - Parameters:
    ///   - username: Nombre de usuario
    ///   - password: Contraseña
    public func saveBasicAuth(username: String, password: String) {
        credentialManager.saveCredentials(for: .basic(username: nil, password: nil),
                                       credentials: "\(username):\(password)")
    }
    
    /// Guarda un token Bearer
    /// - Parameters:
    ///   - token: Token a guardar
    ///   - tokenType: Tipo de token (JWT o normal)
    public func saveToken(_ token: String, tokenType: GlobalIDs = .tokenID) {
        credentialManager.saveCredentials(for: .bearer(tokenType: tokenType), credentials: token)
    }
    
    /// Guarda una API Key
    /// - Parameter apiKey: API Key a guardar
    public func saveApiKey(_ apiKey: String) {
        credentialManager.saveCredentials(for: .apiKey(key: nil, headerName: "X-API-Key"),
                                       credentials: apiKey)
    }
    
    /// Borra todas las credenciales
    public func clearAllCredentials() {
        credentialManager.clearAllCredentials()
    }
}

/// An extension of `URLRequest` to simplify the creation of HTTP requests with common configurations and with support for automatic authentication
extension URLRequest {
    
    /// Configura el método de autenticación global predeterminado
    /// - Parameter method: Método a usar como predeterminado
    public static func setDefaultAuthMethod(_ method: AuthMethod) async {
        await AuthMiddlewareManager.shared.setDefaultAuthMethod(method)
    }
    
    /// Creates a GET request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - authMethod: Método específico de autenticación (o nil para usar el predeterminado)
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a GET operation.
    public static func get(
        _ url: URL,
        authMethod: AuthMethod? = nil,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest {
        let request = buildRequest(from: .get, with: url, and: authorizedHeader)
        return authorizedHeader["Authorization"] != nil ? request : await AuthMiddlewareManager.shared.authenticate(request, using: authMethod)
    }
    
    /// Creates a DELETE request for the specified URL with optional authorized headers.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - authMethod: Método específico de autenticación (o nil para usar el predeterminado)
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for a DELETE operation.
    public static func delete(
        _ url: URL,
        authMethod: AuthMethod? = nil,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest {
        let request = buildRequest(from: .get, with: url, and: authorizedHeader)
        return authorizedHeader["Authorization"] != nil ? request : await AuthMiddlewareManager.shared.authenticate(request, using: authMethod)
    }
    
    /// Creates a POST or custom HTTP request with a JSON-encoded body.
    /// - Parameters:
    ///   - url: The `URL` for the request.
    ///   - body: The JSON-encodable body to include in the request.
    ///   - encoder: The JSONEncoder to convert Swift data (such as structs or classes) to JSON format
    ///   - method: The HTTP method to use. Defaults to `.post`.
    ///   - authMethod: Método específico de autenticación (o nil para usar el predeterminado)
    ///   - authorizedHeader: A dictionary containing authorization headers. Defaults to an empty dictionary.
    /// - Returns: A configured `URLRequest` for the specified HTTP method with a JSON-encoded body.
    /// - Note: Sets the "Content-Type" header to `application/json; charset=utf-8`.
    public static func post<JSON>(
        url: URL,
        body: JSON,
        encoder: JSONEncoder = JSONEncoder(),
        method: HTTPMethod = .post,
        authMethod: AuthMethod? = nil,
        authorizedHeader: [String: String] = [:]
    ) async -> URLRequest where JSON: Encodable {
        var request: URLRequest = .buildRequest(from: method, with: url, and: authorizedHeader)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(body)
        return authorizedHeader["Authorization"] != nil ? request : await AuthMiddlewareManager.shared.authenticate(request, using: authMethod)
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

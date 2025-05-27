//
//  GlobalIDs.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Foundation

/// Define los diferentes métodos de autenticación soportados
public enum AuthMethod: Sendable {
    /// Sin autenticación
    case none
    
    /// Autenticación con token Bearer (OAuth 2.0, JWT)
    /// - Parameter tokenType: Tipo de token a usar (.tokenID o .tokedJWT)
    case bearer(tokenType: GlobalIDs?)
    
    /// Autenticación con token Bearer (OAuth 2.0, JWT)
    /// - Parameter token: Token string a usar
    case bearerToken(token: String)
    
    /// Autenticación Basic con usuario y contraseña
    /// - Parameters:
    ///   - username: Nombre de usuario
    ///   - password: Contraseña
    case basic(username: String?, password: String?)
    
    /// Autenticación por API Key
    /// - Parameters:
    ///   - key: Valor de la API key
    ///   - headerName: Nombre del header (por defecto "X-API-Key")
    case apiKey(key: String?, headerName: String)
    
    /// Autenticación Digest
    case digest(username: String?, password: String?)
    
    /// Autenticación personalizada
    /// - Parameter headerValue: Valor completo del header Authorization
    case custom(headerValue: String)
    
    /// Método para determinar si este método usa el header Authorization
    public var usesAuthorizationHeader: Bool {
        switch self {
        case .none, .apiKey:
            return false
        case .bearer, .bearerToken ,.basic, .digest, .custom:
            return true
        }
    }
}

/// Define las claves para almacenar tokens y credenciales
public enum GlobalIDs: String, Sendable {
    case tokenID = "OAUTH_TOKEN"
    case tokedJWT = "JWT_TOKEN"
    case basicAuth = "BASIC_AUTH"
    case digestAuth = "DIGEST_AUTH"
    case apiKey = "API_KEY"
    case appleSIWA = "APPLE_SIWA"
}

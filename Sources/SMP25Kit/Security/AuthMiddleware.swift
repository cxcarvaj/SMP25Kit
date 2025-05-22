//
//  AuthMiddleware.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Foundation

/// Middleware que intercepta y añade tokens de autenticación a las solicitudes HTTP
public struct AuthMiddleware: Sendable {
    private let tokenManager: TokenManager
    
    /// Crea un middleware con un gestor de tokens personalizado
    /// - Parameter tokenManager: El gestor de tokens a utilizar
    public init(tokenManager: TokenManager = TokenManager()) {
        self.tokenManager = tokenManager
    }
    
    /// Aplica el token de autenticación a una solicitud HTTP si existe
    /// - Parameter request: La solicitud original
    /// - Returns: La solicitud con el token añadido si existe
    public func authenticate(_ request: URLRequest) -> URLRequest {
        var authenticatedRequest = request
        
        // Solo añadimos el token si no hay ya un header de autenticación
        if authenticatedRequest.value(forHTTPHeaderField: "Authorization") == nil,
           let token = tokenManager.getFormattedToken() {
            authenticatedRequest.setValue(token, forHTTPHeaderField: "Authorization")
        }
        
        return authenticatedRequest
    }
}

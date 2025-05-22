//
//  TokenManager.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Foundation

/// Gestiona el almacenamiento seguro y acceso a tokens de autenticación usando Keychain
public struct TokenManager: Sendable {
    private enum TokenType: String {
        case bearer = "bearer"
        case basic = "basic"
        // Añadir otros tipos según sea necesario
    }
    
    private let tokenKey = "auth.api.token"
    private let tokenTypeKey = "auth.api.token.type"
    
    public init() {}
    
    private let keyStore = SecKeyStore.shared
    
    /// Guarda un token con su tipo en el llavero
    /// - Parameters:
    ///   - token: El token a guardar
    ///   - type: El tipo de token (por defecto "bearer")
    public func saveToken(_ token: String, type: String = "bearer") {
        if let tokenData = token.data(using: .utf8) {
            keyStore.storeValue(tokenData, withLabel: tokenKey)
        }
        
        if let typeData = type.data(using: .utf8) {
            keyStore.storeValue(typeData, withLabel: tokenTypeKey)
        }
    }
    
    /// Obtiene el token actual con su formato completo (ej: "Bearer xyz123")
    /// - Returns: Token formateado o nil si no existe
    public func getFormattedToken() -> String? {
        guard let tokenData = keyStore.readValue(withLabel: tokenKey),
              let token = String(data: tokenData, encoding: .utf8),
              let typeData = keyStore.readValue(withLabel: tokenTypeKey),
              let typeString = String(data: typeData, encoding: .utf8),
              let type = TokenType(rawValue: typeString.lowercased()) else {
            return nil
        }
        
        switch type {
        case .bearer:
            return "Bearer \(token)"
        case .basic:
            return "Basic \(token)"
        }
    }
    
    /// Elimina el token actual
    public func clearToken() {
        keyStore.deleteValue(withLabel: tokenKey)
        keyStore.deleteValue(withLabel: tokenTypeKey)
    }
    
    /// Verifica si existe un token guardado
    public var hasToken: Bool {
        keyStore.readValue(withLabel: tokenKey) != nil
    }
}

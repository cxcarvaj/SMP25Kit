//
//  AuthCredentialManager.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Foundation

/// Gestor de credenciales para diferentes métodos de autenticación
public struct AuthCredentialManager: Sendable {
    private let keyStore = SecKeyStore.shared
    
    public init() {}
    
    /// Obtiene el header completo para un método de autenticación
    /// - Parameter method: Método de autenticación a utilizar
    /// - Returns: Tupla con (headerName, headerValue) o nil si no hay credenciales disponibles
    public func getAuthHeader(for method: AuthMethod) -> (name: String, value: String)? {
        switch method {
        case .none:
            return nil
            
        case .bearer(let tokenType):
            // Determinar qué token usar (explícito o buscar automáticamente)
            let tokenId = tokenType ?? .tokenID
            
            // Intentar JWT si no se especificó un tipo concreto
            if tokenType == nil && tokenId == .tokenID {
                if let jwtToken = getToken(for: .tokedJWT) {
                    return ("Authorization", "Bearer \(jwtToken)")
                }
            }
            
            // Obtener el token del tipo solicitado
            if let token = getToken(for: tokenId) {
                return ("Authorization", "Bearer \(token)")
            }
        
        case .bearerToken(token: let token):
            return ("Authorization", "Bearer \(token)")
            
        case .basic(let username, let password):
            // Si se proporcionan username/password explícitos, usarlos
            if let username = username, let password = password {
                let credentials = "\(username):\(password)"
                let base64Credentials = Data(credentials.utf8).base64EncodedString()
                return ("Authorization", "Basic \(base64Credentials)")
            }
            
            // Si no, buscar en el keystore
            if let credentialsData = keyStore.readValue(withLabel: GlobalIDs.basicAuth.rawValue),
               let credentials = String(data: credentialsData, encoding: .utf8) {
                let parts = credentials.split(separator: ":").map(String.init)
                if parts.count == 2 {
                    let base64Credentials = Data("\(parts[0]):\(parts[1])".utf8).base64EncodedString()
                    return ("Authorization", "Basic \(base64Credentials)")
                }
            }
            
        case .apiKey(let key, let headerName):
            // Si se proporciona una key explícita, usarla
            if let key = key {
                return (headerName, key)
            }
            
            // Si no, buscar en el keystore
            if let keyData = keyStore.readValue(withLabel: GlobalIDs.apiKey.rawValue),
               let apiKey = String(data: keyData, encoding: .utf8) {
                return (headerName, apiKey)
            }
            
        case .digest(let username, let password):
            // Implementación básica de Digest Auth
            // En una aplicación real, necesitarías manejar nonce, etc.
            if let username = username, let password = password {
                // Digest Auth necesitaría una implementación más compleja con challenge response
                // Esto es un placeholder simplificado
                return ("Authorization", "Digest username=\"\(username)\", realm=\"example\"")
            }
            
            // Buscar en keystore (simplificado)
            if let digestData = keyStore.readValue(withLabel: GlobalIDs.digestAuth.rawValue),
               let digestCreds = String(data: digestData, encoding: .utf8) {
                return ("Authorization", digestCreds)
            }
            
        case .custom(let headerValue):
            return ("Authorization", headerValue)
        }
        
        return nil
    }
    
    /// Guarda credenciales para un método de autenticación específico
    /// - Parameters:
    ///   - method: Método de autenticación
    ///   - credentials: Credenciales a guardar
    public func saveCredentials(for method: AuthMethod, credentials: String) {
        guard let data = credentials.data(using: .utf8) else { return }
        
        switch method {
        case .bearer(let tokenType):
            let key = tokenType?.rawValue ?? GlobalIDs.tokenID.rawValue
            keyStore.storeValue(data, withLabel: key)
        
        case .bearerToken(let token):
            guard let data = token.data(using: .utf8) else { return }
            keyStore.storeValue(data, withLabel: GlobalIDs.appleSIWA.rawValue)
            
        case .basic:
            keyStore.storeValue(data, withLabel: GlobalIDs.basicAuth.rawValue)
            
        case .apiKey:
            keyStore.storeValue(data, withLabel: GlobalIDs.apiKey.rawValue)
            
        case .digest:
            keyStore.storeValue(data, withLabel: GlobalIDs.digestAuth.rawValue)
            
        case .none, .custom:
            break // No almacenar
        }
    }
    
    /// Borra credenciales para un método específico
    /// - Parameter method: Método cuyas credenciales se borrarán
    public func clearCredentials(for method: AuthMethod) {
        switch method {
        case .bearer(let tokenType):
            if let type = tokenType {
                keyStore.deleteValue(withLabel: type.rawValue)
            } else {
                keyStore.deleteValue(withLabel: GlobalIDs.tokenID.rawValue)
                keyStore.deleteValue(withLabel: GlobalIDs.tokedJWT.rawValue)
            }
        case .bearerToken(let token):
            keyStore.deleteValue(withLabel: GlobalIDs.appleSIWA.rawValue)
            
        case .basic:
            keyStore.deleteValue(withLabel: GlobalIDs.basicAuth.rawValue)
            
        case .apiKey:
            keyStore.deleteValue(withLabel: GlobalIDs.apiKey.rawValue)
            
        case .digest:
            keyStore.deleteValue(withLabel: GlobalIDs.digestAuth.rawValue)
            
        case .none, .custom:
            break // No hacer nada
        }
    }
    
    /// Valida y almacena un JWT recibido del backend.
    /// - Parameters:
    ///   - jwt: El token JWT recibido.
    ///   - issuer: El issuer esperado.
    ///   - key: Clave simétrica HS256 con la que validar el JWT.
    /// - Throws: NetworkError en caso de error de validación.
    /// - Returns: true si se validó y almacenó correctamente.
    public func validateAndStoreJWT(
        jwt: String,
        issuer: String,
        key: Data
    ) throws(NetworkError) -> Bool {
        // 1. Validar el JWT
        let validator = ValidateJWT()
        let valid = try validator.JWTValidation(jwt: jwt, issuer: issuer, key: key)
        guard valid else {
            throw .security("JWT inválido o expirado")
        }
        // 2. Almacenar en Keychain
        guard let data = jwt.data(using: .utf8) else {
            throw .security("No se pudo convertir el JWT a datos")
        }
        keyStore.storeValue(data, withLabel: GlobalIDs.tokedJWT.rawValue)
        return true
    }
    
    /// Borra todas las credenciales almacenadas
    public func clearAllCredentials() {
        keyStore.deleteValue(withLabel: GlobalIDs.tokenID.rawValue)
        keyStore.deleteValue(withLabel: GlobalIDs.tokedJWT.rawValue)
        keyStore.deleteValue(withLabel: GlobalIDs.basicAuth.rawValue)
        keyStore.deleteValue(withLabel: GlobalIDs.apiKey.rawValue)
        keyStore.deleteValue(withLabel: GlobalIDs.digestAuth.rawValue)
        keyStore.deleteValue(withLabel: GlobalIDs.appleSIWA.rawValue)
    }
    
    // Método de ayuda para obtener un token
    private func getToken(for tokenType: GlobalIDs) -> String? {
        guard let tokenData = keyStore.readValue(withLabel: tokenType.rawValue),
              let token = String(data: tokenData, encoding: .utf8) else {
            return nil
        }
        return token
    }
}

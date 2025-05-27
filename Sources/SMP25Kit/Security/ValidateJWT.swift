//
//  ValidateJWT.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 26/5/25.
//

import Foundation
import CryptoKit

public struct JWTBody: Codable {
    public let exp: Double
    public let iss: String
    public let sub: String
    public let aud: String
}

public struct JWTHeader: Codable {
    public let alg: String
    public let typ: String
}

public final class ValidateJWT: Sendable {
    public init() {}
    
    // Corrige el relleno base64 para el último fragmento del JWT (firma)
    func base64Padding(jwt: String) -> String {
        var encoded = jwt
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let count = encoded.count % 4
        if count > 0 {
            encoded += String(repeating: "=", count: 4 - count)
        }
        return encoded
    }
    
    // Comprueba si el token está expirado
    func isTokenExpired(exp: Double) -> Bool {
        let expirationTime = TimeInterval(exp)
        let expirationDate = Date(timeIntervalSince1970: expirationTime)
        return Date() >= expirationDate
    }
    
    /// Valida un JWT HS256: firma, issuer y expiración
    /// - Parameters:
    ///   - jwt: El token JWT, en formato estándar (header.payload.signature)
    ///   - issuer: El issuer que esperas (ejemplo: "TaskeandoAPI")
    ///   - key: Clave secreta HS256
    /// - Throws: NetworkError si hay fallo de seguridad
    /// - Returns: true si el JWT es válido y vigente
    public func JWTValidation(jwt: String, issuer: String, key: Data) throws(NetworkError) -> Bool {
        let simmetricKey = SymmetricKey(data: key)

        let jwtParts = jwt.components(separatedBy: ".")
        guard jwtParts.count == 3,
              let headerData = Data(base64Encoded: base64Padding(jwt: jwtParts[0])),
              let bodyData = Data(base64Encoded: base64Padding(jwt: jwtParts[1])),
              let signatureData = Data(base64Encoded: base64Padding(jwt: jwtParts[2])) else {
            throw NetworkError.security("Formato de token JWT inválido.")
        }
    
        do {
            let header = try JSONDecoder().decode(JWTHeader.self, from: headerData)
            let body = try JSONDecoder().decode(JWTBody.self, from: bodyData)
            
            guard header.alg == "HS256", header.typ == "JWT" else {
                throw NetworkError.security("Cabecera no válida en el JWT.")
            }
            
            if body.iss != issuer || isTokenExpired(exp: body.exp) {
                throw NetworkError.security("Issuer o fecha de expiración inválida.")
            }

            let verify = jwtParts[0] + "." + jwtParts[1]
            let verifyData = Data(verify.utf8)

            let validSignature = HMAC<SHA256>.isValidAuthenticationCode(
                signatureData,
                authenticating: verifyData,
                using: simmetricKey
            )
            if !validSignature {
                throw NetworkError.security("Firma inválida en el JWT.")
            }
            return true
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.security("Fallo genérico en la validación del token JWT")
        }
    }
}

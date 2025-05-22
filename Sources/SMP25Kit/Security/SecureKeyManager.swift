//
//  SecureKeyManager.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//

import Foundation
import CryptoKit

final class SecureKeyManager: Sendable {
    static let shared = SecureKeyManager()  // Singleton de la clase
    static private let keyLabel = "SecureEncryptionKey"  // Etiqueta descriptiva para la clave en el almacenamiento seguro
    static private let randomNumberLabel = "SecureRandomNumber"  // Etiqueta descriptiva para el número aleatorio
    static private let certificateName = "SecureEncryptionCertificate"

    static private func generateRandomNumber(bits: Int) -> Data? {
        var randomBytes = [UInt8](repeating: 0, count: bits / 8)
        let result = SecRandomCopyBytes(
            kSecRandomDefault,
            randomBytes.count,
            &randomBytes
        )
        return result == errSecSuccess ? Data(randomBytes) : nil
    }
    
    private let encryptionKey: SymmetricKey  // Clave de cifrado
    private let secureRandomNumber: Data  // Número aleatorio seguro
    private let privateKey: SecureEnclave.P256.Signing.PrivateKey
    
    private init() {
        // Gestionar la clave de cifrado
        if let storedKeyData = SecKeyStore.shared.readValue(
            withLabel: SecureKeyManager.keyLabel
        ) {
            self.encryptionKey = SymmetricKey(data: storedKeyData)
        } else {
            self.encryptionKey = SymmetricKey(size: .bits256)
            let keyData = self.encryptionKey.withUnsafeBytes { Data($0) }
            SecKeyStore.shared
                .storeValue(keyData, withLabel: SecureKeyManager.keyLabel)
        }
        
        // Gestionar el número aleatorio seguro
        if let storedRandom = SecKeyStore.shared.readValue(
            withLabel: SecureKeyManager.randomNumberLabel
        ) {
            self.secureRandomNumber = storedRandom
        } else {
            if let newRandom = SecureKeyManager.generateRandomNumber(
                bits: 256
            ) {
                self.secureRandomNumber = newRandom
                SecKeyStore.shared
                    .storeValue(
                        newRandom,
                        withLabel: SecureKeyManager.randomNumberLabel
                    )
            } else {
                self.secureRandomNumber = Data()
            }
        }
        do {
            if let privateKey = SecKeyStore.shared.readPrivateKey(
                tag: SecureKeyManager.certificateName
            ) {
                self.privateKey = try SecureEnclave.P256.Signing
                    .PrivateKey(dataRepresentation: privateKey)
            } else {
                privateKey = try SecureEnclave.P256.Signing.PrivateKey()
                SecKeyStore.shared
                    .storePrivateKey(
                        privateKey.dataRepresentation,
                        tag: SecureKeyManager.certificateName
                    )
            }
        } catch {
            fatalError("An error occurred while accessing the Secure Enclave. The app could not be started.")
        }
    }
    
    func hashHMAC(data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: encryptionKey))
    }
    
    func hashHMAC(data: String) -> Data {
        let data = Data(data.utf8)
        return Data(
            HMAC<SHA256>.authenticationCode(for: data, using: encryptionKey)
        )
    }
       
    func validateHMAC(data: Data, hash: Data) -> Bool {
        HMAC<SHA256>
            .isValidAuthenticationCode(
                hash,
                authenticating: data,
                using: encryptionKey
            )
    }
       
    func validateHMAC(data: String, hash: Data) -> Bool {
        let data = Data(data.utf8)
        return HMAC<SHA256>
            .isValidAuthenticationCode(
                hash,
                authenticating: data,
                using: encryptionKey
            )
    }
       
    func GCMEncrypt(data: Data) throws -> Data? {
        let box = try AES.GCM.seal(data, using: encryptionKey)
        return box.combined
    }
       
    func GCMEncrypt(data: String) throws -> Data? {
        let data = Data(data.utf8)
        let box = try AES.GCM.seal(data, using: encryptionKey)
        return box.combined
    }
       
    func GCMDecrypt(data: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        let openBox = try AES.GCM.open(box, using: encryptionKey)
        return openBox
    }
       
    func GCMDecryptString(data: Data) throws -> String? {
        let box = try AES.GCM.SealedBox(combined: data)
        let openBox = try AES.GCM.open(box, using: encryptionKey)
        return String(data: openBox, encoding: .utf8)
    }
    
    func ChaChaEncryptB64(data: Data) throws -> String {
        let box = try ChaChaPoly.seal(data, using: encryptionKey)
        return box.combined.base64EncodedString()
    }
    
    func ChaChaEncrypt(data: Data) throws -> Data {
        let box = try ChaChaPoly.seal(data, using: encryptionKey)
        return box.combined
    }
       
    func ChaChaEncrypt(data: String) throws -> Data {
        let data = Data(data.utf8)
        let box = try ChaChaPoly.seal(data, using: encryptionKey)
        return box.combined
    }
       
    func ChaChaDecrypt(data: Data) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: data)
        let openBox = try ChaChaPoly.open(box, using: encryptionKey)
        return openBox
    }
       
    func ChaChaDecryptString(data: Data) throws -> String? {
        let box = try ChaChaPoly.SealedBox(combined: data)
        let openBox = try ChaChaPoly.open(box, using: encryptionKey)
        return String(data: openBox, encoding: .utf8)
    }
    
    func ChaChaDecryptB64(data: String) throws -> String? {
        guard let data = Data(base64Encoded: data) else { return nil }
        let box = try ChaChaPoly.SealedBox(combined: data)
        let openBox = try ChaChaPoly.open(box, using: encryptionKey)
        return String(data: openBox, encoding: .utf8)
    }
    
    func sign(data: Data) throws -> Data {
        let signature = try privateKey.signature(for: data)
        return signature.rawRepresentation
    }
    
    func sign(data: String) throws -> Data {
        let data = Data(data.utf8)
        return try sign(data: data)
    }
        
    func validateSignature(data: Data, signature: Data) throws -> Bool {
        let regeneratedSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return privateKey.publicKey.isValidSignature(regeneratedSignature, for: data)
    }
        
    func validateSignature(dataString: String, signature: Data) throws -> Bool {
        let data = Data(dataString.utf8)
        return try validateSignature(data: data, signature: signature)
    }
}

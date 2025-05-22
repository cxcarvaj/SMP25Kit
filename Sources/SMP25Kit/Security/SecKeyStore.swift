//
//  SecKeyStore.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//

import Foundation
import os.log

@preconcurrency import Security

//extension SecAccessControl: @retroactive @unchecked Sendable {}

struct SecKeyStore {
    private static let accessControl: SecAccessControl = {
        guard let accessControl = SecAccessControlCreateWithFlags(nil,
                                                       kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                       [.privateKeyUsage, .userPresence],
                                                       nil) else {
            fatalError("Error creating access control")
        }
        return accessControl
    }()
    
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "", category: "SecKeyStore")

    static let shared = SecKeyStore()
    
    func storeValue(_ data: Data, withLabel label: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "com.cxcarvaj.SecretApp",
//            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked, //Deprecado
            kSecAttrAccessControl: Self.accessControl,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: data
        ] as [String: Any]
        
        if readValue(withLabel: label) == nil {
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Error storing key: \(label) - Error: \(status)")
                os_log("Error storing key", log: Self.log, type: .error, label, status)
            }
        } else {
            let attrsToUpdate = [
                kSecValueData: data,
            ] as [String: Any]
            
            let status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
            if status != errSecSuccess {
                print("Error updating key: \(label) - Error: \(status)")
                os_log("Error updating key", log: Self.log, type: .error, label, status)
            }
        }
    }
    
    func readValue(withLabel label: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "com.cxcarvaj.SecretApp",
//            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked, //Deprecado
            kSecAttrAccessControl: Self.accessControl,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ] as [String: Any]
        
        var item: CFTypeRef?
        
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecSuccess {
            print("Error reading key: \(label) - Error: \(status)")
            os_log("Error reading key", log: Self.log, type: .error, label, status)
            return nil
        }
        return item as? Data
    }
    
    func deleteValue(withLabel label: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: label,
            kSecUseDataProtectionKeychain: true,
        ] as [String: Any]
        
        let result = SecItemDelete(query as CFDictionary)
        if result == noErr {
            print("Item with \(label) has been deleted")
        }
    }
    
    func storePrivateKey(_ certificate: Data, tag: String) {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData,
            kSecAttrAccessControl: Self.accessControl,
            kSecAttrIsPermanent: true,
            kSecValueData: certificate
        ] as [String: Any]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecSuccess: break
        case errSecDuplicateItem:
            os_log("The certificate key is duplicated for the tag:", log: Self.log, type: .error, tag, status)
        default:
            os_log("Error saving the certificate", log: Self.log, type: .error, tag, status)
        }
    }
    
    func readPrivateKey(tag: String) -> Data? {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData,
            kSecAttrAccessControl: Self.accessControl,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            os_log("Error reading the certificate", log: Self.log, type: .error, tag, status)
            return nil
        }
        return item as? Data
    }
    
    func deletePrivateKey(tag: String) {
        let tagData = Data(tag.utf8)
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrApplicationTag: tagData
        ] as [String: Any]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            os_log("Error deleting key", log: Self.log, type: .error, tag, status)
            return
        }
    }
}

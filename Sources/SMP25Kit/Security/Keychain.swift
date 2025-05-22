//
//  Keychain.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Foundation

@propertyWrapper
public struct Keychain {
    let key: String
    
    public init(key: String) {
        self.key = key
    }
    
    public var wrappedValue: Data? {
        get {
            SecKeyStore.shared.readValue(withLabel: key)
        }
        set {
            if let value = newValue {
                SecKeyStore.shared.storeValue(value, withLabel: key)
            } else {
                SecKeyStore.shared.deleteValue(withLabel: key)
            }
        }
    }
}

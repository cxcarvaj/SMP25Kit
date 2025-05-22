//
//  LocalAuthVM.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import LocalAuthentication

enum Biometry {
    case faceID
    case touchID
    case opticID
    case none
}

// Esto se debe a que LAContext no es Sendable
extension LAContext: @retroactive @unchecked Sendable {}

@Observable
final class LocalAuthVM {
    let context = LAContext()
    
    var biometry: Biometry = .none
    var accessGranted = false
    
    init() {
        initBiometry()
    }
    
    func initBiometry() {
        var authError: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if context.biometryType == .faceID {
                biometry = .faceID
            } else if context.biometryType == .touchID {
                biometry = .touchID
            } else if context.biometryType == .opticID {
                biometry = .opticID
            }
        }
    }
    
    @MainActor
    func checkBiometry() async throws {
        guard biometry != .none else { return }
        
        if try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Se verificará el acceso al contenido privado de la app") {
            accessGranted = true
        }
    }
}

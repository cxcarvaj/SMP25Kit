//
//  NetworkError.swift
//  EmployeesAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 10/4/25.
//

import Foundation

public enum NetworkError: LocalizedError {
    case general(Error)
    case status(Int)
    case json(Error)
    case dataNotValid
    case security(String)
    case nonHTTP
    
    public var errorDescription: String? {
        switch self {
        case .general(let error):
            error.localizedDescription
        case .status(let code):
            "HTTP status code: \(code)"
        case .json(let error):
            "JSON error: \(error)"
        case .dataNotValid:
            "Invalid data received from server"
        case .security(let string):
            "Server certificate validation failed: \(string)"
        case .nonHTTP:
            "URLSession did not return an HTTPURLResponse"
        }
    }
}

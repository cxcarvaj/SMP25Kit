//
//  NetworkMonitor.swift
//  SMP25Kit
//
//  Created by Carlos Xavier Carvajal Villegas on 28/5/25.
//

import SwiftUI
import Network

@Observable @MainActor
public final class NetworkMonitor {
    public enum Status {
        case offline, online, unknown
    }
    
    public var status: Status = .online
    
    let monitor = NWPathMonitor()
    @ObservationIgnored var queue = DispatchQueue(label: "NetworkMonitor")
    
    public init() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [self] path in
            Task { @MainActor in
                self.status = path.status == .satisfied ? .online : .offline
            }
        }
    }
}

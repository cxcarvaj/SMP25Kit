//
//  AsyncImageVM.swift
//  EmployeesAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 10/4/25.
//


import SwiftUI
 
 @Observable @MainActor
 public final class AsyncImageVM {
     let imageDownloader = ImageDownloader.shared
     
     public var image: UIImage?
     
     public init() {}
     
     public func getImage(url: URL?) {
         guard let url,
               let cacheURL = imageDownloader.createHeicCacheURL(for: url) else { return }
         if FileManager.default.fileExists(atPath: cacheURL.path) {
             if let data = try? Data(contentsOf: cacheURL) {
                 image = UIImage(data: data)
             }
         } else {
             // Cómo conseguimos que una captura semántica de self en un closure sea segura?
             // Passing closure as a 'sending' parameter risks causing data races between code in the current task and concurrent execution of the closure
             // Tenemos 2 maneras:
             // 1. Hacer la clase @Sendable
             // 2. Hacer la clase atada a un Hilo
             Task { await getImageAsync(url: url) }
         }
     }
     
     func getImageAsync(url: URL) async {
         do {
             let image = try await imageDownloader.loadCachedImage(from: url)
             self.image = image
         } catch {
             print("Error retrieving image: \(error.localizedDescription)")
         }
     }
 }

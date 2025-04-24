//
//  ImageDownloader.swift
//  EmployeesAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 10/4/25.
//

import SwiftUI
 // Esto es aplicable a cualquier tipo de dato, siempre y cuando tengamos un valor de identificación única de ese dato. (Por ejemplo Json's)
 actor ImageDownloader {
     static let shared = ImageDownloader()
     var maxWidth: CGFloat = 300
     
     private enum ImageStatus {
         case downloading(task: Task<UIImage, any Error>)
         case downloaded(image: UIImage)
     }
     
     private var cache: [URL: ImageStatus] = [:]
     
     private func getImage(url: URL) async throws -> UIImage {
         let (data, _) = try await URLSession.shared.data(from: url)
         if let image = UIImage(data: data) {
             return image
         } else {
             throw URLError(.badServerResponse)
         }
     }
     
     /// Obtiene una imagen desde una URL utilizando un sistema de caché en memoria
     /// - Parameter url: La URL de la imagen a descargar
     /// - Returns: La imagen descargada
     /// - Throws: Errores de red o procesamiento de imagen
     func loadCachedImage(from url: URL) async throws -> UIImage {
         if let imageStatus = cache[url] {
             switch imageStatus {
             case .downloading(let task):
                 return try await task.value
             case .downloaded(let image):
                 return image
             }
         }
         
         let task = Task {
             try await getImage(url: url)
         }
         
         cache[url] = .downloading(task: task)
         
         do {
             let image = try await task.value
             cache[url] = .downloaded(image: image)
             return try await saveImageAsHeic(for: url)
         } catch {
             cache.removeValue(forKey: url)
             throw error
         }
     }
     
     /// Guarda una imagen previamente descargada en formato HEIC en el sistema de archivos
     /// - Parameter url: La URL original de la imagen
     /// - Returns: La imagen redimensionada
     /// - Throws: Error si no se puede acceder al caché o escribir el archivo
     func saveImageAsHeic(for url: URL) async throws -> UIImage {
         // Verificar que la imagen esté en caché y obtenemos la URL de destino
         guard let cacheEntry = cache[url],
               let destinationURL = createHeicCacheURL(for: url) else {
             throw URLError(.cannotDecodeContentData)
         }
         
         // Verificar que la imagen esté en estado "descargada" y procesarla
         if case .downloaded(let originalImage) = cacheEntry,
            let resizedImage = await resizeImage(originalImage),
            let heicImageData = resizedImage.heicData() {
             
             // Guardar los datos HEIC en el sistema de archivos
             try heicImageData.write(to: destinationURL, options: .atomic)
             
             // Eliminar la entrada del caché en memoria ya que ahora está en disco
             cache.removeValue(forKey: url)
             
             return resizedImage
         } else {
             throw URLError(.cannotDecodeContentData)
         }
     }
     
     func resizeImage(_ image: UIImage) async -> UIImage? {
         let scale = image.size.width / maxWidth
         let height = image.size.height / scale
         return await image.byPreparingThumbnail(ofSize: CGSize(width: maxWidth, height: height))
     }
     
     /// Crea una URL en el directorio de caché para almacenar una versión HEIC
     /// de un archivo identificado por la URL original
     nonisolated func createHeicCacheURL(for originalURL: URL) -> URL? {
         let fileNameWithoutExtension = originalURL.deletingPathExtension().lastPathComponent
         return URL.cachesDirectory
             .appendingPathComponent(fileNameWithoutExtension)
             .appendingPathExtension("heic")
     }
 }

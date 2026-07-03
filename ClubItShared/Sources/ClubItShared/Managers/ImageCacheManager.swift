#if canImport(UIKit)
import UIKit

/// A singleton in-memory image cache that eliminates redundant network requests.
/// Images are keyed by their URL string and stored as UIImage objects in NSCache.
public final class ImageCacheManager {
    public static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    
    /// Tracks in-flight downloads to avoid duplicate requests for the same URL
    private var activeTasks: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()
    
    private init() {
        cache.countLimit = 200 // Max 200 images in memory
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB cap
        
        // Use a URLSession with disk caching for network-level caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB memory
            diskCapacity: 200 * 1024 * 1024     // 200 MB disk
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Synchronous cache lookup
    
    /// Returns a cached UIImage if available, nil otherwise.
    public func cachedImage(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }
    
    /// Stores a UIImage in the cache.
    public func store(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
    
    // MARK: - Async download with deduplication
    
    /// Downloads and caches the image. Deduplicates concurrent requests for the same URL.
    public func loadImage(from urlString: String) async -> UIImage? {
        // 1. Check in-memory cache
        if let cached = cachedImage(for: urlString) {
            return cached
        }
        
        // 2. Check if there's already a download in progress for this URL
        let existingTask = lock.withLock { activeTasks[urlString] }
        if let existingTask {
            return await existingTask.value
        }
        
        // 3. Start a new download task
        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await session.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                store(image, for: urlString)
                return image
            } catch {
                print("DEBUG: ImageCacheManager failed to load \(urlString): \(error.localizedDescription)")
                return nil
            }
        }
        
        lock.withLock { activeTasks[urlString] = task }
        
        let result = await task.value
        
        lock.withLock { activeTasks.removeValue(forKey: urlString) }
        
        return result
    }
    
    // MARK: - Bulk pre-fetch
    
    /// Pre-fetches a batch of image URLs concurrently in the background.
    public func prefetch(urls: [String]) {
        Task.detached(priority: .utility) {
            await withTaskGroup(of: Void.self) { group in
                for urlString in urls {
                    // Skip if already cached
                    if self.cachedImage(for: urlString) != nil { continue }
                    group.addTask {
                        _ = await self.loadImage(from: urlString)
                    }
                }
            }
        }
    }
    
    /// Removes a specific image from the cache.
    public func removeImage(for urlString: String) {
        cache.removeObject(forKey: urlString as NSString)
    }
    
    /// Clears the entire image cache.
    public func clearCache() {
        cache.removeAllObjects()
    }
}
#endif

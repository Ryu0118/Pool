import Foundation

final class DiskCache: @unchecked Sendable, Cacher {
    static let shared = DiskCache()
    
    private let fileManager = FileManager.default
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    func set<Value, Policy>(
        _ pool: Pool<Value, Policy>,
        _ function: StaticString
    ) throws {
        try removeInvalidCaches(pool)
        
        let cacheDirectory = getCacheDirectory(pool)
        let fileUrl = cacheDirectory.appendingPathComponent("\(function)")
        
        try createDirectoryIfNeeded(cacheDirectory)
        try createCacheFile(pool, path: fileUrl)
    }
    
    func get<Value, Policy>(
        _ key: Pool<Value, Policy>.Type,
        _ function: StaticString
    ) throws -> Pool<Value, Policy> {
        var pool = key.init()
        
        try removeInvalidCaches(pool)
        
        let fileUrl = getFileUrl(pool, function)
        
        let data = try getCachedData(fileUrl: fileUrl, decode: Value.self)
        pool.overwriteContainer(value: data)
        
        return pool
    }
}

private extension DiskCache {
    func createDirectoryIfNeeded(_ url: URL) throws {
        guard !fileManager.fileExists(atPath: url.absoluteString) else {
            return
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    func createCacheFile<Value, Policy>(
        _ pool: Pool<Value, Policy>,
        path: URL
    ) throws {
        guard let target = pool.container else {
            throw DiskCacheError.targetDataIsNil
        }
        let data = try jsonEncoder.encode(target)
        try data.write(to: path)
    }
    
    func getCacheDirectory<Value, Policy>(
        _ pool: Pool<Value, Policy>
    ) -> URL {
        pool
            .cachePolicy
            .diskCachePolicy
            .directory
            .appendingPathComponent(
                pool.cachePolicy.name,
                isDirectory: true
            )
    }
    
    func getCachedData<Value>(
        fileUrl: URL,
        decode to: Value.Type
    ) throws -> Value where Value: Cacheable {
        let data = try Data(contentsOf: fileUrl)
        return try jsonDecoder.decode(to, from: data)
    }
    
    func getFileUrl<Value, Policy>(
        _ pool: Pool<Value, Policy>,
        _ function: StaticString
    ) -> URL {
        let cacheDirectory = getCacheDirectory(pool)
        return cacheDirectory.appendingPathComponent("\(function)")
    }
    
    func removeObject<Value, Policy>(
        _ pool: Pool<Value, Policy>,
        _ function: StaticString
    ) throws {
        let fileUrl = getFileUrl(pool, function)
        try fileManager.removeItem(at: fileUrl)
    }
    
    func removeAll<Value, Policy>(
        _ pool: Pool<Value, Policy>
    ) throws {
        let url = getCacheDirectory(pool)
        try fileManager.removeItem(at: url)
        try createDirectoryIfNeeded(url)
    }
    
    func removeInvalidCaches<Value, Policy>(
        _ pool: Pool<Value, Policy>
    ) throws {
        let cacheUrl = getCacheDirectory(pool)
        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .contentModificationDateKey,
            .totalFileAllocatedSizeKey
        ]
        var resourceObjects = [(url: URL, resourceValues: URLResourceValues)]()
        var filesToDelete = [URL]()
        var totalSize: UInt = 0
        let fileEnumerator = fileManager.enumerator(
            at: cacheUrl,
            includingPropertiesForKeys: resourceKeys,
            options: .skipsHiddenFiles,
            errorHandler: nil
        )
        
        guard let urlArray = fileEnumerator?.allObjects as? [URL] else {
            throw DiskCacheError.fileEnumeratorIsNil
        }
        
        for url in urlArray {
            let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
            guard resourceValues.isDirectory != true else {
                continue
            }
            
            if let expiryDate = resourceValues.contentModificationDate,
               expiryDate > pool.cachePolicy.diskCachePolicy.expiry.date {
                filesToDelete.append(url)
                continue
            }
            
            if let fileSize = resourceValues.totalFileAllocatedSize {
                totalSize += UInt(fileSize)
                resourceObjects.append((url: url, resourceValues: resourceValues))
            }
        }
        
        // Remove expired objects
        for url in filesToDelete {
            try fileManager.removeItem(at: url)
        }
        
        try removeResourceObjects(pool: pool, objects: resourceObjects, totalSize: totalSize)
    }
    
    func removeResourceObjects<Value, Policy>(
        pool: Pool<Value, Policy>,
        objects: [(url: URL, resourceValues: URLResourceValues)],
        totalSize: UInt
    ) throws {
        guard pool.cachePolicy.diskCachePolicy.maxSize > 0 && totalSize > pool.cachePolicy.diskCachePolicy.maxSize else {
            return
        }
        
        var totalSize = totalSize
        let targetSize = pool.cachePolicy.diskCachePolicy.maxSize / 2
        
        let sortedFiles = objects.sorted {
            if let time1 = $0.resourceValues.contentModificationDate?.timeIntervalSinceReferenceDate,
               let time2 = $1.resourceValues.contentModificationDate?.timeIntervalSinceReferenceDate {
                return time1 > time2
            } else {
                return false
            }
        }
        
        for file in sortedFiles {
            try fileManager.removeItem(at: file.url)
            
            if let fileSize = file.resourceValues.totalFileAllocatedSize {
                totalSize -= UInt(fileSize)
            }
            
            if totalSize < targetSize {
                break
            }
        }
    }
}

extension DiskCache {
    enum DiskCacheError: LocalizedError {
        case targetDataIsNil
        case fileEnumeratorIsNil
        
        var errorDescription: String? {
            switch self {
            case .targetDataIsNil:
                return "Data to be stored in Disk is nil."
            case .fileEnumeratorIsNil:
                return "File Enumerator is nil."
            }
        }
    }
}

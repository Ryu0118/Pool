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
                pool.cachePolicy.diskCachePolicy.name,
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
}

extension DiskCache {
    enum DiskCacheError: LocalizedError {
        case targetDataIsNil

        var errorDescription: String? {
            switch self {
            case .targetDataIsNil:
                return "Data to be stored in Disk is nil."
            }
        }
    }
}

import Foundation
import CryptoKit

public protocol CachePolicy: Hashable, Sendable, Encodable {
    var diskCachePolicy: DiskCachePolicy { get }
    var memoryCachePolicy: MemoryCachePolicy { get }
    init()
}

public struct DefaultCachePolicy: CachePolicy, Sendable, Encodable {
    public let diskCachePolicy: DiskCachePolicy = .init(name: "Default")
    public let memoryCachePolicy: MemoryCachePolicy = .init()
    public init() {}
}

public struct DiskCachePolicy: Hashable, Sendable, Encodable {
    public let name: String
    public let expiry: Expiry
    public let maxSize: UInt
    public let directory: URL

    public init(
        name: String,
        expiry: Expiry = .never,
        maxSize: UInt = .max,
        directory: URL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    ) {
        self.name = name
        self.expiry = expiry
        self.maxSize = maxSize
        self.directory = directory
    }
}

public struct MemoryCachePolicy: Hashable, Sendable, Encodable {
    public let expiry: Expiry
    public let limit: UInt
    public let maxSize: UInt
    public let memoryPressureLevel: MemoryPressureLevel

    public init(
        expiry: Expiry = .never,
        limit: UInt = .max,
        maxSize: UInt = .max,
        memoryPressureLevel: MemoryPressureLevel = .normal
    ) {
        self.expiry = expiry
        self.limit = limit
        self.maxSize = maxSize
        self.memoryPressureLevel = memoryPressureLevel
    }
}

public enum Expiry: Hashable, Sendable, Encodable {
    case date(Date)
    case hours(UInt)
    case minutes(UInt)
    case seconds(UInt)
    case never
}

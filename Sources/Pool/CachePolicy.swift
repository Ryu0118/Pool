import Foundation
import CryptoKit

public protocol CachePolicy: Hashable, Sendable, Encodable {
    var name: String { get }
    var diskCachePolicy: DiskCachePolicy { get }
    var memoryCachePolicy: MemoryCachePolicy { get }
    init()
}

public extension CachePolicy {
    var name: String {
        String(describing: Self.self)
    }
}

public struct DefaultCachePolicy: CachePolicy, Sendable, Encodable {
    public let name = "Default"
    public let diskCachePolicy: DiskCachePolicy = .init()
    public let memoryCachePolicy: MemoryCachePolicy = .init()
    public init() {}
}

public struct DiskCachePolicy: Hashable, Sendable, Encodable {
    public let expiry: Expiry
    public let maxSize: UInt
    public let directory: URL

    public init(
        expiry: Expiry = .never,
        maxSize: UInt = .max,
        directory: URL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    ) {
        self.expiry = expiry
        self.maxSize = maxSize
        self.directory = directory
    }
}

public struct MemoryCachePolicy: Hashable, Sendable, Encodable {
    public let memoryPressureLevel: MemoryPressureLevel

    public init(
        memoryPressureLevel: MemoryPressureLevel = .normal
    ) {
        self.memoryPressureLevel = memoryPressureLevel
    }
}

public enum Expiry: Hashable, Sendable, Encodable {
    case date(Date)
    case hours(UInt)
    case minutes(UInt)
    case seconds(UInt)
    case never

    var date: Date {
        switch self {
        case .date(let date):
            return date
        case .hours(let uInt):
            return Date().addingTimeInterval(60 * 60 * Double(uInt))
        case .minutes(let uInt):
            return Date().addingTimeInterval(60 * Double(uInt))
        case .seconds(let uInt):
            return Date().addingTimeInterval(TimeInterval(uInt))
        case .never:
            return .distantFuture
        }
    }
}

import Foundation

public struct Pool<Value, Policy>: @unchecked Sendable where Policy: CachePolicy, Value: Cacheable {
    let cachePolicy: Policy

    var isContainerNil: Bool { container == nil }

    private(set) var container: Value?

    private let lock = NSRecursiveLock()

    public init() {
        cachePolicy = Policy()
    }

    mutating func overwriteContainer(value: Value?) {
        defer { lock.unlock() }
        lock.lock()

        self.container = value
    }
}

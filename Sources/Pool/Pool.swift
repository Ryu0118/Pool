import Foundation

public struct Pool<Value, Policy>: @unchecked Sendable where Policy: CachePolicy, Value: Cacheable {
    let cachePolicy: Policy

    var isContainerNil: Bool { container == nil }

    private(set) var container: Value?

    private let lock = NSRecursiveLock()

    init() {
        cachePolicy = Policy()
    }

    mutating func overwriteContainer(value: Value?) {
        defer { lock.unlock() }
        lock.lock()

        self.container = value
    }
}

extension Pool: Hashable {
    public static func == (lhs: Pool<Value, Policy>, rhs: Pool<Value, Policy>) -> Bool {
        let lhsContainerString = try? lhs.container?.string
        let rhsContainerString = try? rhs.container?.string

        return lhs.cachePolicy == rhs.cachePolicy && lhsContainerString == rhsContainerString
    }

    public func hash(into hasher: inout Hasher) {
        let containerString = try? container?.string

        hasher.combine(cachePolicy)
        hasher.combine(isContainerNil)

        if let containerString {
            hasher.combine(containerString)
        }
    }
}

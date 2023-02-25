import Foundation

private typealias PoolIdentifier = ObjectIdentifier
private typealias MemoryCacheContainer = [PolicyIdentifier: [PoolIdentifier: AnySendable]]

// MARK: - MemoryCache
final class MemoryCache: @unchecked Sendable, Cacher {
    static let shared = MemoryCache()
    private init() { }

    private var cached = MemoryCacheContainer()
    private let lock = NSRecursiveLock()

    func get<Value, Policy>(
        _ key: Pool<Value, Policy>.Type,
        _ : StaticString
    ) throws -> Pool<Value, Policy> {
        defer { lock.unlock() }
        lock.lock()

        return cached[PolicyIdentifier(Policy.self)]?[PoolIdentifier(key)]?.base as? Pool<Value, Policy> ?? Pool<Value, Policy>()
    }

    func set<Value, Policy>(
        _ value: Pool<Value, Policy>,
        _ : StaticString
    ) throws {
        defer { lock.unlock() }
        lock.lock()

        let policyIdentifier = PolicyIdentifier(value.cachePolicy)
        var policyContainer = cached[policyIdentifier] ?? [PoolIdentifier: AnySendable]()
        policyContainer.updateValue(AnySendable(value), forKey: PoolIdentifier(Pool<Value, Policy>.self))
        cached[policyIdentifier] = policyContainer
    }

    func removeAllMemoryCache() {
        defer { lock.unlock() }
        lock.lock()

        cached.removeAll()
    }

    func deleteBasedOn(memoryPressureLevel: MemoryPressureLevel) {
        defer { lock.unlock() }
        lock.lock()

        for (policy, _) in cached where policy.policy.memoryCachePolicy.memoryPressureLevel == memoryPressureLevel {
            cached[policy]?.removeAll()
        }
    }
}

// MARK: - AnySendable
private struct AnySendable: @unchecked Sendable {
    let base: Any

    @inlinable
    init<Base: Sendable>(_ base: Base) {
        self.base = base
    }
}

// MARK: - PolicyIdentifier
private struct PolicyIdentifier: Hashable {
    let policy: any CachePolicy
    let objectIdentifier: ObjectIdentifier

    init<Policy: CachePolicy>(_ policy: Policy) {
        self.policy = policy
        self.objectIdentifier = ObjectIdentifier(type(of: policy))
    }

    init<Policy: CachePolicy>(_ policyType: Policy.Type) {
        self.policy = Policy()
        self.objectIdentifier = ObjectIdentifier(policyType)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }

    static func == (lhs: PolicyIdentifier, rhs: PolicyIdentifier) -> Bool {
        lhs.objectIdentifier == rhs.objectIdentifier
    }
}

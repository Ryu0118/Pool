import Foundation

public final class AsyncValue<Value, Policy>: @unchecked Sendable where Policy: CachePolicy, Value: Cacheable {
    public typealias AtomicPool = Pool<Value, Policy>
    public typealias Cached = CachedValues<Value, Policy>
    private let keyPath: WritableKeyPath<Cached, AtomicPool>
    private var cachedValues: Cached

    init(
        keyPath: WritableKeyPath<Cached, AtomicPool>,
        cachedValues: Cached
    ) {
        self.keyPath = keyPath
        self.cachedValues = cachedValues
    }

    public func get() async -> Value? {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: nil)
                return
            }
            Task.detached {
                continuation.resume(returning: self.cachedValues[keyPath: self.keyPath].container)
            }
        }
    }

    public func set(_ value: Value?) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(returning: ())
                return
            }
            Task.detached {
                continuation.resume(returning: self.cachedValues[keyPath: self.keyPath].overwriteContainer(value: value))
            }
        }
    }
}

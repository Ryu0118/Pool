import Foundation

@propertyWrapper
public final class AsyncCache<Value, Policy> where Policy: CachePolicy, Value: Cacheable {
    public typealias AtomicPool = Pool<Value, Policy>
    public typealias Cached = CachedValues<Value, Policy>

    private let keyPath: WritableKeyPath<Cached, AtomicPool>
    private let cachedValues = Cached()

    public init(_ keyPath: WritableKeyPath<Cached, AtomicPool>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: AsyncValue<Value, Policy> {
        AsyncValue(keyPath: keyPath, cachedValues: cachedValues)
    }

    public var projectedValue: ErrorObservable {
        get { ErrorObservable(observeErrors: cachedValues.observeError) }
        set { cachedValues.observeError = newValue.observeErrors }
    }
}

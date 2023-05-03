import Foundation

@propertyWrapper
public final class Cache<Value, Policy> where Policy: CachePolicy, Value: Cacheable {
    public typealias AtomicPool = Pool<Value, Policy>
    public typealias Cached = CachedValues<Value, Policy>

    private let keyPath: WritableKeyPath<Cached, AtomicPool>
    private var cachedValues = Cached()

    public init(_ keyPath: WritableKeyPath<Cached, AtomicPool>) {
        self.keyPath = keyPath
    }

    public var wrappedValue: Value? {
        get { cachedValues[keyPath: keyPath].container }
        set { cachedValues[keyPath: keyPath].overwriteContainer(value: newValue) }
    }

    public var projectedValue: ErrorObservable {
        get { ErrorObservable(observeErrors: cachedValues.observeError) }
        set { cachedValues.observeError = newValue.observeErrors }
    }
}

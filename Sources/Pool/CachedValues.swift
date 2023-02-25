import Foundation

public final class CachedValues<Value, Policy>: @unchecked Sendable where Value: Cacheable, Policy: CachePolicy {
    public typealias AtomicPool = Pool<Value, Policy>

    var observeError: ((Error) -> Void)?

    private let memoryPressureMonitor: MemoryPressureMonitor = .shared
    private let memoryCache: MemoryCache = .shared
    private let diskCache: DiskCache = .shared
    private var memoryPressureTask: Task<(), Never>?

    init() {
        observeMemoryPressure()
    }

    deinit {
        memoryPressureTask?.cancel()
    }

    public subscript(
        _ key: Pool<Value, Policy>.Type,
        function: StaticString = #function
    ) -> Pool<Value, Policy> {
        get {
            get(key, function)
        }
        set {
            set(newValue, function) // always successful
        }
    }

    private func observeMemoryPressure() {
        memoryPressureTask = Task {
            for await memoryPressure in memoryPressureMonitor.memoryPressures {
                memoryCache.deleteBasedOn(memoryPressureLevel: memoryPressure)
            }
        }
    }

    private func set(
        _ newValue: Pool<Value, Policy>,
        _ function: StaticString
    ) {
        do {
            try! memoryCache.set(newValue, function) // always successful
            try diskCache.set(newValue, function)
        }
        catch {
            print("[Pool Error]: ", error)
            observeError?(error)
        }
    }

    private func get(
        _ key: Pool<Value, Policy>.Type,
        _ function: StaticString
    ) -> Pool<Value, Policy> {
        let memoryCachedPool = try! memoryCache.get(key, function) // always successful

        guard memoryCachedPool.isContainerNil else {
            return memoryCachedPool // use memoryCache if memoryCachedPool.container is nil
        }

        do {
            let diskCachePool = try diskCache.get(key, function)
            return diskCachePool
        }
        catch {
            observeError?(error)
            return memoryCachedPool
        }
    }
}

public enum MemoryPressureLevel: Sendable, Encodable {
    case normal, warning, critical
}

private final class MemoryPressureMonitor: @unchecked Sendable {
    static let shared = MemoryPressureMonitor()

    private let dispatchSource = DispatchSource.makeMemoryPressureSource(eventMask: .all)

    var memoryPressures: AsyncStream<MemoryPressureLevel> {
        AsyncStream { continuation in
            dispatchSource.setEventHandler { [weak self] in
                guard let self = self else { return }
                let event = self.dispatchSource.data

                if !self.dispatchSource.isCancelled {
                    switch event {
                    case .normal:
                        continuation.yield(.normal)
                    case .warning:
                        continuation.yield(.warning)
                    case.critical:
                        continuation.yield(.critical)
                    default: break
                    }
                }
            }
        }
    }

    private init() {
        dispatchSource.activate()
    }

    deinit {
        dispatchSource.cancel()
    }
}
extension String: LocalizedError {}

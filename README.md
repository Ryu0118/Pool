# Pool

Modern cache library written in Swift

## Installation
```Swift
.package(url: "https://github.com/Ryu0118/Pool.git", from: "0.0.1")
```

## Usage
```Swift
extension CachedValues<String, DefaultCachePolicy> {
    var hoge: AtomicPool {
        get { self[AtomicPool.self] }
        set { self[AtomicPool.self] = newValue }
    }
}

class Hoge {
    @Cache(\.hoge) var hoge
    
    func get() -> String? {
        hoge
    }
    
    func set(_ newValue: String) {
        hoge = newValue
    }
}
```

### Custom CachePolicy
```Swift
struct MyCachePolicy: CachePolicy {
    let memoryCachePolicy: MemoryCachePolicy
    let diskCachePolicy: DiskCachePolicy

    init() {
        memoryCachePolicy = .init()
        diskCachePolicy = .init(expiry: .hours(1), maxSize: 10000)
    }
}

extension CachedValues<String, CustomCachePolicy> {
    var hoge: AtomicPool {
        get { self[AtomicPool.self] }
        set { self[AtomicPool.self] = newValue }
    }
}
```

### Cacheable
```Swift
struct Hoge: Cacheable {
    let hoge: String
    let fuga: String
}

extension CachedValues<Hoge, DefaultCachePolicy> {
    var hoge: AtomicPool {
        get { self[AtomicPool.self] }
        set { self[AtomicPool.self] = newValue }
    }
}
```

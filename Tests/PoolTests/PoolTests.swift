import XCTest
@testable import Pool

final class PoolTests: XCTestCase {
    @Cache(\.test) var testCache
    @Cache(\.test) var testCache2
    @Cache(\.array) var arrayCache

    @AsyncCache(\.test) var asyncTest
    @AsyncCache(\.array) var asyncArray

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        testCache = Test(test: "String")
        XCTAssertEqual(testCache?.test ?? "", "String")
        XCTAssertEqual(testCache2?.test ?? "", "String")
        testCache?.test = "Int"
        XCTAssertEqual(testCache?.test ?? "", "Int")

        arrayCache = []
        arrayCache?.append("String")
        XCTAssertEqual(arrayCache?.first ?? "", "String")
    }

    func testAsyncCache() async throws {
        var test = await asyncTest.get()
        test?.test = "Bool"
        await asyncTest.set(test)

        XCTAssertEqual(test?.test ?? "", "Bool")
    }
}

struct MyCachePolicy: CachePolicy {
    let memoryCachePolicy: MemoryCachePolicy
    let diskCachePolicy: DiskCachePolicy

    init() {
        memoryCachePolicy = .init()
        diskCachePolicy = .init(expiry: .never, maxSize: .max)
    }
}

struct Test: Cacheable {
    var test: String
}

extension CachedValues<Test, DefaultCachePolicy> {
    var test: AtomicPool {
        get { self[AtomicPool.self] }
        set { self[AtomicPool.self] = newValue }
    }
}

extension CachedValues<[String], MyCachePolicy> {
    var array: AtomicPool {
        get { self[AtomicPool.self] }
        set { self[AtomicPool.self] = newValue }
    }
}

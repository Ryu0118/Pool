import Foundation

protocol Cacher: Sendable {
    func get<Value, Policy>(
        _ key: Pool<Value, Policy>.Type,
        _ function: StaticString
    ) throws -> Pool<Value, Policy>

    func set<Value, Policy>(
        _ value: Pool<Value, Policy>,
        _ function: StaticString
    ) throws
}

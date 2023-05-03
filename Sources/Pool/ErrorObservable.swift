import Foundation

public struct ErrorObservable {
    var observeErrors: ((Error) -> Void)?

    public mutating func observeErrors(_ observer: @escaping (Error) -> Void) {
        self.observeErrors = observer
    }
}

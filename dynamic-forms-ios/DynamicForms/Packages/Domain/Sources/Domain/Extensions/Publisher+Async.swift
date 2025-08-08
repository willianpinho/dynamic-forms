import Foundation
import Combine

/// Extension to bridge Combine Publishers to async/await
/// Following Clean Code principles with clear naming and single responsibility
@available(iOS 13.0, macOS 10.15, *)
public extension Publisher {
    
    /// Convert Publisher to async/await
    /// - Returns: The publisher's output value
    /// - Throws: The publisher's error
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
    
    /// Convert Publisher to async sequence
    /// - Returns: AsyncThrowingStream of the publisher's output values
    func asyncSequence() -> AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.finish()
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        continuation.yield(value)
                    }
                )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
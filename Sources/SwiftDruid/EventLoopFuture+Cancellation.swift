import NIOConcurrencyHelpers
import NIOCore

extension EventLoopFuture where Value: Sendable {
    /// Awaits the future, but stops waiting as soon as the current task is cancelled.
    ///
    /// `EventLoopFuture.get()` ignores Swift task cancellation: a cancelled caller keeps waiting
    /// until the future completes, which for a Druid query means until the broker answers. This
    /// variant throws `CancellationError` at the moment of cancellation instead. The future itself
    /// is not cancelled and keeps running in the background, so callers that own a resource behind
    /// it (such as a query running on Druid) must release that resource themselves.
    func getUnlessCancelled() async throws -> Value {
        let handoff = ContinuationHandoff<Value>()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Value, any Error>) in
                handoff.attach(continuation)
                self.whenComplete { result in
                    handoff.finish(with: result)
                }
            }
        } onCancel: {
            handoff.finish(with: .failure(CancellationError()))
        }
    }
}

/// Resumes a continuation exactly once, whichever of "future completed" and "task cancelled"
/// happens first, in whichever order the continuation is attached and the outcome arrives.
private final class ContinuationHandoff<Value: Sendable>: Sendable {
    private struct State {
        var continuation: CheckedContinuation<Value, any Error>?
        var outcome: Result<Value, any Error>?
    }

    private let state = NIOLockedValueBox(State())

    func attach(_ continuation: CheckedContinuation<Value, any Error>) {
        let alreadyFinished: Result<Value, any Error>? = state.withLockedValue { state in
            if let outcome = state.outcome {
                return outcome
            }
            state.continuation = continuation
            return nil
        }
        if let alreadyFinished {
            continuation.resume(with: alreadyFinished)
        }
    }

    func finish(with result: Result<Value, any Error>) {
        let waiting: CheckedContinuation<Value, any Error>? = state.withLockedValue { state in
            guard state.outcome == nil else { return nil }
            state.outcome = result
            defer { state.continuation = nil }
            return state.continuation
        }
        waiting?.resume(with: result)
    }
}

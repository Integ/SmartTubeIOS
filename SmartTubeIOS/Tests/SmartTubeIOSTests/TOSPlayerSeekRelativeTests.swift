#if !os(tvOS)
import Testing

@testable import SmartTubeIOS

// MARK: - TOSPlayerSeekRelativeTests (#140)

@Suite("TOSPlayerViewModel.clampedSeekTarget")
struct TOSPlayerSeekRelativeTests {

    @Test("skip forward within bounds adds delta to currentTime")
    func forwardWithinBounds() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 30, delta: 10, duration: 120)
        #expect(result == 40)
    }

    @Test("skip back within bounds subtracts delta from currentTime")
    func backwardWithinBounds() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 30, delta: -10, duration: 120)
        #expect(result == 20)
    }

    @Test("skip back past the start clamps to 0")
    func backwardClampsToZero() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 5, delta: -10, duration: 120)
        #expect(result == 0)
    }

    @Test("skip forward past the end clamps to duration")
    func forwardClampsToDuration() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 115, delta: 10, duration: 120)
        #expect(result == 120)
    }

    @Test("duration of 0 (not yet known) still clamps the lower bound to 0")
    func unknownDurationStillClampsLowerBound() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 5, delta: -10, duration: 0)
        #expect(result == 0)
    }

    @Test("duration of 0 (not yet known) does not clamp the upper bound")
    func unknownDurationDoesNotClampUpperBound() {
        let result = TOSPlayerViewModel.clampedSeekTarget(currentTime: 100, delta: 30, duration: 0)
        #expect(result == 130)
    }
}
#endif

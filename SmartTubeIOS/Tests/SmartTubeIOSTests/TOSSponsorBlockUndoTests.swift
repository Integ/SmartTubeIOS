#if !os(tvOS)
import Foundation
import Testing

@testable import SmartTubeIOSCore
@testable import SmartTubeIOS

// MARK: - TOSSponsorBlockUndoTests (#20)
//
// checkSponsorSkip's `.skip` branch already sets `activeSkipEnd = seg.end`, which is
// exactly the flag SponsorBlockDecisionEngine checks via `isSkipInProgress` to avoid
// re-triggering a skip already in flight (see
// "skip already in progress returns none" in SponsorBlockDecisionEngineTests — the
// engine-level half of this guarantee). This suite covers the view-model-level wiring:
// an auto-skip populates `recentAutoSkip`, and `undoAutoSkip()` seeks back and clears
// it without touching `activeSkipEnd`, so a re-check at the undone position doesn't
// immediately re-skip.

@Suite("TOS SponsorBlock undo-auto-skip (#20)", .serialized)
@MainActor
struct TOSSponsorBlockUndoTests {

    private func makeVM(segments: [SponsorSegment]) -> TOSPlayerViewModel {
        let vm = TOSPlayerViewModel(videoId: "test_undo_skip", api: InnerTubeAPI())
        var settings = AppSettings()
        settings.sponsorBlockEnabled = true
        settings.sponsorBlockActions = [.sponsor: .skip]
        vm.updateSettings(settings)
        vm.sponsorSegments = segments
        return vm
    }

    @Test("an auto-skip populates recentAutoSkip with the skipped segment")
    func autoSkipPopulatesRecentAutoSkip() {
        let seg = SponsorSegment(start: 10, end: 30, category: .sponsor)
        let vm = makeVM(segments: [seg])

        vm.checkSponsorSkip(at: 15)

        #expect(vm.recentAutoSkip == seg)
        #expect(vm.activeSkipEnd == 30)
    }

    @Test("undoAutoSkip clears recentAutoSkip without touching activeSkipEnd")
    func undoClearsToastButKeepsSkipInProgressFlag() {
        let seg = SponsorSegment(start: 10, end: 30, category: .sponsor)
        let vm = makeVM(segments: [seg])
        vm.checkSponsorSkip(at: 15)
        #expect(vm.recentAutoSkip != nil)

        vm.undoAutoSkip()

        #expect(vm.recentAutoSkip == nil, "the undo toast must dismiss once tapped")
        #expect(
            vm.activeSkipEnd == 30,
            "undo must NOT clear activeSkipEnd — that's the flag isSkipInProgress reads to stop the engine re-triggering a skip the instant the undone seek lands back inside the segment"
        )
    }

    @Test("re-checking at the undone position does not re-trigger a skip")
    func recheckAfterUndoDoesNotReskip() {
        let seg = SponsorSegment(start: 10, end: 30, category: .sponsor)
        let vm = makeVM(segments: [seg])
        vm.checkSponsorSkip(at: 15)
        vm.undoAutoSkip()

        // Simulate the "tick" handler re-checking once playback resumes from the
        // undone position (back inside the segment, e.g. t=10).
        vm.checkSponsorSkip(at: 10)

        #expect(
            vm.activeSkipEnd == 30,
            "a fresh .skip decision would reset activeSkipEnd to the same value, so this alone doesn't prove no re-skip — the real proof is recentAutoSkip below"
        )
        // If checkSponsorSkip had re-triggered `.skip`, it would call
        // showUndoAutoSkipToast again and recentAutoSkip would be non-nil again.
        #expect(
            vm.recentAutoSkip == nil,
            "re-entering the segment right after undo must not immediately re-skip and re-show the undo toast — the user just asked to watch this part"
        )
    }

    @Test("reportIncorrectSegment returns false for a segment with no apiUUID")
    func reportIncorrectSegmentSkipsWithoutApiUUID() async {
        // No apiUUID (nil default) — e.g. a UI-test-injected synthetic segment that
        // doesn't exist on SponsorBlock's servers to vote on.
        let seg = SponsorSegment(start: 10, end: 30, category: .sponsor)
        let vm = makeVM(segments: [seg])

        let ok = await vm.reportIncorrectSegment(seg)

        #expect(!ok)
    }

    @Test("checkSponsorSkip does nothing when SponsorBlock is disabled")
    func disabledSponsorBlockDoesNotSetRecentAutoSkip() {
        let seg = SponsorSegment(start: 10, end: 30, category: .sponsor)
        let vm = TOSPlayerViewModel(videoId: "test_undo_skip_disabled", api: InnerTubeAPI())
        var settings = AppSettings()
        settings.sponsorBlockEnabled = false
        settings.sponsorBlockActions = [.sponsor: .skip]
        vm.updateSettings(settings)
        vm.sponsorSegments = [seg]

        vm.checkSponsorSkip(at: 15)

        #expect(vm.recentAutoSkip == nil)
    }
}
#endif

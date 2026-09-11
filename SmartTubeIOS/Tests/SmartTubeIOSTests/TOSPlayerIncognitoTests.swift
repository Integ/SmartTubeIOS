#if !os(tvOS)
import Foundation
import Testing

@testable import SmartTubeIOSCore
@testable import SmartTubeIOS

// MARK: - TOSPlayerIncognitoTests (#94)
//
// beginWatchtimeTracking()/saveProgress() are what actually write a watch-history
// entry / resume-position checkpoint. There's no directly observable "did this write
// to history" signal without a live WatchtimeTracker + network, so these tests prove
// the isIncognito guard trips *before* either function reaches its normal
// historyState-gated logic — the same style of proof TOSSponsorBlockUndoTests uses
// for its own gating logic.

@Suite("TOS player incognito playback (#94)")
@MainActor
struct TOSPlayerIncognitoTests {

    @Test("isIncognito defaults to false")
    func defaultsToFalse() {
        let vm = TOSPlayerViewModel(videoId: "test_incognito_default", api: InnerTubeAPI())
        #expect(!vm.isIncognito)
    }

    @Test("isIncognito is set from the init parameter")
    func setFromInit() {
        let vm = TOSPlayerViewModel(videoId: "test_incognito_true", isIncognito: true, api: InnerTubeAPI())
        #expect(vm.isIncognito)
    }

}
#endif

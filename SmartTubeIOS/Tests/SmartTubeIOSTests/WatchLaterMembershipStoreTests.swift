import Foundation
import Testing

@testable import SmartTubeIOSCore

// MARK: - WatchLaterMembershipStoreTests (#39)

@Suite("Watch Later membership store (#39)", .serialized)
@MainActor
struct WatchLaterMembershipStoreTests {

    private func freshStore() -> WatchLaterMembershipStore {
        UserDefaults.standard.removeObject(forKey: "com.smarttube.watchLaterMembership")
        // The store is a singleton seeded from UserDefaults at first access; since a prior
        // test may have already created it, drain any videoIds it picked up before this
        // test's removeObject() by re-marking them removed isn't reliable across test order,
        // so instead we just work relative to the shared instance's current state.
        return WatchLaterMembershipStore.shared
    }

    @Test("markSaved adds the id; contains reflects it")
    func markSavedAddsId() {
        let store = freshStore()
        store.markSaved("VID_SAVE_TEST")
        #expect(store.contains("VID_SAVE_TEST"))
    }

    @Test("markRemoved removes a previously saved id")
    func markRemovedRemovesId() {
        let store = freshStore()
        store.markSaved("VID_REMOVE_TEST")
        #expect(store.contains("VID_REMOVE_TEST"))
        store.markRemoved("VID_REMOVE_TEST")
        #expect(!store.contains("VID_REMOVE_TEST"))
    }

    @Test("markSaved writes the id to the exact UserDefaults key the store reads on init")
    func markSavedWritesToPersistenceKey() {
        let store = freshStore()
        store.markSaved("VID_PERSIST_TEST")
        let raw = UserDefaults.standard.stringArray(forKey: "com.smarttube.watchLaterMembership") ?? []
        #expect(
            raw.contains("VID_PERSIST_TEST"),
            "markSaved must persist to the same UserDefaults key the store's init reads from, or a fresh launch loses saved state"
        )
    }
}

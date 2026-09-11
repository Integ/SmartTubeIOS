import Foundation
import Observation

// MARK: - WatchLaterMembershipStore (#39)
//
// Tracks which video IDs this app has saved to (or removed from) the user's Watch
// Later playlist, so VideoCardView can show a "Saved" indicator on a video's card
// wherever it reappears (Home, Search, a channel page, etc.).
//
// IMPORTANT LIMITATION: YouTube's feed/browse responses do not include a per-video
// "is this in my Watch Later" flag, so there is no way to derive this from the API
// without fetching and diffing the entire Watch Later playlist on every card render
// (not practical for feed-sized lists). This store therefore only reflects videos
// added or removed via *this app*, persisted locally across launches — it will not
// know about videos saved from another SmartTube install, the official YouTube app,
// or youtube.com. That's a real gap, but it's still strictly more accurate than no
// indicator at all for the common case (the user saves videos from this app).
@Observable
@MainActor
public final class WatchLaterMembershipStore {
    public static let shared = WatchLaterMembershipStore()

    private static let defaultsKey = "com.smarttube.watchLaterMembership"

    public private(set) var videoIds: Set<String> = []

    private init() {
        videoIds = Set(UserDefaults.standard.stringArray(forKey: Self.defaultsKey) ?? [])
    }

    public func contains(_ videoId: String) -> Bool {
        videoIds.contains(videoId)
    }

    public func markSaved(_ videoId: String) {
        guard videoIds.insert(videoId).inserted else { return }
        persist()
    }

    public func markRemoved(_ videoId: String) {
        guard videoIds.remove(videoId) != nil else { return }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(Array(videoIds), forKey: Self.defaultsKey)
    }
}

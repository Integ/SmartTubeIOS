import Foundation
import Testing

@testable import SmartTubeIOSCore

@Suite("Fresh personalised recommendation batches")
struct RecommendationRefreshTests {
    private enum Failure: Error { case unavailable }

    private actor Pages {
        var requests: [String?] = []
        let pages: [String: VideoGroup]

        init(_ pages: [String: VideoGroup]) { self.pages = pages }

        func fetch(_ token: String?) throws -> VideoGroup {
            requests.append(token)
            guard let page = pages[token ?? "root"] else { throw Failure.unavailable }
            return page
        }
    }

    private func page(_ ids: [String], next: String? = nil) -> VideoGroup {
        VideoGroup(videos: ids.map { Video(id: $0, title: $0, channelTitle: "Channel") }, nextPageToken: next)
    }

    @Test func advancesPersonalisedCursorAndPrioritizesNewVideos() async throws {
        let pages = Pages([
            "next": page(["old", "new-a", "new-a"], next: "more"),
            "more": page(["new-b", "old"]),
        ])
        let result = try await RecommendationRefresh.fetch(
            excluding: ["old"], continuationToken: "next", fetchPage: { try await pages.fetch($0) })
        #expect(result.videos.map(\.id) == ["new-a", "new-b", "old"])
        #expect(result.nextPageToken == nil)
        #expect(await pages.requests == ["next", "more"])
    }

    @Test func expiredCursorRetriesPersonalisedLandingPage() async throws {
        let pages = Pages(["root": page(["fresh"])])
        let result = try await RecommendationRefresh.fetch(
            excluding: ["old"], continuationToken: "expired", fetchPage: { try await pages.fetch($0) })
        #expect(result.videos.map(\.id) == ["fresh"])
        #expect(await pages.requests == ["expired", nil])
    }

    @Test func partialFailurePreservesFetchedVideosAndRetryCursor() async throws {
        let pages = Pages(["root": page(["fresh"], next: "offline")])
        let result = try await RecommendationRefresh.fetch(
            excluding: [], continuationToken: nil, fetchPage: { try await pages.fetch($0) })
        #expect(result.videos.map(\.id) == ["fresh"])
        #expect(result.nextPageToken == "offline")
    }

    @Test func repeatedContinuationCannotLoopForever() async throws {
        let pages = Pages(["repeat": page(["old"], next: "repeat")])
        let result = try await RecommendationRefresh.fetch(
            excluding: ["old"], continuationToken: "repeat", fetchPage: { try await pages.fetch($0) })
        #expect(await pages.requests == ["repeat"])
        #expect(result.videos.map(\.id) == ["old"])
        #expect(result.nextPageToken == nil)
    }

    @Test func boundsRequestsWhenYouTubeKeepsRepeatingVideos() async throws {
        let pages = Pages([
            "root": page(["old"], next: "second"),
            "second": page(["old"], next: "third"),
            "third": page(["old"], next: "fourth"),
        ])
        let result = try await RecommendationRefresh.fetch(
            excluding: ["old"], continuationToken: nil, fetchPage: { try await pages.fetch($0) })
        #expect(await pages.requests.count == RecommendationRefresh.maximumPages)
        #expect(result.nextPageToken == "fourth")
        #expect(result.videos.map(\.id) == ["old"])
    }

    @Test func cancellationIsNotRetried() async {
        await #expect(throws: CancellationError.self) {
            try await RecommendationRefresh.fetch(excluding: [], continuationToken: "next") { _ in
                throw CancellationError()
            }
        }
    }

    @Test func totalFailureIsReportedInsteadOfReplacingTheFeed() async {
        let pages = Pages([:])
        await #expect(throws: Failure.self) {
            try await RecommendationRefresh.fetch(
                excluding: [], continuationToken: nil, fetchPage: { try await pages.fetch($0) })
        }
    }
}

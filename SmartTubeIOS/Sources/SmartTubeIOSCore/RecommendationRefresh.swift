import Foundation

/// Advances the personalised feed without discarding its ranking or visitor session.
enum RecommendationRefresh {
    static let maximumPages = 3
    static let desiredNewVideos = 12

    static func fetch(
        excluding previousIDs: Set<String>,
        continuationToken: String?,
        fetchPage: @Sendable (String?) async throws -> VideoGroup
    ) async throws -> VideoGroup {
        var token = continuationToken
        var visited = Set<String>()
        var seen = Set<String>()
        var videos: [Video] = []
        var result = VideoGroup(title: "Recommended", videos: [])
        for _ in 0..<maximumPages {
            try Task.checkCancellation()
            if let token, !visited.insert(token).inserted {
                result.nextPageToken = nil
                break
            }
            let page: VideoGroup
            do {
                page = try await fetchPage(token)
            } catch {
                if error is CancellationError { throw error }
                try Task.checkCancellation()
                if !videos.isEmpty { break }
                // Continuations can expire. Retry the personalised landing page,
                // never a generic search that loses the account's interests.
                guard token != nil else { throw error }
                token = nil
                continue
            }
            try Task.checkCancellation()
            videos.append(contentsOf: page.videos.filter { seen.insert($0.id).inserted })
            result = page
            token = page.nextPageToken
            let newCount = videos.filter { !previousIDs.contains($0.id) && !$0.isShort }.count
            if newCount >= desiredNewVideos || token == nil { break }
        }
        result.videos = prioritizingNew(videos, excluding: previousIDs)
        return result
    }

    static func prioritizingNew(_ videos: [Video], excluding previousIDs: Set<String>) -> [Video] {
        videos.filter { !previousIDs.contains($0.id) } + videos.filter { previousIDs.contains($0.id) }
    }
}

import Foundation
import Testing

@testable import SmartTubeIOSCore

// MARK: - SmartTubeURLSchemeTests (#84)

@Suite("SmartTubeURLScheme.videoID(from:)")
struct SmartTubeURLSchemeTests {

    @Test("smarttube://video/VIDEO_ID extracts the video ID")
    func videoPathForm() throws {
        let url = try #require(URL(string: "smarttube://video/dQw4w9WgXcQ"))
        #expect(SmartTubeURLScheme.videoID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("smarttube://watch?v=VIDEO_ID extracts the video ID")
    func watchQueryForm() throws {
        let url = try #require(URL(string: "smarttube://watch?v=dQw4w9WgXcQ"))
        #expect(SmartTubeURLScheme.videoID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("smarttube://watch?v=VIDEO_ID with extra query params still extracts the video ID")
    func watchQueryFormWithExtraParams() throws {
        let url = try #require(URL(string: "smarttube://watch?list=PL123&v=dQw4w9WgXcQ&t=30"))
        #expect(SmartTubeURLScheme.videoID(from: url) == "dQw4w9WgXcQ")
    }

    @Test("a non-smarttube scheme returns nil")
    func wrongSchemeReturnsNil() throws {
        let url = try #require(URL(string: "https://video/dQw4w9WgXcQ"))
        #expect(SmartTubeURLScheme.videoID(from: url) == nil)
    }

    @Test("an unrecognized host returns nil")
    func unrecognizedHostReturnsNil() throws {
        let url = try #require(URL(string: "smarttube://channel/UC123"))
        #expect(SmartTubeURLScheme.videoID(from: url) == nil)
    }

    @Test("smarttube://watch with no v= query param returns nil")
    func watchWithoutVideoIDReturnsNil() throws {
        let url = try #require(URL(string: "smarttube://watch?list=PL123"))
        #expect(SmartTubeURLScheme.videoID(from: url) == nil)
    }

    @Test("smarttube://video/ with an empty path returns nil")
    func emptyVideoPathReturnsNil() throws {
        let url = try #require(URL(string: "smarttube://video/"))
        #expect(SmartTubeURLScheme.videoID(from: url) == nil)
    }
}

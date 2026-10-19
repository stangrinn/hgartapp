import XCTest
@testable import HGArt

final class VideoOverlayManagerTests: XCTestCase {
    func testHTTPFailuresNeverOverwriteCachedVideo() throws {
        for status in [404, 500] {
            try withDownload(status: status) { source, response, destination in
                let existing = Data("existing video".utf8)
                try existing.write(to: destination)
                XCTAssertThrowsError(try ARSceneVideoOverlay.cacheDownloadedVideo(at: source, response: response, destination: destination))
                XCTAssertEqual(try Data(contentsOf: destination), existing)
            }
        }
    }

    func testSuccessfulDownloadIsMovedToCache() throws {
        try withDownload(status: 200) { source, response, destination in
            let expected = try Data(contentsOf: source)
            try ARSceneVideoOverlay.cacheDownloadedVideo(at: source, response: response, destination: destination)
            XCTAssertEqual(try Data(contentsOf: destination), expected)
            XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        }
    }

    func testHTMLAndEmptyResponsesAreRejected() throws {
        try withDownload(status: 200, mime: "text/html") { source, response, destination in
            XCTAssertThrowsError(try ARSceneVideoOverlay.cacheDownloadedVideo(at: source, response: response, destination: destination))
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
        try withDownload(status: 200) { source, response, destination in
            try Data().write(to: source)
            XCTAssertThrowsError(try ARSceneVideoOverlay.cacheDownloadedVideo(at: source, response: response, destination: destination))
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
    }

    private func withDownload(status: Int, mime: String = "video/mp4",
                              check: (URL, HTTPURLResponse, URL) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appendingPathComponent("download")
        let destination = folder.appendingPathComponent("cached.mp4")
        try Data("downloaded content".utf8).write(to: source)
        let response = HTTPURLResponse(url: URL(string: "https://example.com/video.mp4")!, statusCode: status,
                                       httpVersion: nil, headerFields: ["Content-Type": mime])!
        try check(source, response, destination)
    }
}

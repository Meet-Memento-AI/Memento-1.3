import XCTest
@testable import MeetMemento

final class ChatResponseDecodingTests: XCTestCase {
    private func data(named name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name).json")
        return try Data(contentsOf: url)
    }

    func test_decode_chatResponse_success_roundTripFields() throws {
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: try data(named: "chat_response_success"))
        XCTAssertEqual(decoded.reply, "Hello from the fixture.")
        XCTAssertNil(decoded.heading1)
        XCTAssertNil(decoded.heading2)
        XCTAssertEqual(decoded.sources.count, 0)
        XCTAssertEqual(decoded.sessionId, "550e8400-e29b-41d4-a716-446655440000")
    }

    func test_decode_chatResponse_withHeadings_andSources() throws {
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: try data(named: "chat_response_success_with_headings"))
        XCTAssertEqual(decoded.heading1, "First heading")
        XCTAssertEqual(decoded.heading2, "Second heading")
        XCTAssertEqual(decoded.sources.count, 1)
        XCTAssertEqual(decoded.sources[0].id, "660e8400-e29b-41d4-a716-446655440001")
        XCTAssertEqual(decoded.sources[0].preview, "Journal excerpt preview")
    }

    func test_decode_chatResponse_emptySources() throws {
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: try data(named: "chat_response_empty_sources"))
        XCTAssertEqual(decoded.sources.count, 0)
        XCTAssertEqual(decoded.reply, "Reply only.")
    }

    func test_decode_chatSource_snakeCaseCreatedAt() throws {
        let json = """
        {"id":"aa","created_at":"2025-03-01T00:00:00Z","preview":"p"}
        """.data(using: .utf8)!
        let s = try JSONDecoder().decode(ChatSource.self, from: json)
        XCTAssertEqual(s.id, "aa")
        XCTAssertEqual(s.createdAt, "2025-03-01T00:00:00Z")
        XCTAssertEqual(s.preview, "p")
    }
}

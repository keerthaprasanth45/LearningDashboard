//
//  MockCourseAPI.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

enum APIError: Error, Equatable {
    case fileNotFound
    case invalidResponse
}

final class MockCourseAPI: CourseAPI {

    /// Injected failure for tests and previews.
    /// The catalog is bundled JSON, so offline behavior is simulated here
    /// instead of reading the device network path.
    private let forcedError: Error?

    init(forcedError: Error? = nil) {
        self.forcedError = forcedError
    }

    func fetchCourses() async throws -> [Course] {
        if let forcedError {
            throw forcedError
        }

        guard let url = Bundle.main.url(
            forResource: "courses",
            withExtension: "json"
        ) else {
            throw APIError.fileNotFound
        }

        let data = try Data(contentsOf: url)

        do {
            return try JSONDecoder().decode([Course].self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}

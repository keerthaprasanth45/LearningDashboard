//
//  CourseAPI.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

protocol CourseAPI {
    /// Loads the course catalog.
    /// A throwing implementation stands in for an offline or failed API.
    func fetchCourses() async throws -> [Course]
}

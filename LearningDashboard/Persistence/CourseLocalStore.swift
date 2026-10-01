//
//  CourseLocalStore.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

protocol CourseLocalStore {
    func save(_ courses: [Course]) throws
    func fetchCourses() throws -> [Course]
}

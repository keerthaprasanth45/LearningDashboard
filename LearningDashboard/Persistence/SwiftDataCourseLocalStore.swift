//
//  SwiftDataCourseLocalStore.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation
import SwiftData

final class SwiftDataCourseLocalStore: CourseLocalStore {

    private let container: ModelContainer

    init() throws {
        let schema = Schema([
            CachedCourse.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    func save(_ courses: [Course]) throws {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<CachedCourse>()
        let existingCourses = try context.fetch(descriptor)

        for course in existingCourses {
            context.delete(course)
        }

        let encoder = JSONEncoder()

        for course in courses {
            let lessonsData = try encoder.encode(course.lessons)

            let cachedCourse = CachedCourse(
                id: course.id,
                title: course.title,
                instructor: course.instructor,
                lessonsData: lessonsData
            )

            context.insert(cachedCourse)
        }

        try context.save()
    }

    func fetchCourses() throws -> [Course] {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<CachedCourse>()
        let cachedCourses = try context.fetch(descriptor)

        let decoder = JSONDecoder()

        return try cachedCourses.map { cachedCourse in
            let lessons = try decoder.decode(
                [Lesson].self,
                from: cachedCourse.lessonsData
            )

            return Course(
                id: cachedCourse.id,
                title: cachedCourse.title,
                instructor: cachedCourse.instructor,
                lessons: lessons
            )
        }
    }
}

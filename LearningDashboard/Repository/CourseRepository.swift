//
//  CourseRepository.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

final class CourseRepository {

    private let api: CourseAPI
    private let localStore: CourseLocalStore

    init(
        api: CourseAPI,
        localStore: CourseLocalStore
    ) {
        self.api = api
        self.localStore = localStore
    }

    func fetchCourses() async throws -> [Course] {
        do {
            let remoteCourses = try await api.fetchCourses()
            let cachedCourses = (try? localStore.fetchCourses()) ?? []

            // The mock catalog is static JSON. Keep completion flags already
            // saved on device so the next successful fetch does not reset them.
            let courses = mergingCompletion(
                from: cachedCourses,
                into: remoteCourses
            )
            .sorted { $0.id < $1.id }

            try localStore.save(courses)

            return courses

        } catch let apiError {
            let cachedCourses = try localStore.fetchCourses()

            guard !cachedCourses.isEmpty else {
                throw apiError
            }

            return cachedCourses.sorted { $0.id < $1.id }
        }
    }

    func saveCourses(_ courses: [Course]) throws {
        try localStore.save(courses)
    }

    private func mergingCompletion(
        from cachedCourses: [Course],
        into remoteCourses: [Course]
    ) -> [Course] {
        guard !cachedCourses.isEmpty else {
            return remoteCourses
        }

        var completionByCourse: [Int: [Int: Bool]] = [:]

        for course in cachedCourses {
            var completionByLesson: [Int: Bool] = [:]

            for lesson in course.lessons {
                completionByLesson[lesson.id] = lesson.completed
            }

            completionByCourse[course.id] = completionByLesson
        }

        return remoteCourses.map { course in
            guard let completionByLesson = completionByCourse[course.id] else {
                return course
            }

            var course = course

            course.lessons = course.lessons.map { lesson in
                guard let completed = completionByLesson[lesson.id] else {
                    return lesson
                }

                var lesson = lesson
                lesson.completed = completed
                return lesson
            }

            return course
        }
    }
}

//
//  CourseDashboardViewModel.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Combine
import Foundation

enum CourseListState {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

@MainActor
final class CourseDashboardViewModel: ObservableObject {

    @Published private(set) var courses: [Course] = []
    @Published private(set) var state: CourseListState = .idle
    @Published private(set) var persistenceError: String?

    private let repository: CourseRepository

    init(repository: CourseRepository) {
        self.repository = repository
    }

    func course(withID id: Int) -> Course? {
        courses.first { $0.id == id }
    }

    func loadCourses() async {
        if courses.isEmpty {
            state = .loading
        }

        do {
            let loadedCourses = try await repository.fetchCourses()

            courses = loadedCourses
            persistenceError = nil
            state = loadedCourses.isEmpty ? .empty : .loaded

        } catch {
            if courses.isEmpty {
                state = .error("Unable to load courses. Please try again.")
            }
        }
    }

    func toggleLesson(
        courseID: Int,
        lessonID: Int
    ) {
        guard let courseIndex = courses.firstIndex(
            where: { $0.id == courseID }
        ) else {
            return
        }

        guard let lessonIndex = courses[courseIndex].lessons.firstIndex(
            where: { $0.id == lessonID }
        ) else {
            return
        }

        var updatedCourses = courses
        updatedCourses[courseIndex].lessons[lessonIndex].completed.toggle()

        do {
            try repository.saveCourses(updatedCourses)
            courses = updatedCourses
            persistenceError = nil
            state = .loaded
        } catch {
            persistenceError = "Couldn't save your progress. Please try again."
        }
    }
}

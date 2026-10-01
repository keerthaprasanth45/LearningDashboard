//
//  LearningDashboardTests.swift
//  LearningDashboardTests
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Testing
@testable import LearningDashboard

@MainActor
struct CourseProgressTests {

    @Test func twoOfFourCompletedLessonsIsFiftyPercent() {
        let course = makeCourse(
            id: 1,
            completed: [true, true, false, false]
        )

        #expect(course.progress == 50)
    }

    @Test func allCompletedLessonsIsOneHundredPercent() {
        let course = makeCourse(
            id: 1,
            completed: [true, true, true, true, true]
        )

        #expect(course.progress == 100)
    }

    @Test func courseWithNoLessonsIsZeroPercent() {
        let course = makeCourse(id: 1, completed: [])

        #expect(course.progress == 0)
    }
}

@MainActor
struct CourseRepositoryTests {

    @Test func successfulFetchReturnsCoursesAndCachesThem() async throws {
        let courses = [
            makeCourse(id: 2, completed: [true]),
            makeCourse(id: 1, completed: [false, true])
        ]
        let api = StubCourseAPI(result: .success(courses))
        let store = InMemoryCourseLocalStore()
        let repository = CourseRepository(api: api, localStore: store)

        let loaded = try await repository.fetchCourses()

        #expect(loaded.map(\.id) == [1, 2])
        #expect(try store.fetchCourses().map(\.id) == [1, 2])
        #expect(api.fetchCount == 1)
    }

    @Test func failedFetchReturnsCachedCourses() async throws {
        let cached = [makeCourse(id: 1, completed: [true, false])]
        let api = StubCourseAPI(result: .failure(APIError.fileNotFound))
        let store = InMemoryCourseLocalStore(courses: cached)
        let repository = CourseRepository(api: api, localStore: store)

        let loaded = try await repository.fetchCourses()

        #expect(loaded == cached)
        #expect(api.fetchCount == 1)
    }

    @Test func failedFetchWithEmptyCacheThrowsTheAPIError() async {
        let api = StubCourseAPI(result: .failure(APIError.fileNotFound))
        let store = InMemoryCourseLocalStore()
        let repository = CourseRepository(api: api, localStore: store)

        await #expect(throws: APIError.fileNotFound) {
            try await repository.fetchCourses()
        }
    }

    @Test func successfulFetchKeepsCachedLessonCompletion() async throws {
        let cached = makeCourse(id: 1, completed: [true, false])
        var remote = cached
        remote.lessons[0].completed = false
        remote.lessons.append(
            Lesson(id: 199, title: "New Lesson", completed: false)
        )

        let api = StubCourseAPI(result: .success([remote]))
        let store = InMemoryCourseLocalStore(courses: [cached])
        let repository = CourseRepository(api: api, localStore: store)

        let loaded = try await repository.fetchCourses()

        #expect(loaded[0].lessons[0].completed)
        #expect(loaded[0].lessons[1].completed == false)
        #expect(loaded[0].lessons[2].completed == false)
        #expect(try store.fetchCourses() == loaded)
    }

    @Test func saveCoursesWritesLocallyWithoutCallingTheAPI() async throws {
        let courses = [makeCourse(id: 1, completed: [true])]
        let api = StubCourseAPI(result: .failure(APIError.invalidResponse))
        let store = InMemoryCourseLocalStore()
        let repository = CourseRepository(api: api, localStore: store)

        try repository.saveCourses(courses)

        #expect(api.fetchCount == 0)
        #expect(try store.fetchCourses() == courses)
    }
}

@MainActor
struct CourseDashboardViewModelTests {

    @Test func toggleLessonPersistsWithoutFetchingAgain() async throws {
        let course = makeCourse(id: 1, completed: [false, true])
        let api = StubCourseAPI(result: .success([course]))
        let store = InMemoryCourseLocalStore()
        let viewModel = CourseDashboardViewModel(
            repository: CourseRepository(api: api, localStore: store)
        )

        await viewModel.loadCourses()
        viewModel.toggleLesson(courseID: 1, lessonID: course.lessons[0].id)

        #expect(viewModel.course(withID: 1)?.lessons[0].completed == true)
        #expect(viewModel.course(withID: 1)?.progress == 100)
        #expect(viewModel.persistenceError == nil)
        #expect(api.fetchCount == 1)
        #expect(try store.fetchCourses().first?.lessons[0].completed == true)
    }

    @Test func toggleLessonKeepsThePreviousValueWhenSavingFails() async throws {
        let course = makeCourse(id: 1, completed: [false])
        let api = StubCourseAPI(result: .success([course]))
        let store = InMemoryCourseLocalStore()
        let viewModel = CourseDashboardViewModel(
            repository: CourseRepository(api: api, localStore: store)
        )

        await viewModel.loadCourses()
        store.saveError = APIError.invalidResponse
        viewModel.toggleLesson(courseID: 1, lessonID: course.lessons[0].id)

        #expect(viewModel.course(withID: 1)?.lessons[0].completed == false)
        #expect(viewModel.persistenceError != nil)
        #expect(try store.fetchCourses().first?.lessons[0].completed == false)
    }
}

@MainActor
private func makeCourse(id: Int, completed: [Bool]) -> Course {
    Course(
        id: id,
        title: "Course \(id)",
        instructor: "Instructor \(id)",
        lessons: completed.enumerated().map { offset, isCompleted in
            Lesson(
                id: (id * 100) + offset + 1,
                title: "Lesson \(offset + 1)",
                completed: isCompleted
            )
        }
    )
}

@MainActor
private final class StubCourseAPI: CourseAPI {

    var result: Result<[Course], Error>
    private(set) var fetchCount = 0

    init(result: Result<[Course], Error>) {
        self.result = result
    }

    func fetchCourses() async throws -> [Course] {
        fetchCount += 1

        switch result {
        case .success(let courses):
            return courses
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class InMemoryCourseLocalStore: CourseLocalStore {

    var courses: [Course]
    var saveError: Error?

    init(courses: [Course] = []) {
        self.courses = courses
    }

    func save(_ courses: [Course]) throws {
        if let saveError {
            throw saveError
        }

        self.courses = courses
    }

    func fetchCourses() throws -> [Course] {
        courses
    }
}

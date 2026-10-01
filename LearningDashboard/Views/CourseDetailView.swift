//
//  CourseDetailView.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import SwiftUI

struct CourseDetailView: View {

    @ObservedObject var viewModel: CourseDashboardViewModel
    let courseID: Int

    private var course: Course? {
        viewModel.course(withID: courseID)
    }

    var body: some View {
        Group {
            if let course {
                courseContent(course)
            } else {
                ContentUnavailableView(
                    "Course Unavailable",
                    systemImage: "book.closed",
                    description: Text("This course could not be found.")
                )
            }
        }
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func courseContent(_ course: Course) -> some View {
        List {
            if let persistenceError = viewModel.persistenceError {
                Text(persistenceError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(course.title)
                        .font(.title2.bold())

                    Text("Instructor: \(course.instructor)")
                        .foregroundStyle(.secondary)

                    ProgressView(
                        value: Double(course.progress),
                        total: 100
                    )

                    Text("\(course.progress)% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Lessons") {
                ForEach(course.lessons) { lesson in
                    Button {
                        viewModel.toggleLesson(
                            courseID: course.id,
                            lessonID: lesson.id
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(
                                systemName: lesson.completed
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundStyle(
                                lesson.completed ? .green : .secondary
                            )

                            Text(lesson.title)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(lesson.completed ? "Completed" : "Not completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(lesson.title)
                    .accessibilityValue(
                        lesson.completed ? "Completed" : "Not completed"
                    )
                }
            }
        }
    }
}

#Preview {
    CourseDetailPreviewHost()
}

private struct CourseDetailPreviewHost: View {

    @StateObject private var viewModel: CourseDashboardViewModel

    init() {
        let repository = CourseRepository(
            api: PreviewCourseAPI(),
            localStore: PreviewCourseStore()
        )

        _viewModel = StateObject(
            wrappedValue: CourseDashboardViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            CourseDetailView(viewModel: viewModel, courseID: 1)
        }
        .task {
            await viewModel.loadCourses()
        }
    }
}

private final class PreviewCourseAPI: CourseAPI {

    func fetchCourses() async throws -> [Course] {
        [
            Course(
                id: 1,
                title: "Swift Programming",
                instructor: "John Smith",
                lessons: [
                    Lesson(id: 1, title: "Introduction", completed: true),
                    Lesson(id: 2, title: "Swift Basics", completed: false)
                ]
            )
        ]
    }
}

private final class PreviewCourseStore: CourseLocalStore {

    private var courses: [Course] = []

    func save(_ courses: [Course]) throws {
        self.courses = courses
    }

    func fetchCourses() throws -> [Course] {
        courses
    }
}

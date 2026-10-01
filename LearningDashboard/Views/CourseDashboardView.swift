//
//  CourseDashboardView.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import SwiftUI

struct CourseDashboardView: View {

    @StateObject private var viewModel: CourseDashboardViewModel

    init() {
        do {
            let localStore = try SwiftDataCourseLocalStore()
            let api = MockCourseAPI()

            let repository = CourseRepository(
                api: api,
                localStore: localStore
            )

            _viewModel = StateObject(
                wrappedValue: CourseDashboardViewModel(
                    repository: repository
                )
            )

        } catch {
            fatalError(
                "Failed to initialize local storage: \(error)"
            )
        }
    }

    var body: some View {
        Group {
            switch viewModel.state {

            case .idle, .loading:
                loadingView

            case .loaded:
                courseList

            case .empty:
                emptyView

            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("My Courses")
        .task {
            await viewModel.loadCourses()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Loading courses...")
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    private var courseList: some View {
        List {
            if let persistenceError = viewModel.persistenceError {
                Text(persistenceError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .listRowSeparator(.hidden)
            }

            ForEach(viewModel.courses) { course in
                NavigationLink {
                    CourseDetailView(
                        viewModel: viewModel,
                        courseID: course.id
                    )
                } label: {
                    CourseRowView(course: course)
                }
                .navigationLinkIndicatorVisibility(.hidden)
            }
        }
        .listStyle(.plain)
    }
    

    private var emptyView: some View {
        ContentUnavailableView(
            "No Courses",
            systemImage: "book.closed",
            description: Text(
                "There are no courses available."
            )
        )
    }

    private func errorView(
        _ message: String
    ) -> some View {

        ContentUnavailableView {
            Label(
                "Something went wrong",
                systemImage: "exclamationmark.triangle"
            )

        } description: {
            Text(message)

        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.loadCourses()
                }
            }
        }
    }
}

private struct CourseRowView: View {

    let course: Course

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(course.title)
                .font(.headline)

            Text(
                "Instructor: \(course.instructor)"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ProgressView(
                value: Double(course.progress),
                total: 100
            )

            HStack {
                Text("\(course.progress)% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(lessonCount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Continue")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor, in: Capsule())
        }
        .padding(.vertical, 8)
    }

    private var lessonCount: String {
        let count = course.lessons.count
        return count == 1 ? "1 lesson" : "\(count) lessons"
    }
}

#Preview {
    NavigationStack {
        CourseDashboardView()
    }
}

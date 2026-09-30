//
//  Course.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

struct Course: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let instructor: String
    var lessons: [Lesson]

    var progress: Int {
        guard !lessons.isEmpty else {
            return 0
        }

        let completedLessons = lessons.filter(\.completed).count

        return Int(
            (Double(completedLessons) / Double(lessons.count)) * 100
        )
    }
}

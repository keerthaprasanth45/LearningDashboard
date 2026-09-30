//
//  Lesson.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation

struct Lesson: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    var completed: Bool
}

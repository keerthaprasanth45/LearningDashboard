//
//  CachedCourse.swift
//  LearningDashboard
//
//  Created by Keerthaprasanth on 30/09/26.
//

import Foundation
import SwiftData

@Model
final class CachedCourse {
    var id: Int
    var title: String
    var instructor: String
    var lessonsData: Data

    init(
        id: Int,
        title: String,
        instructor: String,
        lessonsData: Data
    ) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.lessonsData = lessonsData
    }
}

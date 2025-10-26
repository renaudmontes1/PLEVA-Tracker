//
//  Item.swift
//  PLEVA Tracker
//
//  Created by Renaud Montes on 3/7/25.
//

import Foundation
import SwiftData

@Model
public final class DiaryEntry {
    @Attribute(originalName: "timestamp") public var timestamp: Date = Date()
    @Attribute(originalName: "notes") public var notes: String = ""
    @Attribute(originalName: "severity") public var severity: Int = 1
    @Attribute(originalName: "photos") public var photos: [Data] = []
    @Attribute(originalName: "location") public var location: String = ""
    public var weeklySummary: String?
    public var summaryDate: Date?
    @Attribute(originalName: "papulesFace") public var papulesFace: Int = 0
    @Attribute(originalName: "papulesNeck") public var papulesNeck: Int = 0
    @Attribute(originalName: "papulesChest") public var papulesChest: Int = 0
    @Attribute(originalName: "papulesLeftArm") public var papulesLeftArm: Int = 0
    @Attribute(originalName: "papulesRightArm") public var papulesRightArm: Int = 0
    @Attribute(originalName: "papulesBack") public var papulesBack: Int = 0
    @Attribute(originalName: "papulesButtocks") public var papulesButtocks: Int = 0
    @Attribute(originalName: "papulesLeftLeg") public var papulesLeftLeg: Int = 0
    @Attribute(originalName: "papulesRightLeg") public var papulesRightLeg: Int = 0
    @Attribute(originalName: "papulesBelly") public var papulesBelly: Int = 0
    @Attribute(originalName: "papulesLeftFoot") public var papulesLeftFoot: Int = 0
    @Attribute(originalName: "papulesRightFoot") public var papulesRightFoot: Int = 0
    
    public init(timestamp: Date = Date(),
         notes: String = "",
         severity: Int = 1,
         photos: [Data] = [],
         location: String = "",
         weeklySummary: String? = nil,
         summaryDate: Date? = nil,
         papulesFace: Int = 0,
         papulesNeck: Int = 0,
         papulesChest: Int = 0,
         papulesLeftArm: Int = 0,
         papulesRightArm: Int = 0,
         papulesBack: Int = 0,
         papulesButtocks: Int = 0,
         papulesLeftLeg: Int = 0,
         papulesRightLeg: Int = 0,
         papulesBelly: Int = 0,
         papulesLeftFoot: Int = 0,
         papulesRightFoot: Int = 0) {
        self.timestamp = timestamp
        self.notes = notes
        self.severity = severity
        self.photos = photos
        self.location = location
        self.weeklySummary = weeklySummary
        self.summaryDate = summaryDate
        self.papulesFace = papulesFace
        self.papulesNeck = papulesNeck
        self.papulesChest = papulesChest
        self.papulesLeftArm = papulesLeftArm
        self.papulesRightArm = papulesRightArm
        self.papulesBack = papulesBack
        self.papulesButtocks = papulesButtocks
        self.papulesLeftLeg = papulesLeftLeg
        self.papulesRightLeg = papulesRightLeg
        self.papulesBelly = papulesBelly
        self.papulesLeftFoot = papulesLeftFoot
        self.papulesRightFoot = papulesRightFoot
    }
}

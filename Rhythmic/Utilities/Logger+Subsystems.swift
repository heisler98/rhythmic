//
//  Logger+Subsystems.swift
//  Rhythmic
//
//  Created by Hunter Eisler on 8/11/20.
//

import Foundation
import os

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let audioIO = Logger(subsystem: subsystem, category: "audioIO")
}

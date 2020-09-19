//
//  FileFinder.swift
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/18/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//

import Foundation

class FileFinder {
    let fileManager = FileManager.default
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   
    func newFiles() -> [String]? {
        return try? fileManager.contentsOfDirectory(atPath: documentsDir.path).filter { $0.contains(".") && !$0.hasPrefix(".")}
    }
}

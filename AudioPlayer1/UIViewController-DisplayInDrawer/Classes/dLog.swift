//  Copyright © 2017 Inloop s.r.o. All rights reserved.

import Foundation

func dLog(_ message:  @autoclosure () -> Any, filename: NSString = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    NSLog("[\(filename.lastPathComponent):\(line)] \(function) - %@", String(describing: message()))
    #endif
}

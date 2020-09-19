//
//  AudioPlayer1-Bridging-Header.h
//  AudioPlayer1
//
//  Created by Hunter Eisler on 10/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//

#ifndef AudioPlayer1_Bridging_Header_h
#define AudioPlayer1_Bridging_Header_h
#import <Foundation/Foundation.h>

@interface EssentiaTempoHandler : NSObject

- (float) analyzeRhythm: (NSURL *) url;

@end
#endif /* AudioPlayer1_Bridging_Header_h */


//
//  EssentiaTempoHandler.mm
//  AudioPlayer1
//
//  Created by Hunter Eisler on 9/17/20.
//  Copyright © 2020 Hunter Eisler. All rights reserved.
//
/**
 Used the following libraries:
 - Essentia
 - eric(k?)/libsamplerate
 - ffmpeg including libavsample
 - 
 */
#include "AudioPlayer1-Bridging-Header.h"
#include "algorithmfactory.h"
#include "essentiamath.h"
#include "poolstorage.h"
#include "network.h"
using namespace std;
using namespace essentia;
using namespace essentia::streaming;
using namespace essentia::scheduler;

@implementation EssentiaTempoHandler : NSObject

- (float) analyzeRhythm: (NSURL *)url {
    essentia::init();
    Pool pool;
    
    string audioFilename = [self convertURLToString:url];
    if (audioFilename.empty() == TRUE) {
        return 120;
    }
    // create the algorithm factory
    streaming::AlgorithmFactory& factory = streaming::AlgorithmFactory::instance();
    
    // create the MonoLoader and RhythmExtractor2013
    Algorithm *monoLoader = factory.create("MonoLoader", "filename", audioFilename);
    Algorithm *extractor = factory.create("RhythmExtractor2013");
    
    monoLoader->configure("sampleRate", 44100.);
    
    // Connect the algorithms
    monoLoader->output("audio") >> extractor->input("signal");
    
    extractor->output("bpm") >> PC(pool, "bpm");
    extractor->output("ticks") >> NOWHERE;
    extractor->output("confidence") >> NOWHERE;
    extractor->output("estimates") >> NOWHERE;
    extractor->output("bpmIntervals") >> NOWHERE;
    
    Network network(monoLoader);
    network.run();
    
    Real bpm;
    if (pool.contains<Real>("bpm")) {
        bpm = pool.value<Real>("bpm");
    } else {
        bpm = 120;
    }
    
    essentia::shutdown();
    return bpm;
}

- (string) convertURLToString: (NSURL *)url {
    if (![url checkResourceIsReachableAndReturnError:NULL]) {
        // resource is not reachable;
        return "";
    }
    if ([[url scheme] isEqualToString:@"file"]) {
        return [[url path] UTF8String];
    } else {
        return [[url absoluteString] UTF8String];
    }
}

@end

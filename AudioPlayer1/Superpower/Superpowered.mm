//
//  Superpowered.mm
//  BPMAnalyzer
//
//  Created by Gleb Karpushkin on 29/03/2017.
//  Copyright © 2017 Gleb Karpushkin. All rights reserved.
//

#include "AudioPlayer1-Bridging-Header.h"
#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAnalyzer.h"

@implementation Superpowered : NSObject 

- (float)offlineAnalyze:(NSURL *)url {
    // Open the input file.
    if (![url checkResourceIsReachableAndReturnError:NULL]) {
        NSLog(@"Resource is not reachable");
        return 0;
    }
    SuperpoweredDecoder *decoder = new SuperpoweredDecoder();
    const char *openError;
    if ([[url scheme] isEqualToString:@"file"]) {
        openError = decoder->open([[url path] UTF8String], false, 0, 0);
    } else {
        openError = decoder->open([[url absoluteString] UTF8String], false, 0, 0);
    }
    
    if (openError) {
        NSLog(@"open error: %s", openError);
        delete decoder;
        return 0;
    };
    
    // Create the analyzer.
    SuperpoweredOfflineAnalyzer *analyzer = new SuperpoweredOfflineAnalyzer(decoder->samplerate, 0, decoder->durationSeconds);
    
    // Create a buffer for the 16-bit integer samples coming from the decoder.
    short int *intBuffer = (short int *)malloc(decoder->samplesPerFrame * 2 * sizeof(short int) + 32768);
    // Create a buffer for the 32-bit floating point samples required by the effect.
    float *floatBuffer = (float *)malloc(decoder->samplesPerFrame * 2 * sizeof(float) + 32768);
    
    // Processing.
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        unsigned int samplesDecoded = decoder->samplesPerFrame;
        if (decoder->decode(intBuffer, &samplesDecoded) == SUPERPOWEREDDECODER_ERROR) break;
        if (samplesDecoded < 1) break;
        
        // Convert the decoded PCM samples from 16-bit integer to 32-bit floating point.
        SuperpoweredShortIntToFloat(intBuffer, floatBuffer, samplesDecoded);
        
        // Submit samples to the analyzer.
        analyzer->process(floatBuffer, samplesDecoded);
        
    };
    
    // Get the result.
    float bpm = 0;
    analyzer->getresults(nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, &bpm, nil, nil);
    
    // Cleanup.
    delete decoder;
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
    
    return bpm;
}

@end

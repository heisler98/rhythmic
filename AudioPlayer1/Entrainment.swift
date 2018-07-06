//
//  Entrainment.swift
//  Rhythmic | AudioPlayer1
//
//  Created by Hunter Eisler on 6/24/18.
//  Copyright © 2018 Hunter Eisler. All rights reserved.
//
//  Freq. range 20-14000Hz

import Foundation
import AudioKit

class Entrainment {
    
    fileprivate static let waveform = AKTable(.sine, count: 4096)
    private lazy var lowerBinauralOsc : AKOscillator = osc()
    private lazy var upperBinauralOsc : AKOscillator = osc()
    private var mixer : AKMixer?
    
    private var clarinet : AKClarinet?
    private var bCallback : AKPeriodicFunction?
    private var panner : AKPanner?
    
    private lazy var isochronicOsc : AKOscillator = osc()
    private var iCallback : AKPeriodicFunction?
    
    /// Play binaural beats
    func binaural(midFrequency freq : NSNumber) {
        lowerBinauralOsc.frequency = freq.doubleValue-5
        upperBinauralOsc.frequency = freq.doubleValue+5
        
        let lowerPan = AKPanner(lowerBinauralOsc)
        lowerPan.pan = -1
        
        let upperPan = AKPanner(upperBinauralOsc)
        upperPan.pan = 1
        
        mixer = AKMixer(lowerPan, upperPan)
        AudioKit.output = mixer!
        
        do {
            try AudioKit.start()
            lowerBinauralOsc.start()
            upperBinauralOsc.start()
            mixer!.start()
        } catch {
            print(error)
        }
    }
    
    /// Stop binaural playback
    func stopBinaural() {
        guard let _ = mixer else { return }
        mixer!.stop()
        lowerBinauralOsc.stop()
        upperBinauralOsc.stop()
        
    }
    
    /// Start bilateral beats
    func bilateral(tonalFrequency : NSNumber, period : NSNumber) {
        clarinet = AKClarinet(frequency: tonalFrequency.doubleValue, amplitude: 0.5)
        panner = AKPanner(clarinet!)
        panner!.pan = -1
        
        bCallback = AKPeriodicFunction(every: period.doubleValue, handler: {
            self.panner!.pan *= -1
            self.clarinet!.trigger()
        })
        
        AudioKit.output = panner!
        
        do {
            try AudioKit.start(withPeriodicFunctions: bCallback!)
            clarinet!.start()
            panner!.start()
            bCallback!.start()
        } catch {
            print(error)
        }
        
    }
    
    /// Stop bilateral playback
    func stopBilateral() {
        guard let _ = panner else { return }
        guard let _ = bCallback else { return }
        clarinet?.stop()
        panner!.stop()
        bCallback!.stop()
        
        
    }
    
    /// Start isochronic tones
    func isochronic(tonalFrequency : NSNumber, brainwaveTarget target : NSNumber) {
        
        isochronicOsc.frequency = tonalFrequency.doubleValue
        iCallback = AKPeriodicFunction(frequency: target.doubleValue, handler: {
            self.isochronicOsc.amplitude = (self.isochronicOsc.amplitude == 1) ? 0 : 1
        })
        
        AudioKit.output = isochronicOsc
        
        do {
            try AudioKit.start(withPeriodicFunctions: iCallback!)
            isochronicOsc.start()
            iCallback!.start()
        } catch {
            print(error)
        }
        
    }
    
    /// Stop isochronic tone playback
    func stopIsochronic() {
        guard let _ = iCallback else { return }
        iCallback!.stop()
        isochronicOsc.stop()
    }
    
    /// Stop all audio playback and reset oscillators
    func stopAudio() {
        try? AudioKit.stop()
        stopBinaural()
        stopBilateral()
        stopIsochronic()
    }
    
}

func osc() -> AKOscillator {
    return AKOscillator(waveform: Entrainment.waveform)
}

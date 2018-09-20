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

// MARK: - Convenience oscillator return
let osc : () -> AKOscillator = {
    return AKOscillator(waveform: Entrainment.waveform)
}
// binaural:midFreq:
// bilateral:tonalFreq:period:
// isochronic:tonalFreq:brainwaveTarget:
public enum EntrainmentType {
    case Binaural(freq: Double)
    case Bilateral(freq: Double, period: Double)
    case Isochronic(freq: Double, target: Double)
}

// MARK: - Entrainment
public class Entrainment {
    
    // MARK: - Private properties
    fileprivate static let waveform = AKTable(.sine)
    private lazy var lowerBinauralOsc : AKOscillator = osc()
    private lazy var upperBinauralOsc : AKOscillator = osc()
    private var mixer : AKMixer?
    
    private var bilateralOsc : AKOscillator = osc()
    private var bCallback : AKPeriodicFunction?
    private var panner : AKPanner?
    
    private lazy var isochronicOsc : AKOscillator = osc()
    private var iCallback : AKPeriodicFunction?
    
    // MARK: - Public properties
    public var isPlaying : Bool {
        get {
            return lowerBinauralOsc.isStarted || bilateralOsc.isStarted || isochronicOsc.isStarted
        }
    }
    
    // MARK: - Entrainment methods
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
        bilateralOsc.frequency = tonalFrequency.doubleValue
        panner = AKPanner(bilateralOsc)
        panner!.pan = -1
        
        bCallback = AKPeriodicFunction(every: period.doubleValue, handler: {
            self.panner!.pan *= -1
        })
        
        AudioKit.output = panner!
        
        do {
            try AudioKit.start(withPeriodicFunctions: bCallback!)
            bilateralOsc.start()
            panner!.start()
            bCallback!.start()
        } catch {
            print(error)
        }
        
    }
    
    func changeBilateralPeriod(to : NSNumber) throws {
        guard let _ = bCallback, let _ = panner else {
            throw NSError(domain: "EntrainNotInited", code: 1, userInfo: nil)
        }
        if !bCallback!.isStarted || !bilateralOsc.isStarted {
            throw NSError(domain: "EntrainNotPlaying", code: 1, userInfo: nil)
        }
        
        bilateralOsc.stop()
        bCallback = AKPeriodicFunction(every: to.doubleValue, handler: {
            self.panner!.pan *= -1
        })
        do {
            try AudioKit.start(withPeriodicFunctions: bCallback!)
            bilateralOsc.start()
            bCallback!.start()
        } catch {
            print(error)
        }
    }
    
    /// Stop bilateral playback
    func stopBilateral() {
        guard let _ = panner else { return }
        guard let _ = bCallback else { return }
        bilateralOsc.stop()
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
        stopBinaural()
        stopBilateral()
        stopIsochronic()
    }
    
    init() {
        
    }
}


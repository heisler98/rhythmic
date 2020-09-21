# Rhythmic
A bilateral stimulation music player for iOS

Rhythmic is a simple BLS music player for iOS. Add songs via iTunes, File Sharing, or AirDrop, and Rhythmic will rhythmically pan the L/R balance at the tempo of the song. 

## Compilation
*Please see AudioPlayer1/Essentia Licensing.txt for license information. Rhythmic contains third-party libraries that are licensed under LGPLv3, GPL, and others.*

To build, Rhythmic requires the following libraries: 
- Accelerate.framework
- AVFoundation.framework
- CoreGraphics.framework
- libavcodec.a ([ffmpeg](https://www.ffmpeg.org))
- libavdevice.a (ffmpeg)
- libavfilter.a (ffmpeg)
- libavformat.a (ffmpeg)
- libavresample.a (ffmpeg)
- libavutil.a (ffmpeg)
- libswresample.a (ffmpeg)
- libswscale.a (ffmpeg)
- libbz2.tbd
- libiconv.tbd
- libz.tbd
- MediaPlayer.framework
- StoreKit.framework
- VideoToolbox.framework
- libessentia.a ([Essentia](http://essentia.upf.edu))
- libsamplerate.a ([erikd/libsamplerate](https://github.com/erikd/libsamplerate))


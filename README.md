### miniaudio_ffi

This package is designed to hold the only the dart bindings to the attached miniaudio library, so it can be used without Flutter. 

## Features

This packages currently wraps the following miniaudio APIs

- miniaudio converter
- miniaudio decoder
- miniaudio device
- miniaudio ring buffer.

Some of the APIs are using a NativeFinalizer, so they don't need to be disposed early, but do keep in mind the caveats that Dart will finalize the native resources as soon as the object is unreachable.

## Getting started

You should get ahold of a copy of miniaudio compiled as a DLL with the features you're going to use, or otherwise, statically link it to some executable, since Dart's Dynamic library constructor can adapt to it.

After that, you should initialize the bindings.

You may use the static function [MiniAudioBindings.getFlutterBindings] to automatically initialize the bindings while loading the expected shared library object for each platform it's running on, when using the miniaudio_flutter package (to be released).

## Usage

First initialize the library, then use any of the provided APIs to use miniaudio.

Player example (error checking is skipped for brevity): 

```dart
void main(List<String> arguments){
    try {
        final audioFilePath = arguments.first;
        final ffi = MiniAudioBindings.getFlutterBindings();
        final decoder = MiniAudioDecoder.openPath(ffi, audioFilePath);
        final device = MiniAudioDevice.playbackDevice(
            playbackFormat: decoder.format,
            channels: decoder.channelCount,
            sampleRate: sampleRate,
            dataCallback: 'Instead of this string, point this to a C callback that will provide the samples on a different thread (a Dart function can\'t work ATM since running Dart code outside of an isolate aborts the process and this callback gets called by miniaudio on a different thread)',
            userData: decoder.decoder.ref, // I'm passing the decoder struct by pointer, but you may pass anything else that has samples.
        );
        device.startDevice();
        // You might want to keep the decoder as a static variable so it doesn't get removed, but this is just because dart's GC can't see that the native resources are being used in C.
        await Future.delayed(Duration(seconds: 30));
    } catch (e){
        // Ignore exception.
    }    
}
```

## Additional information

It is very recommended you read the miniaudio documentation in [miniaud.io](https://miniaud.io/docs/) so you familiarize with the some of the return values this library exposes directly to the user.




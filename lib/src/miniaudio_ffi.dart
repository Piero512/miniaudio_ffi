import 'dart:ffi';
import 'dart:io';

import 'miniaudio_ringbuffer.dart';

import 'miniaudio_decode.dart';
import 'miniaudio_device.dart';
import 'miniaudio_bindings.dart';
import 'miniaudio_converter.dart';

class MiniAudio {
  static MiniAudioBindings getFlutterBindings() {
    if (Platform.isAndroid || Platform.isLinux) {
      return MiniAudioBindings(DynamicLibrary.open('libminiaudio.so'));
    } else if (Platform.isMacOS) {
      return MiniAudioBindings(DynamicLibrary.open('libminiaudio.dylib'));
    } else if (Platform.isIOS) {
      var lib = DynamicLibrary.open('miniaudio.framework/miniaudio');
      return MiniAudioBindings(lib);
    } else if (Platform.isWindows) {
      return MiniAudioBindings(DynamicLibrary.open('miniaudio_plugin.dll'));
    }
    return MiniAudioBindings(DynamicLibrary.executable());
  }

  static MiniAudioDecoder openDecoder(MiniAudioBindings ffi, String path) {
    return MiniAudioDecoder.openPath(ffi, path);
  }

  /// Initializes a default miniaudio device for playback.
  /// The [dataCallback] parameter must be able to be called from any thread
  /// so you need to get this function pointer from another piece of C code
  /// in your project. Or wait until isolate-independent FFI code is added to Dart.
  static MiniAudioDevice getDefaultPlaybackDevice(MiniAudioBindings ffi,
      ma_device_data_proc dataCallback, Pointer<Void> userData) {
    return MiniAudioDevice.defaultPlaybackDevice(
      ffi,
      dataCallback: dataCallback,
      userData: userData,
    );
  }

  static MiniAudioPCMRingBuffer getNewRingBuffer(
      MiniAudioBindings ffi, int sampleFormat, int frameCount, int channels) {
    return MiniAudioPCMRingBuffer.managed(
      ffi: ffi,
      format: sampleFormat,
      frameCount: frameCount,
      channels: channels,
    );
  }

  static MiniAudioConverter getDefaultConverter(
    MiniAudioBindings ffi, {
    int? inputFormat,
    int? outputFormat,
    int? inputChannels,
    int? outputChannels,
    int? inputSampleRate,
    int? outputSampleRate,
  }) {
    return MiniAudioConverter.initDefault(
      ffi,
      inputFormat: inputFormat,
      outputFormat: outputFormat,
      inputChannels: inputChannels,
      outputChannels: outputChannels,
      inputSampleRate: inputSampleRate,
      outputSampleRate: outputSampleRate,
    );
  }
}

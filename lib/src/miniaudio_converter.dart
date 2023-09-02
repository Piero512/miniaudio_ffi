import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:miniaudio_ffi/miniaudio_ffi.dart';
import 'package:miniaudio_ffi/src/utils.dart';

import 'miniaudio_bindings.dart';

typedef ConvertFramesReturnRecord = ({
  int errorCode,
  int inputFramesConsumed,
  int outputFramesConsumed
});

class MiniAudioConverter implements Finalizable {
  final MiniAudioBindings ffi;
  final Pointer<ma_data_converter> converter;
  bool disposed = false;
  static NativeFinalizer? _finalizer;

  MiniAudioConverter._(this.ffi, this.converter) : assert(converter != nullptr);

  factory MiniAudioConverter.initDefault(
    MiniAudioBindings ffi, {
    int? inputFormat,
    int? outputFormat,
    int? inputChannels,
    int? outputChannels,
    int? inputSampleRate,
    int? outputSampleRate,
  }) {
    _finalizer ??= NativeFinalizer(
      ffi.addresses.ma_data_converter_uninit.cast(),
    );
    return using((alloc) {
      final cConfig = alloc.call<ma_data_converter_config>();
      cConfig.ref = ffi.ma_data_converter_config_init_default();
      if (inputFormat != null) cConfig.ref.formatIn = inputFormat;
      if (outputFormat != null) cConfig.ref.formatOut = outputFormat;
      if (inputChannels != null) cConfig.ref.channelsIn = inputChannels;
      if (outputChannels != null) cConfig.ref.channelsOut = outputChannels;
      if (inputSampleRate != null) cConfig.ref.sampleRateIn = inputSampleRate;
      if (outputSampleRate != null) {
        cConfig.ref.sampleRateOut = outputSampleRate;
      }

      final converterPtr = calloc.call<ma_data_converter>();
      final result = ffi.ma_data_converter_init(cConfig, nullptr, converterPtr);
      if (result == ma_result.MA_SUCCESS) {
        final newConverter = MiniAudioConverter._(ffi, converterPtr);
        _finalizer?.attach(newConverter, converterPtr.cast(),
            detach: newConverter, externalSize: sizeOf<ma_data_converter>());
        return newConverter;
      } else {
        final readableError =
            ffi.ma_result_description(result).cast<Utf8>().toDartString();
        calloc.free(converterPtr);
        throw ArgumentError(readableError);
      }
    });
  }

  ConvertFramesReturnRecord convertFrames(
    Pointer<Uint8> inputBuffer,
    int inputframeCount,
    Pointer<Uint8> outBuffer,
    int outputFrameCount,
  ) {
    runtimeAssert(!disposed);
    return using(
      (alloc) {
        final iframeCountPtr = alloc.call<Uint64>()..value = inputframeCount;
        final oFrameCountPtr = alloc.call<Uint64>()..value = outputFrameCount;

        final errCode = ffi.ma_data_converter_process_pcm_frames(
          converter,
          inputBuffer.cast(),
          iframeCountPtr.cast(),
          outBuffer.cast(),
          oFrameCountPtr.cast(),
        );
        return (
          errorCode: errCode,
          inputFramesConsumed: iframeCountPtr.value,
          outputFramesConsumed: oFrameCountPtr.value
        );
      },
    );
  }

  void dispose() {
    if (!disposed) {
      _finalizer?.detach(this);
      ffi.ma_data_converter_uninit(converter, nullptr);
      malloc.free(converter);
      disposed = true;
    }
  }
}
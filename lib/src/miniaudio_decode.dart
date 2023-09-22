import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:miniaudio_ffi/src/utils.dart';

import 'miniaudio_bindings.dart';
import 'utils.dart' as ma;

typedef ReadFramesReturnRecord = ({int errCode, int framesActuallyRead});

class MiniAudioDecoder implements Finalizable {
  static NativeFinalizer? _decoderFinalizer;
  static final Finalizer<Pointer<ma_decoder>> _allocFinalizer = Finalizer(
    (ptr) => malloc.free(ptr),
  );
  final MiniAudioBindings ffi;
  final Pointer<ma_decoder> decoder;
  bool finalized = false;
  static const _finalizedMessage = 'This instance is already finalized';
  int? _cachedLength;

  MiniAudioDecoder._(
    this.ffi,
    this.decoder,
  ) : assert(decoder != nullptr);

  factory MiniAudioDecoder.openPath(MiniAudioBindings ffi, String path) {
    _decoderFinalizer ??=
        NativeFinalizer(ffi.addresses.ma_decoder_uninit.cast());
    return using((alloc) {
      var decoder = calloc.call<ma_decoder>();
      var pathCString = path.toNativeUtf8(allocator: alloc);
      var result =
          ffi.ma_decoder_init_file(pathCString.cast(), nullptr, decoder);
      if (result == ma_result.MA_SUCCESS) {
        final retval = MiniAudioDecoder._(ffi, decoder);
        _decoderFinalizer?.attach(
          retval,
          decoder.cast(),
          detach: retval,
          externalSize: sizeOf<ma_decoder>(),
        );
        _allocFinalizer.attach(retval, decoder, detach: retval);
        return retval;
      } else {
        var readableError =
            ffi.ma_result_description(result).cast<Utf8>().toDartString();
        malloc.free(decoder);
        throw ArgumentError.value(path, 'path', readableError);
      }
    });
  }

  void dispose() => closeDecoder();

  void closeDecoder() {
    if (!finalized) {
      _allocFinalizer.detach(this);
      _decoderFinalizer?.detach(this);
      ffi.ma_decoder_uninit(decoder);
      malloc.free(decoder);
    }
    finalized = true;
  }

  int get sampleSize {
    runtimeAssert(finalized != true, _finalizedMessage);
    return ffi.ma_get_bytes_per_sample(decoder.ref.outputFormat);
  }

  int get sampleRate {
    runtimeAssert(finalized != true, _finalizedMessage);
    return decoder.ref.outputSampleRate;
  }

  int get frameSize => sampleSize * channelCount;

  int get channelCount {
    runtimeAssert(finalized != true, _finalizedMessage);
    return decoder.ref.outputChannels;
  }

  int get outputFormat {
    runtimeAssert(finalized != true, _finalizedMessage);
    return decoder.ref.outputFormat;
  }

  /// Read frames from decoder
  /// params:
  ///
  /// [frameBuffer] buffer to receive the frames
  ///
  /// [frameBufferSize]  size (in bytes) of the buffer passed before
  ///
  /// [framesToRead] frames to read.
  ///
  /// You should have allocated at least [framesToRead] * [frameSize] bytes in this buffer.
  /// otherwise, the operation will be aborted.
  /// Returns a record with the error code and the frames read.
  ReadFramesReturnRecord readFrames(
      Pointer<Uint8> frameBuffer, int frameBufferSize, int framesToRead) {
    runtimeAssert(finalized != true, _finalizedMessage);
    if (frameSize * framesToRead <= frameBufferSize) {
      return using(
        (alloc) {
          final Pointer<Uint64> framesRead = alloc.call()..value = 0;
          final retval = ffi.ma_decoder_read_pcm_frames(decoder,
              frameBuffer.cast<Void>(), framesToRead, framesRead.cast());
          return (errCode: retval, framesActuallyRead: framesRead.value);
        },
      );
    } else {
      throw ArgumentError.value(
          frameBufferSize, 'frameBufferSize', 'is too small!');
    }
  }

  int get positionInPCMFrames {
    return using((a) {
      final positionPtr = a.call<ma_uint64>();
      final result = ffi.ma_decoder_get_cursor_in_pcm_frames(
        decoder,
        positionPtr,
      );
      ma.throwIfNonSuccess(result, ffi);
      return positionPtr.value;
    });
  }

  set positionInPCMFrames(int value) {
    final res = ffi.ma_decoder_seek_to_pcm_frame(decoder, value);
    ma.throwIfNonSuccess(res, ffi);
  }

  int get lengthInPCMFrames {
    _cachedLength ??= using((a) {
      final lengthPtr = a.call<ma_uint64>();
      final result = ffi.ma_decoder_get_length_in_pcm_frames(
        decoder,
        lengthPtr,
      );
      ma.throwIfNonSuccess(result, ffi);
      return lengthPtr.value;
    });
    return _cachedLength!;
  }
}

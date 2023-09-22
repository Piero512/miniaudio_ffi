import 'package:ffi/ffi.dart';
import 'package:miniaudio_ffi/miniaudio_ffi.dart';

const _kDefaultAssertMessage = 'This instance is already finalized';

void runtimeAssert(bool expression, [String message = _kDefaultAssertMessage]) {
  if (!expression) {
    throw StateError(message);
  }
}

typedef Ex = MiniaudioException;

class MiniaudioException implements Exception {
  final int returnValue;
  final String message;

  MiniaudioException(this.returnValue, this.message);

  factory MiniaudioException.fromResultValue(
          int retval, MiniAudioBindings ffi) =>
      MiniaudioException(
        retval,
        ffi.ma_result_description(retval).cast<Utf8>().toDartString(),
      );
}

void throwIfNonSuccess(int retval, MiniAudioBindings ffi) {
  if (retval != 0) {
    throw MiniaudioException.fromResultValue(retval, ffi);
  }
}

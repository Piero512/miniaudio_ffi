import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:miniaudio_ffi/src/utils.dart';

import 'miniaudio_bindings.dart';

class MiniAudioDevice implements Finalizable {
  static NativeFinalizer? _finalizer;
  static final Finalizer<Pointer> _allocFinalizer =
      Finalizer((ptr) => malloc.free(ptr));
  final Pointer<ma_device> _ptr;
  final MiniAudioBindings ffi;
  bool disposed = false;
  MiniAudioDevice._(this.ffi, this._ptr);

  factory MiniAudioDevice.playbackDevice(
    MiniAudioBindings ffi, {
    required int playbackFormat,
    required int channels,
    required int sampleRate,
    required ma_device_data_proc dataCallback,
    required Pointer<Void> userData,
  }) {
    _finalizer ??= NativeFinalizer(ffi.addresses.ma_device_uninit.cast());
    final device = malloc.call<ma_device>();
    final deviceConfig = malloc.call<ma_device_config>()
      ..ref = ffi.ma_device_config_init(ma_device_type.ma_device_type_playback);
    deviceConfig.ref.playback.format = playbackFormat;
    deviceConfig.ref.playback.channels = channels;
    deviceConfig.ref.sampleRate = sampleRate;
    deviceConfig.ref.dataCallback = dataCallback;
    deviceConfig.ref.pUserData = userData;
    ffi.ma_device_init(nullptr, deviceConfig, device);
    final retval = MiniAudioDevice._(ffi, device);
    _finalizer?.attach(
      retval,
      device.cast(),
      detach: retval,
      externalSize: sizeOf<ma_device>(),
    );
    _allocFinalizer.attach(retval, device);
    _allocFinalizer.attach(retval, deviceConfig);
    return retval;
  }

  factory MiniAudioDevice.defaultPlaybackDevice(MiniAudioBindings ffi,
      {required ma_device_data_proc dataCallback,
      required Pointer<Void> userData}) {
    return MiniAudioDevice.playbackDevice(
      ffi,
      playbackFormat: ma_format.ma_format_unknown,
      channels: 0,
      sampleRate: 0,
      dataCallback: dataCallback,
      userData: userData,
    );
  }

  int startDevice() {
    runtimeAssert(!disposed, "Can't start playback on a disposed device");
    return ffi.ma_device_start(_ptr);
  }

  int stopDevice() {
    runtimeAssert(!disposed, "Can't stop playback on a disposed device");
    return ffi.ma_device_stop(_ptr);
  }

  void uninit() {
    if (!disposed) {
      _finalizer?.detach(this);
      _allocFinalizer.detach(this);
      ffi.ma_device_uninit(_ptr);
      malloc.free(_ptr);
      disposed = true;
    }
  }
}

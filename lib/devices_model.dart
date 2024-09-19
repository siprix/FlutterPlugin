import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'siprix_voip_sdk.dart';

////////////////////////////////////////////////////////////////////////////////////////
//Devices list model

class DevicesModel extends ChangeNotifier {  
  final List<MediaDevice> _playout = [];
  final List<MediaDevice> _recording = [];
  final List<MediaDevice> _video = [];

  int _selPlayoutIndex=-1;
  int _selRecordingIndex=-1;
  int _selVideoIndex=-1;
  bool _foregroundModeEnabled = false;

  final ILogsModel? _logs;
  bool _loaded = false;
  
  DevicesModel([this._logs]) {
    SiprixVoipSdk().dvcListener = DevicesStateListener(
      devicesChanged : onAudioDevicesChanged
    );
  }

  List<MediaDevice> get playout   => List.unmodifiable(_playout);
  List<MediaDevice> get recording => List.unmodifiable(_recording);
  List<MediaDevice> get video     => List.unmodifiable(_video);

  int get playoutIndex   => _selPlayoutIndex;
  int get recordingIndex => _selRecordingIndex;
  int get videoIndex     => _selVideoIndex;

  bool get foregroundModeEnabled => _foregroundModeEnabled;

  void load() {
    if(_loaded) return;
    _loadPlayoutDevices();
    _loadRecordingDevices();
    _loadVideoDevices();
    _loadForegroundMode();    
    _loaded = true;
  }
  
  void _loadPlayoutDevices() async {
    try {
      _playout.clear();
      int dvcsNumber = await SiprixVoipSdk().getPlayoutDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getPlayoutDevice(index);        
        if((dvc != null) && (_playout.indexWhere((p) => p.guid==dvc.guid) ==-1))   _playout.add(dvc);
      }
      _selPlayoutIndex = -1;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load playoutDevices. Err: ${err.code} ${err.message}');
    }
  }

  void _loadRecordingDevices() async {    
    try {
      _recording.clear();
      int dvcsNumber = await SiprixVoipSdk().getRecordingDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getRecordingDevice(index);
        if((dvc != null) && (_recording.indexWhere((p) => p.guid==dvc.guid) ==-1))   _recording.add(dvc);
      }
      _selRecordingIndex = -1;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load recordingDevices. Err: ${err.code} ${err.message}');
    }
  }
  
  void _loadVideoDevices() async {    
    try {
      _video.clear();
      int dvcsNumber = await SiprixVoipSdk().getVideoDevices() ?? 0;
      for(int index=0; index < dvcsNumber; ++index) {
        MediaDevice? dvc = await SiprixVoipSdk().getVideoDevice(index);
        if((dvc != null) && (_video.indexWhere((p) => p.guid==dvc.guid) ==-1))   _video.add(dvc);
      }
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t load videoDevices. Err: ${err.code} ${err.message}');
    }
  }

  void onAudioDevicesChanged() {
    _logs?.print('onAudioDevicesChanged');
    _loadPlayoutDevices();
    _loadRecordingDevices();
  }

  Future<void> setPlayoutDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set playoutDevice - $index');

    try {
      await SiprixVoipSdk().setPlayoutDevice(index);
      _selPlayoutIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set playoutDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> setRecordingDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set recordingDevice - $index');

    try {
      await SiprixVoipSdk().setRecordingDevice(index);
      _selRecordingIndex = index;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set recordingDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> setVideoDevice(int? index) async{
    if(index==null) return;
    _logs?.print('set videoDevice - $index');

    try {
      await SiprixVoipSdk().setVideoDevice(index);
      _selVideoIndex = index;      
    } on PlatformException catch (err) {
      _logs?.print('Can\'t set videoDevice. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> setForegroundMode(bool enabled) async{
    if(Platform.isAndroid) {
      if(_foregroundModeEnabled==enabled) return;
      _logs?.print('set foreground mode - $enabled');

      try {
        await SiprixVoipSdk().setForegroundMode(enabled);

        _foregroundModeEnabled = enabled;

        notifyListeners();

      } on PlatformException catch (err) {
        _logs?.print('Can\'t setForegroundMode. Err: ${err.code} ${err.message}');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    }
  }

  void _loadForegroundMode() async {
    if(Platform.isAndroid) {
      try {
        bool? mode = await SiprixVoipSdk().isForegroundMode();
        if(mode != null) {
          _foregroundModeEnabled = mode;
          notifyListeners();
        }
      } on PlatformException catch (err) {
        _logs?.print('Can\'t load videoDevices. Err: ${err.code} ${err.message}');
      }
    }
  }   

  

}//DevicesModel
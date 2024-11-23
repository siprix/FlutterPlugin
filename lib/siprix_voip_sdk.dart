import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'accounts_model.dart';
import 'network_model.dart';
import 'calls_model.dart';

////////////////////////////////////////////////////////////////////////////
//Events arguments

class AccRegStateArg {
  int accId=0;
  RegState regState=RegState.success;
  String response="";

  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    int stateVal=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdk._kArgAccId)&&(value is int))    { accId    = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kRegState)&&(value is int))    { stateVal = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });

    switch (stateVal) {
      case SiprixVoipSdk.kRegStateSuccess: regState = RegState.success;
      case SiprixVoipSdk.kRegStateFailed:  regState = RegState.failed;
      case SiprixVoipSdk.kRegStateRemoved: regState = RegState.removed;
    }
    return (argsCounter==3);
  }
}


class NetworkStateArg {  
  String name="";
  NetState state=NetState.lost;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    int stateVal=0; 
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdk._kArgName)&&(value is String)) { name     = value; argsCounter+=1; }
      if((key == SiprixVoipSdk._kNetState)&&(value is int))   { stateVal = value; argsCounter+=1; }
    });

    switch (stateVal) {
      case SiprixVoipSdk.kNetStateLost:      state = NetState.lost;
      case SiprixVoipSdk.kNetStateRestored:  state = NetState.restored;
      case SiprixVoipSdk.kNetStateSwitched:  state = NetState.switched;
    }

    return (argsCounter==2);
  }
}

class PlayerStateArg {
  int playerId=0;
  PlayerState state=PlayerState.failed;

  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;    
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdk._kArgPlayerId)&&(value is int))    { playerId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kPlayerState)&&(value is int))    { state = PlayerState.from(value); argsCounter+=1; }       
    });

    return (argsCounter==2);
  }
}


class CallProceedingArg {
  int callId=0;
  String response="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))   { callId   = value; argsCounter+=1; } else      
      if((key == SiprixVoipSdk._kResponse)&&(value is String)) { response = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

class CallIncomingArg {
  int accId=0;
  int callId=0;
  String from="";
  String to="";
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {
      if((key == SiprixVoipSdk._kArgAccId)&&(value is int))      { accId     = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))     { callId    = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kFrom)&&(value is String))       { from      = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kTo)&&(value is String))         { to        = value; argsCounter+=1; }
    });
    return (argsCounter==5);
  }
}

class CallAcceptNotifArg {  
  int callId=0;
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))     { callId = value;    argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; } 
    });
    return (argsCounter==2);
  }
}

class CallConnectedArg {  
  int callId=0;
  String from="";
  String to="";
  bool withVideo = false;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgWithVideo)&&(value is bool)) { withVideo = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))     { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kFrom)&&(value is String))       { from   = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kTo)&&(value is String))         { to     = value; argsCounter+=1; }
    });
    return (argsCounter==4);
  }
}

class CallTerminatedArg {  
  int callId=0;
  int statusCode=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))     { callId     = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgStatusCode)&&(value is int)) { statusCode = value; argsCounter+=1; } 
    });
    return (argsCounter==2);
  }
}

class CallDtmfReceivedArg {  
  int callId=0;
  int tone=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int)) { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgTone)&&(value is int))   { tone   = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}

class CallTransferredArg {  
  int callId=0;
  int statusCode=0;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int))     { callId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgStatusCode)&&(value is int)) { statusCode = value; argsCounter+=1; } 
    });
    return (argsCounter==2);
  }
}

class CallRedirectedArg {  
  int origCallId=0;
  int relatedCallId=0;
  String referTo="";
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgFromCallId)&&(value is int)) { origCallId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgToCallId)&&(value is int))   { relatedCallId = value; argsCounter+=1; } else
      if((key == SiprixVoipSdk._kArgToExt)&&(value is String))   { referTo = value; argsCounter+=1; } 
    });
    return (argsCounter==3);
  }
}


class CallHeldArg {  
  int callId=0;
  HoldState state = HoldState.none;
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int)) { callId = value;               argsCounter+=1; } else
      if((key == SiprixVoipSdk._kHoldState)&&(value is int)) { state  = HoldState.from(value); argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}


class CallSwitchedArg {  
  int callId=0;  
  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgCallId)&&(value is int)) { callId = value; argsCounter+=1; }      
    });
    return (argsCounter==1);
  }
}


class MediaDevice {
  MediaDevice(this.index);
  String  name="";
  String  guid="";
  int index = 0;

  bool fromMap(Map<dynamic, dynamic> argsMap) {    
    int argsCounter=0;    
    argsMap.forEach((key, value) {      
      if((key == SiprixVoipSdk._kArgDvcName)&&(value is String)) { name = value; argsCounter+=1; }
      if((key == SiprixVoipSdk._kArgDvcGuid)&&(value is String)) { guid = value; argsCounter+=1; }
    });
    return (argsCounter==2);
  }
}


////////////////////////////////////////////////////////////////////////////
//Listeners

class AccStateListener {
  AccStateListener({this.regStateChanged});
  void Function(int accId, RegState state, String response)? regStateChanged;
}

class NetStateListener {
  NetStateListener({this.networkStateChanged});  
  void Function(String name, NetState state)? networkStateChanged;
}

class CallStateListener {
  CallStateListener({this.proceeding, this.incoming, this.acceptNotif,
    this.connected, this.terminated, this.dtmfReceived,
    this.transferred, this.redirected, this.held, this.switched, 
    this.playerStateChanged});

  void Function(int playerId, PlayerState s)? playerStateChanged;
  void Function(int callId, String response)?  proceeding;
  void Function(int callId, int accId, bool withVideo, String from, String to)? incoming;
  void Function(int callId, bool withVideo)? acceptNotif;  
  void Function(int callId, String from, String to, bool withVideo)? connected;
  void Function(int callId, int statusCode)? terminated;
  void Function(int callId, int statusCode)? transferred;
  void Function(int origCallId, int relatedCallId, String referTo)? redirected;
  void Function(int callId, int tone)? dtmfReceived;
  void Function(int callId, HoldState)? held;
  void Function(int callId)? switched;
}

class DevicesStateListener {
  DevicesStateListener({this.devicesChanged});
  void Function()?  devicesChanged;
}

class TrialModeListener {
  TrialModeListener({this.notified});
  void Function()?  notified;
}

abstract interface class ILogsModel {
  void print(String s);
}

abstract interface class IAccountsModel {
  String getUri(int accId);
  bool hasSecureMedia(int accId);
}


//////////////////////////////////////////////////////////////////////////////////////////
//SiprixVoipSdk - root implementation

class SiprixVoipSdk extends PlatformInterface 
{
  ////////////////////////////////////////////////////////////////////////////////////////  
  //Constants
  static const int kLogLevelStack   = 0;
  static const int kLogLevelDebug   = 1;
  static const int kLogLevelInfo    = 2;
  static const int kLogLevelWarning = 3;
  static const int kLogLevelError   = 4;
  static const int kLogLevelNone    = 5;

  static const int kSipTransportUdp = 0;
  static const int kSipTransportTcp = 1;
  static const int kSipTransportTls = 2;

  static const int kSecureMediaDisabled = 0;
  static const int kSecureMediaSdesSrtp = 1;  
  static const int kSecureMediaDtlsSrtp = 2;

  static const int kRegStateSuccess = 0;
  static const int kRegStateFailed  = 1;
  static const int kRegStateRemoved = 2;

  static const int kNetStateLost     = 0;
  static const int kNetStateRestored = 1;
  static const int kNetStateSwitched = 2;

  static const int kPlayerStateStarted = 0;
  static const int kPlayerStateStopped = 1;
  static const int kPlayerStateFailed  = 2;

  static const int kAudioCodecOpus  = 65;
  static const int kAudioCodecISAC16= 66;
  static const int kAudioCodecISAC32= 67;
  static const int kAudioCodecG722  = 68;
  static const int kAudioCodecILBC  = 69;
  static const int kAudioCodecPCMU  = 70;
  static const int kAudioCodecPCMA  = 71;  
  static const int kAudioCodecDTMF  = 72;
  static const int kAudioCodecCN    = 73;

  static const int kVideoCodecH264  = 80;
  static const int kVideoCodecVP8   = 81;
  static const int kVideoCodecVP9   = 82;
  static const int kVideoCodecAV1   = 83;

  static const int kDtmfMethodRtp  = 0;
  static const int kDtmfMethodInfo = 1;

  static const int kHoldStateNone   = 0;
  static const int kHoldStateLocal  = 1;
  static const int kHoldStateRemote = 2;
  static const int kHoldStateLocalAndRemote = 3;

  static const int eOK = 0;
  static const int eDuplicateAccount=-1021;
  
  static const int kLocalVideoCallId=0;
  
  static const String _kChannelName = 'siprix_voip_sdk';
  
  static const String _kMethodModuleInitialize  = 'Module_Initialize';
  static const String _kMethodModuleUnInitialize= 'Module_UnInitialize';
  static const String _kMethodModuleHomeFolder  = 'Module_HomeFolder';
  static const String _kMethodModuleVersionCode = 'Module_VersionCode';
  static const String _kMethodModuleVersion     = 'Module_Version';

  static const String _kMethodAccountAdd        = 'Account_Add';
  static const String _kMethodAccountUpdate     = 'Account_Update';
  static const String _kMethodAccountRegister   = 'Account_Register';
  static const String _kMethodAccountUnregister = 'Account_Unregister';
  static const String _kMethodAccountDelete     = 'Account_Delete';
  
  static const String _kMethodCallInvite          = 'Call_Invite';
  static const String _kMethodCallReject          = 'Call_Reject';
  static const String _kMethodCallAccept          = 'Call_Accept';
  static const String _kMethodCallHold            = 'Call_Hold';
  static const String _kMethodCallGetHoldState    = 'Call_GetHoldState';
  static const String _kMethodCallGetSipHeader    = 'Call_GetSipHeader';
  static const String _kMethodCallMuteMic         = 'Call_MuteMic';
  static const String _kMethodCallMuteCam         = 'Call_MuteCam';
  static const String _kMethodCallSendDtmf        = 'Call_SendDtmf';
  static const String _kMethodCallPlayFile        = 'Call_PlayFile';
  static const String _kMethodCallStopPlayFile    = 'Call_StopPlayFile';
  static const String _kMethodCallRecordFile      = 'Call_RecordFile';
  static const String _kMethodCallStopRecordFile  = 'Call_StopRecordFile';
  static const String _kMethodCallTransferBlind   = 'Call_TransferBlind';  
  static const String _kMethodCallTransferAttended= 'Call_TransferAttended';
  static const String _kMethodCallBye             = 'Call_Bye';

  static const String _kMethodMixerSwitchToCall   = 'Mixer_SwitchToCall';
  static const String _kMethodMixerMakeConference = 'Mixer_MakeConference';

  static const String _kMethodDvcSetForegroundMode= 'Dvc_SetForegroundMode';
  static const String _kMethodDvcIsForegroundMode=  'Dvc_IsForegroundMode';
  static const String _kMethodDvcGetPlayoutNumber = 'Dvc_GetPlayoutDevices';
  static const String _kMethodDvcGetRecordNumber  = 'Dvc_GetRecordingDevices';
  static const String _kMethodDvcGetVideoNumber   = 'Dvc_GetVideoDevices';
  static const String _kMethodDvcGetPlayout       = 'Dvc_GetPlayoutDevice';
  static const String _kMethodDvcGetRecording     = 'Dvc_GetRecordingDevice';
  static const String _kMethodDvcGetVideo         = 'Dvc_GetVideoDevice';
  static const String _kMethodDvcSetPlayout       = 'Dvc_SetPlayoutDevice';
  static const String _kMethodDvcSetRecording     = 'Dvc_SetRecordingDevice';
  static const String _kMethodDvcSetVideo         = 'Dvc_SetVideoDevice';
  static const String _kMethodDvcSetVideoParams   = 'Dvc_SetVideoParams';

  static const String _kMethodVideoRendererCreate  = 'Video_RendererCreate';
  static const String _kMethodVideoRendererSetSrc  = 'Video_RendererSetSrc';  
  static const String _kMethodVideoRendererDispose = 'Video_RendererDispose';

  static const String _kOnTrialModeNotif   = "OnTrialModeNotif";
  static const String _kOnDevicesChanged   = 'OnDevicesChanged';
  
  static const String _kOnAccountRegState  = 'OnAccountRegState';
  static const String _kOnNetworkState     = 'OnNetworkState';
  static const String _kOnPlayerState      = 'OnPlayerState';

  static const String _kOnCallProceeding   = 'OnCallProceeding';
  static const String _kOnCallTerminated   = 'OnCallTerminated';
  static const String _kOnCallConnected    = 'OnCallConnected';
  static const String _kOnCallIncoming     = 'OnCallIncoming';
  static const String _kOnCallAcceptNotif  = 'OnCallAcceptNotif';  
  static const String _kOnCallDtmfReceived = 'OnCallDtmfReceived';
  static const String _kOnCallTransferred  = "OnCallTransferred";
  static const String _kOnCallRedirected   = "OnCallRedirected";
  static const String _kOnCallSwitched     = 'OnCallSwitched';
  static const String _kOnCallHeld         = 'OnCallHeld';

  static const String _kArgVideoTextureId = 'videoTextureId';
  static const String _kArgForeground = 'foreground';
  static const String _kArgStatusCode = 'statusCode';
  static const String _kArgExpireTime = 'expireTime';
  static const String _kArgWithVideo  = 'withVideo';
  static const String _kArgDvcIndex   = 'dvcIndex';
  static const String _kArgDvcName    = 'dvcName';
  static const String _kArgDvcGuid    = 'dvcGuid';
  static const String _kArgCallId     = 'callId';
  static const String _kArgFromCallId = 'fromCallId';
  static const String _kArgToCallId   = 'toCallId';
  static const String _kArgToExt      = 'toExt';
  static const String _kArgAccId      = 'accId';
  static const String _kArgPlayerId   = "playerId";
  static const String _kRegState      = 'regState'; 
  static const String _kHoldState     = 'holdState';
  static const String _kNetState      = 'netState';
  static const String _kPlayerState   = "playerState";
    static const String _kResponse  = 'response';
  static const String _kArgName   = 'name';
  static const String _kArgTone   = 'tone';
  static const String _kFrom      = 'from';
  static const String _kTo        = 'to';

  ////////////////////////////////////////////////////////////////////////////////////////
  //Channel and instance implementation
  static final Object _token = Object();

  static final SiprixVoipSdk _instance = SiprixVoipSdk._internal();
  static  SiprixVoipSdk get instance => _instance;
  factory SiprixVoipSdk() { return _instance; }

  SiprixVoipSdk._internal() : super(token: _token);

  final _methodChannel = const MethodChannel(_kChannelName);
  NetStateListener? netListener;
  AccStateListener? accListener;
  CallStateListener? callListener;
  DevicesStateListener? dvcListener;
  TrialModeListener? trialListener;

  
  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix module methods implementation

  void initialize(InitData iniData, ILogsModel? logsModel) async {
    _methodChannel.setMethodCallHandler(_eventsHandler);
    try {
      await _methodChannel.invokeMethod<void>(_kMethodModuleInitialize, iniData.toMap());
      String verStr = await version() ?? "???";
      //int verCode = await versionCode() ?? 0;
      logsModel?.print('Siprix module initialized successfully');
      logsModel?.print('Version: $verStr');
    } on PlatformException catch (err) {
      logsModel?.print('Can\'t initialize Siprix module Err: ${err.code} ${err.message}');
    }
  }

  void unInitialize(ILogsModel? logsModel) async {    
    try {
      await _methodChannel.invokeMethod<void>(_kMethodModuleUnInitialize);
      logsModel?.print('Siprix module uninitialized');
    } on PlatformException catch (err) {
      logsModel?.print('Can\'t uninitilize Siprix module Err: ${err.code} ${err.message}');
    }
  }

  Future<String?> homeFolder() async {
    return _methodChannel.invokeMethod<String>(_kMethodModuleHomeFolder, {});
  }

  Future<String?> version() async {
    return _methodChannel.invokeMethod<String>(_kMethodModuleVersion, {});
  }

  Future<int?> versionCode() async {
    return _methodChannel.invokeMethod<int>(_kMethodModuleVersionCode, {});
  } 


  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Account methods implementation

  Future<int?> addAccount(AccountModel newAccount) {
    return _methodChannel.invokeMethod<int>(_kMethodAccountAdd, 
      newAccount.toJson());
  }

  Future<void> updateAccount(AccountModel updAccount) {
    Map<String, dynamic> argMap = updAccount.toJson();
    argMap[_kArgAccId] = updAccount.myAccId;
    return _methodChannel.invokeMethod<void>(_kMethodAccountUpdate, argMap);
  }

  Future<void> deleteAccount(int accId) {
    return _methodChannel.invokeMethod<void>(_kMethodAccountDelete, 
      {_kArgAccId:accId} );
  }

  Future<void> unRegisterAccount(int accId) {
    return _methodChannel.invokeMethod<void>(_kMethodAccountUnregister, 
      {_kArgAccId:accId} );
  }

  Future<void> registerAccount(int accId, int expireTime) {
    return _methodChannel.invokeMethod<void>(_kMethodAccountRegister, 
      {_kArgAccId:accId, _kArgExpireTime:expireTime} );
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Calls methods implementation 

  Future<int?> invite(CallDestination dest) {
    return _methodChannel.invokeMethod<int>(_kMethodCallInvite, dest.toMap());
  }

  Future<void> reject(int callId, int statusCode) {
    return _methodChannel.invokeMethod<void>(_kMethodCallReject, 
      {_kArgCallId:callId, _kArgStatusCode:statusCode} );
  }

  Future<void> accept(int callId, bool withVideo) {
    return _methodChannel.invokeMethod<void>(_kMethodCallAccept, 
      {_kArgCallId:callId, _kArgWithVideo:withVideo} );
  }

  Future<void> sendDtmf(int callId, String tones, int durationMs, int intertoneGapMs, [int method = kDtmfMethodRtp]) {
    return _methodChannel.invokeMethod<void>(_kMethodCallSendDtmf, 
      {_kArgCallId:callId, 'dtmfs':tones, 
        'durationMs':durationMs, 'intertoneGapMs':intertoneGapMs, 'method':method} );
  }

  Future<void> bye(int callId) {
    return _methodChannel.invokeMethod<void>(_kMethodCallBye, 
      {_kArgCallId:callId} );
  }

  Future<void> hold(int callId) {
    return _methodChannel.invokeMethod<void>(_kMethodCallHold, 
      {_kArgCallId:callId} );
  }

  Future<int?> getHoldState(int callId) {
    return _methodChannel.invokeMethod<int>(_kMethodCallGetHoldState, 
        {_kArgCallId:callId} );    
  }

  Future<String?> getSipHeader(int callId, String headerName) {
    return _methodChannel.invokeMethod<String>(_kMethodCallGetSipHeader, 
        {_kArgCallId:callId, 'hdrName':headerName} );
  }

  Future<void> muteMic(int callId, bool mute) {
    return _methodChannel.invokeMethod<void>(_kMethodCallMuteMic, 
      {_kArgCallId:callId, 'mute':mute} );
  }

  Future<void> muteCam(int callId, bool mute) {
    return _methodChannel.invokeMethod<void>(_kMethodCallMuteCam, 
      {_kArgCallId:callId, 'mute':mute} );
  }

  Future<int?> playFile(int callId, String pathToMp3File, bool loop) {
    return _methodChannel.invokeMethod<int>(_kMethodCallPlayFile, 
      {_kArgCallId:callId, 'pathToMp3File':pathToMp3File, 'loop':loop} );
  }

  Future<void> stopPlayFile(int playerId) {
    return _methodChannel.invokeMethod<void>(_kMethodCallStopPlayFile, 
      {_kArgPlayerId:playerId} );
  }
    
  Future<void> recordFile(int callId, String pathToMp3File) {
    return _methodChannel.invokeMethod<void>(_kMethodCallRecordFile, 
      {_kArgCallId:callId, 'pathToMp3File':pathToMp3File} );
  }

  Future<void> stopRecordFile(int callId) {
    return _methodChannel.invokeMethod<void>(_kMethodCallStopRecordFile, 
      {_kArgCallId:callId} );
  }  

  Future<void> transferBlind(int callId, String toExt) {
    return _methodChannel.invokeMethod<void>(_kMethodCallTransferBlind, 
      {_kArgCallId:callId, _kArgToExt:toExt} );
  }
  
  Future<void> transferAttended(int fromCallId, int toCallId) {
    return _methodChannel.invokeMethod<void>(_kMethodCallTransferAttended, 
      {_kArgFromCallId:fromCallId, _kArgToCallId:toCallId} );
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Mixer methods implmentation
  
  Future<void> switchToCall(int callId) {
    return _methodChannel.invokeMethod<void>(_kMethodMixerSwitchToCall,
      {_kArgCallId:callId} );
  }
  
  Future<void> makeConference() {
    return _methodChannel.invokeMethod<void>(_kMethodMixerMakeConference, {} );
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix Devices methods implementation

  Future<int?> getPlayoutDevices() {
    return _methodChannel.invokeMethod<int>(_kMethodDvcGetPlayoutNumber, {});
  }

  Future<int?> getRecordingDevices() {
    return _methodChannel.invokeMethod<int>(_kMethodDvcGetRecordNumber, {});
  }

  Future<int?> getVideoDevices() {
    return _methodChannel.invokeMethod<int>(_kMethodDvcGetVideoNumber, {});
  }

  Future<MediaDevice?> _getMediaDevice(int index, String methodName) async {
     try {
      Map<dynamic, dynamic>? argsMap = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(methodName, {_kArgDvcIndex:index});
      if(argsMap==null) return null;
      
      MediaDevice dvc = MediaDevice(index);
      return dvc.fromMap(argsMap) ? dvc : null;
    } on PlatformException catch (err) {
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }
  
  Future<MediaDevice?> getPlayoutDevice(int index) async {
    return _getMediaDevice(index, _kMethodDvcGetPlayout);     
  }

  Future<MediaDevice?> getRecordingDevice(int index) async {
    return _getMediaDevice(index, _kMethodDvcGetRecording);     
  }

  Future<MediaDevice?> getVideoDevice(int index) async {
    return _getMediaDevice(index, _kMethodDvcGetVideo);     
  }

  Future<void> setPlayoutDevice(int index) {
    return _methodChannel.invokeMethod<void>(_kMethodDvcSetPlayout, {_kArgDvcIndex:index} );
  }
  
  Future<void> setRecordingDevice(int index) {
    return _methodChannel.invokeMethod<void>(_kMethodDvcSetRecording, {_kArgDvcIndex:index} );
  }

  Future<void> setVideoDevice(int index) {
    return _methodChannel.invokeMethod<void>(_kMethodDvcSetVideo, {_kArgDvcIndex:index} );
  }

  Future<void> setVideoParams(VideoData vdo) {
    return _methodChannel.invokeMethod<void>(_kMethodDvcSetVideoParams, vdo.toMap() );
  }
  
  //Future<void> routeAudioTo(iOSAudioRoute route) {
  //  return _methodChannel.invokeMethod<void>(_kMethodDvcRouteAudio, {_kArgIOSRoute:route} );
  //}
  
  
  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix video renderers

  Future<int?> videoRendererCreate() {
    return _methodChannel.invokeMethod<int>(_kMethodVideoRendererCreate, {});
  }

  Future<void> videoRendererSetSourceCall(int textureId, int callId) {
    return _methodChannel.invokeMethod<void>(_kMethodVideoRendererSetSrc, 
      {_kArgVideoTextureId:textureId, _kArgCallId:callId} );
  }

  
  Future<void> videoRendererDispose(int textureId) {
    return _methodChannel.invokeMethod<void>(_kMethodVideoRendererDispose, {_kArgVideoTextureId:textureId} );
  }
  
  ////////////////////////////////////////////////////////////////////////////////////////
  //Android specific implmentation

  Future<void>? setForegroundMode(bool enabled) {    
    if(Platform.isAndroid) {
      return _methodChannel.invokeMethod<void>(_kMethodDvcSetForegroundMode, {_kArgForeground:enabled} );
    }
    return null;
  }

  Future<bool?>? isForegroundMode() {
    if(Platform.isAndroid) {
      return _methodChannel.invokeMethod<bool?>(_kMethodDvcIsForegroundMode, {});
    }
    return null;    
  }
  
  

  ////////////////////////////////////////////////////////////////////////////////////////
  //Siprix callbacks handler

  Future<void> _eventsHandler(MethodCall methodCall) async {
    debugPrint('event ${methodCall.method.toString()} ${methodCall.arguments.toString()}');
    if(methodCall.arguments is! Map<dynamic, dynamic>) {
      return;
    }

    Map<dynamic, dynamic> argsMap = methodCall.arguments as Map<dynamic, dynamic>;
    switch(methodCall.method) {
      case _kOnAccountRegState  : onAccountRegState(argsMap);  break;
      case _kOnNetworkState     : onNetworkState(argsMap);     break;
      case _kOnPlayerState      : onPlayerState(argsMap);      break;

      case _kOnTrialModeNotif   : onTrialModeNotif(argsMap);   break;
      case _kOnDevicesChanged   : onDevicesChanged(argsMap);   break;
      
      case _kOnCallIncoming     : onCallIncoming(argsMap);     break;
      case _kOnCallAcceptNotif  : onCallAcceptNotif(argsMap);  break;
      case _kOnCallConnected    : onCallConnected(argsMap);    break;      
      case _kOnCallTerminated   : onCallTerminated(argsMap);   break;
      case _kOnCallProceeding   : onCallProceeding(argsMap);   break;      
      case _kOnCallDtmfReceived : onCallDtmfReceived(argsMap); break;
      case _kOnCallTransferred  : onCallTransferred(argsMap);  break;
      case _kOnCallRedirected   : onCallRedirected(argsMap);   break;
      case _kOnCallSwitched     : onCallSwitched(argsMap);     break;
      case _kOnCallHeld         : onCallHeld(argsMap);         break;
    }    
  }

  void onAccountRegState(Map<dynamic, dynamic> argsMap) {
    AccRegStateArg arg = AccRegStateArg();
    if(arg.fromMap(argsMap)) {
      accListener?.regStateChanged?.call(arg.accId, arg.regState, arg.response);
    }
  }

  void onNetworkState(Map<dynamic, dynamic> argsMap) {
    NetworkStateArg arg = NetworkStateArg();
    if(arg.fromMap(argsMap)) {      
      netListener?.networkStateChanged?.call(arg.name, arg.state);
    }    
  }
  

  void onPlayerState(Map<dynamic, dynamic> argsMap) {
    PlayerStateArg arg =PlayerStateArg();
    if(arg.fromMap(argsMap)) {
      callListener?.playerStateChanged?.call(arg.playerId, arg.state);
    }
  }
  
  void onCallProceeding(Map<dynamic, dynamic> argsMap) {
    CallProceedingArg arg = CallProceedingArg();
    if(arg.fromMap(argsMap)) {
      callListener?.proceeding?.call(arg.callId, arg.response);
    }
  }

  void onCallTerminated(Map<dynamic, dynamic> argsMap) {
    CallTerminatedArg arg = CallTerminatedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.terminated?.call(arg.callId, arg.statusCode);
    }
  }

  void onCallConnected(Map<dynamic, dynamic> argsMap) {
    CallConnectedArg arg = CallConnectedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.connected?.call(arg.callId, arg.from, arg.to, arg.withVideo);
    }
  }

  void onCallIncoming(Map<dynamic, dynamic> argsMap) {
    CallIncomingArg arg = CallIncomingArg();
    if(arg.fromMap(argsMap)) {
      callListener?.incoming?.call(arg.callId, arg.accId, arg.withVideo, arg.from, arg.to);
    }
  }

  void onCallAcceptNotif(Map<dynamic, dynamic> argsMap) {
    CallAcceptNotifArg arg = CallAcceptNotifArg();
    if(arg.fromMap(argsMap)) {
      callListener?.acceptNotif?.call(arg.callId, arg.withVideo);
    }
  }
  

  void onCallDtmfReceived(Map<dynamic, dynamic> argsMap) {
    CallDtmfReceivedArg arg = CallDtmfReceivedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.dtmfReceived?.call(arg.callId, arg.tone);
    }
  }

  void onCallTransferred(Map<dynamic, dynamic> argsMap) {
    CallTransferredArg arg = CallTransferredArg();
    if(arg.fromMap(argsMap)) {
      callListener?.transferred?.call(arg.callId, arg.statusCode);
    }
  }

  void onCallRedirected(Map<dynamic, dynamic> argsMap) {
    CallRedirectedArg arg = CallRedirectedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.redirected?.call(arg.origCallId, arg.relatedCallId, arg.referTo);
    }
  }

  void onCallHeld(Map<dynamic, dynamic> argsMap) {
    CallHeldArg arg = CallHeldArg();
    if(arg.fromMap(argsMap)) {
      callListener?.held?.call(arg.callId, arg.state);
    }
  }

  void onCallSwitched(Map<dynamic, dynamic> argsMap) {
    CallSwitchedArg arg = CallSwitchedArg();
    if(arg.fromMap(argsMap)) {
      callListener?.switched?.call(arg.callId);
    }
  }

  void onDevicesChanged(Map<dynamic, dynamic> argsMap) {
    dvcListener?.devicesChanged?.call();
  }

  void onTrialModeNotif(Map<dynamic, dynamic> argsMap) {
    trialListener?.notified?.call();
  }

  
  
}//SiprixVoipSdk

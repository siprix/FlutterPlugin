import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

import 'siprix_voip_sdk.dart';
import 'cdrs_model.dart';

////////////////////////////////////////////////////////////////////////////////////////
//Call destination

class CallDestination{
  CallDestination(this.toExt, this.fromAccId, this.withVideo);
  String toExt = "";  
  int    fromAccId = 0;
  bool   withVideo = false;
  int?   inviteTimeout;
  Map<String, String>? xheaders={};

  Map<String, dynamic> toMap() {
    Map<String, dynamic> ret = {
      'extension': toExt,
      'accId'    : fromAccId,
      'withVideo': withVideo
    };
    if(xheaders !=null)      ret['xheaders']      = xheaders;
    if(inviteTimeout !=null) ret['inviteTimeout'] = inviteTimeout;
    
    return ret;
  }
}


////////////////////////////////////////////////////////////////////////////////////////
//Call state

enum CallState{
  dialing,      //Outgoing call just initiated
  proceeding,   //Outgoing call in progress, received 100Trying or 180Ringing
  
  ringing,      //Incoming call just received
  rejecting,    //Incoming call rejecting after invoke 'call.reject'
  accepting,    //Incoming call accepting after invoke 'call.accept'
  
  connected,    //Call successfully established, RTP is flowing
  
  disconnecting,//Call disconnecting after invoke 'call.bye'
  
  holding,      //Call holding (renegotiating RTP stream states)
  held,         //Call held, RTP is NOT flowing

  transferring, //Call transferring
}

extension CallStateExtension on CallState {
  String get name {
    switch(this) {
      case CallState.dialing:    return "Dialing";
      case CallState.proceeding: return "Proceeding";
      case CallState.ringing:    return "Ringing";
      case CallState.rejecting:  return "Rejecting";
      case CallState.accepting:  return "Accepting";
      case CallState.connected:  return "Connected";
      case CallState.holding:    return "Holding";
      case CallState.held:       return "Held";
      case CallState.disconnecting: return "Disconnecting";
      case CallState.transferring:  return "Transferring";
    }
  }  
}

////////////////////////////////////////////////////////////////////////////////////////
//Hold state

enum HoldState {
  none(SiprixVoipSdk.kHoldStateNone, "None"),
  local(SiprixVoipSdk.kHoldStateLocal, "Local"), 
  remote(SiprixVoipSdk.kHoldStateRemote, "Remote"),
  localAndRemote(SiprixVoipSdk.kHoldStateLocalAndRemote, "LocalAndRemote");

  const HoldState(this.id, this.name);
  final int id;
  final String name;

  static HoldState from(int val) { 
    switch(val) {
      case SiprixVoipSdk.kHoldStateLocal: return HoldState.local;
      case SiprixVoipSdk.kHoldStateRemote: return HoldState.remote;
      case SiprixVoipSdk.kHoldStateLocalAndRemote: return HoldState.localAndRemote;
      default: return HoldState.none;
    }
  } 
}


////////////////////////////////////////////////////////////////////////////////////////
//PlayerState

enum PlayerState 
{
  started(SiprixVoipSdk.kPlayerStateStarted, "Started"),
  stoppped(SiprixVoipSdk.kPlayerStateStopped,"Stopped"),
  failed(SiprixVoipSdk.kPlayerStateFailed,   "Failed"); 

  const PlayerState(this.id, this.name);
  final int id;
  final String name;

  static PlayerState from(int val) { 
    switch (val) {
      case SiprixVoipSdk.kPlayerStateStarted: return PlayerState.started;      
      case SiprixVoipSdk.kPlayerStateStopped: return PlayerState.stoppped;
      default:  return PlayerState.failed;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//App-based contact name resolver

typedef ResolveContactNameCallback = String Function(String phoneNumber);
typedef CallSwitchedCallCallback = void Function(int callId);
typedef NewIncomingCallCallback = void Function();

////////////////////////////////////////////////////////////////////////////////////////
//Call model

class CallModel extends ChangeNotifier {
  CallModel(this.myCallId, this.accUri, this.remoteExt, this.isIncoming, this.hasSecureMedia, this._hasVideo, [this._logs]) {
    _state = isIncoming ? CallState.ringing : CallState.dialing;
  }
  
  final int myCallId;
  final String accUri;     //Account URI used to accept/make this call

  final String remoteExt;  //Phone number(extension) of remote side
  
  String displName="";     //Contact name
  
  String _receivedDtmf="";
  String _response="";
  CallState _state = CallState.dialing;
  HoldState _holdState = HoldState.none;
  DateTime _startTime = DateTime.now();
  Duration _duration = const Duration(seconds: 0);
  bool _hasVideo;
  int _playerId=0;
  final bool isIncoming;
  final bool hasSecureMedia;
  bool _isMicMuted=false;
  bool _isCamMuted=false;
  bool _isRecStarted=false;
  final ILogsModel? _logs;
  
  CallState get state => _state;
  HoldState get holdState => _holdState;

  String get nameAndExt => displName.isEmpty ? remoteExt : "$displName ($remoteExt)";
    
  String get durationStr => formatDuration(_duration);
  String get receivedDtmf => _receivedDtmf;
  String get response => _response;
    
  bool get isMicMuted => _isMicMuted;
  bool get isCamMuted => _isCamMuted;  
  bool get isRecStarted => _isRecStarted;  
  bool get hasVideo   => _hasVideo;
  int  get playerId   => _playerId;
  
  bool get isLocalHold => (_holdState==HoldState.local)||(_holdState==HoldState.localAndRemote);
  bool get isRemoteHold => (_holdState==HoldState.remote)||(_holdState==HoldState.localAndRemote);

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    int hours = duration.inHours;
    if(hours != 0) {
      return "${twoDigits(hours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void calcDuration() {
    if(_state != CallState.connected) return;

    _duration = DateTime.now().difference(_startTime);
    notifyListeners();
  }

  void updateDisplName(String newDisplName) {
    displName = newDisplName;
    notifyListeners();
  }

  Future<void> bye() async{
    _logs?.print('Ending callId:$myCallId');
    try{
      await SiprixVoipSdk().bye(myCallId);
      _state = CallState.disconnecting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Cant end callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> accept([bool withVideo=true]) async{
    _logs?.print('Accepting callId:$myCallId withVideo:$withVideo');
    try{
      await SiprixVoipSdk().accept(myCallId, withVideo);
      _state = CallState.accepting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t accept callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }
  
  Future<void> reject() async{
    _logs?.print('Rejecting callId:$myCallId');
    try {
      await SiprixVoipSdk().reject(myCallId, 486);//Send '486 Busy now'
      _state = CallState.rejecting;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t reject callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> muteMic(bool mute) async{
    _logs?.print('Muting $mute mic of call $myCallId');

    try {
      await SiprixVoipSdk().muteMic(myCallId, mute);
      _isMicMuted = mute;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t mute call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> muteCam(bool mute) async{
    _logs?.print('Muting $mute camera of call $myCallId');

    try {
      await SiprixVoipSdk().muteCam(myCallId, mute);
      _isCamMuted = mute;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t mute camera of call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> sendDtmf(String tone) async {
    _logs?.print('Sending dtmf callId:$myCallId tone:$tone');
    try{
      await SiprixVoipSdk().sendDtmf(myCallId, tone, 200, 50);
    } on PlatformException catch (err) {
      _logs?.print('Can\'t send dtmf callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> playFile(String pathToMp3File, {bool loop=false}) async {
    _logs?.print('Starting play file callId:$myCallId $pathToMp3File loop:$loop');
    try {
      _playerId = await SiprixVoipSdk().playFile(myCallId, pathToMp3File, loop) ?? 0;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t start playing file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> stopPlayFile() async {
    if(_playerId==0) return;
    _logs?.print('Stop play file callId:$myCallId playerId:$_playerId');
    try {
      await SiprixVoipSdk().stopPlayFile(_playerId);
    } on PlatformException catch (err) {
      _logs?.print('Can\'t stop playing file playerId:$_playerId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> recordFile(String pathToMp3File) async {
    _logs?.print('Starting record file callId:$myCallId $pathToMp3File');
    try {
      await SiprixVoipSdk().recordFile(myCallId, pathToMp3File);
      _isRecStarted = true;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t start recording file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> stopRecordFile() async {
    if(!_isRecStarted) return;
    _logs?.print('Stop record file callId:$myCallId');
    try {
      await SiprixVoipSdk().stopRecordFile(myCallId);
      _isRecStarted = false;
    } on PlatformException catch (err) {
      _logs?.print('Can\'t stop recording file callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> hold() async {
    _logs?.print('Hold callId:$myCallId');
    try{
      await SiprixVoipSdk().hold(myCallId);
      _state = CallState.holding;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t hold callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> transferBlind(String toExt) async {
    _logs?.print('Transfer blind callId:$myCallId to:"$toExt"');
    if(toExt.isEmpty) return;
    try{
      await SiprixVoipSdk().transferBlind(myCallId, toExt);
      
      _state = CallState.transferring;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t transfer callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> transferAttended(int toCallId) async {
    _logs?.print('Transfer attended callId:$myCallId to callId $toCallId');
    
    try{
      await SiprixVoipSdk().transferAttended(myCallId, toCallId);
      
      _state = CallState.transferring;
      notifyListeners();
    } on PlatformException catch (err) {
      _logs?.print('Can\'t transfer callId:$myCallId Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  
  //Event handlers
  void onProceeding(String resp) {
    _state = CallState.proceeding;
    _response = resp;
    notifyListeners();
  }

  void onConnected(String hdrFrom, String hdrTo, bool withVideo) {
    _state = CallState.connected;
    _startTime = DateTime.now();
    _hasVideo = withVideo;
    _duration = const Duration(seconds: 0);
    notifyListeners();
  }

  void onDtmfReceived(int tone) {
    if(tone == 10) { _receivedDtmf += '*'; }else
    if(tone == 11) { _receivedDtmf += '#'; }
    else           { _receivedDtmf += tone.toString(); }
    notifyListeners();
  }

  void onTransferred(int statusCode) {
    _state = CallState.connected;
    notifyListeners();
  }

  void onHeld(HoldState holdState) {
    _holdState = holdState;
    _state = (holdState==HoldState.none) ?  CallState.connected : CallState.held;
    notifyListeners();
  }

}//CallModel



////////////////////////////////////////////////////////////////////////////////////////
//Calls list model

class CallsModel extends ChangeNotifier {
  final List<CallModel> _callItems = [];
  final IAccountsModel _accountsModel;
  final CdrsModel? _cdrs;
  final ILogsModel? _logs;
  
  static const int kEmptyCallId=0;
  int _switchedCallId = kEmptyCallId;
  bool _confModeStarted = false;
    
  CallsModel(this._accountsModel, [this._logs, this._cdrs]) {
    SiprixVoipSdk().callListener = CallStateListener(
      playerStateChanged: onPlayerStateChanged,
      proceeding : onProceeding, 
      incoming : onIncoming, 
      acceptNotif: onAcceptNotif,
      connected : onConnected, 
      terminated : onTerminated, 
      transferred : onTransferred,
      redirected : onRedirected,
      dtmfReceived : onDtmfReceived,
      switched : onSwitched,
      held : onHeld
    );
  }

  ResolveContactNameCallback? onResolveContactName;  
  CallSwitchedCallCallback? onSwitchedCall;
  NewIncomingCallCallback? onNewIncomingCall;

  bool get isEmpty => _callItems.isEmpty;
  int get length => _callItems.length;
  CallModel operator [](int i) => _callItems[i]; // get

  int get switchedCallId => _switchedCallId;
  bool get confModeStarted => _confModeStarted;
  
  CallModel? switchedCall() {
    final int index = _callItems.indexWhere((c) => c.myCallId==_switchedCallId);
    return (index == -1) ? null : _callItems[index];
  }

  bool contains(int callId) {
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    return (index != -1);
  }

  bool hasConnectedFewCalls() {
    int counter = 0;
    for(CallModel m in _callItems) {
      counter += (m.state == CallState.connected) ? 1 : 0;
    }
    return counter > 1;
  }

  void calcDuration() {
    for(var c in _callItems) {
      c.calcDuration();
    }
  }

  Future<void> invite(CallDestination dest) async{
    _logs?.print('Trying to invite ${dest.toExt} from account:${dest.fromAccId}');
    try {
      int callId = await SiprixVoipSdk().invite(dest) ?? 0;
      
      String accUri       = _accountsModel.getUri(dest.fromAccId);
      bool hasSecureMedia = _accountsModel.hasSecureMedia(dest.fromAccId);

      CallModel newCall = CallModel(callId, accUri, dest.toExt, false, hasSecureMedia, dest.withVideo, _logs);    
      _callItems.add(newCall);
      _cdrs?.add(newCall);
      _postResolveContactName(newCall);

      if(_switchedCallId == kEmptyCallId) {
         _switchedCallId = callId;
      }

      notifyListeners();

    } on PlatformException catch (err) {
      _logs?.print('Can\'t invite Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> switchToCall(int callId) async{
    _logs?.print('Switching mixer to call $callId');

    try {
      await SiprixVoipSdk().switchToCall(callId);
      _confModeStarted = false;
      //Value '_switchedCallId' will set in the callback 'onSwitched'

    } on PlatformException catch (err) {
      _logs?.print('Can\'t switch to call. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> makeConference() async{
    try {
      if(_confModeStarted){
        _logs?.print('Ending conference, switch mixer to call $_switchedCallId');
        await SiprixVoipSdk().switchToCall(_switchedCallId);
        _confModeStarted = false;
      }
      else {
        _logs?.print('Joining all calls to conference');
        await SiprixVoipSdk().makeConference(); 
        _confModeStarted = true;
      }

    } on PlatformException catch (err) {
      _logs?.print('Can\'t make conference. Err: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  //Events handlers
  void onProceeding(int callId, String response) {
    _logs?.print('onProceeding callId:$callId response:$response');

    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].onProceeding(response);
  }

  void onIncoming(int callId, int accId, bool withVideo, String hdrFrom, String hdrTo) {
    _logs?.print('onIncoming callId:$callId accId:$accId from:$hdrFrom to:$hdrTo withVideo:$withVideo');

    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) return;//Call already exists, skip

    String accUri = _accountsModel.getUri(accId);
    bool hasSecureMedia = _accountsModel.hasSecureMedia(accId);

    CallModel newCall = CallModel(callId, accUri, parseExt(hdrFrom), true, hasSecureMedia, withVideo, _logs);
    newCall.displName = parseDisplayName(hdrFrom);
    _callItems.add(newCall);

    if(_switchedCallId == kEmptyCallId) {
       _switchedCallId = callId;
    }

    notifyListeners();

    _cdrs?.add(newCall);

    _postResolveContactName(newCall);
    onNewIncomingCall?.call();
  }

  void onAcceptNotif(int callId, bool withVideo) {
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].accept(withVideo);
  }

  void onConnected(int callId, String from, String to, bool withVideo) {
    _logs?.print('onConnected callId:$callId from:$from to:$to withVideo:$withVideo');
    _cdrs?.setConnected(callId, from, to, withVideo);

    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].onConnected(from, to, withVideo);
  }

  void onTerminated(int callId, int statusCode) {
    _logs?.print('onTerminated callId:$callId statusCode:$statusCode');
    
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    
    if(index != -1) {
      _cdrs?.setTerminated(callId, statusCode, _callItems[index].displName, _callItems[index].durationStr);

      _callItems.removeAt(index);

      if(_confModeStarted && !hasConnectedFewCalls()) {
        _confModeStarted = false;
      }

      notifyListeners();
    }
  }

  void onTransferred(int callId, int statusCode) {
    _logs?.print('onTransferred callId:$callId statusCode:$statusCode');
    
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].onTransferred(statusCode);
  }

  void onRedirected(int origCallId, int relatedCallId, String referTo) {
    _logs?.print('onRedirected origCallId:$origCallId relatedCallId:$relatedCallId to:$referTo');
    
    //Find 'origCallId'
    int index = _callItems.indexWhere((c) => c.myCallId==origCallId);
    if(index == -1) return;

    //Clone 'origCallId' and add to collection of calls as related one
    CallModel origCall = _callItems[index];
    CallModel relatedCall = CallModel(relatedCallId, origCall.accUri, parseExt(referTo), false, origCall.hasSecureMedia, origCall.hasVideo, _logs);
    _callItems.add(relatedCall);
    notifyListeners();
  }

  void onDtmfReceived(int callId, int tone) {
    _logs?.print('onDtmfReceived callId:$callId tone:$tone');
    
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].onDtmfReceived(tone);
  }

  void onHeld(int callId, HoldState s) {
    _logs?.print('onHeld callId:$callId $s');
    
    int index = _callItems.indexWhere((c) => c.myCallId==callId);
    if(index != -1) _callItems[index].onHeld(s);
    notifyListeners();
  }

  void onSwitched(int callId) {
    _logs?.print('onSwitched callId:$callId');
    
    if(_switchedCallId != callId) {
      _switchedCallId = callId;
      notifyListeners();
      onSwitchedCall?.call(_switchedCallId);
    }
  }
    
  void onPlayerStateChanged(int playerId, PlayerState state) {
    _logs?.print('onPlayerStateChanged playerId:$playerId $state');
  }


  static String parseExt(String uri) {
    //uri format: "displName" <sip:ext@domain:port>
    final int startIndex = uri.indexOf(':');
    if(startIndex == -1) return "";

    final int endIndex = uri.indexOf('@', startIndex + 1);
    return (endIndex == -1) ? "" : uri.substring(startIndex+1, endIndex);
  }

  static String parseDisplayName(String uri) {
    //uri format: "displName" <sip:ext@domain:port>
    final int startIndex = uri.indexOf('"');
    if(startIndex == -1) return "";

    final int endIndex = uri.indexOf('"', startIndex + 1);
    return (endIndex == -1) ? "" : uri.substring(startIndex+1, endIndex);
  }

  void _postResolveContactName(CallModel c) {    
    if(onResolveContactName != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
          String? name = onResolveContactName?.call(c.remoteExt);
          if((name != null)&&(name != "")) c.updateDisplName(name);
      });
    }
  }

}//CallsModel


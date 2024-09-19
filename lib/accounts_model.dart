// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart'; 
import 'package:flutter/material.dart';

import 'dart:convert';
import 'logs_model.dart';
import 'siprix_voip_sdk.dart';
import 'network_model.dart';

////////////////////////////////////////////////////////////////////////////////////////
//InitData - holds argument for Creating siprix module

class InitData {
  String? license;
  String? noCameraImgPath;
  LogLevel? logLevelFile;
  LogLevel? logLevelIde;
  int?  rtpStartPort;
  bool? tlsVerifyServer;
  bool? singleCallMode;
  bool? shareUdpTransport;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> ret = {};
    if(license!=null)           ret['license'] = license;
    if(noCameraImgPath!=null)   ret['noCameraImgPath'] = noCameraImgPath;    
    if(logLevelFile!=null)      ret['logLevelFile'] = logLevelFile!.id;
    if(logLevelIde!=null)       ret['logLevelIde']  = logLevelIde!.id;
    if(rtpStartPort!=null)      ret['rtpStartPort'] = rtpStartPort;
    if(tlsVerifyServer!=null)   ret['tlsVerifyServer'] = tlsVerifyServer;
    if(singleCallMode!=null)    ret['singleCallMode'] = singleCallMode;
    if(shareUdpTransport!=null) ret['shareUdpTransport'] = shareUdpTransport;
    return ret;
  }
}//InitData


////////////////////////////////////////////////////////////////////////////////////////
//VideoData - holds video capturer params

class VideoData {  
  String? noCameraImgPath;  
  int?  framerateFps;
  int?  bitrateKbps;
  int?  height;
  int?  width;  

  Map<String, dynamic> toMap() {
    Map<String, dynamic> ret = {};    
    if(noCameraImgPath!=null) ret['noCameraImgPath'] = noCameraImgPath;    
    if(framerateFps!=null)    ret['framerateFps'] = framerateFps;
    if(bitrateKbps!=null)     ret['bitrateKbps']  = bitrateKbps;
    if(height!=null)          ret['height'] = height;
    if(width!=null)           ret['width'] = width;
    return ret;
  }
}//VideoData

////////////////////////////////////////////////////////////////////////////////////////
//Codec helper

class Codec {
  Codec(this.id, {this.selected=true});
  int  id;
  bool selected;

  static String name(int codecId) {
    switch(codecId) {
      case SiprixVoipSdk.kAudioCodecOpus: return "OPUS/48000";
      case SiprixVoipSdk.kAudioCodecISAC16: return "ISAC/16000";
      case SiprixVoipSdk.kAudioCodecISAC32: return "ISAC/32000";
      case SiprixVoipSdk.kAudioCodecG722: return "G722/8000";
      case SiprixVoipSdk.kAudioCodecILBC: return "ILBC/8000";
      case SiprixVoipSdk.kAudioCodecPCMU: return "PCMU/8000";
      case SiprixVoipSdk.kAudioCodecPCMA: return "PCMA/8000";
      case SiprixVoipSdk.kAudioCodecDTMF: return "DTMF/8000";
      case SiprixVoipSdk.kAudioCodecCN:   return "CN/8000";
      case SiprixVoipSdk.kVideoCodecH264: return "H264";
      case SiprixVoipSdk.kVideoCodecVP8:  return "VP8";
      case SiprixVoipSdk.kVideoCodecVP9:  return "VP9";
      case SiprixVoipSdk.kVideoCodecAV1:  return "AV1";
      default: return "Undefined";
    }
  }

  static List<int> availableCodecs(bool audio) {
    if(audio) {
      return [
        SiprixVoipSdk.kAudioCodecOpus,
        SiprixVoipSdk.kAudioCodecISAC16,
        SiprixVoipSdk.kAudioCodecISAC32,
        SiprixVoipSdk.kAudioCodecG722,
        SiprixVoipSdk.kAudioCodecILBC,
        SiprixVoipSdk.kAudioCodecPCMU,
        SiprixVoipSdk.kAudioCodecPCMA,
        SiprixVoipSdk.kAudioCodecILBC,
        SiprixVoipSdk.kAudioCodecCN,
        SiprixVoipSdk.kAudioCodecDTMF
      ];
    }else {
      return [
        SiprixVoipSdk.kVideoCodecH264,
        SiprixVoipSdk.kVideoCodecVP8,
        SiprixVoipSdk.kVideoCodecVP9,
        SiprixVoipSdk.kVideoCodecAV1,
      ];
    }
  }

  static List<Codec> getCodecsList(List<int>? selectedCodecsIds, {bool audio=true}) {
    List<Codec> ret = <Codec>[];
    if(selectedCodecsIds != null) {
      for(var c in selectedCodecsIds) {
        ret.add(Codec(c, selected:true));
      }

      for(var c in Codec.availableCodecs(audio)) {
        if(ret.indexWhere((codec) => (codec.id == c))==-1) {
          ret.add(Codec(c, selected:false));          
        }
      }
    }
    else {
      for(var c in Codec.availableCodecs(audio)) {
        bool sel = ((c==SiprixVoipSdk.kAudioCodecDTMF)||(c==SiprixVoipSdk.kVideoCodecVP8)||
                  (c==SiprixVoipSdk.kAudioCodecOpus)||(c==SiprixVoipSdk.kAudioCodecPCMA));
        ret.add(Codec(c, selected:sel));       
      }
    }    
    
    return ret;
  }

  static List<int> getSelectedCodecsIds(List<Codec> codecsList) {
    List<int> ret = <int>[];
    for(var c in codecsList) {
      if(c.selected) ret.add(c.id);
    }
    return ret;
  }

  static bool validateSel(List<Codec> items) {    
    for(Codec c in items) {
      if(c.selected) return true;
    }
    return false;
  }

}

////////////////////////////////////////////////////////////////////////////////////////
//SecureMedia

enum SecureMedia {
  Disabled(SiprixVoipSdk.kSecureMediaDisabled, "Disabled"),  
  SdesSrtp(SiprixVoipSdk.kSecureMediaSdesSrtp, "SDES SRTP"), 
  DtlsSrtp(SiprixVoipSdk.kSecureMediaDtlsSrtp, "DTLS SRTP");

  const SecureMedia(this.id, this.name);
  final int id;
  final String name;

  static SecureMedia from(int val) {
    switch(val) {
      case SiprixVoipSdk.kSecureMediaSdesSrtp: return SecureMedia.SdesSrtp;
      case SiprixVoipSdk.kSecureMediaDtlsSrtp: return SecureMedia.DtlsSrtp;
      default:                                 return SecureMedia.Disabled;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//Account's registration state
enum RegState { success, failed, removed, inProgress}


////////////////////////////////////////////////////////////////////////////////////////
//Account model

class AccountModel {  
  AccountModel({this.sipServer="", this.sipExtension="", this.sipPassword="", this.expireTime});
  int      myAccId=0;
  RegState regState=RegState.inProgress;
  String   regText="";

  String  sipServer="";
  String  sipExtension="";
  String  sipPassword="";

  String? sipAuthId;  
  String? sipProxy;
  String? displName;
  String? userAgent;
  int?    expireTime;//seconds
  SipTransport? transport = SipTransport.udp;
  int?    port;
  String? tlsCaCertPath;
  bool?   tlsUseSipScheme;
  bool?   rtcpMuxEnabled;
  String? instanceId;
  String? ringTonePath;

  int?    keepAliveTime;//seconds
  bool?   rewriteContactIp;
  SecureMedia?  secureMedia;
    
  Map<String, String>? xheaders;
  List<int>? aCodecs;
  List<int>? vCodecs;

  String get uri => '$sipExtension@$sipServer';

  bool get hasSecureMedia => (secureMedia!=null)&&(secureMedia!=SecureMedia.Disabled);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'sipServer': sipServer,
      'sipExtension' : sipExtension,
      'sipPassword' : sipPassword
    };
    if(sipAuthId       !=null) ret['sipAuthId']       = sipAuthId;
    if(sipProxy        !=null) ret['sipProxy']        = sipProxy;
    if(displName       !=null) ret['displName']       = displName;
    if(userAgent       !=null) ret['userAgent']       = userAgent;
    if(expireTime      !=null) ret['expireTime']      = expireTime;
    if(transport       !=null) ret['transport']       = transport?.id;
    if(port            !=null) ret['port']            = port;
    if(tlsCaCertPath   !=null) ret['tlsCaCertPath']   = tlsCaCertPath;
    if(tlsUseSipScheme !=null) ret['tlsUseSipScheme'] = tlsUseSipScheme;
    if(rtcpMuxEnabled  !=null) ret['rtcpMuxEnabled']  = rtcpMuxEnabled;
    if(instanceId      !=null) ret['instanceId']      = instanceId;
    if(ringTonePath    !=null) ret['ringTonePath']    = ringTonePath;
    if(keepAliveTime   !=null) ret['keepAliveTime']   = keepAliveTime;    
    if(rewriteContactIp!=null) ret['rewriteContactIp']= rewriteContactIp;
    if(secureMedia     !=null) ret['secureMedia']     = secureMedia?.id;
    if(xheaders        !=null) ret['xheaders']        = xheaders;
    if(aCodecs         !=null) ret['aCodecs']         = aCodecs;
    if(vCodecs         !=null) ret['vCodecs']         = vCodecs;    
    return ret;
  }

  factory AccountModel.fromJson(Map<String, dynamic> jsonMap) {
    AccountModel acc = AccountModel();
    jsonMap.forEach((key, value) {
      if((key == 'sipServer')&&(value is String))     { acc.sipServer = value;    } else
      if((key == 'sipExtension')&&(value is String))  { acc.sipExtension = value; } else
      if((key == 'sipPassword')&&(value is String))   { acc.sipPassword = value;  } else
      if((key == 'sipAuthId')&&(value is String))     { acc.sipAuthId = value;    } else
      if((key == 'sipProxy')&&(value is String))      { acc.sipProxy = value;     } else
      if((key == 'displName')&&(value is String))     { acc.displName = value;    } else
      if((key == 'userAgent')&&(value is String))     { acc.userAgent = value;    } else
      if((key == 'expireTime')&&(value is int))       { acc.expireTime = value;   } else
      if((key == 'transport')&&(value is int))        { acc.transport = SipTransport.from(value);  } else      
      if((key == 'port')&&(value is int))             { acc.port = value;           } else
      if((key == 'tlsCaCertPath')&&(value is String)) { acc.tlsCaCertPath = value;  } else
      if((key == 'tlsUseSipScheme')&&(value is bool)) { acc.tlsUseSipScheme = value;} else
      if((key == 'rtcpMuxEnabled')&&(value is bool))  { acc.rtcpMuxEnabled = value; } else
      if((key == 'instanceId')&&(value is String))    { acc.instanceId = value;     } else
      if((key == 'ringTonePath')&&(value is String))  { acc.ringTonePath = value;   } else
      if((key == 'keepAliveTime')&&(value is int))    { acc.keepAliveTime = value;  } else
      if((key == 'rewriteContactIp')&&(value is bool)) { acc.rewriteContactIp = value; } else
      if((key == 'secureMedia')&&(value is int))      { acc.secureMedia = SecureMedia.from(value);  } else
      if((key == 'xheaders')&&(value is Map))         { acc.xheaders = Map<String, String>.from(value); } else
      if((key == 'aCodecs')&&(value is List))         { acc.aCodecs = List<int>.from(value); } else
      if((key == 'vCodecs')&&(value is List))         { acc.vCodecs = List<int>.from(value); } 
    });    
    return acc;
  }

}//AccountModel


typedef SaveChangesCallback = void Function(String jsonStr);
////////////////////////////////////////////////////////////////////////////////////////
//Accounts list model

class AccountsModel extends ChangeNotifier implements IAccountsModel {
  final List<AccountModel> _accounts = [];
  final ILogsModel? _logs;
  int? _selAccountIndex;
    
  AccountsModel([this._logs]) {
    SiprixVoipSdk().accListener = AccStateListener(
      regStateChanged : onRegStateChanged
    );
  }

  bool get isEmpty => _accounts.isEmpty;
  int get length => _accounts.length;
  int? get selAccountId => (_selAccountIndex==null) ? null : _accounts[_selAccountIndex!].myAccId;
  AccountModel operator [](int i) => _accounts[i];
  
  SaveChangesCallback? onSaveChanges;
  
  void _selectAccount(int? index) {
    if((index != null)&&(index >=0)&&(index < length)&&(_selAccountIndex != index)){
      _selAccountIndex = index;      
      _raiseSaveChanges();
      notifyListeners();
    }
  }

  void setSelectedAccountById(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    if(index != -1) _selectAccount(index);
  }

  void setSelectedAccountByUri(String uri) {
    int index = _accounts.indexWhere((a) => a.uri==uri);
    if(index != -1) _selectAccount(index);
  }

  @override
  String getUri(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    return (index == -1) ? "?" : _accounts[index].uri;
  }

  @override
  bool hasSecureMedia(int accId) {
    int index = _accounts.indexWhere((a) => a.myAccId==accId);
    return (index == -1) ? false : _accounts[index].hasSecureMedia;
  }

  Future<void> addAccount(AccountModel acc, {bool saveChanges=true}) async {
    _logs?.print('Adding new account: ${acc.uri}');

    try {
      acc.myAccId  = await SiprixVoipSdk().addAccount(acc) ?? 0;
      acc.regState = (acc.expireTime==0) ? RegState.removed : RegState.inProgress;
      acc.regText = (acc.expireTime==0) ? "Removed" : "In progress...";

      _integrateAddedAccount(acc, saveChanges);
      
    } on PlatformException catch (err) {
      if(err.code == SiprixVoipSdk.eDuplicateAccount.toString()) {
        int existingAccId = err.details;
        int idx = _accounts.indexWhere((account) => (account.myAccId == existingAccId));
        if(idx==-1) {
          //This case is possible in Android when:
          // - activity started as usual and initialized SDK Core
          // - activity destroyed, but SDK Core is still running (as Service)
          // - activity started again, loaded saved state and has to sync it
          acc.myAccId = existingAccId;
          acc.regState = (acc.expireTime==0) ? RegState.removed : RegState.success;
          acc.regText = (acc.expireTime==0) ? "Removed" : "200 OK";
          _integrateAddedAccount(acc, saveChanges);
        }
      }
      else {
        _logs?.print('Can\'t add account: ${err.code} ${err.message} ');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    } on Exception catch (err) {
         _logs?.print('Can\'t add account: ${err.toString()}');
        return Future.error(err.toString());
    }
  }

  void _integrateAddedAccount(AccountModel acc, bool saveChanges) {
    _accounts.add(acc);
      // ignore: prefer_conditional_assignment
      if(_selAccountIndex==null) {
        _selAccountIndex = 0;//modify only if null
      }
      notifyListeners();

      _logs?.print('Added successfully with id: ${acc.myAccId}');
      if(saveChanges) _raiseSaveChanges();
  }


  Future<void> updateAccount(AccountModel acc) async {
     try {
      int index = _accounts.indexWhere((a) => a.myAccId==acc.myAccId);
      if(index == -1) return Future.error("Account with specified id not found");
      
      await SiprixVoipSdk().updateAccount(acc);
      
      _accounts[index] = acc;
      
      notifyListeners();      
      _raiseSaveChanges();
      _logs?.print('Updated account accId:${acc.myAccId}');
      
    } on PlatformException catch (err) {
      _logs?.print('Can\'t update account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }
  
  Future<void> deleteAccount(int index) async {
    try {
      int accId = _accounts[index].myAccId;
      await SiprixVoipSdk().deleteAccount(accId);
      
      _accounts.removeAt(index);

      if(_selAccountIndex! >= length) {
        _selAccountIndex = _accounts.isEmpty ? null : length-1;
      }

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Deleted account accId:$accId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t delete account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> unregisterAccount(int index) async {
    try {
      //Send register request
      int accId = _accounts[index].myAccId;      
      await SiprixVoipSdk().unRegisterAccount(accId);

      //Update UI
      _accounts[index].expireTime = 0;
      _accounts[index].regState = RegState.inProgress;

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Unregistering accId:$accId');      

    } on PlatformException catch (err) {
      _logs?.print('Can\'t unregister account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  Future<void> registerAccount(int index) async {
    try {
      //Send register request (use 300sec as expire time when account not registered)
      int accId      = _accounts[index].myAccId;
      int? expireSec = _accounts[index].expireTime;
      if((expireSec == null)||(expireSec == 0)) { expireSec = 300; }
      await SiprixVoipSdk().registerAccount(accId, expireSec);

      //Update UI
      _accounts[index].expireTime = expireSec;
      _accounts[index].regState = RegState.inProgress;
      notifyListeners();

      //Save changes      
      _raiseSaveChanges();
      _logs?.print('Refreshing registration accId:$accId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t register account: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  void _raiseSaveChanges() {    
    if(onSaveChanges != null) {
      Future.delayed(Duration.zero, () {
          onSaveChanges?.call(storeToJson());
      });
    }
  }

  void onRegStateChanged(int accId, RegState state, String response) {
    _logs?.print('onRegStateChanged accId:$accId resp:\'$response\' ${state.toString()}');
    int idx = _accounts.indexWhere((account) => (account.myAccId == accId));
    if(idx == -1) return;

    AccountModel acc = _accounts[idx];
    acc.regText = response;
    acc.regState = state;
    
    notifyListeners();
  }

 
  bool loadFromJson(String accJsonStr) {
    try {
      if(accJsonStr.isEmpty) return false;

      Map<String, dynamic> map = jsonDecode(accJsonStr);
      if(map.containsKey('selAccIndex')) {
        _selAccountIndex = map['selAccIndex'];
      }

      if(map.containsKey('accList')) {
        final parsedList = map['accList'];
        for (var parsedAcc in parsedList) {
          addAccount(AccountModel.fromJson(parsedAcc), saveChanges:false);
        }
        return parsedList.isNotEmpty;
      }
      return false;
    }catch (e) {
      _logs?.print('Can\'t load accounts from json. Err: $e');
      return false;
    }
  }

  String storeToJson() {
    Map<String, dynamic> ret = {
      'selAccIndex': _selAccountIndex,
      'accList': _accounts};
    
    return jsonEncode(ret);
  }

}//AccountsModel


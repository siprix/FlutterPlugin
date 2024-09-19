import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calls_model.dart';

////////////////////////////////////////////////////////////////////////////////////////
//CDR = CallDetailRecord

class CdrModel extends ChangeNotifier {    
  CdrModel.fromCall(this.myCallId, this.accUri, this.remoteExt, this.incoming, this.hasVideo);
  CdrModel();
  static final _fmt = DateFormat('MMM dd, HH:mm a');
  
  int myCallId=0;
  
  String displName="";  //Contact name
  String remoteExt="";  //Phone number(extension) of remote side
  String accUri="";     //Account URI
  
  String duration="";
  bool hasVideo = false;
  bool incoming = false;
  bool connected = false;
  String madeAtDate = _fmt.format(DateTime.now());
  int statusCode=0;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'accUri' : accUri,
      'remoteExt': remoteExt,
      'displName': displName,
      'statusCode' : statusCode,
      'incoming' : incoming,
      'connected': connected,
      'duration': duration,
      'madeAt': madeAtDate,
      'hasVideo': hasVideo
    };
    return ret;
  }

  factory CdrModel.fromJson(Map<String, dynamic> jsonMap) {
    CdrModel cdr = CdrModel();
    jsonMap.forEach((key, value) {      
      if((key == 'accUri')&&(value is String))     { cdr.accUri    = value; } else
      if((key == 'remoteExt')&&(value is String))  { cdr.remoteExt = value; } else
      if((key == 'displName')&&(value is String))  { cdr.displName = value; } else      
      if((key == 'statusCode')&&(value is int))    { cdr.statusCode= value; } else
      if((key == 'incoming')&&(value is bool))     { cdr.incoming  = value; } else
      if((key == 'connected')&&(value is bool))    { cdr.connected = value; } else 
      if((key == 'duration')&&(value is String))   { cdr.duration  = value; } else
      if((key == 'madeAtDate')&&(value is String)) { cdr.madeAtDate= value; }
    });    
    return cdr;
  }

}//CdrModel



typedef SaveChangesCallback = void Function(String jsonStr);

////////////////////////////////////////////////////////////////////////////////////////
//Cdrs list model

class CdrsModel extends ChangeNotifier {
  final List<CdrModel> _cdrItems = [];
  static const int kMaxItems=10;

  bool get isEmpty => _cdrItems.isEmpty;
  int get length => _cdrItems.length;
  CdrModel operator [](int i) => _cdrItems[i]; // get

  SaveChangesCallback? onSaveChanges;

  void add(CallModel c) {
    CdrModel cdr = CdrModel.fromCall(c.myCallId, c.accUri, c.remoteExt, c.isIncoming, c.hasVideo);
    _cdrItems.insert(0, cdr);

    if(_cdrItems.length > kMaxItems) {
      _cdrItems.removeLast();
    }
    notifyListeners();
  }

  void setConnected(int callId, String from, String to, bool hasVideo) {
    int index = _cdrItems.indexWhere((c) => c.myCallId==callId);
    if(index == -1) return;
    
    CdrModel cdr = _cdrItems[index];
    cdr.hasVideo = hasVideo;
    cdr.connected = true;    
    notifyListeners();
  }

  void setTerminated(int callId, int statusCode, String displName, String duration) {
    int index = _cdrItems.indexWhere((c) => c.myCallId==callId);
    if(index == -1) return;
    
    CdrModel cdr = _cdrItems[index];
    cdr.displName = displName;
    cdr.statusCode = statusCode;
    cdr.duration = duration;
    
    notifyListeners();

    _raiseSaveChanges();
  }

  void remove(int index) {
    if((index>=0)&&(index < length)) {
      _cdrItems.removeAt(index);
      notifyListeners();
    }
  }

  bool loadFromJson(String cdrsJsonStr) {
    try {
      if(cdrsJsonStr.isEmpty) return false;
      final parsedList = (jsonDecode(cdrsJsonStr) as List).cast<Map<String, dynamic>>();
      
      _cdrItems.clear();
      for (var parsedCdr in parsedList) {
        _cdrItems.add(CdrModel.fromJson(parsedCdr));
      }
      
      notifyListeners();

      return parsedList.isNotEmpty;
    }catch (e) {      
      return false;
    }
  }

  void _raiseSaveChanges() {    
    if(onSaveChanges != null) {
      Future.delayed(Duration.zero, () {
          onSaveChanges?.call(storeToJson());
      });
    }
  }

  String storeToJson() {
    return jsonEncode(_cdrItems);
  }

}//CdrsModel


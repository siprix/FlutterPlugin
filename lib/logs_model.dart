import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'siprix_voip_sdk.dart';


////////////////////////////////////////////////////////////////////////////////////////
//LogLevel helper

enum LogLevel {
  stack(SiprixVoipSdk.kLogLevelStack, "Stack"),
  debug(SiprixVoipSdk.kLogLevelDebug, "Debug"),
  info(SiprixVoipSdk.kLogLevelInfo, "Info"), 
  warning(SiprixVoipSdk.kLogLevelWarning, "Warning"),
  error(SiprixVoipSdk.kLogLevelError, "Error"),
  none(SiprixVoipSdk.kLogLevelNone, "None");

  const LogLevel(this.id, this.name);
  final int id;
  final String name;
}


////////////////////////////////////////////////////////////////////////////////////////
//LogsModel helper

class LogsModel extends ChangeNotifier implements ILogsModel {  
  String _logStr = "";
  final bool _uiLog;
  
  String get logStr => _logStr;

  LogsModel(this._uiLog) {
    SiprixVoipSdk().trialListener = TrialModeListener(
      notified : onTrialModeNotified
    );
  }

  @override
  void print(String str) {
    debugPrint(str);

    if(_uiLog) {
      DateTime now = DateTime.now();    
      _logStr += DateFormat('kk:mm:ss ').format(now);
      _logStr += str;
      _logStr += '\n';
      notifyListeners();
    }
  }

  void onTrialModeNotified() {
    print("--- SIPRIX SDK is working in TRIAL mode ---");
  }  
}

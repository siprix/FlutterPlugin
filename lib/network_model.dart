import 'package:flutter/material.dart';

import 'siprix_voip_sdk.dart';

////////////////////////////////////////////////////////////////////////////////////////
//SipTransport helper

enum SipTransport {
  udp(SiprixVoipSdk.kSipTransportUdp, "UDP"),
  tcp(SiprixVoipSdk.kSipTransportTcp, "TCP"), 
  tls(SiprixVoipSdk.kSipTransportTls, "TLS");

  const SipTransport(this.id, this.name);
  final int id;
  final String name;

  static SipTransport from(int val) {
    switch(val) {
      case SiprixVoipSdk.kSipTransportTcp: return SipTransport.tcp;
      case SiprixVoipSdk.kSipTransportTls: return SipTransport.tls;      
      default:  return SipTransport.udp;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//Network state

enum NetState {
  lost(SiprixVoipSdk.kNetStateLost, "Lost"),
  restored(SiprixVoipSdk.kNetStateRestored, "Restored"), 
  switched(SiprixVoipSdk.kNetStateSwitched, "Switched");

  const NetState(this.id, this.name);
  final int id;
  final String name;

  static NetState from(int val) {
    switch(val) {      
      case SiprixVoipSdk.kNetStateRestored:  return NetState.restored;
      case SiprixVoipSdk.kNetStateSwitched:  return NetState.switched;
      default: return  NetState.lost;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//NetworkModel

class NetworkModel extends ChangeNotifier {    
  bool _networkLost = false;
  final ILogsModel? _logs;

  bool get networkLost => _networkLost;
  
  NetworkModel([this._logs]) {
    SiprixVoipSdk().netListener = NetStateListener(      
      networkStateChanged : onNetworkStateChanged
    );
  }

  void onNetworkStateChanged(String name, NetState state) {
    _logs?.print('onNetworkStateChanged name:$name $state');
    _networkLost = (state==NetState.lost);
    notifyListeners();
  }

}//NetworkModel
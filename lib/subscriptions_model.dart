// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart'; 
import 'package:flutter/material.dart';

import 'dart:convert';
import 'siprix_voip_sdk.dart';

////////////////////////////////////////////////////////////////////////////////////////
//SubscriptionModel

class SubscriptionModel extends ChangeNotifier {
  SubscriptionModel([this.toExt="", this.fromAccId=0, this.mimeSubType="", this.eventType=""]);
  int mySubscrId=0;
  String toExt="";
  int    fromAccId=0;
  String mimeSubType="";
  String eventType="";
  String label="";
  int? expireTime;

  SubscriptionState state = SubscriptionState.created;
  String response="";
  String accUri="";     //Account URI used to accept/make this call

  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = {
      'extension': toExt,
      'label'    : label,
      'accId'    : fromAccId,
      'accUri'   : accUri,
      'mimeSubType': mimeSubType,
      'eventType': eventType
    };
    if(expireTime !=null)  ret['expireTime']  = expireTime;
    return ret;
  }

  SubscriptionModel.fromJson(Map<String, dynamic> jsonMap) {
    jsonMap.forEach((key, value) {
      if((key == 'extension')&&(value is String))   { toExt = value;       } else
      if((key == 'label')&&(value is String))       { label = value;       } else
      if((key == 'accId')&&(value is int))          { fromAccId = value;   } else
      if((key == 'accUri')&&(value is String))      { accUri = value;      } else
      if((key == 'mimeSubType')&&(value is String)) { mimeSubType = value; } else
      if((key == 'eventType')&&(value is String))   { eventType = value;   } else
      if((key == 'expireTime')&&(value is int))     { expireTime = value;  }
    });
  }

  // ignore: non_constant_identifier_names
  factory SubscriptionModel.BLF(String ext, int accId) {
    return SubscriptionModel(ext, accId, "dialog-info+xml", "dialog");
  }

  // ignore: non_constant_identifier_names
  factory SubscriptionModel.Presence(String ext, int accId) {
    return SubscriptionModel(ext, accId, "pidf+xml", "presence");
  }

  void onSubscrStateChanged(SubscriptionState s, String resp) {
    response = resp;
    state = s;
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//Subscription state
enum SubscriptionState { created, updated, destroyed}

typedef SaveChangesCallback = void Function(String jsonStr);

////////////////////////////////////////////////////////////////////////////////////////
//Subscriptions list model

class SubscriptionsModel<T extends SubscriptionModel> extends ChangeNotifier {
  final T Function(Map<String, dynamic>) _itemCreateFunc;
  final List<T> _subscriptions = [];  
  final IAccountsModel _accountsModel;
  final ILogsModel? _logs;  
    
  SubscriptionsModel(this._accountsModel, this._itemCreateFunc, [this._logs]) {
    SiprixVoipSdk().subscrListener = SubscrStateListener(
      subscrStateChanged : onSubscrStateChanged
    );
  }

  bool get isEmpty => _subscriptions.isEmpty;
  int get length => _subscriptions.length;

  T operator [](int i) => _subscriptions[i];

  SaveChangesCallback? onSaveChanges;

  Future<void> addSubscription(T sub, {bool saveChanges=true}) async {
    _logs?.print('Adding new subscription ext:${sub.toExt} accId:${sub.fromAccId}');

    try {
      //When accUri present - model loaded from json, search accId as it might be changed
      if(sub.accUri.isNotEmpty) { sub.fromAccId = _accountsModel.getAccId(sub.accUri);  }
      else                      { sub.accUri    = _accountsModel.getUri(sub.fromAccId); }

      //Add
      sub.mySubscrId  = await SiprixVoipSdk().addSubscription(sub) ?? 0;
      
      _integrateAddedSubscription(sub, saveChanges);
      
    } on PlatformException catch (err) {
      if(err.code == SiprixVoipSdk.eSubscrAlreadyExist.toString()) {
        int existingSubscrId = err.details;
        int idx = _subscriptions.indexWhere((s) => (s.mySubscrId == existingSubscrId));
        if(idx==-1) {
          //This case is possible in Android when:
          // - activity started as usual and initialized SDK Core
          // - activity destroyed, but SDK Core is still running (as Service)
          // - activity started again, loaded saved state and has to sync it
          sub.mySubscrId = existingSubscrId;
          _integrateAddedSubscription(sub, saveChanges);
        }
      }
      else {
        _logs?.print('Can\'t add subscription: ${err.code} ${err.message} ');
        return Future.error((err.message==null) ? err.code : err.message!);
      }
    } on Exception catch (err) {
         _logs?.print('Can\'t add subscription: ${err.toString()}');
        return Future.error(err.toString());
    }
  }

  void _integrateAddedSubscription(T sub, bool saveChanges) {
    _subscriptions.add(sub);

    notifyListeners();

    _logs?.print('Added successfully with id: ${sub.mySubscrId}');
    if(saveChanges) _raiseSaveChanges();
  }
  
  Future<void> deleteSubscription(int index) async {
    try {
      int subscrId = _subscriptions[index].mySubscrId;
      await SiprixVoipSdk().deleteSubscription(subscrId);
      
      _subscriptions.removeAt(index);

      notifyListeners();
      _raiseSaveChanges();
      _logs?.print('Deleted subscription subscrId:$subscrId');

    } on PlatformException catch (err) {
      _logs?.print('Can\'t delete subscription: ${err.code} ${err.message}');
      return Future.error((err.message==null) ? err.code : err.message!);
    }
  }

  void onSubscrStateChanged(int subscrId, SubscriptionState s, String resp) {
    _logs?.print('onSubscrStateChanged subscrId:$subscrId resp:$resp ${s.toString()}');
    int idx = _subscriptions.indexWhere((sub) => (sub.mySubscrId == subscrId));
    if(idx != -1) {
      _subscriptions[idx].onSubscrStateChanged(s, resp);
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
    return jsonEncode(_subscriptions);
  }
 
  bool loadFromJson(String subscrJsonStr) {
    try {
      if(subscrJsonStr.isEmpty) return false;

      final List<dynamic> parsedList = jsonDecode(subscrJsonStr);
      for (var parsedSubscr in parsedList) {
        addSubscription(_itemCreateFunc(parsedSubscr), saveChanges:false);
      }
      return parsedList.isNotEmpty;
    }catch (e) {
      _logs?.print('Can\'t load subscriptions from json. Err: $e');
      return false;
    }
  }

}//SubscriptionsModel


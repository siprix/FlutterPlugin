import 'package:siprix_voip_sdk/subscriptions_model.dart';


enum BLFState {trying, proceeding, early, terminated, confirmed, unknown}

////////////////////////////////////////////////////////////////////////////////////////
//BlfSubscrModel

class BlfSubscrModel extends SubscriptionModel {
  BlfSubscrModel(String ext, int accId) : super(ext, accId, "dialog-info+xml", "dialog");

  BlfSubscrModel.fromJson(Map<String, dynamic> jsonMap) : super.fromJson(jsonMap);

  BLFState blfState = BLFState.unknown;
 
  @override
  void onSubscrStateChanged(SubscriptionState s, String resp) {
    //Parse 'response' (contains XML body received in NOTIFY request)
    // and use parsed attributes for UI rendering
    int startIndex = resp.indexOf('<state');
    if(startIndex != -1) {
      startIndex = resp.indexOf('>', startIndex);
      int endIndex = resp.indexOf('</state>', startIndex);
      String blfStateStr = resp.substring(startIndex+1, endIndex);
      switch (blfStateStr) {
        case "trying"     : blfState = BLFState.trying;     break;
        case "proceeding" : blfState = BLFState.proceeding; break;
        case "early"      : blfState = BLFState.early;      break;
        case "terminated" : blfState = BLFState.terminated; break;
        case "confirmed"  : blfState = BLFState.confirmed;  break;
        default: BLFState.unknown;
      }
    }

    state = s;
    response = resp;
    notifyListeners();
  }
}



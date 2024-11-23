import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/cdrs_model.dart';
import 'package:siprix_voip_sdk/devices_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/subscriptions_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

import 'account_add.dart';
import 'call_add.dart';
import 'subscr_add.dart';
import 'subscr_model.dart';
import 'settings.dart';
import 'home.dart';

void main() async {  
  LogsModel logsModel = LogsModel(true);//Set 'false' when logs won't rendering on UI
  CdrsModel cdrsModel = CdrsModel();//List of recent calls (Call Details Records)

  DevicesModel devicesModel = DevicesModel(logsModel);//List of devices
  NetworkModel networkModel = NetworkModel(logsModel);//Network state details
  AccountsModel accountsModel = AccountsModel(logsModel);//List of accounts
  CallsModel callsModel = CallsModel(accountsModel, logsModel, cdrsModel);//List of calls
  SubscriptionsModel subscrModel = SubscriptionsModel<BlfSubscrModel>(accountsModel, BlfSubscrModel.fromJson, logsModel);//List of subscriptions

  //Run app
  runApp(
    MultiProvider(providers:[
      ChangeNotifierProvider(create: (context) => accountsModel),
      ChangeNotifierProvider(create: (context) => networkModel),
      ChangeNotifierProvider(create: (context) => devicesModel),
      ChangeNotifierProvider(create: (context) => subscrModel),
      ChangeNotifierProvider(create: (context) => callsModel),
      ChangeNotifierProvider(create: (context) => cdrsModel),
      ChangeNotifierProvider(create: (context) => logsModel),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});  
  static String _ringtonePath="";

  @override
  State<MyApp> createState() => _MyAppState();

  static String getRingtonePath() => _ringtonePath;

  void writeRingtoneAsset() async {
    _ringtonePath = await writeAssetAndGetFilePath("ringtone.mp3");
  }

  static Future<String> writeAssetAndGetFilePath(String assetsFileName) async {
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$assetsFileName';
    
    var file = File(filePath);
    var exists = file.existsSync();
    debugPrint("writeAsset: '$filePath' exists:$exists");
    if (exists) return filePath;

    final byteData = await rootBundle.load('assets/$assetsFileName');
    await file.create(recursive: true);
    file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return filePath;
  }

  static Future<String> getRecFilePath(String recFileName) async {
    var homeFolder = await SiprixVoipSdk().homeFolder();
    var filePath = '$homeFolder$recFileName';
    return filePath;
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    _initializeSiprix(context.read<LogsModel>());
    widget.writeRingtoneAsset();//after initialize Siprix as uses its 'homeFolder'
    _readSavedState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        CallAddPage.routeName: (BuildContext context) => const CallAddPage(true),
        SettingsPage.routeName: (BuildContext context) => const SettingsPage(),
        AccountPage.routeName: (BuildContext context) => const AccountPage(),
        SubscrAddPage.routeName: (BuildContext context) => const SubscrAddPage(),
      },
      home: const HomePage(),
      title: 'Siprix VoIP app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
    );
  }

  void _initializeSiprix(LogsModel? logsModel) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.debug;
    iniData.logLevelIde = LogLevel.info;
    //iniData.listenTelState = true;
    //iniData.singleCallMode = false;
    //iniData.tlsVerifyServer = false;
    SiprixVoipSdk().initialize(iniData, logsModel);

    //Set video params (if required)
    //VideoData vdoData = VideoData();
    //vdoData.noCameraImgPath = await MyApp.writeAssetAndGetFilePath("noCamera.jpg");
    //vdoData.bitrateKbps = 800;
    //SiprixVoipSdk().setVideoParams(vdoData);
  }

  void _readSavedState() {
    SharedPreferences.getInstance().then((prefs) {
      String accJsonStr = prefs.getString('accounts') ?? '';
      String subsJsonStr = prefs.getString('subscriptions') ?? '';
      String cdrsJsonStr = prefs.getString('cdrs') ?? '';
      _loadModels(accJsonStr, cdrsJsonStr, subsJsonStr);
    });
  }

  void _loadModels(String accJsonStr, String cdrsJsonStr, String subsJsonStr) {
    //Accounts
    AccountsModel accsModel = context.read<AccountsModel>();
    accsModel.onSaveChanges = _saveAccountChanges;

    //Subscriptions
    SubscriptionsModel subsModel = context.read<SubscriptionsModel>();
    subsModel.onSaveChanges = _saveSubscriptionChanges;

    //CDRs (Call Details Records)
    CdrsModel cdrs = context.read<CdrsModel>();
    cdrs.onSaveChanges = _saveCdrsChanges;

    //Load accounts, then other models
    accsModel.loadFromJson(accJsonStr).then((val)  {
      subsModel.loadFromJson(subsJsonStr);
      cdrs.loadFromJson(cdrsJsonStr);
    });

    //Assign contact name resolver
    context.read<CallsModel>().onResolveContactName = _resolveContactName;

    //Load devices
    context.read<DevicesModel>().load();
  }

  void _saveCdrsChanges(String cdrsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cdrs', cdrsJsonStr);
    });
  }

  void _saveAccountChanges(String accountsJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('accounts', accountsJsonStr);
    });
  }

  void _saveSubscriptionChanges(String subscrJsonStr) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('subscriptions', subscrJsonStr);
    });
  }

  String _resolveContactName(String phoneNumber) {
    return ""; //TODO add own implementation
    //if(phoneNumber=="100") { return "MyFriend100"; } else
    //if(phoneNumber=="101") { return "MyFriend101"; } 
    //else                  { return "";        }
  }
}




/*
//=======================================//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';
import 'package:siprix_voip_sdk/siprix_voip_sdk.dart';

void main() async {  
  AccountsModel accountsModel = AccountsModel();
  CallsModel callsModel = CallsModel(accountsModel);
  runApp(
    MultiProvider(providers:[
      ChangeNotifierProvider(create: (context) => accountsModel),      
      ChangeNotifierProvider(create: (context) => callsModel),      
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});  

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeSiprix();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siprix VoIP app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        visualDensity: VisualDensity.adaptivePlatformDensity,        
      ),
      home: Scaffold(body:buildBody())
    );
  }

  Widget buildBody() {
    final accounts = context.watch<AccountsModel>();
    final calls = context.watch<CallsModel>();
    return Column(children: [
      ListView.separated(
        shrinkWrap: true,        
        itemCount: accounts.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          AccountModel acc = accounts[index];
          return 
            ListTile(title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(acc.regText),
                tileColor: Colors.blue
            ); 
        },
      ),
      ElevatedButton(onPressed: _addAccount, child: const Icon(Icons.add_card)),
      const Divider(height: 1),
      ListView.separated(
        shrinkWrap: true,
        itemCount: calls.length,        
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          CallModel call = calls[index];
          return 
            ListTile(title: Text(call.nameAndExt, style: Theme.of(context).textTheme.titleSmall),
              subtitle: Text(call.state.name), tileColor: Colors.amber,
              trailing: IconButton(
                onPressed: (){ call.bye(); },
                icon: const Icon(Icons.call_end))
            );
        },
      ),
      ElevatedButton(onPressed: _addCall, child: const Icon(Icons.add_call)),
      const Spacer(),
    ]);
  }

  void _initializeSiprix([LogsModel? logsModel]) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.info;    
    SiprixVoipSdk().initialize(iniData, logsModel);
  }

  void _addAccount() {
    AccountModel account = AccountModel();
    account.sipServer = "192.168.0.122";
    account.sipExtension = "1016";
    account.sipPassword = "12345";
    account.expireTime = 300;
    context.read<AccountsModel>().addAccount(account)
      .catchError(showSnackBar);
  }

  void _addCall() {
    final accounts = context.read<AccountsModel>();
    if(accounts.selAccountId==null) return;

    CallDestination dest = CallDestination("1012", accounts.selAccountId!, false);

    context.read<CallsModel>().invite(dest)
      .catchError(showSnackBar);
  }

  void showSnackBar(dynamic err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }
}
*/

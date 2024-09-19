# siprix_voip_sdk

Siprix VoIP SDK plugin for embedding voice and video communication (based on SIP/RTP protocols) into Flutter applications.

Example application contains ready to use SIP VoIP Client. It has ability to:
- Add multiple SIP accounts
- Send/receive multiple calls (Audio and Video)
- Manage calls with (hold, mute microphone/camera, play sound to call from file, send/receive DTMF,...)
 
Application's UI may not contain all the features, avialable in the SDK, they can be added later or manually in scope of the own application.


## Usage


### Prepare models

```dart
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
```
### Init SDK
```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeSiprix();
  }

  void _initializeSiprix([LogsModel? logsModel]) async {
    InitData iniData = InitData();
    iniData.license  = "...license-credentials...";
    iniData.logLevelFile = LogLevel.info;
    SiprixVoipSdk().initialize(iniData, logsModel);
  }
```

### Build UI, add accounts/calls
```dart
Widget buildBody() {
    final accounts = context.watch<AccountsModel>();
    final calls = context.watch<CallsModel>();
    return Column(children: [
      ListView.separated(shrinkWrap: true,
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
      ElevatedButton(onPressed: _addCall, child: const Icon(Icons.add_call)),
      ...
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
  
  
```

[More detailed integration guide](https://docs.siprix-voip.com/rst/flutter.html#integration-into-flutter-application)


## Limitations

Siprix doesn't provide VoIP services. For testing app you need an account(s) credentials from a SIP service provider(s). 
Some features may be not supported by all SIP providers.

Attached Siprix SDK works in trial mode and has limited call duration - it drops call after 60sec.
Upgrading to a paid license removes this restriction, enabling calls of any length.

Please contact [sales@siprix-voip.com](mailto:sales@siprix-voip.com) for more details.

## More resources

Product web site: [siprix-voip.com](https://siprix-voip.com)

Manual: [docs.siprix-voip.com](https://docs.siprix-voip.com)


## Screenshots

<a href="https://docs.siprix-voip.com/screenshots/Flutter_Accounts.png"  title="Accounts screenshot">
<img src="https://docs.siprix-voip.com/screenshots/Flutter_Accounts_Mini.png" width="50"></a>|<a href="https://docs.siprix-voip.com/screenshots/Flutter_CallAdd.png"  title="example image">
<img src="https://docs.siprix-voip.com/screenshots/Flutter_CallAdd_Mini.png" width="50"></a>|<a href="https://docs.siprix-voip.com/screenshots/Flutter_Calls.png"  title="example image">
<img src="https://docs.siprix-voip.com/screenshots/Flutter_Calls_Mini.png" width="50"></a>|<a href="https://docs.siprix-voip.com/screenshots/Flutter_CallsDtmf.png"  title="example image">
<img src="https://docs.siprix-voip.com/screenshots/Flutter_CallsDtmf_Mini.png" width="50"></a>|<a href="https://docs.siprix-voip.com/screenshots/Flutter_Logs.PNG"  title="example image">
<img src="https://docs.siprix-voip.com/screenshots/Flutter_Logs_Mini.png" width="50"></a>

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'dart:io' show Platform;

import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';
import 'package:siprix_voip_sdk/logs_model.dart';

import 'accounts_list.dart';
import 'settings.dart';
import 'calls_list.dart';

////////////////////////////////////////////////////////////////////////////////////////
//HomePage

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const routeName = "/home";

   @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {  
  final _pageController = PageController();
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    //Switch tab when incoming call received
    context.read<CallsModel>().onNewIncomingCall = (){ if(_selectedPageIndex != 1) _onTabTapped(1); };
  }

  @override
  Widget build(BuildContext context) {
    return 
      Scaffold(
        appBar: AppBar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.4), 
          titleSpacing: 0,
          title: ListTile(            
            title:Text('Siprix VoIP SDK', style: Theme.of(context).textTheme.headlineSmall),
            subtitle: Text('www.siprix-voip.com', style: Theme.of(context).textTheme.bodySmall),
          ),
          actions: [            
            Padding(padding: const EdgeInsets.only(right: 20), 
              child:IconButton(icon: const Icon(Icons.settings), onPressed:_onShowSettings)),
          ]
        ),
        body: PageView(controller: _pageController, children: const [
          AccountsListPage(),
          CallsListPage(),
          LogsPage()
        ]),
        bottomSheet: _networkLostIndicator(),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.widgets), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.phone_in_talk),label: 'Calls'),
            BottomNavigationBarItem(icon: Icon(Icons.text_snippet), label: 'Logs'),
          ],
          currentIndex: _selectedPageIndex,
          type: BottomNavigationBarType.fixed,
          onTap: _onTabTapped,
        )
     );
  }

  Widget? _networkLostIndicator() {
    if(context.watch<NetworkModel>().networkLost) {
      return Container(color: Colors.red,
          child: const Text("Internet connection lost",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center)
        );
    }
    return null;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
      _pageController.jumpToPage(index);      
    });
  }

  void _onShowSettings() {
    Navigator.of(context).pushNamed(SettingsPage.routeName);
  }
}

////////////////////////////////////////////////////////////////////////////////////////
//LogsPage - represents diagnostic messages

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(5.0),
      child: Consumer<LogsModel>(
        builder: (context, logsModel, child) {
          return SelectableText(logsModel.logStr, style: Theme.of(context).textTheme.bodySmall);
        }
      )
    );
  }
}

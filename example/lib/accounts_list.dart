import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'account_add.dart';

////////////////////////////////////////////////////////////////////////////////////////
//AccountsListPage - represents list of accounts

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

enum AccAction {delete, unregister, register, edit}

class _AccountsListPageState extends State<AccountsListPage> {
  int _selRowIdx=0;

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsModel>();
    return Column(children: [
      const ListTile(leading: Text('State'), title: Text('Name'), trailing: Text('Action'),),
      const Divider(height: 0),
      ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: accounts.length,
        itemBuilder: (BuildContext context, int index) { return _accListTile(accounts, index); },
        separatorBuilder: (BuildContext context, int index) => const Divider(height: 0,),
      ),
      Align(alignment: Alignment.topRight, 
        child:Padding(padding: const EdgeInsets.all(11), 
          child:ElevatedButton(onPressed: _addAccount, child: const Icon(Icons.add_circle)))
      ),
      const Spacer(),
    ]);
  }

  ListTile _accListTile(AccountsModel accounts, int index) {
    AccountModel acc = accounts[index];
    return 
      ListTile(
        selected: (_selRowIdx == index),
        selectedColor: Colors.black,
        selectedTileColor: Theme.of(context).secondaryHeaderColor,
        leading: _getAccIcon(acc.regState),
        title: Text(acc.uri, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text('ID: ${acc.myAccId} REG: ${acc.regText}', 
          style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.grey)),
        trailing: _accListTileMenu(acc, index),
        onTap: () { onTapAccListTile(index); },
        dense: true,
      );
  }

  PopupMenuButton<AccAction> _accListTileMenu(AccountModel acc, int index) {  
    return 
      PopupMenuButton<AccAction>(
        onOpened: () { onTapAccListTile(index); },
        onSelected: (AccAction action) { _doAccountAction(action, index); },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<AccAction>>[
          const PopupMenuItem<AccAction>(
            value: AccAction.edit,
            child: Wrap(spacing:5, children:[Icon(Icons.edit), Text("Edit")])
          ),
          PopupMenuItem<AccAction>(
            value: AccAction.register,
            enabled: (acc.regState!=RegState.inProgress),
            child: const Wrap(spacing:5, children:[Icon(Icons.refresh), Text("Register"),])
          ),
          PopupMenuItem<AccAction>(
            value: AccAction.unregister,
            enabled: (acc.regState!=RegState.inProgress)&&(acc.regState!=RegState.removed),
            child: const Wrap(spacing:5, children:[Icon(Icons.cancel_presentation), Text("Unregister")])
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<AccAction>(
            value: AccAction.delete,
            child: Wrap(spacing:5, children:[Icon(Icons.delete), Text("Delete"),])
          ),
        ],
      );
  }
  
  void onTapAccListTile(int rowIndex) {
    setState(() {
      _selRowIdx = rowIndex;
    });
  }

  void _addAccount() {
    Navigator.of(context).pushNamed(AccountPage.routeName, arguments: AccountModel());
  }

  void _editAccount(int index) {
    final accModel = context.read<AccountsModel>();
    Navigator.of(context).pushNamed(AccountPage.routeName, arguments: accModel[index]);
  }

  void _doAccountAction(AccAction action, int index) {    
    final accModel = context.read<AccountsModel>();      
    Future<void> f;
    switch(action) {
      case AccAction.delete:     f = accModel.deleteAccount(index);     break;
      case AccAction.unregister: f = accModel.unregisterAccount(index); break;
      case AccAction.register:   f = accModel.registerAccount(index);   break;
      case AccAction.edit:       _editAccount(index);                   return;
    }    
    f.catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    });
  }
  
  Widget _getAccIcon(RegState s) {
    switch(s){
      case RegState.success:    return const Icon(Icons.cloud_done_outlined, color: Colors.green);
      case RegState.failed:     return const Icon(Icons.cloud_off_outlined, color: Colors.red);      
      case RegState.inProgress: return const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 3,));
      default:                  return const Icon(Icons.done, color: Colors.grey);
    }
  }  

}//AccountsListPage
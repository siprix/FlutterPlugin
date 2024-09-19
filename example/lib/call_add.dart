import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';

////////////////////////////////////////////////////////////////////////////////////////
//CallAddPage - allows enter destination number and source account. Used for starting new outgoing calls

class CallAddPage extends StatefulWidget {
  const CallAddPage(this.popUpMode, {super.key});
  static const routeName = "/addCall";
  final bool popUpMode;

  @override
  State<CallAddPage> createState() => _CallAddPageState();
}

class _CallAddPageState extends State<CallAddPage> {  
  final _phoneNumbCtrl = TextEditingController();  
  String _errText="";

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AccountsModel>();
    return Scaffold(
        appBar: widget.popUpMode ? AppBar(title: const Text('Add Call'), backgroundColor: Theme.of(context).primaryColor.withOpacity(0.4)) : null,
        body: accounts.isEmpty ? _buildEmptyBody() : _buildBody(accounts),
    );
  }

  Widget _buildEmptyBody() {
   return const Padding(padding: EdgeInsets.all(16.0),
      child: Text('Can\'t make calls. Required to add account')
    );
  }

  Widget _buildBody(AccountsModel accounts) {
    return 
      Container(padding: const EdgeInsets.all(10.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAccountsMenu(accounts),
            const SizedBox(height: 15,),
            _buildPhoneNumberField(),
            const SizedBox(height: 15),
            Wrap(alignment: WrapAlignment.center, spacing: 25, children:[
              ElevatedButton(onPressed: _inviteAudio, child: const Icon(Icons.add_call)),
              ElevatedButton(onPressed: _inviteVideo, child: const Icon(Icons.video_call_outlined))
            ]),
            const Spacer(),
            Text(_errText, style: const TextStyle(color: Colors.red))
          ]
        ),
      );
  }

  Widget _buildAccountsMenu(AccountsModel accounts) {
    return ButtonTheme(alignedDropdown: true, child: DropdownButtonFormField<int>(
      decoration: const InputDecoration(border: UnderlineInputBorder(), 
        labelText: 'Select account:', 
        contentPadding: EdgeInsets.all(0)),
      value: accounts.selAccountId,
      onChanged: (int? accId) {  accounts.setSelectedAccountById(accId!); },
      items: List.generate(accounts.length, (index) => accMenuItem(accounts[index], index)),
    ));
  }

  DropdownMenuItem<int> accMenuItem(AccountModel acc, int index) {
    return DropdownMenuItem<int>(value: acc.myAccId, child: Text(acc.uri));
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      decoration: const InputDecoration(
        border: UnderlineInputBorder(),
        labelText: 'Enter phone number',
        contentPadding: EdgeInsets.all(0),
      ),
      controller: _phoneNumbCtrl,
    );
  }

  void _inviteVideo() => _invite(true);
  void _inviteAudio() => _invite(false);

  void _invite(bool withVideo) {
    //Check entered number
    if(_phoneNumbCtrl.text.isEmpty) {
      setState((){ _errText="Phone(extenstion) number is empty"; });
      return;
    }

    //Check selected account
    final accounts = context.read<AccountsModel>();
    if(accounts.selAccountId==null) {
      setState((){ _errText="Account not selected"; });
      return;
    }

    //Prepare destination details    
    CallDestination dest = CallDestination(_phoneNumbCtrl.text, accounts.selAccountId!, withVideo);

    //Invite
    context.read<CallsModel>().invite(dest)
      .then((_) => setState((){ _errText=""; }))
      .catchError((error) {
        setState(() { _errText = error.toString();  });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errText)));
      });

    if(widget.popUpMode) {
        Navigator.of(context).pop();
    }
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/calls_model.dart';
import 'package:siprix_voip_sdk/cdrs_model.dart';

enum CdrAction {delete, deleteAll}

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
  int _selCdrRowIdx=0;

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
      Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(color: Theme.of(context).dialogBackgroundColor, padding: const EdgeInsets.fromLTRB(10,0,10,5), 
            child: Column(children: [
              _buildAccountsMenu(accounts),
              const SizedBox(height: 5),
              _buildPhoneNumberField(),
            ])),
          Expanded(child: buildCdrsList()),
          if(_errText.isNotEmpty)
            Text(_errText, style: const TextStyle(color: Colors.red))
        ]);
  }

  Widget _buildAccountsMenu(AccountsModel accounts) {
    return ButtonTheme(child: DropdownButtonFormField<int>(
      decoration: const InputDecoration(border: UnderlineInputBorder(), 
        labelText: 'Select account:', ),
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
      style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: 'Enter phone number',
        //contentPadding: const EdgeInsets.all(0),
        suffixIcon: Wrap(alignment: WrapAlignment.center, spacing: 10, children:[
            FilledButton(onPressed: _inviteAudio, child: const Icon(Icons.add_call)),
            OutlinedButton(onPressed: _inviteVideo, child: const Icon(Icons.video_call_outlined))
            ]),
      ),
      controller: _phoneNumbCtrl,
    );
  }

  Widget buildCdrsList() {
    final cdrs = context.watch<CdrsModel>();
    return ListView.separated(
      scrollDirection: Axis.vertical,
      itemCount: cdrs.length,
      itemBuilder: (BuildContext context, int index) {
        CdrModel cdr = cdrs[index];
        return ListTile(
          selected: (_selCdrRowIdx == index),
          selectedColor: Colors.black,
          selectedTileColor: Theme.of(context).secondaryHeaderColor,
          //contentPadding:const EdgeInsets.fromLTRB(0, 0, 10, 0),
          leading: _getCdrIcon(cdr),
          title: _getCdrTitle(cdr),
          subtitle: _getCdrSubTitle(cdr, (_selCdrRowIdx == index)),
          trailing: _getCdrRowTrailing(cdr, index),
          dense: true,
          onTap: () { 
              setState(() {
                context.read<AccountsModel>().setSelectedAccountByUri(cdr.accUri);
                _phoneNumbCtrl.text = cdr.remoteExt;
                _selCdrRowIdx = index;
              });
            }
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(height: 0,),
    );
  }

  Icon _getCdrIcon(CdrModel cdr) {
    if(cdr.incoming) {
      return cdr.connected ? const Icon(Icons.call_received_rounded, color: Colors.green,)
                           : const Icon(Icons.call_missed_rounded, color: Colors.red);
    }
    else {
      return cdr.connected ? const Icon(Icons.call_made_rounded, color: Colors.lightGreen)
                           : const Icon(Icons.call_missed_outgoing_rounded, color: Colors.orange);
    }
  }

  Widget _getCdrTitle(CdrModel cdr) {
    return 
      Text(cdr.displName.isEmpty ? cdr.remoteExt : "${cdr.displName} (${cdr.remoteExt})", 
        style: Theme.of(context).textTheme.titleSmall);
  }

  Widget _getCdrSubTitle(CdrModel cdr, bool isSelected) {
    Text accText = Text(cdr.accUri, style: const TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.grey));
    if(!isSelected) { return accText;  }
    else {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        accText,
        Wrap(spacing:5, children: [
          Text(cdr.madeAtDate), 
          if(cdr.connected) Text("Duration: ${cdr.duration}"),
          if(cdr.statusCode!=0) Text("Status code: ${cdr.statusCode}"),
          if(cdr.hasVideo) const Icon(Icons.videocam_outlined, color: Colors.grey, size:18),
        ])
      ]);
    }
  }

  Widget _getCdrRowTrailing(CdrModel cdr, int index) {
    return 
        PopupMenuButton<CdrAction>(
          onSelected: (CdrAction action) { _onCdrMenuAction(action, index); },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<CdrAction>>[
            const PopupMenuItem<CdrAction>(
              value: CdrAction.delete,
              child: Wrap(spacing:5, children:[Icon(Icons.delete), Text("Delete"),])
            ),
          ]);
  }

  void _onCdrMenuAction(CdrAction action, int index) {
    final cdrs = context.read<CdrsModel>();
    cdrs.remove(index);
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


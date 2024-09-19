import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:siprix_voip_sdk/accounts_model.dart';
import 'package:siprix_voip_sdk/network_model.dart';

import 'main.dart';

////////////////////////////////////////////////////////////////////////////////////////
//AccountPage - represents fields of selected account. Used for adding/editing accounts

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  static const routeName = '/addAccount';

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  AccountModel _account = AccountModel();
  String _errText = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _account = ModalRoute.of(context)!.settings.arguments as AccountModel;    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.4), 
        title: Text(isAddMode() ? 'Add Account' : 'Edit Account')
      ),
      body: SingleChildScrollView(scrollDirection: Axis.vertical, 
        child: Form(key: _formKey, 
          child: Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sip server/domain'),
                  validator: (value) { return (value == null || value.isEmpty) ? 'Please enter domain' : null; },
                  onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipServer = value; }); },        
                  initialValue: _account.sipServer,
                  enabled: isAddMode(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sip extension'),
                  validator: (value) { return (value == null || value.isEmpty) ? 'Please enter user name.' : null; },
                  onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipExtension = value; }); },
                  initialValue: _account.sipExtension,
                  enabled: isAddMode(),
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Sip password'),
                  validator: (value) { return (value == null || value.isEmpty) ? 'Please enter password.' : null; },
                  onChanged: (String? value) { setState(() { if((value!=null) && value.isNotEmpty) _account.sipPassword = value; }); },        
                  initialValue: _account.sipPassword,
                ),
                TextFormField(
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Expire time (seconds)'),
                  onChanged: (String? val) { setState(() { if((val!=null) && val.isNotEmpty) _account.expireTime = int.parse(val);  }); },        
                  initialValue: _account.expireTime?.toString(),
                  enabled: isAddMode(),
                ),
                 _buildTransportsDropDown(),
                CheckboxListTile(
                  contentPadding: const EdgeInsetsDirectional.all(0),
                  title: const Text('Rewrite Contact IP address'),                
                  onChanged: (bool? val) {  setState(() { _account.rewriteContactIp = val;  }); },
                  value: _account.rewriteContactIp,
                  tristate:true,
                ),
                Padding(padding: const EdgeInsets.all(20), child:
                  ElevatedButton(onPressed:_submit,
                    child: Wrap(spacing:5, 
                      children: [const Icon(Icons.archive), Text(isAddMode() ? 'Add' : 'Update')
                    ])
                  )
                ),
                
                Text(_errText, style: const TextStyle(color: Colors.red), ),
              ]
            )
          )
        )
      )
    );
  }

  bool isAddMode() {
    return (_account.myAccId == 0);
  }
  
  DropdownMenuItem<SipTransport> transportItem(SipTransport transp) {
    return DropdownMenuItem<SipTransport>(value: transp, child: 
      Text(transp.name, style:Theme.of(context).textTheme.bodyMedium,)
    );
  }

  Widget _buildTransportsDropDown() {
    return ButtonTheme(alignedDropdown: true, child: 
      DropdownButtonFormField<SipTransport>(
        decoration: InputDecoration(
          border: const UnderlineInputBorder(), 
          labelText: 'Sip signalling transport:', 
          labelStyle: TextStyle(color: isAddMode() ? null : Theme.of(context).disabledColor),
          contentPadding: const EdgeInsets.all(0),
        ),
        value: _account.transport,
        onChanged: isAddMode() ? (SipTransport? value) { setState(() { _account.transport = value!; }); } : null,
        items: SipTransport.values.map((t) => transportItem(t)).toList() 
    ));
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    
    if(isAddMode()) {
      _account.ringTonePath = MyApp.getRingtonePath();
      context.read<AccountsModel>().addAccount(_account)
        .then((_) { Navigator.pop(context, true); })
        .catchError((error) {        
          setState(() { _errText = error;  });
      });
    } else {
      context.read<AccountsModel>().updateAccount(_account)
        .then((_) { Navigator.pop(context, true); })
        .catchError((error) {
          setState(() { _errText = error;  });
      });
    }
    
  }//_submit 

}//AccountPageState

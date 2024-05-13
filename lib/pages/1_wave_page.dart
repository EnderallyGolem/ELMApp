import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../main.dart';
//import '/util_classes.dart';

class ProviderWaveState extends ChangeNotifier {

  static List waveModuleArr = [];

  void updateWaveState(){
    notifyListeners();                                    //Updates the displayed wave UI state
    updateWaveCodeInMain(waveModuleArr: waveModuleArr);   //Updates wave code in main.dart
    ProviderMainState().updateLevelCode();                //Updates the full code in main.dart
  }

  //Generate the updated waveCode, then updates the waveCode in main.dart with it
  static void updateWaveCodeInMain({required waveModuleArr}){

    dynamic waveCode = {
      "objects": [],
      "levelModules": [],
      "waveModules": [],
    };

    for (int waveIndex = 0; waveIndex < waveModuleArr.length; waveIndex++){
      //TO-DO: Proper updating of waveCode once the proper wave module format is made
      waveCode["objects"].add(waveModuleArr[waveIndex].value);
      print('Updating waveCode["objects"]. New value = ${waveModuleArr[waveIndex].value} New waveCode["objects"] = ${waveCode["objects"]}');
    }
    ProviderMainState.waveCode = waveCode;
  }

  static void importWaveCode({dynamic waveCodeToAdd = ''}){
    waveModuleArr = [];
    for(int waveIndex = 0; waveIndex < waveCodeToAdd.length; waveIndex++){
      print('this run sright');
      waveModuleArr.insert(waveIndex, WaveModule(waveIndex: waveIndex, value: waveCodeToAdd[waveIndex].toString())); //TO-DO: Change value
      print('loop for waveindex $waveIndex: ${waveModuleArr[waveIndex]}');
    }
  }

}



//Each wave is a WaveModule class
//Each WaveModule class contains a bunch of EventModule classes [WHICH I HAVE NOT MADE. TO-DO]
///
/// Usage: WaveModule(value: [value])
/// [value] is the code in each wave. it is currently a string. well. that needs to be changed eventually.
///

class WaveModule extends StatefulWidget {
  final int waveIndex;
  dynamic value;
  TextEditingController? controllers;
  String display = "";

  WaveModule({required this.waveIndex, this.value = '', this.controllers = null}) {
    controllers ??= TextEditingController(text: value); //Sets a value if null
    display = 'Wave ${waveIndex + 1}: $value';
    print(display);
  }

  static void deleteModule({int waveIndex = 0, required providerWaveState}) {
    ProviderWaveState.waveModuleArr.removeAt(waveIndex);
  }

  static void addModuleBelow({int waveIndex = -1, dynamic newValue = null, required providerWaveState}) {
    ProviderWaveState.waveModuleArr.insert(waveIndex+1, WaveModule(waveIndex: waveIndex, value: newValue)); //newValue will be new module list
  }

  static void updateAllModuleName({int firstWaveIndex = 0, required appWaveState}) {
    if (firstWaveIndex < 0){ firstWaveIndex=0; }
    for (firstWaveIndex; firstWaveIndex < ProviderWaveState.waveModuleArr.length; firstWaveIndex++) {
      ProviderWaveState.waveModuleArr[firstWaveIndex].display = 'Wave ${firstWaveIndex + 1}: ${ProviderWaveState.waveModuleArr[firstWaveIndex].value}';
    }
    appWaveState.updateWaveState();
  }

  static void updateModule({int waveIndex = 0, dynamic newValue, required appWaveState}) {
    ProviderWaveState.waveModuleArr[waveIndex].value = newValue;
    ProviderWaveState.waveModuleArr[waveIndex].display = 'Wave ${waveIndex + 1}: ${newValue}';
    appWaveState.updateWaveState();
  }

  @override
  State<WaveModule> createState() => _WaveModuleState();
}

class _WaveModuleState extends State<WaveModule> {

  @override
  void initState() {
    super.initState();
    //_controllers = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //UI for each wave ------------------------------------------------------------------------------
    var appWaveState = context.watch<ProviderWaveState>();
    return Column(
      children: [
        TextField(
          controller: widget.controllers,
          onChanged: (value) {
            // Update the value directly through the provider
            WaveModule.updateModule(
              waveIndex: widget.waveIndex,
              newValue: value,
              appWaveState: appWaveState,
            );
          },
          decoration: InputDecoration(
            labelText: '${widget.display}',
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  WaveModule.deleteModule(
                    waveIndex: widget.waveIndex,
                    providerWaveState: appWaveState,
                  );
                  WaveModule.updateAllModuleName(
                    firstWaveIndex: widget.waveIndex,
                    appWaveState: appWaveState,
                  );
                });
              },
              child: Icon(Icons.delete),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  WaveModule.addModuleBelow(
                    waveIndex: widget.waveIndex,
                    providerWaveState: appWaveState,
                  );
                  WaveModule.updateAllModuleName(
                    firstWaveIndex: widget.waveIndex,
                    appWaveState: appWaveState,
                  );
                });
              },
              child: Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}


class Page_Wave extends StatefulWidget {
  @override
  _Page_WaveState createState() => _Page_WaveState();
}

class _Page_WaveState extends State<Page_Wave> {
  //UI for all waves ------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    var appWaveState = context.watch<ProviderWaveState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Waves'),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState((){
                WaveModule.addModuleBelow(waveIndex: -1, newValue: null, providerWaveState: appWaveState);
                WaveModule.updateAllModuleName(appWaveState: appWaveState);
              });
            },
            child: Row(children: [Icon(Icons.add), Text('Add Wave')])
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: ProviderWaveState.waveModuleArr.length,
        itemBuilder: (context, index) {
          return WaveModule(
            waveIndex: index,
            value: ProviderWaveState.waveModuleArr[index].value,
            controllers: ProviderWaveState.waveModuleArr[index].controllers,
          );
        },
      ),
    );
  }
}

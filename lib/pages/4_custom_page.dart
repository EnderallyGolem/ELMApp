import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:get/get.dart';


class ProviderCustomState extends ChangeNotifier implements GenericProviderState {

  List<ElmModuleList> elmModuleListArr = [];
  bool allowCallback = false;
  Color themeColour = Color.fromARGB(255, 58, 104, 183); //Change this colour if needed
  GlobalKey<AnimatedListState> animatedModuleListKey = GlobalKey<AnimatedListState>();
  bool updateCode = true;

  @override
  Type getProviderType() => ProviderCustomState; // !!! Edit ProviderNewState!

  // Updates UI and main level code
  @override
  void updateModuleState(){
    notifyListeners();                                              //Updates the displayed module UI state
    updateModuleCodeInMain(elmModuleListArr: elmModuleListArr);     //Updates module code in main.dart
    ProviderMainState.updateLevelCode();                            //Updates the full code in main.dart
  }

  // Generate the updated waveCode, then updates the waveCode in main.dart with it
  void updateModuleCodeInMain({required elmModuleListArr}){
    dynamic moduleCode = {"objects": [], "levelModules": [], "waveModules": [],};
  
    for (int moduleIndex = 0; moduleIndex < elmModuleListArr.length; moduleIndex++){
      //TO-DO: Proper updating of moduleCode once the proper module format is made
      moduleCode["objects"].add(elmModuleListArr[moduleIndex].value);
    }
    ProviderMainState.customCode = moduleCode;
  }

  // Imports code from main. allowCallback true means list is recreated when first loaded.
  // Enable if code is imported (it should be set to false when done)
  void importModuleCode({dynamic moduleCodeToAdd = ''}){
    allowCallback = true;
    elmModuleListArr = [];
    for(int moduleIndex = 0; moduleIndex < moduleCodeToAdd.length; moduleIndex++){
      elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: moduleCodeToAdd[moduleIndex].toString())); //TO-DO: Change value
    }
  }
}

class Page_Custom extends StatefulWidget {
  @override
  _Page_CustomState createState() => _Page_CustomState();
}

class _Page_CustomState extends State<Page_Custom> {
  //UI for all waves ------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ProviderCustomState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('page_custom'.tr),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () {
              ElmModuleList.addModuleBelow(moduleIndex: -1, newValue: null, appState: appState);
            },
            child: Row(children: [Icon(Icons.add, color: appState.themeColour,), Text('custom_addcode'.tr, selectionColor: appState.themeColour,)])
          ),
        ],
      ),
      body: AnimatedList(
        key: appState.animatedModuleListKey,
        initialItemCount: appState.elmModuleListArr.length,
        itemBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: elmSizeTween(animation: animation),
              axis: Axis.vertical,
              axisAlignment: 0,
              child: ElmModuleList<ProviderCustomState>(
                moduleIndex: index,
                value: appState.elmModuleListArr[index].value,
                controllers: appState.elmModuleListArr[index].controllers,
              ),
            ),
          );
        },
      ),
    );
  }
}
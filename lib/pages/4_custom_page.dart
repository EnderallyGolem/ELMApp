import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:get/get.dart';


class ProviderCustomState extends ChangeNotifier implements GenericProviderState {

  //Change these first 4!
  @override Color themeColour = Color.fromARGB(255, 58, 104, 183); //Colour used by UI
  @override bool isVertical = false; //If modules extend vertically down or horizontally right
  @override Map<String, bool> enabledButtons = //Change enabled buttons. extra contains all disabled buttons.
    {'shiftup': false, 'shiftdown': false, 'copy': false, 'delete': true, 'add': true, 'extra': true}; //TO-DO: Button for copying event into another wave

  @override List<ElmModuleList> elmModuleListArr = [];
  @override GlobalKey<AnimatedListState> animatedModuleListKey = GlobalKey<AnimatedListState>();
  @override bool updateCode = true;
  @override ScrollController scrollController = ScrollController();
  @override double scrollOffset = 0.0;

  // Updates UI and main level code
  @override void updateModuleState(){
    debugPrint('custom page | updateModuleState');
    notifyListeners();                                              //Updates the displayed module UI state
    updateModuleCodeInMain(elmModuleListArr: elmModuleListArr);     //Updates module code in main.dart
    ProviderMainState.updateLevelCode();                            //Updates the full code in main.dart
  }

  // Generate the updated waveCode, then updates the waveCode in main.dart with it
  @override void updateModuleCodeInMain({required elmModuleListArr}){
    dynamic moduleCode = {"objects": [], "levelModules": [], "waveModules": [],};
  
    for (int moduleIndex = 0; moduleIndex < elmModuleListArr.length; moduleIndex++){
      //TO-DO: Proper updating of moduleCode once the proper module format is made
      moduleCode["objects"].add(elmModuleListArr[moduleIndex].value);
    }
    ProviderMainState.customCode = moduleCode;
  }

  // Imports code from main. updateCode true means list is recreated when first loaded.
  // Enable if code is imported (it should be set to false when done)
  @override void importModuleCode({dynamic moduleCodeToAdd = ''}){
    updateCode = true;
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
  void initState() {
    super.initState();
    var appState = context.read<ProviderCustomState>();
    appState.scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.scrollController.jumpTo(appState.scrollOffset); // Restore scroll position
    });
  }
  void dispose() {
    super.dispose();
  }
  void _scrollListener() {
    if (mounted){
      var appState = context.read<ProviderCustomState>();
      appState.scrollOffset = appState.scrollController.offset;
    }
  }
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ProviderCustomState>();
    return ElmModuleListWidget(
      appState: appState,
      title: 'page_custom'.tr,
      addModuleText: 'custom_addcode'.tr
    );
  }
}

import 'package:elmapp/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:get/get.dart';


class ProviderCustomState extends ChangeNotifier implements GenericProviderState {

  //Change these first 4!
  @override Color themeColour = Color.fromARGB(255, 58, 104, 183); //Colour used by UI
  @override bool isVertical = true; //If modules extend vertically down or horizontally right
  @override Map<String, bool> enabledButtons = //Change enabled buttons. extra contains all disabled buttons.
    {'minimise': false, 'shiftup': false, 'shiftdown': false, 'copy': false, 'delete': true, 'add': true, 'extra': true}; //TO-DO: Button for copying event into another wave
  @override String moduleJsonFileName = 'modules_custom';
  @override VoidCallback? onNavigateToTargetPage;

  @override List<ElmModuleList> elmModuleListArr = [];
  @override GlobalKey<AnimatedListState> animatedModuleListKey = GlobalKey<AnimatedListState>();
  @override bool updateCode = true;
  @override ScrollController scrollController = ScrollController();
  @override double scrollOffset = 0.0;

  // Updates main level code
  @override void updateModuleState(){
    updateModuleCodeInMain(elmModuleListArr: elmModuleListArr);     //Updates module code in main.dart
    ProviderMainState.updateLevelCode();                            //Updates the full code in main.dart
  }

  // Updates UI
  @override void updateModuleUI(){
    notifyListeners();                                              //Updates the displayed module UI state
  }

  // Generate the updated waveCode, then updates the waveCode in main.dart with it
  @override void updateModuleCodeInMain({required elmModuleListArr}){
    dynamic moduleCode = {"objects": [], "levelModules": [], "waveModules": [],};
  
    for (int moduleIndex = 0; moduleIndex < elmModuleListArr.length; moduleIndex++){

      //TO-DO: WaveModules has to be changed. It is to be added to the wave number.
      //Might be a good idea to keep it in the wave number + RTID format until the end.
      if(elmModuleListArr[moduleIndex].value['internal_data']['objects'] != null && elmModuleListArr[moduleIndex].value['internal_data']['objects'] != ""){
        moduleCode["objects"] = [...moduleCode["objects"], ...elmModuleListArr[moduleIndex].value['internal_data']['objects']];
      }
      if(elmModuleListArr[moduleIndex].value['internal_data']['levelModules'] != null && elmModuleListArr[moduleIndex].value['internal_data']['levelModules'] != ""){
        moduleCode["levelModules"] = [...moduleCode["levelModules"], ...elmModuleListArr[moduleIndex].value['internal_data']['levelModules']];
      }
      if(elmModuleListArr[moduleIndex].value['internal_data']['waveModules'] != null && elmModuleListArr[moduleIndex].value['internal_data']['waveModules'] != ""){
        moduleCode["waveModules"] = [...moduleCode["waveModules"], ...elmModuleListArr[moduleIndex].value['internal_data']['waveModules']];
      }
    }
    ProviderMainState.customCode = moduleCode;
  }

  ProviderCustomState() {
    // Listen for the CheckImportModuleCodeEvent
    eventBus.on<CheckImportModuleCodeEvent>().listen((event) {
      checkImportModuleCode();
    });
  }

  // Imports code from main. 
  // updateCode true means list is recreated when first loaded. Enable if code is imported (it should be set to false when done)
  @override void checkImportModuleCode(){

    dynamic codeToAdd = ProviderMainState.customCode;

    print(codeToAdd);
    if(codeToAdd['importCheck'] == true){
      codeToAdd['importCheck'] = false;
      dynamic moduleCodeToAdd = codeToAdd['objects'];

      updateCode = true;
      elmModuleListArr = [];

      print(moduleCodeToAdd);

      for(int moduleIndex = 0; moduleIndex < moduleCodeToAdd.length; moduleIndex++){
        print(moduleCodeToAdd[moduleIndex]);
        String? aliases = moduleCodeToAdd?[moduleIndex]?['aliases'][0]; //For debugging and errors

        //Try to obtain value data from stored internal data. If it doesn't exist, oof
        dynamic value;
        String? data = moduleCodeToAdd[moduleIndex]['#data'];
        if(data == null){
          ProviderMainState.global['nonElmImportWarn'].add(aliases);
          //FRICK!
        } else if (data is int){
          //Do absolutely nothing!
          continue;
        } else {
          //Decode to obtain data, and use that as value.
          value = deepCopy(decodeNestedStructure(data));
        }

        try {
          elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: value));
        } catch (e) {
          debugPrint('Custom: Error occured when trying to import module: $aliases');
          ProviderMainState.global['nonElmImportWarn'].add(aliases);
          elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: null));
        }
      }      
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
    appState.checkImportModuleCode();
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

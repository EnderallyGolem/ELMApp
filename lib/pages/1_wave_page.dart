import 'package:elmapp/util_functions.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:get/get.dart';

class ProviderWaveState extends ChangeNotifier {
  List<ProviderWaveEventState> waveList = [];
  List<Map> waveDataList = [];
  Color themeColour = const Color.fromARGB(255, 58, 104, 183);
  GlobalKey<AnimatedListState> animatedWaveListKey = GlobalKey<AnimatedListState>();
  @override ScrollController scrollController = ScrollController();
  @override double scrollOffset = 0.0;
  Map<String, bool> enabledButtons = //Change enabled buttons. extra contains all disabled buttons.
    {'minimise': false, 'shiftup': false, 'shiftdown': false, 'copy': false, 'delete': true, 'add': true, 'extra': true};

  void addWaveBelow({required int waveIndex, List<ElmModuleList>? elmModuleListArr, Map? waveData}) {

    ProviderWaveEventState newWaveEventState = ProviderWaveEventState();
    elmModuleListArr ??= [];
    newWaveEventState.elmModuleListArr = elmModuleListArr;

    waveList.add(newWaveEventState);

    waveData ??= {
      'minimised': false,
    };

    waveDataList.add(waveData);
    animatedWaveListKey.currentState!.insertItem(
      waveIndex+1, 
      duration: const Duration(milliseconds: 150)
    );
  }

  void deleteWave({required int waveIndex}) {
    waveList.removeAt(waveIndex);
    waveDataList.removeAt(waveIndex);
    animatedWaveListKey.currentState!.removeItem(
      waveIndex,
      duration: Duration(milliseconds: 150),
      (context, animation) => _buildAnimatedElmModuleList(waveIndex: waveIndex, animation: animation)
    );
  }

  void updateAllWave() {
    notifyListeners();
  }

  static Widget _buildAnimatedElmModuleList({required int waveIndex, required Animation<double> animation}) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        axisAlignment: 0,
        axis: Axis.vertical,
        sizeFactor: elmSizeTween(animation: animation),
        child: WaveWidget(waveIndex: waveIndex),
      ),
    );
  }
}

class ProviderWaveEventState extends ChangeNotifier implements GenericProviderState {

  //Change these first 4!
  @override Color themeColour = Color.fromARGB(255, 58, 104, 183); //Colour used by UI
  @override bool isVertical = false; //If modules extend vertically down or horizontally right
  @override Map<String, bool> enabledButtons = //Change enabled buttons. extra contains all disabled buttons.
    {'minimise': false, 'shiftup': false, 'shiftdown': false, 'copy': false, 'delete': true, 'add': true, 'extra': true}; //TO-DO: Button for copying event into another wave (not new event)
  @override String moduleJsonFileName = 'modules_events';

  @override VoidCallback? onNavigateToTargetPage;
  @override List<ElmModuleList> elmModuleListArr = [];
  @override GlobalKey<AnimatedListState> animatedModuleListKey = GlobalKey<AnimatedListState>();
  @override bool runForFirstTime = true;
  @override bool isImportingModules = false;
  @override bool allowUpdateModule = true;
  @override ScrollController scrollController = ScrollController();
  @override double scrollOffset = 0.0;

  // Updates main level code
  @override void updateModuleState(){
    if (allowUpdateModule) {
      updateModuleCodeInMain(elmModuleListArr: elmModuleListArr);               //Updates module code in main.dart
      scrollOffset = scrollController.offset;                                   //Update scroll offset
      ProviderMainState.updateLevelCode(scrollData: ['wave', scrollOffset]);    //Updates the full code in main.dart
    }
  }


  // Updates UI
  @override void updateModuleUI(){
    notifyListeners();  //Updates the displayed module UI state
  }

  // Generate the updated module code, then updates the module code in main.dart with it
  @override void updateModuleCodeInMain({required elmModuleListArr}){
    dynamic moduleCode = {"objects": [], "levelModules": [], "waveModules": [], "importCheck": false};
  
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
    ProviderMainState.waveCode = moduleCode; //Change this
  }

  // Imports code from main.
  @override void checkImportModuleCode(){
    dynamic codeToAdd = ProviderMainState.waveCode; //Change this
    isImportingModules = true;

    if(codeToAdd['importCheck'] == true){
      codeToAdd['importCheck'] = false;
      dynamic moduleCodeToAdd = codeToAdd['objects'];

      elmModuleListArr = [];

      for(int moduleIndex = 0; moduleIndex < moduleCodeToAdd.length; moduleIndex++){
        String? aliases = moduleCodeToAdd?[moduleIndex]?['aliases']?[0]; //For debugging and errors

        //Try to obtain value data from stored internal data. If it doesn't exist, oof
        dynamic value;
        String moduleName;
        String? data = moduleCodeToAdd[moduleIndex]['#data'];

        obtainValueFromCode({required String moduleName, required dynamic moduleObject, required dynamic jsonFile, dynamic currentValue}){

          currentValue ??= {
            'module_dropdown_list': {
              'dropdown_module_internal_name': moduleName
            },
          };

          currentValue = deepCopy(currentValue); //Yes. This fixes a bug. currentValue may not be expandable. This fixes it. Don't ask.

          //Run through the code and loop through every key yay
          dynamic jsonFileModule = jsonFile[moduleName];
          iterateAndModifyNested(nestedItem: moduleObject, function: (key, value, path) {
            //iterate across all values in moduleobject. Only do strings + special one for aliases

            //Get the keyMap: Last key that is for a map
            List pathMap = deepCopy(path);
            String? keyMap;
            for(int index = pathMap.length-1; index >= 0; index--){
              if(pathMap[index] is String){
                keyMap = pathMap[index];
                break;
              }
            }

            if(key is String || keyMap == 'aliases'){
              //Find if keyMap is equal to any of the inputs. If so, set level module value as input's currentValue
              for(dynamic inputEntry in jsonFileModule?['inputs'].entries){
                if(inputEntry.key == keyMap){
                  print('Set $currentValue > input_data > ${inputEntry.key} to $value');
                  setNestedProperty(obj: currentValue, path: ['input_data', inputEntry.key], value: value);
                }
              }
            }
            return value;
          });
          return currentValue;
        }

        if(data == null){
          ProviderMainState.global['nonElmImportWarn'].add(aliases); //Note down that this event has issues

          //Obtain module name. If cannot find, default to 'custom_code'.
          //Get objclass
          String? moduleObjclass = moduleCodeToAdd?[moduleIndex]?['objclass'];

          //Search json for class.
          dynamic jsonFile = ProviderMainState.global["moduleJsons"][moduleJsonFileName];
          String? moduleName;

          if(jsonFile != null){ //Null occurs on first load. Though the template level shouldn't run this anyways.
            for(dynamic entry in jsonFile.entries){
              
              //Only check match with 1 item long ones
              if(entry.value?['raw_code']?[0] != null && entry.value?['raw_code'].length == 1 && entry.value?['raw_code']?[0] is! String && entry.value?['raw_code']?[0]?['objclass'] == moduleObjclass){
                moduleName = entry.key;
                break;
              } 
            }
            if(moduleName != null){
              //Not null - Add event based on moduleName
              value = obtainValueFromCode(moduleName: moduleName, moduleObject: moduleCodeToAdd?[moduleIndex], jsonFile: jsonFile); //Obtain the direct-input values
            } else {
              //Null - Default to 'custom_code'.

              String jsonToAdd = jsonEncode(moduleCodeToAdd?[moduleIndex]);

              value = {
                'module_dropdown_list': {
                  'dropdown_module_internal_name': 'custom_code',
                },
                'input_data': {'L_raw_code': [[jsonToAdd]]},
                'input_header_data': {
                  'L_raw_code': {
                  'axis_row': [0],
                  'axis_column': [0],
                  'rowNum': 1,
                  'columnNum': 1,
                  }
                }
              };
            }
          }

        } else if (data is int){
          //Do absolutely nothing!
          continue;
        } else {
          //Decode to obtain data, and use that as value.
          //Do not obtain from values, as certain stuff might break. Eg: Aliases being left blank intentionally but replaced with a value
          value = decodeNestedStructure(data);
          moduleName = value['module_dropdown_list']['dropdown_module_internal_name'];
        }

        try {
          elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: deepCopy(value)));
        } catch (e) {
          debugPrint('Wave: Error occured when trying to import module: $aliases. Error: $e');
          ProviderMainState.global['nonElmImportWarn'].add(aliases);
          elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: null));
        }
      }      
    }
  }
}

class Page_Wave extends StatefulWidget {
  @override
  _Page_WaveState createState() => _Page_WaveState();
}

class _Page_WaveState extends State<Page_Wave> {
  @override
  Widget build(BuildContext context) {
    var waveState = context.watch<ProviderWaveState>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        title: Text('page_wave'.tr),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              minimumSize: const Size(110, 25),
              fixedSize: const Size(110, 25),
            ),
            onPressed: () {
              waveState.addWaveBelow(waveIndex: -1);
              waveState.updateAllWave();
            },
            child: Row(children: [Icon(Icons.add, color: waveState.themeColour,), Text('wave_addwave'.tr, selectionColor: waveState.themeColour,)])
          ),
          ElmIconButton(iconData: Icons.undo, iconColor: waveState.themeColour, onPressFunctions: (){
            if (allowUpdateUndoStack){
              allowUpdateUndoStack = false;
              appUndoStack.undo();
              appUndoStackDelayedEnable();
            }
          }),
          ElmIconButton(iconData: Icons.redo, iconColor: waveState.themeColour, onPressFunctions: (){
            if (allowUpdateUndoStack){
              allowUpdateUndoStack = false;
              appUndoStack.redo();
              appUndoStackDelayedEnable();
            }
          }),
        ],
      ),
      body: AnimatedList(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 200), //Extra padding is to allow scrolling past the end
        clipBehavior: Clip.none,
        scrollDirection: Axis.vertical,
        key: waveState.animatedWaveListKey,
        initialItemCount: waveState.waveList.length,
        controller: waveState.scrollController,
        itemBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: elmSizeTween(animation: animation),
              axis: Axis.vertical,
              axisAlignment: 0,
              child: ChangeNotifierProvider.value(
                key: ValueKey(index),
                value: waveState.waveList[index],
                child: WaveWidget(
                  key: ValueKey(index),
                  waveIndex: index,
                ),
              )
            ),
          );
        },
      ),
    );
  }
}


class WaveWidget extends StatelessWidget {

  final int waveIndex;

  const WaveWidget({super.key, required this.waveIndex});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ProviderWaveEventState>();
    var waveAppState = context.watch<ProviderWaveState>();
    if (appState.runForFirstTime) {
      appState.runForFirstTime = false;
      eventBus.on<CheckImportModuleCodeEvent>().listen((event) {
        appState.allowUpdateModule = false;
        appState.checkImportModuleCode();
        appState.updateModuleUI();
        void doAsyncStuff() async {
          await Future.delayed(Duration(milliseconds: 50)); //Wait some time for firings to complete
          appState.allowUpdateModule = true;
        }
          doAsyncStuff();
      });
      eventBus.on<SetScrollEvent>().listen((event) {
        if (event.page == 'wave'){
          //Needs to change depending on which wave was edited
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('i am jumping to wave page position ${event.scrollOffset}');
            appState.scrollController.jumpTo(event.scrollOffset); // Restore scroll position
          });
        }
      });
      eventBus.on<RebuildPageEvent>().listen((event) {
        if (event.allExcept && event.page != '!wave' || event.page == 'wave'){
          appState.updateModuleUI();
        }
      });
    }
    return SizedBox(
      height: 270,
      child: ElmModuleListWidget(
        superAppStateData: {
          'appState': waveAppState,
          'waveIndex': waveIndex,
        },
        appState: appState,
        title: 'page_wave'.tr,
        addModuleText: 'wave_addevent'.tr
      ),
    );
  }
}

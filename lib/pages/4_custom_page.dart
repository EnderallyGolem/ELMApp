import 'package:elmapp/util_functions.dart';
import 'dart:convert';
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
  @override bool runForFirstTime = true;
  @override bool isImportingModules = false;

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

  // Imports code from main.
  @override void checkImportModuleCode(){

    dynamic codeToAdd = ProviderMainState.customCode;
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
              print('aeiou');
              print(moduleCodeToAdd?[moduleIndex]);

              String jsonToAdd = jsonEncode(moduleCodeToAdd?[moduleIndex]);

              print(jsonToAdd);

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
          print('Insert to custom: $moduleIndex $value');
          elmModuleListArr.insert(moduleIndex, ElmModuleList(moduleIndex: moduleIndex, value: deepCopy(value)));
        } catch (e) {
          debugPrint('Custom: Error occured when trying to import module: $aliases. Error: $e');
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
  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ProviderCustomState>();
    if (appState.runForFirstTime) {
      appState.runForFirstTime = false;
      eventBus.on<CheckImportModuleCodeEvent>().listen((event) {
        appState.checkImportModuleCode();
        appState.updateModuleUI();
      });
      eventBus.on<RebuildPageEvent>().listen((event) {
        if (event.allExcept && event.pageToRebuild != '!custom' || event.pageToRebuild == 'custom'){
          appState.updateModuleUI();
          debugPrint('custom rebuild');
        }
      });
    }
    return ElmModuleListWidget(
      appState: appState,
      title: 'page_custom'.tr,
      addModuleText: 'custom_addcode'.tr
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; 
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';


Future loadJson({required String path}) async {
  String data = await rootBundle.loadString(path);
  var jsonResult = json.decode(data);
  debugPrint('Loaded json at $path: $jsonResult');
  return jsonResult;
}

///
/// Set value of a nested object/array/whatever.
/// Changes the value if it already exists, otherwise adds a new value.
/// 
/// [obj] : The object. Probably appState.elmModuleListArr[moduleIndex].value
/// 
/// [path] : Array with each item being the path. Eg: ['moduleName', 'display'] or ['test', 0]
/// 
/// [value] : Dynamic value to be set at that path
///
void setNestedProperty({required dynamic obj, required List<dynamic> path, required dynamic value}) {
  dynamic current = obj;
  for (int i = 0; i < path.length; i++) {
    var key = path[i];
    if (i == path.length - 1) {
      // If it's the last key in the path, set the value
      if (current is Map<String, dynamic>) {
        current[key] = value;
      } else if (current is List<dynamic> && key is int) {
        if (key >= 0 && key < current.length) {
          current[key] = value;
        } else {
          current.insert(key, value);  // Optionally handle out-of-bounds index
        }
      } else {
        throw Exception('Invalid path or object type');
      }
    } else {
      // Traverse to the next key in the path
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else if (current is List<dynamic> && key is int && key >= 0 && key < current.length) {
        current = current[key];
      } else {
        throw Exception('Invalid path or object type');
      }
    }
  }
}


/// A small button that only consists of an icon and runs some functions.
/// 
/// [iconData] is the icon type, eg: Icons.arrow_upward
/// [iconColor] is the icon colour, eg: Color.fromARGB(255, 58, 104, 183)
/// [onPressFunctions] are functions to be ran when button is clicked.
/// Optional doubles [buttonWidth] and [buttonHeight] for width and height of buttons. Default 60, 35
/// 
class ElmIconButton extends StatelessWidget {
  ElmIconButton({
    super.key,
    required this.iconData,
    required this.iconColor,
    required this.onPressFunctions,
    this.buttonWidth = 45,
    this.buttonHeight = 25,
    this.iconSize = 20,
    this.enabled = true,
  });

  final IconData iconData;
  final Color iconColor;
  final Function onPressFunctions;
  final double buttonWidth;
  final double buttonHeight;
  final double iconSize;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: enabled == false,
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          ),
          onPressed: () {
            onPressFunctions();
          },
          child: Icon(
            iconData,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}




// ElmModuleList
// To use: Copy from custom page lol

abstract class GenericProviderState {

  late List<ElmModuleList> elmModuleListArr = [];
  late Color themeColour;
  late final GlobalKey<AnimatedListState> animatedModuleListKey;
  late bool updateCode;
  late bool isVertical;
  late ScrollController scrollController;
  late double scrollOffset;
  late Map<String, bool> enabledButtons;

  void dispose();
  void updateModuleState();
  void updateModuleCodeInMain({required elmModuleListArr});
  void importModuleCode({dynamic moduleCodeToAdd = ''});
}



class ElmModuleList<T extends GenericProviderState> extends StatefulWidget {
  final int moduleIndex;
  dynamic value;

  ElmModuleList({required this.moduleIndex, this.value = null}) {
    //Sets a value if null
    value ??= {
      'moduleName': {
        'display': '', //This is unused lol!
        'internal': '',
      },
      'moduleDropdownList': {
        'dropdownModuleDisplayName': 'util_default_module_dropdown'.tr,
        'dropdownModuleInternalName': '',
        'dropdownIconData': Icons.arrow_drop_down,
      },
    };
    //Update values on rebuild
    //value['moduleName']['display'] = 'test ${moduleIndex + 1}';
  }

  static Widget _buildAnimatedElmModuleList<T extends GenericProviderState>({required int moduleIndex, required Animation<double> animation, required T appState}) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        axisAlignment: 0,
        axis: appState.isVertical ? Axis.vertical : Axis.horizontal,
        sizeFactor: elmSizeTween(animation: animation),
        child: ElmModuleList<T>(moduleIndex: moduleIndex),
      ),
    );
  }
  static void deleteModule<T extends GenericProviderState>({required int moduleIndex, required T appState, required BuildContext context}) {
    appState.elmModuleListArr.removeAt(moduleIndex);
    appState.animatedModuleListKey.currentState!.removeItem(
      moduleIndex,
      duration: Duration(milliseconds: 150),
      (context, animation) => _buildAnimatedElmModuleList<T>(moduleIndex: moduleIndex, animation: animation, appState: appState)
    );
    debugPrint('util_classes | deleteModule: Deleted module for index ${moduleIndex}');
  }

  static void addModuleBelow<T extends GenericProviderState>({required int moduleIndex, dynamic newValue = null, required T appState}) {
    moduleIndex = moduleIndex < -1 ? -1 : moduleIndex;
    moduleIndex = moduleIndex > appState.elmModuleListArr.length - 1 ? appState.elmModuleListArr.length - 2 : moduleIndex;
    appState.elmModuleListArr.insert(moduleIndex+1, ElmModuleList<T>(moduleIndex: moduleIndex, value: newValue)); //newValue will be new module list
    appState.animatedModuleListKey.currentState!.insertItem(
      moduleIndex+1, 
      duration: Duration(milliseconds: 150)
    );
    debugPrint('util_classes | addModuleBelow: Added value ${newValue} at index ${moduleIndex}');
  }

  ///
  /// Example for [path] : ['moduleName', 'display'] or ['test', 0]
  ///
  static void changeModuleValue<T extends GenericProviderState>({int moduleIndex = 0, required dynamic newValue, required dynamic path, required T appState}) {
    setNestedProperty(obj: appState.elmModuleListArr[moduleIndex].value, path: path, value: newValue);
    debugPrint('util_classes | changeModuleValue: Updated module for index ${moduleIndex}. New value: ${newValue}');
  }

  static void updateAllModule<T extends GenericProviderState>({required T appState}) {
    appState.updateModuleState();
    debugPrint('util_classes | updateAllModule: Updated all modules');
  }

  @override
  State<ElmModuleList<T>> createState() => _ElmModuleListState<T>();
}

class _ElmModuleListState<T extends GenericProviderState> extends State<ElmModuleList<T>> {

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
    var appGenericState = context.watch<T>();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if(appGenericState.updateCode){
        appGenericState.updateModuleState(); //Update state the first time it is loaded. Such a dumb workaround...
        appGenericState.updateCode = false;
      }
    });

    bool isVertical = appGenericState.isVertical;
    if(isVertical){
      return ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical);
    } else {
      return IntrinsicWidth(
        child: ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical),
      );
    }
  }
}

//TO-DO: Shift this out of util_classes and allow option to insert new events.json stuff here (+custom icons)
final Map<String, Map<String, Object>> moduleDropdownListItems = {
  "NormalSpawn": {
    "display_name": "Normal Spawn",
    "iconData": Icons.flag
  },
  "CustomCode": {
    "display_name": "Custom Code",
    "iconData": Icons.dashboard_customize
  },
  "test event": {
    "display_name": "Test Event with an overly super duper ridiciously comically long name",
    "iconData": Icons.abc
  }
};

///
/// Single Module - Upper Half
///
class ElmSingleModuleMainWidget<T extends GenericProviderState> extends StatelessWidget {
  const ElmSingleModuleMainWidget({
    super.key,
    required this.widget,
    required this.appGenericState,
    required this.isVertical,
  });

  final ElmModuleList widget;
  final T appGenericState;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(widget.value),
      children: [
        Row(
          children: [
            //Module Name
            //Expanded(child: Text(widget.value['moduleName']['display'])),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: Row(
                    children: [
                      Icon(
                        widget.value['moduleDropdownList']['dropdownIconData'],
                        size: 14,
                        color: appGenericState.themeColour,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: AutoSizeText(
                          widget.value['moduleDropdownList']['dropdownModuleDisplayName'],
                          maxFontSize: 14,
                          minFontSize: 5,
                          style: TextStyle(
                            //fontSize: 14,
                            color: appGenericState.themeColour,
                          ),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                  items: moduleDropdownListItems.entries.map<DropdownMenuItem<String>>((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: FittedBox(
                      child: Row(
                        children: [
                          Icon(entry.value['iconData'] as IconData, size: 12),
                          SizedBox(width: 5),
                          Text(
                            entry.value['display_name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ],
                      ),
                    ),
                  );
                  }).toList(),
                  //value: widget.value['moduleDropdownList']['dropdownModuleDisplayName'],
                  onChanged: (value) {
                    widget.value['moduleDropdownList']['dropdownModuleInternalName'] = value;
                    if(moduleDropdownListItems[value] == null){
                      widget.value['moduleDropdownList']['dropdownModuleDisplayName'] = value;
                    } else {
                      widget.value['moduleDropdownList']['dropdownModuleDisplayName'] = moduleDropdownListItems[value]!["display_name"];
                      widget.value['moduleDropdownList']['dropdownIconData'] = moduleDropdownListItems[value]!["iconData"];
                    }
                    debugPrint('Set to ${widget.value['moduleDropdownList']['dropdownModuleInternalName']}');
                    ElmModuleList.updateAllModule(appState: appGenericState);
                  },
                  buttonStyleData: ButtonStyleData(
                    height: 50,
                    width: 160,
                    padding: const EdgeInsets.only(left: 14, right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black26,
                      ),
                      color: const Color.fromARGB(255, 216, 216, 216),
                    ),
                    elevation: 2,
                  ),
                  iconStyleData: IconStyleData(
                    icon: Icon(
                      Icons.arrow_forward_ios_outlined,
                    ),
                    iconSize: 14,
                    iconEnabledColor: appGenericState.themeColour,
                    iconDisabledColor: appGenericState.themeColour,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color.fromARGB(255, 216, 216, 216),
                    ),
                    offset: const Offset(-20, 0),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: MaterialStateProperty.all(6),
                      thumbVisibility: MaterialStateProperty.all(true),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.only(left: 14, right: 14),
                  ),
                ),
              ),
            ),
            //Shift Up
            ElmIconButton(iconData: isVertical ? Icons.arrow_upward : Icons.arrow_back, iconColor: appGenericState.themeColour, buttonWidth: 35, enabled: appGenericState.enabledButtons['shiftup'],
              onPressFunctions: () {
                ElmModuleList.addModuleBelow(
                  moduleIndex: widget.moduleIndex - 2,
                  appState: appGenericState,
                  newValue: widget.value,
                );
                ElmModuleList.deleteModule(
                  moduleIndex: widget.moduleIndex + 1, 
                  appState: appGenericState, 
                  context: context,
                );
                ElmModuleList.updateAllModule(
                  appState: appGenericState,
                );
              }
            ),
            //Shift Down
            ElmIconButton(iconData: isVertical ? Icons.arrow_downward : Icons.arrow_forward, iconColor: appGenericState.themeColour, buttonWidth: 35, enabled: appGenericState.enabledButtons['shiftdown'],
              onPressFunctions: () {
                ElmModuleList.addModuleBelow(
                  moduleIndex: widget.moduleIndex + 1,
                  appState: appGenericState,
                  newValue: widget.value,
                );
                ElmModuleList.deleteModule(
                  moduleIndex: widget.moduleIndex, 
                  appState: appGenericState, 
                  context: context,
                );
                ElmModuleList.updateAllModule(
                  appState: appGenericState,
                );
              }
            ),
            //Copy
            ElmIconButton(iconData: Icons.copy, iconColor: appGenericState.themeColour, enabled: appGenericState.enabledButtons['copy'],
              onPressFunctions: () {
                ElmModuleList.addModuleBelow(
                  moduleIndex: widget.moduleIndex,
                  appState: appGenericState,
                  newValue: widget.value,
                );
                ElmModuleList.updateAllModule(
                  appState: appGenericState,
                );
              }
            ),
            //Delete
            ElmIconButton(iconData: Icons.delete, iconColor: appGenericState.themeColour, enabled: appGenericState.enabledButtons['delete'],
            onPressFunctions: (){
              //TO-DO: Option to disable warning
              Get.defaultDialog(title: 'util_deletewave_warning_title'.tr, middleText:  'util_deletewave_warning_desc'.tr, textCancel: 'Cancel'.tr, textConfirm: 'generic_confirm'.tr, onConfirm: (){
                ElmModuleList.deleteModule(
                  moduleIndex: widget.moduleIndex,
                  appState: appGenericState,
                  context: context
                );
                ElmModuleList.updateAllModule(
                  appState: appGenericState,
                );
                Get.back();
              });
    
            }),
            //Add
            ElmIconButton(iconData: Icons.add, iconColor: appGenericState.themeColour, enabled: appGenericState.enabledButtons['add'],
              onPressFunctions:(){
                ElmModuleList.addModuleBelow(
                  moduleIndex: widget.moduleIndex,
                  appState: appGenericState,
                  newValue: null,
                );
                ElmModuleList.updateAllModule(
                  appState: appGenericState,
                );
              }
            ),
            //Extra Menu. Contains all disabled buttons.
            ElmIconButton(iconData: Icons.more_horiz, iconColor: appGenericState.themeColour, enabled: appGenericState.enabledButtons['extra'],
              onPressFunctions:(){
                Get.defaultDialog(title: 'util_moreactions'.tr, middleTextStyle: TextStyle(fontSize: 0), textCancel: 'Cancel'.tr, 
                  actions: [
                    //Shift Up
                    ElmIconButton(iconData: isVertical ? Icons.arrow_upward : Icons.arrow_back, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['shiftup'],
                      onPressFunctions: () {
                        ElmModuleList.addModuleBelow(
                          moduleIndex: widget.moduleIndex - 2,
                          appState: appGenericState,
                          newValue: widget.value,
                        );
                        ElmModuleList.deleteModule(
                          moduleIndex: widget.moduleIndex + 1, 
                          appState: appGenericState, 
                          context: context,
                        );
                        ElmModuleList.updateAllModule(
                          appState: appGenericState,
                        );
                        Get.back();
                      }
                    ),
                    //Shift Down
                    ElmIconButton(iconData: isVertical ? Icons.arrow_downward : Icons.arrow_forward, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['shiftdown'],
                      onPressFunctions: () {
                        ElmModuleList.addModuleBelow(
                          moduleIndex: widget.moduleIndex + 1,
                          appState: appGenericState,
                          newValue: widget.value,
                        );
                        ElmModuleList.deleteModule(
                          moduleIndex: widget.moduleIndex, 
                          appState: appGenericState, 
                          context: context,
                        );
                        ElmModuleList.updateAllModule(
                          appState: appGenericState,
                        );
                        Get.back();
                      }
                    ),
                    //Copy
                    ElmIconButton(iconData: Icons.copy, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['copy'],
                      onPressFunctions: () {
                        ElmModuleList.addModuleBelow(
                          moduleIndex: widget.moduleIndex,
                          appState: appGenericState,
                          newValue: widget.value,
                        );
                        ElmModuleList.updateAllModule(
                          appState: appGenericState,
                        );
                        Get.back();
                      }
                    ),
                    //Delete
                    ElmIconButton(iconData: Icons.delete, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['delete'],
                    onPressFunctions: (){
                      //TO-DO: Option to disable warning
                      Get.defaultDialog(title: 'util_deletewave_warning_title'.tr, middleText:  'util_deletewave_warning_desc'.tr, textCancel: 'Cancel'.tr, textConfirm: 'generic_confirm'.tr, onConfirm: (){
                        ElmModuleList.deleteModule(
                          moduleIndex: widget.moduleIndex,
                          appState: appGenericState,
                          context: context
                        );
                        ElmModuleList.updateAllModule(
                          appState: appGenericState,
                        );
                        Get.back();
                        Get.back();
                      });
                    }),
                    //Add
                    ElmIconButton(iconData: Icons.add, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['add'],
                      onPressFunctions:(){
                        ElmModuleList.addModuleBelow(
                          moduleIndex: widget.moduleIndex,
                          appState: appGenericState,
                          newValue: null,
                        );
                        ElmModuleList.updateAllModule(
                          appState: appGenericState,
                        );
                        Get.back();
                      }
                    ),
                  ]
                );
              }
            ),
          ],
        ),
        //SizedBox(height: 10),
        //Level Modules
        ElmSingleModuleInputWidget(appGenericState: appGenericState, widget: widget),
      ],
    );
  }
}

///
/// Single Module - Lower Half
///
class ElmSingleModuleInputWidget<T extends GenericProviderState> extends StatelessWidget {
  const ElmSingleModuleInputWidget({
    super.key,
    required this.appGenericState,
    required this.widget,
  });

  final T appGenericState;
  final ElmModuleList<GenericProviderState> widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(17, 22, 123, 255), // Light blue background color
        border: Border.all(
          color: Color.fromARGB(63, 10, 53, 117), // Dark blue outline color
          width: 2, // Outline thickness
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(7), // Rounded corners
        ),
      ),
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.all(5),
      height: 200,
      child: Wrap(
        children: [
          //Stuff goes here
        ]
      ),
    );
  }
}

dynamic elmSizeTween({required animation}) {
  return CurvedAnimation(
    parent: animation, // Use the provided animation
    curve: Curves.linear, // Apply an ease-out curve
  );
}

class ElmModuleListWidget<T extends GenericProviderState> extends StatelessWidget {
  ElmModuleListWidget({
    super.key,
    required this.appState,
    required this.title,
    required this.addModuleText,
  });

  final T appState;
  final String title;
  final String addModuleText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () {
              ElmModuleList.addModuleBelow(moduleIndex: -1, newValue: null, appState: appState);
            },
            child: Row(children: [Icon(Icons.add, color: appState.themeColour,), Text(addModuleText, selectionColor: appState.themeColour,)])
          ),
        ],
      ),
      body: AnimatedList(
        scrollDirection: appState.isVertical ? Axis.vertical : Axis.horizontal,
        key: appState.animatedModuleListKey,
        initialItemCount: appState.elmModuleListArr.length,
        controller: appState.scrollController,
        itemBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: elmSizeTween(animation: animation),
              axis: appState.isVertical ? Axis.vertical : Axis.horizontal,
              axisAlignment: 0,
              child: ElmModuleList<T>(
                moduleIndex: index,
                value: appState.elmModuleListArr[index].value,
              ),
            ),
          );
        },
      ),
    );
  }
}
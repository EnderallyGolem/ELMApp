import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart'; 
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:json_editor/json_editor.dart';

import 'main.dart';
import 'util_functions.dart';


//
// This isn't used because I couldn't find a way to make it not jank
// Updating modules midway without causing looping errors and what not is too difficult
//

/// A stack-based class to manage undo and redo functionality.
/// 
/// Set callback functions [addItemFunction], which runs when a function is added with class.add([item]),
/// [undoFunction], when class.undo() is ran, and [redoFunction], which runs when class.redo() is ran.
/// 
/// All 3 functions take [item] as a parameter. (The item is stored in the stack.) 
/// 
/// Optional: An initial [appChangeStack] can be set.
/// Optional: The maximum stack size [maxStackSize] can be set.
class UndoStack {
  List<dynamic> appChangeStack;
  int appChangeStackIndex;
  int? maxStackSize;
  bool canRedo;
  bool canUndo;

  final Function(dynamic item) addItemFunction;
  final Function(dynamic item) undoFunction;
  final Function(dynamic item) redoFunction;

  UndoStack({
    List<dynamic>? initialStack,
    this.maxStackSize,
    required this.addItemFunction,
    required this.undoFunction,
    required this.redoFunction,
  }) : appChangeStack = initialStack ?? [],
        appChangeStackIndex = initialStack != null ? initialStack.length - 1 : -1,
        canRedo = false,
        canUndo = initialStack != null && initialStack.isNotEmpty;

  void add(dynamic newItem) {
    appChangeStack.length = appChangeStackIndex + 1;
    appChangeStack.add(newItem);
    appChangeStackIndex++;
    addItemFunction(newItem);
    canUndo = true;
    canRedo = false;

    //If stack size exceeds max, time to shrink it!
    if(maxStackSize != null && appChangeStackIndex >= maxStackSize!){
      appChangeStackIndex--;
      appChangeStack.removeAt(0);
    }
    //debugPrint('Add: Index $appChangeStackIndex Stack ${appChangeStack[appChangeStackIndex]}');
  }

  void undo() {
    if (canUndo) {
      appChangeStackIndex--;
      undoFunction(appChangeStack[appChangeStackIndex]);
      canUndo = appChangeStackIndex > 0;
      canRedo = true;
      //debugPrint('Undo: Index $appChangeStackIndex Stack ${appChangeStack[appChangeStackIndex]}');
    }
  }

  void redo() {
    if (canRedo) {
      appChangeStackIndex++;
      redoFunction(appChangeStack[appChangeStackIndex]);
      canRedo = appChangeStackIndex < appChangeStack.length - 1;
      canUndo = true;
      //debugPrint('Redo: Index $appChangeStackIndex Stack ${appChangeStack[appChangeStackIndex]}');
    }
  }
}



/// A small button that only consists of an icon and runs some functions.
/// 
/// [iconData] is the icon type, eg: Icons.arrow_upward
/// [iconColor] is the icon colour, eg: Color.fromARGB(255, 58, 104, 183)
/// [onPressFunctions] are functions to be ran when button is clicked.
/// 
/// Optional doubles [buttonWidth] and [buttonHeight] for width and height of buttons. Default 60, 35
/// [borderRadius] to change how rounded the borders are. Default 14.
/// Optional [iconSize] for icon size. Default 20.
/// Optional [backgroundColor] for the background colour. Duh.
/// Optional [enabled]. Button is offstage if false.
/// 
class ElmIconButton extends StatelessWidget {
  ElmIconButton({
    super.key,
    required this.iconData,
    required this.iconColor,
    required this.onPressFunctions,
    this.buttonWidth = 45,
    this.buttonHeight = 25,
    this.borderRadius = 15,
    this.iconSize = 20,
    this.enabled = true,
    this.backgroundColor = const Color.fromARGB(255, 245, 245, 245),
  });

  final IconData iconData;
  final Color iconColor;
  final Function onPressFunctions;
  final double buttonWidth;
  final double buttonHeight;
  final double borderRadius;
  final double iconSize;
  final bool? enabled;
  final Color backgroundColor;

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
            backgroundColor: backgroundColor,
            alignment: Alignment.center,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
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
  late bool runForFirstTime;
  late bool isImportingModules;
  late bool isVertical;
  late Map<String, bool> enabledButtons;
  late String moduleJsonFileName;
  VoidCallback? onNavigateToTargetPage;
  bool allowUpdateModule = true;
  late ScrollController scrollController;
  late double scrollOffset;

  void dispose();
  void updateModuleState();
  void updateModuleUI();
  void updateModuleCodeInMain({required elmModuleListArr});
  void checkImportModuleCode();
}



class ElmModuleList<T extends GenericProviderState> extends StatefulWidget {
  final int moduleIndex;
  dynamic value;
  dynamic uniqueValue; //NOT copied when copy-pasted. TextControllers for example
  Key? key;

  ElmModuleList({required this.moduleIndex, this.value = null, this.uniqueValue, this.key = null}) {
    //Sets a value if null
    key ??= UniqueKey();
    value ??= {
      'module_dropdown_list': null, //Entirely for the dropdown list selecting which module is used
      'internal_data': null, //Stored internal values. Values here are temporary and will not appear in the final code.
      'input_data': {}, //Stores TYPED input data. Data here will be stored in the module itself for importing.
      'input_header_data': {}, //Special input values for headers. This is to store more data while maintaining path format for lists with regular values
      'variables': null //Stored values that are actually used. If you typed nothing, this can be different from internal_data (uses default value instead)
    };

    //This is splitted apart in case only some parts are defined, for instance when importing objs
    value['module_dropdown_list'] ??= {
      'dropdown_module_display_text': 'util_default_module_dropdown'.tr,
      'dropdown_module_internal_name': 'empty',
      'dropdown_image': Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20),
    };
    value['internal_data'] ??= {
      'minimised': false,
      'objects': [],
      'levelModules': [],
      'waveModules': [],
    };
    value['variables'] ??= {
      'select_module_message': 'util_default_module_message'.tr,
      'aliases': null,
      'default_aliases': '',
      'event_number': moduleIndex + 1,
    };
    value['input_data'] ??= {};
    value['input_header_data'] ??= {};

    uniqueValue ??= {
      //Internal data which ARE NOT COPIED when the wave is copied.
      'internal_data': {
        'firstUpdate': true,
      },
      //values is deep copied, but controllers aren't deep copied (so it's more like medium copied?)
      'controller_data': {},
    };
    //Update values on rebuild
    value['variables']['event_number'] = moduleIndex + 1;
    value['variables']['default_aliases'] = '${value['module_dropdown_list']['dropdown_module_internal_name']}_${value['variables']['event_number']}';
    if(value['variables']['aliases'] == null){
      value['variables']['aliases'] = value['variables']['default_aliases'];
    }
    //debugPrint('${key} ${moduleIndex} || Value ${value}');
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
  }
  static void addModuleBelow<T extends GenericProviderState>({required int moduleIndex, dynamic newValue = null, required T appState, bool deepCopyValue = false}) {
    if (newValue != null && deepCopyValue){
      newValue = deepCopy(newValue);
    }
    moduleIndex = moduleIndex < -1 ? -1 : moduleIndex;
    moduleIndex = moduleIndex > appState.elmModuleListArr.length - 1 ? appState.elmModuleListArr.length - 2 : moduleIndex;
    appState.elmModuleListArr.insert(moduleIndex+1, ElmModuleList<T>(moduleIndex: moduleIndex, value: newValue)); //newValue will be new module list
    appState.animatedModuleListKey.currentState!.insertItem(
      moduleIndex+1, 
      duration: Duration(milliseconds: 150)
    );
  }
  static void correctAnimatedModuleListSize<T extends GenericProviderState>({required T appState, required BuildContext context}) {
    appState.animatedModuleListKey.currentState!.removeAllItems(
      duration: Duration(milliseconds: 0),
      (context, animation) => _buildAnimatedElmModuleList<T>(moduleIndex: 0, animation: animation, appState: appState)
    );
    appState.animatedModuleListKey.currentState!.insertAllItems(
      0, appState.elmModuleListArr.length,
      duration: const Duration(milliseconds: 0)
    );
  }

  ///
  /// Example for [path] : ['moduleName', 'display'] or ['test', 0]
  ///
  static void changeModuleValue<T extends GenericProviderState>({int moduleIndex = 0, required dynamic newValue, required dynamic path, required T appState}) {
    setNestedProperty(obj: appState.elmModuleListArr[moduleIndex].value, path: path, value: newValue);
  }

  static void updateAllModuleUI<T extends GenericProviderState>({required T appState}) {
    appState.updateModuleUI();
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

    bool isVertical = appGenericState.isVertical;
    if (widget.value['internal_data']['minimised']){
      //Minimised single module
      return ElmSingleModuleMinimisedWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical);
    } else {
      //The normal single module
      return ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical);
    }
  }
}

///
/// Single Module - Minimised
///
class ElmSingleModuleMinimisedWidget<T extends GenericProviderState> extends StatelessWidget {
  const ElmSingleModuleMinimisedWidget({
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
    if(appGenericState.isVertical){
      //Vertical: Return Row
      return Row(
        children: [
          SizedBox(
            width: 150,
            height: 30,
            child: ElevatedButton(
              onPressed: (){
                widget.value['internal_data']['minimised'] = !widget.value['internal_data']['minimised'];
                ElmModuleList.updateAllModuleUI(appState: appGenericState);
              },
              style: ElevatedButton.styleFrom(
                fixedSize: Size.fromHeight(25),
                minimumSize: Size.fromHeight(25),
                elevation: 2,
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                backgroundColor: Color.fromARGB(255, 216, 216, 216),
                side: BorderSide(
                  color: Color.fromARGB(63, 10, 53, 117), // Dark blue outline color
                  width: 0.6, // Outline thickness
                ),
              ),
              child: Row(
                children: [
                  widget.value['module_dropdown_list']['dropdown_image'],
                  SizedBox(width: 4),
                  Expanded(
                    child: AutoSizeText(
                      widget.value['variables']['aliases'],
                      maxFontSize: 14,
                      minFontSize: 5,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: appGenericState.themeColour,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ]
              )
            ),
          ),
          //Module Button List
          ElmModuleButtonList(appGenericState: appGenericState, widget: widget, isVertical: isVertical),
          //Purpose of offstage instead of nothing is so functions that run when module is built actually run
          Offstage(child: ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical)),
        ],
      );
    } else {
      //Horizontal: Return Column
      return Column(
        children: [
          SizedBox(
            width: 135,
            height: 30,
            child: ElevatedButton(
              onPressed: (){
                widget.value['internal_data']['minimised'] = !widget.value['internal_data']['minimised'];
                ElmModuleList.updateAllModuleUI(appState: appGenericState);
              },
              style: ElevatedButton.styleFrom(
                fixedSize: Size.fromHeight(25),
                minimumSize: Size.fromHeight(25),
                elevation: 2,
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                backgroundColor: Color.fromARGB(155, 216, 216, 216),
                side: BorderSide(
                  color: Color.fromARGB(63, 10, 53, 117), // Dark blue outline color
                  width: 0.6, // Outline thickness
                ),
              ),
              child: Row(
                children: [
                  widget.value['module_dropdown_list']['dropdown_image'],
                  SizedBox(width: 4),
                  Expanded(
                    child: AutoSizeText(
                      widget.value['variables']['aliases'],
                      maxFontSize: 14,
                      minFontSize: 5,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: appGenericState.themeColour,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ]
              )
            ),
          ),
          //Module Button List
          ElmModuleButtonList(appGenericState: appGenericState, widget: widget, isVertical: isVertical),
          //Purpose of offstage instead of nothing is so functions that run when module is built actually run
          Offstage(child: ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical)),
        ],
      );
    }
  }
}

///
/// Single Module - Upper Half
/// Aka the dropdown list
///
class ElmSingleModuleMainWidget<T extends GenericProviderState> extends StatelessWidget {
  const ElmSingleModuleMainWidget({
    super.key,
    required this.widget,
    required this.appGenericState,
    required this.isVertical,
  });

  final ElmModuleList<T> widget;
  final T appGenericState;
  final bool isVertical;



  @override
  Widget build(BuildContext context) {

    //For import: If have 'dropdown_module_internal_name' but not the others

    if(widget.value['module_dropdown_list']['dropdown_module_internal_name'] != null && widget.value['module_dropdown_list']['dropdown_image'] == null){
      String moduleInternalName = widget.value['module_dropdown_list']['dropdown_module_internal_name'];
      widget.value['module_dropdown_list']['dropdown_module_display_text'] = ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][moduleInternalName]!["display_text"];
      widget.value['module_dropdown_list']['dropdown_image'] = ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][moduleInternalName]!["Image"];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(4, 2, 2, 0),
          child: Row(
            children: [
              //Dropdown Button
              SizedBox(
                width: 158,
                height: 30,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        widget.value['module_dropdown_list']['dropdown_image'] ?? Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20),
                        SizedBox(width: 4),
                        Expanded(
                          child: AutoSizeText(
                            widget.value['module_dropdown_list']['dropdown_module_display_text'],
                            maxFontSize: 14,
                            minFontSize: 5,
                            style: TextStyle(
                              color: appGenericState.themeColour,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    items: ProviderMainState.global["moduleJsons"]["${appGenericState.moduleJsonFileName}_enabled"].entries.map<DropdownMenuItem<String>>((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: FittedBox(
                        child: Row(
                          children: [
                            entry.value['Image'] ?? Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20,),
                            SizedBox(width: 5),
                            Text(
                              entry.value['display_text'] as String,
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
                    //value: widget.value['module_dropdown_list']['dropdown_module_display_text'],
                    onChanged: (value) {
                      widget.value['module_dropdown_list']['dropdown_module_internal_name'] = value;
                      if(ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][value] == null){
                        widget.value['module_dropdown_list']['dropdown_module_display_text'] = value;
                      } else {
                        widget.value['module_dropdown_list']['dropdown_module_display_text'] = ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][value]!["display_text"];
                        widget.value['module_dropdown_list']['dropdown_image'] = ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][value]!["Image"];
                      }
                      ElmModuleList.updateAllModuleUI(appState: appGenericState);
                      widget.uniqueValue['internal_data']['firstUpdate'] = true;
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
                        thickness: WidgetStateProperty.all(6),
                        thumbVisibility: WidgetStateProperty.all(true),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                      padding: EdgeInsets.only(left: 14, right: 14),
                    ),
                  ),
                ),
              ),
              //Module Button List
              ElmModuleButtonList(appGenericState: appGenericState, widget: widget, isVertical: isVertical),
            ],
          ),
        ),
        //Level Modules
        //If isVertical, add horizontal scorlling view
        appGenericState.isVertical ?
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ElmSingleModuleInputWidget(appGenericState: appGenericState, widget: widget)
        ) : 
        ElmSingleModuleInputWidget(appGenericState: appGenericState, widget: widget)
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
  final ElmModuleList<T> widget;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: appGenericState.isVertical ? MediaQuery.of(context).size.width : 300, 
        maxWidth: double.infinity,
        maxHeight: 200
      ),
      child: Container(
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
        margin: const EdgeInsets.fromLTRB(2, 3, 2, 5),
        height: 200,
        child: ElmDynamicModuleForm(appState: appGenericState, widget: widget, config: ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName][widget.value['module_dropdown_list']['dropdown_module_internal_name']])
      ),
    );
  }
}

void updateVariablesFromConfig({required String internal_name, required Map<String, dynamic> configVariable, required ElmModuleList widget, required GenericProviderState appState}){
  //debugPrint('updateVariablesFromConfig: $internal_name | $configVariable');
  switch (configVariable['type']) {
    case 'text_concatenate':
      variableTextConcatenate(
        internal_name: internal_name, 
        config: configVariable, 
        widget: widget, 
        appState: appState,
        text_list: configVariable['text_list'],
        text_seperator: configVariable['text_seperator'],
      );
      break;
    case 'number_offset':
      //
      break;
    case 'checkbox_chooser':
      //
      break;
    default:
      break;
  }
}

int loopLimitModule = 0;

///
/// variableCheckString except it checks all values in a nested list/map.
/// 
/// Checks if each value in [input] starts with a !, and if it does, turns into the variable's value.
/// Otherwise, keep unchanged.
/// If null, will become an empty string.
/// 
/// The new (deep-cloned) nested list/map is returned.
///
dynamic variableCheckDynamic({
  bool isExport = false, 
  required dynamic input, 
  required ElmModuleList widget, 
  int loopLimit = 10, 
  dynamic nestedListInfo = null
}){
  dynamic inputClone = deepCopy(input);
  if(loopLimit == 10){loopLimitModule = 300;}
  inputClone = iterateAndModifyNestedListOrdered(
    nestedItem: inputClone,
    function: (key, value, path) {
      return variableCheckString(
        isExport: isExport,
        key: key, 
        input: value, 
        path: path,
        nestedItem: inputClone,
        widget: widget, 
        loopLimit: loopLimit, 
        nestedListInfo: nestedListInfo);
    }
  );
  inputClone ??= "";
  if (inputClone is ReplaceNestedList){
    inputClone = inputClone.value;
  }
  return inputClone;
}

///
/// Checks if [input] starts with a !, and if it does, returns the variable's value.
/// Otherwise, returns itself.
/// 
/// If [input] is null, return empty string
/// 
///
dynamic variableCheckString({
  bool isExport = false, 
  dynamic key = null, //Could be string or int
  required dynamic input, 
  List? path,
  dynamic nestedItem,
  required ElmModuleList widget, 
  int loopLimit = 10, 
  dynamic nestedListInfo = null
}){
  input ??= "";
  dynamic returnValue;
  bool canRemove = true;

  loopLimitModule--;
  //debugPrint('Loop Limits: Single: $loopLimit | Module: $loopLimitModule');

  if(input is! String || loopLimit < 1 || loopLimitModule < 1){
    //If not string (if number maybe) then just immediately return that
    //If loopLimit is exhausted, also immediately cut short and return
    return input;
  };

  if (input.startsWith('!!')){
    //If prefix is !!, it's ! but canRemove is false. (It is a variable, obtain the variable)
    canRemove = false;
    if (input.endsWith('}') && input.contains('{')) {
      //If it is a list that contains some parameter, it runs SPECIAL CODE!
      //This requires the lowest level list to be rebuilt (and reiterated)
      returnValue = variableCheckStringListParameter(widget: widget, objName: input.substring(2), key: key, path: path, nestedItem: nestedItem, nestedListInfo: nestedListInfo, loopLimit: loopLimit-1, isExport: isExport);
    } else {
      //Otherwise, continue iteration as per usual
      returnValue = widget.value['variables'][input.substring(2)];
      //The return value might itself be another variable, thus iterate more! Iterate! Iterate! Iterateeeee!!!!!
      returnValue = variableCheckDynamic(input: returnValue, widget: widget, isExport: isExport, loopLimit: loopLimit-1, nestedListInfo: nestedListInfo);
    }
  } else if (input.startsWith('!')){
    //If prefix is !, it's a variable. Obtain the variable.
    if (input.endsWith('}') && input.contains('{')) {
      returnValue = variableCheckStringListParameter(widget: widget, objName: input.substring(1), key: key, path: path, nestedItem: nestedItem, nestedListInfo: nestedListInfo, loopLimit: loopLimit-1, isExport: isExport);
    } else {
      returnValue = widget.value['variables'][input.substring(1)];
      returnValue = variableCheckDynamic(input: returnValue, widget: widget, isExport: isExport, loopLimit: loopLimit-1, nestedListInfo: nestedListInfo);
    }
  } else {
    returnValue = input;
  }

  //If level code is being exported, empty returnValue means return null (delete that value)
  if(isExport && canRemove && (returnValue == null || returnValue == "")){
    return null;
  } else {
    return returnValue;
  }
}

//
// FOR LISTS WITH PARAMETERS
//
variableCheckStringListParameter({required String objName, required dynamic key, required List? path, required dynamic nestedItem, dynamic nestedListInfo, int loopLimit = 10, required ElmModuleList widget, required bool isExport}) {
  //debugPrint('variable check list stuff: objName $objName | key $key | path $path | nestedItem $nestedItem | nestedListInfo $nestedListInfo');

  nestedListInfo ??= {
    'parametersHaveLooped': {
      //L_textListgrid{item}
    },
    'parametersLoopValue': {
      //L_textListgrid{item} = 4;
    },
    'parametersLoopIndex': {
      //L_textListgrid{item} = 1;
    }
  };

  List parametersToLoop = [
    //[L_textListgrid, axis_column]
  ];

  void addParameter({required String variable, required String parameter}){
    //debugPrint('--------- variable $variable | parameter $parameter | nestedListInfo $nestedListInfo');
    //If parameters aren't stored in parametersHaveLooped, store parametersHaveLooped > key > axis_row = false and axis_column = false
    if(nestedListInfo['parametersHaveLooped']?[variable] == null){
      nestedListInfo['parametersHaveLooped'][variable] = <String, bool>{'axis_row': false, 'axis_column': false};
    }

    //If parametersHaveLooped is false in nestedListInfo (and matching parameter), 
    //add to parameterLooping, and set to true in parametersHaveLooped
    if((parameter == "axis_row" || parameter == "item") && nestedListInfo['parametersHaveLooped'][variable]["axis_row"] == false){
      parametersToLoop.add([variable, 'axis_row']);
      nestedListInfo['parametersHaveLooped'][variable]['axis_row'] = true;
    }
    if((parameter == "axis_column" || parameter == "item") && nestedListInfo['parametersHaveLooped'][variable]["axis_column"] == false){
      parametersToLoop.add([variable, 'axis_column']);
      nestedListInfo['parametersHaveLooped'][variable]['axis_column'] = true;
    }
  }

  if(path == null){
    debugPrint('variableCheckStringListParameter: path == null. Does this ever run? I dont think this ever runs. If it does though, I have to actually make it work xd');
    //If path is null, this simply has to return a filtered list (this shouldn't even be used)
    //set loop value in parametersLoopValue, add to parameterLooping, and set to true in parametersHaveLooped
    //(item = both row and column)
    String variable = objName.substring(objName.startsWith('!!') ? 2 : 1, objName.indexOf('{'));
    String parameter = objName.substring(objName.indexOf('{') + 1, objName.indexOf('}'));
    addParameter(variable: variable, parameter: parameter);

    dynamic returnItem;

    //Extract the filtered item to return
    if(parameter == "axis_row" || parameter == "axis_column"){
      //Return row/col headers
      returnItem = widget.value['input_header_data'][variable][parameter];
    } else {
      //Return flattened ver of list
      returnItem = flatten(widget.value['variables'][variable]);
    }

    return variableCheckDynamic(input: returnItem, widget: widget);

  } else {
    //If path is not null, has to replace the lowest list with a new one.
    //look at ALL items in the current list layer (including any maps in it) and list all the parameters
    //Reduce path until last item is before an int (lowest list)
    for (int index = path.length - 1; index>=0; index--){
      if(path[index] is int){
        path.removeLast();
        break;
      } else {
        path.removeLast();
      }
    }

    //Now iterate across all items in this list layer only, and extract all the parameters in {}
    iterateAndModifyNestedMapAndTopList(
      nestedItem: getNestedProperty(obj: nestedItem, path: path),
      function: (key, value) {
      if(value is String && value.startsWith('!') && value.endsWith('}') && value.contains('{')){
        String variable = value.substring(value.startsWith('!!') ? 2 : 1, value.indexOf('{'));
        String parameter = value.substring(value.indexOf('{') + 1, value.indexOf('}'));

        //Add parameter to parameterLooping (and modify nestedListInfo) if possible
        addParameter(variable: variable, parameter: parameter);
      }
      return value;
      }
    );

    Map<String, Map<String, List<dynamic>>> allVarValues = {}; //For each parameter in parametersToLoop, get all possible values
    parametersToLoop.forEach((value){
      String variable = value[0];
      String parameter = value[1];
      if (widget.value['input_header_data'][variable] == null) {
        //Null only occurs on first run through when dropdown list is first selected.
        //Code is reran when this happens, so no issues here!
        return; //Please stop though. Though to be honest I don't think this return statement even does anything.
      } else {
        allVarValues[variable] ??= {};
        allVarValues[variable]![parameter] = widget.value['input_header_data'][variable][parameter];
      }
    });

    List replacementList = [];

    //Iterate through all items in parameterLooping.
    if (allVarValues.isNotEmpty) {
      multiDimensionalLoopDoubleMap(allVarValues, (combination, indices) {
        //In each iteration, set the loop value in parametersLoopValue (deep clone first!) and throw it into variableCheckDynamic
        Map<String, bool> markToAdd = {'axis': false, 'item': false, 'noItem': true, 'axisNoItem': false};
        dynamic newNestedItem = deepCopy(getNestedProperty(obj: nestedItem, path: path));
        dynamic newNestedListInfo = deepCopy(nestedListInfo);
        iterateAndModifyNestedMapAndTopList(nestedItem: newNestedItem, function: (key, value){
          if(value is String && value.startsWith('!') && value.endsWith('}') && value.contains('{')){
            String variable = value.substring(value.startsWith('!!') ? 2 : 1, value.indexOf('{'));
            String parameter = value.substring(value.indexOf('{') + 1, value.indexOf('}'));
      
            //Make a copy of the list item here, replace the variable text with the correct value, 
            //insert those values into parametersLoopValue, then add this into the list.
      
            //Obtain the new value.
            dynamic newValue;
            if(parameter == 'axis_row' || parameter == 'axis_column'){
              //For axis_row and axis_column, get the parameter value
              //Variable should either be looping or have looped before. (either in parametersToLoop or parametersLoopValue)
              newValue = combination[variable]?[parameter]; //Check parametersToLoop
              newValue ??= newNestedListInfo?['parametersLoopValue']?[variable]?['axis_row']; //Check parametersLoopValue
      
              setNestedProperty(obj: newNestedListInfo, path: ['parametersLoopValue', variable, parameter], value: newValue); //Using setNestedProperty to bypass any null errors lol
              if (indices[variable]?[parameter] != null) {
                setNestedProperty(obj: newNestedListInfo, path: ['parametersLoopIndex', variable, parameter], value: indices[variable]![parameter]);
              }
              
              //If axis is not empty, axisNoItem is set to true.
              //If there is item, only appear if column isn't empty AND !!
              //If there is no item, appear if column isn't empty OR !!
              int? axisIndex;
              axisIndex = indices[variable]?[parameter]; //Check parametersToLoop
              axisIndex ??= newNestedListInfo?['parametersLoopIndex']?[variable]?[parameter]; //Check parametersLoopValue

              if (widget.value['variables'][variable] != null) { //This is here for importing issues as not all variables are set in the first run.
                if(axisIndex == null){
                } else if(parameter == 'axis_row'){
                  if(widget.value['variables'][variable]?[axisIndex].where((e) => e != "" && e != null).length > 0){
                    markToAdd['axisNoItem'] = true; //Sets axisNoItem to true regardless of !!
                    if(value.startsWith('!!')){markToAdd['axis'] = true;} //Sets axis to true ONLY IF !!
                  }
                } else {
                  List<List<dynamic>> transposedVar = transpose(widget.value['variables'][variable].cast<List<dynamic>>());
                  if(transposedVar[axisIndex].where((e) => e != "" && e != null).length > 0){
                    markToAdd['axisNoItem'] = true; //Sets axisNoItem to true regardless of !!
                    if(value.startsWith('!!')){markToAdd['axis'] = true;} //Sets axis to true ONLY IF !!
                  }
                }
              }
      
              //axisNoItem is also set to true if !!
              if(value.startsWith('!!')){
                markToAdd['axisNoItem'] = true;
              }
            } else {
              //For item, both axis_row and axis_column should either be looping or have looped before. (either in parametersToLoop or parametersLoopValue)
              //Get their indexes (not their value)
              int? axisRowIndex, axisColumnIndex;
              dynamic variableList = widget.value['variables'][variable]; //widget.value['variables'][variable][row][column]
              axisRowIndex = indices[variable]?['axis_row']; //Check parametersToLoop
              axisColumnIndex = indices[variable]?['axis_column'];
              axisRowIndex ??= newNestedListInfo?['parametersLoopIndex']?[variable]?['axis_row']; //Check parametersLoopValue
              axisColumnIndex ??= newNestedListInfo?['parametersLoopIndex']?[variable]?['axis_column'];

              if (axisRowIndex != null && axisColumnIndex != null) { //Null occurs on first dropdown select. Ignore.
                newValue = variableList?[axisRowIndex]?[axisColumnIndex];
                setNestedProperty(obj: newNestedListInfo, path: ['parametersLoopIndex', variable, 'axis_column'], value: axisColumnIndex);
                setNestedProperty(obj: newNestedListInfo, path: ['parametersLoopIndex', variable, 'axis_row'], value: axisRowIndex);
              }
              //If !! or not empty, should show up
              if(value.startsWith('!!') || (newValue != "" && newValue != null)){
                markToAdd['item'] = true;
              }
              markToAdd['noItem'] = false;
            }
            return newValue;
          } else {
            return value; //Not a variable
          }
        });
        //Then go further down and run variableCheckDynamic for anything below with the newNestedItem.
        if ( (markToAdd['axis']! || markToAdd['item']!) || (markToAdd['noItem']! && markToAdd['axisNoItem']!)) {
          newNestedItem = variableCheckDynamic(input: newNestedItem, nestedListInfo: newNestedListInfo, widget: widget, isExport: isExport, loopLimit: loopLimit);
          if (newNestedItem is ReplaceNestedList){
            newNestedItem = newNestedItem.value;
          }
          //The thing returned will be ONE item in the list. Push to replacementList
          replacementList = [...replacementList, ...newNestedItem];
        }
      });
    } else {
      //If allVarValues is empty (because parametersToLoop is empty), iterate across values once to set values from parametersLoopValue
      dynamic newNestedItem = deepCopy(getNestedProperty(obj: nestedItem, path: path));
      dynamic newNestedListInfo = deepCopy(nestedListInfo);
      iterateAndModifyNestedMapAndTopList(
        nestedItem: newNestedItem,
        function: (key, value) {
        if(value is String && value.startsWith('!') && value.endsWith('}')){
          String variable = value.substring(value.startsWith('!!') ? 2 : 1, value.indexOf('{'));
          String parameter = value.substring(value.indexOf('{') + 1, value.indexOf('}'));

          //Add parameter to parameterLooping (and modify nestedListInfo) if possible
          dynamic newValue;
          if(parameter == 'axis_row' || parameter == 'axis_column'){
            newValue ??= nestedListInfo?['parametersLoopValue']?[variable]?[parameter];
          } else if (parameter == 'item'){
            int? axisRowIndex = nestedListInfo?['parametersLoopIndex']?[variable]?['axis_row']; //Check parametersLoopValue
            int? axisColumnIndex = nestedListInfo?['parametersLoopIndex']?[variable]?['axis_column'];
            dynamic variableList = widget.value['variables'][variable];
            if (axisRowIndex != null && axisColumnIndex != null) { //Null occurs on first dropdown select. Ignore.
              newValue = variableList?[axisRowIndex]?[axisColumnIndex];
              setNestedProperty(obj: nestedListInfo, path: ['parametersLoopIndex', variable, 'axis_column'], value: axisColumnIndex);
              setNestedProperty(obj: nestedListInfo, path: ['parametersLoopIndex', variable, 'axis_row'], value: axisRowIndex);
            }
          }
          return newValue;
        }
        return value;
        }
      );
      newNestedItem = variableCheckDynamic(input: newNestedItem, nestedListInfo: newNestedListInfo, widget: widget, isExport: isExport, loopLimit: loopLimit);
      if (newNestedItem is ReplaceNestedList && newNestedItem.value is List<dynamic>){
        replacementList = newNestedItem.value;
      } else if (newNestedItem is List<dynamic>) {
        replacementList = newNestedItem;
      }
    }
    //Return replacementList!
    if(replacementList.isEmpty && loopLimit > 0){
      return ReplaceNestedList([]);
    } else if(loopLimit <= 0){
      //Force return nothing if null. This prevents a ReplaceNestedList from being returned when there shouldn't be one.
      return null;
    } else {
      return ReplaceNestedList(replacementList);
    }
  }
}

class ElmDynamicModuleForm<T extends GenericProviderState> extends StatelessWidget {
  final Map<String, dynamic> config;
  final ElmModuleList<T> widget;
  final T appState;

  ElmDynamicModuleForm({required this.config, required this.widget, required this.appState});

  @override
  Widget build(BuildContext context) {
    List<Widget> formWidgets = [];
    const int loopMaxNum = 30;

    //Create widgets for each input
    updateWidgetAndVariableInfo(formWidgets: formWidgets, loopMaxNum: loopMaxNum);

    //If module type is just changed, it isn't updated properly. Update it once more!
    if(widget.uniqueValue['internal_data']['firstUpdate']){
      widget.uniqueValue['internal_data']['firstUpdate'] = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ElmModuleList.updateAllModuleUI(appState: appState);
      });
    }

    //Update level code and export to main

    widget.value['internal_data']['objects'] = variableCheckDynamic(input: config['raw_code'], widget: widget, isExport: true);
    widget.value['internal_data']['levelModules'] = variableCheckDynamic(input: config['level_modules'], widget: widget, isExport: true);
    widget.value['internal_data']['waveModules'] = variableCheckDynamic(input: config['wave_modules'], widget: widget, isExport: true);

    //Add input internal data used for importing level
    if (widget.value['internal_data']['objects'] != null && widget.value['internal_data']['objects'] != "" && widget.value['internal_data']['objects'].length > 0){

      //Each item should be a map, beacuse that's how PvZ2 works. If it is not, attempt to convert into one (custom code string likely.)
      //Also, maps are able to hold data, so that's 2 issues solved at once!
      //Otherwise, yeet
      for(int index = 0; index < widget.value['internal_data']['objects'].length; index++){
        //If it is a string and the sides are {}, convert it map. Or at least try to anyway.
        if(widget.value['internal_data']['objects'][index] is String){
          widget.value['internal_data']['objects'][index] = convertStringToMap(widget.value['internal_data']['objects'][index]);
          //if it can't be converted to map, YEET.
          if(widget.value['internal_data']['objects'][index] is! Map<dynamic, dynamic>){
            (widget.value['internal_data']['objects'] as List).removeAt(index);
            index--;
          }
        }
      }

      try {
        setNestedProperty(obj: widget.value['internal_data']['objects'], path: [0, "#data"], value: encodeNestedStructure(
          {'module_dropdown_list': {'dropdown_module_internal_name': widget.value['module_dropdown_list']['dropdown_module_internal_name']},
          'input_data': widget.value['input_data'],
          'input_header_data': widget.value['input_header_data']
          }
        ));
      } catch (e) {
        //Event is invalid wow... I can't put a dialog here lol
        debugPrint('Error when trying to add data into event!\nProbably invalid format\n\n $e');
      }

      for(int index = 1; index < widget.value['internal_data']['objects'].length; index++){
        setNestedProperty(obj: widget.value['internal_data']['objects'], path: [index, "#data"], value: index); //Secondary ones don't need to store data. Number = secondary. Because.
      }
    }

    //Build the UI
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: formWidgets,
    );
  }

  void updateWidgetAndVariableInfo({required List<Widget> formWidgets, int loopMaxNum = 1}) {
    dynamic beforeData = deepCopy(widget.value);
    
    //Run code for each variable
    config['variables'] ??= {};
    config['variables'].forEach((internal_name, value) {
      if (!internal_name.startsWith('#')) {
        updateVariablesFromConfig(internal_name: internal_name, configVariable: value, widget: widget, appState: appState);
      }
    });

    dynamic afterData = widget.value;

    //Check if should repeat!
    if(deepEquals(beforeData, afterData) == false && loopMaxNum > 0){
      loopMaxNum--;
      updateWidgetAndVariableInfo(formWidgets: formWidgets, loopMaxNum: loopMaxNum);
      return;
    }

    //Create widgets for each input
    config['inputs'] ??= {};
    config['inputs'].forEach((internal_name, value) {
      if (!internal_name.startsWith('#')) {
        formWidgets.add(createWidgetFromConfig(internal_name: internal_name, configInput: value, widget: widget, appState: appState));
      }
    });
  }
}

void variableTextConcatenate({
  required String internal_name, 
  required Map<String, dynamic> config, 
  required ElmModuleList widget, 
  required GenericProviderState appState,
  required List? text_list,
  required String? text_seperator,
}){
  text_list = variableCheckDynamic(input: text_list, widget: widget);
  text_seperator = variableCheckString(input: text_seperator, widget: widget);

  widget.value['variables'][internal_name] = text_list!.join(text_seperator!);
}

Widget createWidgetFromConfig(
  {
    required String internal_name, 
    required Map<String, dynamic> configInput, 
    required ElmModuleList widget, 
    required GenericProviderState appState,

    //For list
    Map<String, dynamic> listItemDetails = const {},
    List? path = null,
  }
){
  path ??= [internal_name];
  //debugPrint('createWidgetFromConfig || internal_name $internal_name | configInput $configInput');
  switch (configInput['type']) {
    case 'none':
      return NoInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        path: path,
        display_text: configInput['display_text'],
      );
    case 'aliases':
      return AliasesInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        path: path,
        display_text: configInput['display_text'],
      );
    case 'text':
      return TextInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        path: path,
        listItemDetails: listItemDetails,
        display_text: configInput['display_text'],
        default_text: configInput['default_text'],
      );
    case 'code':
      return CodeInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        path: path,
        listItemDetails: listItemDetails,
        display_text: configInput['display_text'],
        default_object: configInput['default_object'],
      );
    case 'list':
      return ListInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: configInput['display_text'],
        cell_width: configInput['cell_width'],
        cell_height: configInput['cell_height'],
        header_width: configInput['header_width'],
        header_height: configInput['header_height'],

        itemConfig: configInput['item'],
        rowConfig: configInput['axis_row'],
        columnConfig: configInput['axis_column'],
      );
    default:
      return SizedBox.shrink();
  }
}

class ListInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  String? display_text;
  final String internal_name;
  dynamic cell_width;  //Can be either int or double. Urggh.
  dynamic cell_height; //Can be either int or double. Eeurgh.
  dynamic header_width;  //Can be either int or double. Nnngghh.
  dynamic header_height; //Can be either int or double. Rawrrgh.

  Map<String, dynamic>? itemConfig;
  Map<String, dynamic>? rowConfig;
  Map<String, dynamic>? columnConfig;

  ListInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
    required this.cell_width,
    required this.cell_height,
    required this.header_width,
    required this.header_height,

    required this.itemConfig,
    required this.rowConfig,
    required this.columnConfig,
  }){
    cell_width ??= 100;
    cell_width = cell_width.toDouble();
    cell_height ??= 25;
    cell_height = cell_height.toDouble();
    header_width ??= 50;
    header_width = header_width.toDouble();
    header_height ??= 25;
    header_height = header_height.toDouble();

    display_text = variableCheckString(input: display_text, widget: widget);
    itemConfig ??= {"type": "text"};
    rowConfig ??= {"axis_type": "none", "default_size": "2", "size_range": "2..5"};
    columnConfig ??= {"axis_type": "none", "default_size": "2", "size_range": "2..5"};
  }

  @override
  Widget build(BuildContext context) {

    int? rowNum = null, columnNum = null, rowMinSize = null, rowMaxSize = null, rowInitialSize = null, columnMinSize = null, columnMaxSize = null, columnInitialSize = null;
    List rowHeaderValues = [], rowHeaderValuesDisplay = [], columnHeaderValues = [], columnHeaderValuesDisplay = [];

    rowNum = widget.value?['input_header_data']?[internal_name]?['rowNum'];
    columnNum = widget.value?['input_header_data']?[internal_name]?['columnNum'];

    //Obtain and set information on axis_row and axis_column. Info on (each) item obtained when building table.
    rowConfig!['axis_type'] ??= "none";
    columnConfig!['axis_type'] ??= "none";
    [rowMinSize, rowMaxSize, rowInitialSize] = convertRange(stringRange: rowConfig!['size_range'], inputClamp: rowConfig!['size_default'], minLower: 1, maxUpper: 100, defaultLower: 2, defaultUpper: 5);
    [columnMinSize, columnMaxSize, columnInitialSize] = convertRange(stringRange: columnConfig!['size_range'], inputClamp: columnConfig!['size_default'], minLower: 1, maxUpper: 100, defaultLower: 2, defaultUpper: 10);

    //Only ran the first time in order to obtain initial values
    rowNum ??= rowInitialSize;
    columnNum ??= columnInitialSize;

    void updateHeaderData(List<dynamic> rowHeaderValues, int rowNum, List<dynamic> columnHeaderValues, int columnNum) {
    rowHeaderValues = [];
    rowHeaderValuesDisplay = [];
    columnHeaderValues = [];
    columnHeaderValuesDisplay = [];
      switch (rowConfig!['axis_type']) {
        case 'number':
          //TO-DO
          break;
        default: //None
        for(int index = 0; index < rowNum; index++){
          rowHeaderValues.add(index+1);
          rowHeaderValuesDisplay.add('show row $index');
        }
      }
      switch (columnConfig!['axis_type']) {
        case 'number':
          //TO-DO
          break;
        default: //None
        for(int index = 0; index < columnNum; index++){
          columnHeaderValues.add(index+1);
          columnHeaderValuesDisplay.add('show col $index');
        }
      }
      setNestedProperty(obj: widget.value['input_header_data'], path: [internal_name, 'axis_row'], value: rowHeaderValues);
      setNestedProperty(obj: widget.value['input_header_data'], path: [internal_name, 'rowNum'], value: rowNum);
      setNestedProperty(obj: widget.value['input_header_data'], path: [internal_name, 'axis_column'], value: columnHeaderValues);
      setNestedProperty(obj: widget.value['input_header_data'], path: [internal_name, 'columnNum'], value: columnNum);
    }
    updateHeaderData(rowHeaderValues, rowNum, columnHeaderValues, columnNum);

    const double deleteButtonSize = 18;

    return SizedBox(
      width: cell_width * columnNum + header_width + deleteButtonSize,
      height: cell_height * rowNum  + header_height + deleteButtonSize,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // top-left cell
                Container(
                  width: header_width,
                  height: header_height,
                  alignment: Alignment.center,
                  child: AutoSizeText(display_text!, maxFontSize: 12, minFontSize: 5,)
                ),
                //Header row
                ...List.generate(columnNum, (colIndex) {
                  return Container(
                    width: cell_width,
                    height: header_height,
                    alignment: Alignment.center,
                    child: AutoSizeText(columnHeaderValuesDisplay[colIndex], maxFontSize: 12, minFontSize: 5,),
                  );
                }),
                // Delete Col Button
                ElmIconButton(
                  enabled: columnNum > columnMinSize,
                  iconSize: 15,
                  iconData: Icons.remove,
                  iconColor: const Color.fromARGB(255, 40, 0, 0), 
                  backgroundColor: const Color.fromARGB(255, 255, 197, 203), 
                  buttonWidth: deleteButtonSize,
                  buttonHeight: header_height,
                  borderRadius: 3,
                  onPressFunctions: (){
                      columnNum = columnNum! - 1;
                      columnHeaderValues.length = columnNum!;
                      for (int rowIndex = 0; rowIndex < rowNum!; rowIndex++){
                        widget.value['variables'][internal_name][rowIndex].removeLast();
                        widget.uniqueValue['controller_data']['${internal_name}_${rowIndex}_${columnNum}'] = TextEditingController(text: "");
                      }
                      updateHeaderData(rowHeaderValues, rowNum!, columnHeaderValues, columnNum!);
                      ElmModuleList.updateAllModuleUI(appState: appState);
                  },
                ),
              ]
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Header Column
                Column(
                  children: List.generate(rowNum, (rowIndex) {
                    return Container(
                      width: header_width,
                      height: cell_height,
                      alignment: Alignment.center,
                      child: AutoSizeText(rowHeaderValuesDisplay[rowIndex], maxFontSize: 12, minFontSize: 5,),
                    );
                  }),
                ),
                SizedBox(
                  width: cell_width * columnNum,
                  height: cell_height * rowNum,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnNum!,
                      childAspectRatio: cell_width!/cell_height!,
                    ),
                    itemCount: rowNum * columnNum!,
                    itemBuilder: (context, index) {
                      final row = index ~/ columnNum!;
                      final column = index % columnNum!;
                      //Add a border here (and remove the one from text). This border can't change size and has to look nice
                      return Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(25, 0, 98, 255),
                          border: Border.all(
                            color: Color.fromARGB(255, 86, 125, 188), 
                            width: 0.5,
                            strokeAlign: BorderSide.strokeAlignCenter
                          ),
                        ),
                        //Child = Each individual cell that takes in an input
                        child: createWidgetFromConfig(
                          //======================== ITEM IN EACH CELL IS SET HERE ===================
                          //Each Internal Name: oldname_row_col
                          //Each path: ['internal_name'][row][column]
                          internal_name: '${internal_name}_${row}_${column}',
                          configInput: itemConfig!, 
                          widget: widget, 
                          appState: appState, 
                          listItemDetails: {
                            'cell_width': cell_width,
                            'cell_height': cell_height
                          },
                          //...['name'][0][0]
                          path: [internal_name, row, column]
                        )
                      );
                    },
                  ),
                ),
                //Add col button
                ElmIconButton(
                  enabled: columnNum! < columnMaxSize,
                  iconSize: 15,
                  iconData: Icons.add,
                  iconColor: const Color.fromARGB(255, 0, 40, 7), 
                  backgroundColor: const Color.fromARGB(255, 197, 255, 215), 
                  buttonWidth: deleteButtonSize,
                  buttonHeight: cell_height * rowNum,
                  borderRadius: 3,
                  onPressFunctions: (){
                      columnNum = columnNum! + 1;
                      widget.value['input_header_data'][internal_name]['columnNum'] = columnNum!;
                      for(int rowIndex = 0; rowIndex < rowNum!; rowIndex++){
                        widget.value['variables'][internal_name][rowIndex].add(null);
                      }
                      updateHeaderData(rowHeaderValues, rowNum!, columnHeaderValues, columnNum!);
                      ElmModuleList.updateAllModuleUI(appState: appState);
                  },
                ),
              ],
            ),
            Container(
              width: cell_width * columnNum + header_width,
              height: deleteButtonSize,
              child: Row(
                children: [
                  //Delete row button
                  ElmIconButton(
                    enabled: rowNum > rowMinSize,
                    iconSize: 15,
                    iconData: Icons.remove,
                    iconColor: const Color.fromARGB(255, 40, 0, 0), 
                    backgroundColor: const Color.fromARGB(255, 255, 197, 203), 
                    buttonWidth: header_width,
                    buttonHeight: deleteButtonSize,
                    borderRadius: 3,
                    onPressFunctions: (){
                      rowNum = rowNum! - 1;
                      rowHeaderValues.length = rowNum!;
                      widget.value['variables'][internal_name].removeLast();
                      for (int columnIndex = 0; columnIndex < columnNum!; columnIndex++){
                        widget.uniqueValue['controller_data']['${internal_name}_${rowNum}_${columnIndex}'] = TextEditingController(text: "");
                      }
                      updateHeaderData(rowHeaderValues, rowNum!, columnHeaderValues, columnNum!);
                      ElmModuleList.updateAllModuleUI(appState: appState);
                    },
                  ),
                  //Keeps position the same if delete row button is hidden
                  Offstage(
                    offstage: rowNum! > rowMinSize,
                    child: SizedBox(
                      width: header_width,
                      height: deleteButtonSize,
                    )
                  ),
                  //Add row button
                  ElmIconButton(
                    enabled: rowNum! < rowMaxSize,
                    iconSize: 15,
                    iconData: Icons.add,
                    iconColor: const Color.fromARGB(255, 0, 40, 7), 
                    backgroundColor: Color.fromARGB(255, 197, 255, 215), 
                    buttonWidth: cell_width * columnNum,
                    buttonHeight: deleteButtonSize,
                    borderRadius: 3,
                    onPressFunctions: (){
                      rowNum = rowNum! + 1;
                      widget.value['input_header_data'][internal_name]['rowNum'] = rowNum!;
                      widget.value['variables'][internal_name].add(List<dynamic>.generate(columnNum!, (index) => null));
                      updateHeaderData(rowHeaderValues, rowNum!, columnHeaderValues, columnNum!);
                      ElmModuleList.updateAllModuleUI(appState: appState);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  final List path;
  String? display_text;

  NoInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.path,
    required this.display_text,
  }){
    display_text = variableCheckString(input: display_text!, widget: widget);
  }

  @override
  Widget build(BuildContext context) {
    return Text('${display_text}');
  }
}

class AliasesInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  final List path;
  String? display_text;

  AliasesInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.path,
    required this.display_text,
  }){
    display_text ??= "Aliases";
    display_text = variableCheckString(input: display_text, widget: widget);
  }

  @override
  Widget build(BuildContext context) {
    //If null controller data, set to internal data text (or empty if null)
    widget.uniqueValue['controller_data']['aliases'] ??= widget.value['input_data']['aliases'] == null ? TextEditingController(text: '') : TextEditingController(text: widget.value['input_data']['aliases']);
    //If null internal data or null variable, set to default aliases
    if(widget.value['input_data']['aliases'] == null || widget.value['variables']['aliases'] == null){
      widget.value['variables']['aliases'] = widget.value['variables']['default_aliases'];
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text!),
        SizedBox(
          width: 150,
          height: 25,
          child: Focus(
            onFocusChange: (isFocused) {
              if (!isFocused){
                ElmModuleList.updateAllModuleUI(appState: appState);
              }
            },
            child: AutoSizeTextField(
              textAlignVertical: TextAlignVertical.bottom,
              textAlign: TextAlign.center,
              minFontSize: 8,
              maxLines: 3,
              maxLength: 100,
              key: Key('${widget.key} aliases'),
              controller: widget.uniqueValue['controller_data']['aliases'],
              onChanged: (inputValue) {
                widget.value['input_data']['aliases'] = inputValue;
                if(inputValue == ''){
                  widget.value['variables']['aliases'] = widget.value['variables']['default_aliases'];
                } else {
                  widget.value['variables']['aliases'] = inputValue;
                }
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                counterText: '',
                border: UnderlineInputBorder(),
                constraints: BoxConstraints(minWidth: 150, maxWidth: 150),
                isDense: true,
                isCollapsed: true,
                hintText: widget.value['variables']['default_aliases'],
              ),
            ),
          ),
        )
      ],
    );
  }
}


class TextInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  final List path;
  final Map<String, dynamic> listItemDetails;
  String? display_text;
  String? default_text;

  TextInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.path,
    required this.listItemDetails,
    required this.display_text,
    required this.default_text,
  }){
    display_text = variableCheckString(input: display_text, widget: widget);
    default_text = variableCheckString(input: default_text, widget: widget);
  }

  @override
  Widget build(BuildContext context) {
    
    //If null controller data, set to internal data text (or empty if null)
    widget.uniqueValue['controller_data'][internal_name] ??= 
    TextEditingController(
        text: getNestedProperty(obj: widget.value['input_data'], path: path) ?? ''
    );
    //If null variables but NOT null input data, set variable to internal name, or default if blank
    dynamic inputData = getNestedProperty(obj: widget.value['input_data'], path: path);
    if(
      inputData != null 
      && getNestedProperty(obj: widget.value['variables'], path: path) == null
    ){
      if(inputData == ""){
        setNestedProperty(obj: widget.value['variables'], path: path, value: default_text);
      } else {
        setNestedProperty(obj: widget.value['variables'], path: path, value: inputData);
      }
    }

    //If null input data or null variables, set variable to default and input data to blank
    //(Input data set is only necessary for lists)
    if(
      getNestedProperty(obj: widget.value['input_data'], path: path) == null 
      ||getNestedProperty(obj: widget.value['variables'], path: path) == null 
    ){
      setNestedProperty(obj: widget.value['variables'], path: path, value: default_text);
      setNestedProperty(obj: widget.value['input_data'], path: path, value: '');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text!),
        SizedBox(
          //Width, height, minFontSize, maxLine and maxlength carefully chosen to prevent freeze
          width: listItemDetails['cell_width'] != null ? listItemDetails['cell_width'] - 2 : 150,
          height: listItemDetails['cell_height'] != null ? listItemDetails['cell_height'] - 2 : 25,
          child: Focus(
            onFocusChange: (isFocused) {
              if (!isFocused){
                ElmModuleList.updateAllModuleUI(appState: appState);
              }
            },
            child: AutoSizeTextField(
              textAlignVertical: TextAlignVertical.bottom,
              textAlign: TextAlign.center,
              minFontSize: 8,
              maxLines: 3,
              maxLength: 100,
              key: Key('${widget.key} ${internal_name}'),
              controller: widget.uniqueValue['controller_data'][internal_name],
              onChanged: (inputValue) {
                setNestedProperty(obj: widget.value['input_data'], path: path, value: inputValue);
                if(inputValue == ''){
                  setNestedProperty(obj: widget.value['variables'], path: path, value: default_text);
                } else {
                  setNestedProperty(obj: widget.value['variables'], path: path, value: inputValue);
                }
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                counterText: '',
                border: listItemDetails['cell_width'] == null ? UnderlineInputBorder() : InputBorder.none,
                constraints: BoxConstraints(minWidth: 150, maxWidth: 150),
                isDense: true,
                isCollapsed: true,
                hintText: default_text,
              ),
            ),
          ),
        )
      ],
    );
  }
}


class CodeInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  final List path;
  final Map<String, dynamic> listItemDetails;
  String? display_text;
  Map<dynamic, dynamic>? default_object;

  CodeInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.path,
    required this.listItemDetails,
    required this.display_text,
    required this.default_object,
  }){
    display_text = variableCheckString(input: display_text, widget: widget);
    default_object ??= {};
    default_object = variableCheckDynamic(input: default_object, widget: widget);
  }

  @override
  Widget build(BuildContext context) {

    double _width = listItemDetails['cell_width'] != null ? listItemDetails['cell_width'] - 2 : 150;
    double _height = listItemDetails['cell_height'] != null ? listItemDetails['cell_height'] - 2 : 25;
    int _expectedLength = (_width * _height / 200).round();

    //If imported event doesn't have data, input_data would have been set as a string.
    //Turn it into a map!
    dynamic inputDataTest = getNestedProperty(obj: widget.value['input_data'], path: path);
    if(inputDataTest is String){
      inputDataTest = convertStringToMap(inputDataTest);
      if (inputDataTest is Map<dynamic, dynamic>){
        setNestedProperty(obj: widget.value['input_data'], path: path, value: inputDataTest);
      } else {
        setNestedProperty(obj: widget.value['input_data'], path: path, value: null);
      }
    }

    //If null variables but NOT null input data, set variable to internal name, or default if blank
    Map<dynamic, dynamic>? inputData = getNestedProperty(obj: widget.value['input_data'], path: path);
    if(
      inputData != null 
      && getNestedProperty(obj: widget.value['variables'], path: path) == null
    ){
      if(inputData == ""){
        setNestedProperty(obj: widget.value['variables'], path: path, value: default_object);
      } else {
        setNestedProperty(obj: widget.value['variables'], path: path, value: inputData);
      }
    }

    //If null input data or null variables, set variable to default and input data to blank
    //(Input data set is only necessary for lists)
    if(
      getNestedProperty(obj: widget.value['input_data'], path: path) == null 
      ||getNestedProperty(obj: widget.value['variables'], path: path) == null 
    ){
      setNestedProperty(obj: widget.value['variables'], path: path, value: default_object);
      setNestedProperty(obj: widget.value['input_data'], path: path, value: {});
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text!),
        SizedBox(
          //Width, height, minFontSize, maxLine and maxlength carefully chosen to prevent freeze
          width: _width,
          height: _height,
          child: Focus(
            onFocusChange: (isFocused) {
              if (!isFocused){
                ElmModuleList.updateAllModuleUI(appState: appState);
              }
            },
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 244, 200, 255),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                side: BorderSide(
                  color: Color.fromARGB(78, 10, 53, 117), // Dark blue outline color
                  width: 1, // Outline thickness
                ),
              ),
              onPressed: (){
                Get.dialog(
                  ElmCodeEditor(appState: appState, display_text: display_text!, widget: widget, internal_name: internal_name, path: path, default_object: default_object!),
                );
              }, 
              child: AutoSizeText(
                //This stupid long line takes in the first few _expectedLength characters (or less if there isn't _expectedLength) and adds "..." at the back. If empty, puts "Empty".
                getNestedProperty(obj: widget.value['input_data'], path: path) == {} ?
                  (default_object!.length < _expectedLength ? default_object.toString() : '${default_object.toString().substring(0, _expectedLength)}...')

                  : getNestedProperty(obj: widget.value['input_data'], path: path).toString().length < _expectedLength ? 
                      getNestedProperty(obj: widget.value['input_data'], path: path).toString() :
                      '${getNestedProperty(obj: widget.value['input_data'], path: path).toString().substring(0, _expectedLength)}...',
                textAlign: TextAlign.center,
                minFontSize: 8,
                maxLines: 3,
              )
            )
          ),
        )
      ],
    );
  }
}

class ElmCodeEditor extends StatefulWidget {

  final ElmModuleList widget;
  final String internal_name;
  final List path;
  final Map<dynamic, dynamic> default_object;
  String display_text;
  final GenericProviderState appState;

  ElmCodeEditor({
    super.key,
    required this.widget,
    required this.internal_name,
    required this.path,
    required this.default_object,
    required this.appState,
    required this.display_text,
  }){
    if(display_text == ""){
      display_text = "Edit Code";
    }
  }

  @override
  State<ElmCodeEditor> createState() => _ElmCodeEditorState();
}

class _ElmCodeEditorState extends State<ElmCodeEditor> {

  bool firstOpen = false;

  @override
  void initState(){
    super.initState;
    firstOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_){
      Get.rawSnackbar(
        padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
        backgroundColor: const Color.fromARGB(255, 175, 214, 249),
        duration: Duration(milliseconds: 5000),
        animationDuration: Duration(milliseconds: 300),
        messageText: AutoSizeText('util_module_code_message_waitwarn'.tr,
          maxFontSize: 14,
          minFontSize: 5,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      );
    });
  }

  void dispose(){
    super.dispose();
    try {
      Get.closeAllSnackbars();
    } catch (e) {}
  }

  Widget build(BuildContext context) {
    return Scaffold(
      key: UniqueKey(),
      backgroundColor: const Color.fromARGB(255, 225, 242, 255),
      appBar: AppBar(
        toolbarHeight: 50,
        title: Text(widget.display_text),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          Row(
            children: [
              ElmIconButton(iconData: Icons.delete, iconColor: widget.appState.themeColour, buttonHeight: 30, onPressFunctions: (){
                setState(() {
                  setNestedProperty(obj: widget.widget.value['input_data'], path: widget.path, value: {});
                  ElmModuleList.updateAllModuleUI(appState: widget.appState);
                });
              }),
              Offstage(
                offstage: widget.default_object.isEmpty,
                child: SizedBox(
                  width: 135,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size.fromHeight(25),
                      minimumSize: Size.fromHeight(25),
                      maximumSize: Size.fromHeight(25),
                      padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                    ),
                    onPressed: () {
                      setState(() {
                        setNestedProperty(obj: widget.widget.value['input_data'], path: widget.path, value: widget.default_object);
                        ElmModuleList.updateAllModuleUI(appState: widget.appState);
                      });
                    },
                    child: Row(children: [Icon(Icons.restart_alt, color: widget.appState.themeColour), AutoSizeText('util_module_code_message_setdefault'.tr)])
                  ),
                ),
              ),
            ],
          ),],
      ),
      body: JsonEditorTheme(
        themeData: JsonEditorThemeData.defaultTheme(),
        child: JsonEditor.object(
          openDebug: false,
          object: getNestedProperty(obj: widget.widget.value['input_data'], path: widget.path) as Map<dynamic, dynamic>,
          onValueChanged: (inputValue) {
            if (inputValue.toObject() is Map<dynamic, dynamic>) {
              setNestedProperty(obj: widget.widget.value['input_data'], path: widget.path, value: inputValue.toObject());
              if(inputValue.toJson().isEmpty){
                setNestedProperty(obj: widget.widget.value['variables'], path: widget.path, value: widget.default_object);
              } else {
                setNestedProperty(obj: widget.widget.value['variables'], path: widget.path, value: inputValue.toObject());
              }
              WidgetsBinding.instance.addPostFrameCallback((_){
                ElmModuleList.updateAllModuleUI(appState: widget.appState);
                if (firstOpen == false) {
                  Get.closeAllSnackbars();
                  Get.rawSnackbar(
                    padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                    backgroundColor: const Color.fromARGB(255, 175, 214, 249),
                    duration: Duration(milliseconds: 2000),
                    animationDuration: Duration(milliseconds: 300),
                    messageText: AutoSizeText('util_module_code_message_saved'.tr,
                      maxLines: 1,
                      maxFontSize: 14,
                      minFontSize: 5,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  );
                } else {
                  firstOpen = false;
                }
              });
            } else {
              if (firstOpen == false) {
                Get.closeAllSnackbars();
                Get.rawSnackbar(
                  padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                  backgroundColor: const Color.fromARGB(255, 175, 214, 249),
                  duration: Duration(milliseconds: 5000),
                  animationDuration: Duration(milliseconds: 300),
                  messageText: AutoSizeText('util_module_code_message_notmap'.tr,
                    maxFontSize: 14,
                    minFontSize: 5,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                );
              } else {
                firstOpen = false;
              }
            }
          },
        ),
      ),
    );
  }
}


///
/// Tween used for ELM Modules
///
dynamic elmSizeTween({required animation}) {
  return CurvedAnimation(
    parent: animation, // Use the provided animation
    curve: Curves.linear, // Apply an ease-out curve
  );
}

///
/// Single Module - Button List
///
class ElmModuleButtonList<T extends GenericProviderState> extends StatelessWidget {
  const ElmModuleButtonList({
    super.key,
    required this.appGenericState,
    required this.widget,
    required this.isVertical,
  });

  final T appGenericState;
  final ElmModuleList widget;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //Minimise
        ElmIconButton(iconData: Icons.remove_red_eye_outlined, iconColor: appGenericState.themeColour, buttonWidth: 35, enabled: appGenericState.enabledButtons['minimise'],
          onPressFunctions: () {
            widget.value['internal_data']['minimised'] = !widget.value['internal_data']['minimised'];
            ElmModuleList.updateAllModuleUI(appState: appGenericState);
          }
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
            ElmModuleList.updateAllModuleUI(
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
            ElmModuleList.updateAllModuleUI(
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
              deepCopyValue: true,
            );
            ElmModuleList.updateAllModuleUI(
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
            ElmModuleList.updateAllModuleUI(
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
            ElmModuleList.updateAllModuleUI(
              appState: appGenericState,
            );
          }
        ),
        //Extra Menu. Contains all disabled buttons.
        ElmIconButton(iconData: Icons.more_horiz, iconColor: appGenericState.themeColour, enabled: appGenericState.enabledButtons['extra'],
          onPressFunctions:(){
            Get.defaultDialog(title: 'util_moreactions'.tr, middleTextStyle: TextStyle(fontSize: 0), textCancel: 'Cancel'.tr, 
              actions: [
                //Minimise
                ElmIconButton(iconData: Icons.remove_red_eye_outlined, iconColor: appGenericState.themeColour, buttonWidth: 50, buttonHeight: 30, enabled: false == appGenericState.enabledButtons['minimise'],
                  onPressFunctions: () {
                    widget.value['internal_data']['minimised'] = !widget.value['internal_data']['minimised'];
                    ElmModuleList.updateAllModuleUI(appState: appGenericState);
                    Get.back();
                  }
                ),
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
                    ElmModuleList.updateAllModuleUI(
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
                    ElmModuleList.updateAllModuleUI(
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
                      deepCopyValue: true,
                    );
                    ElmModuleList.updateAllModuleUI(
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
                    ElmModuleList.updateAllModuleUI(
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
                    ElmModuleList.updateAllModuleUI(
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
    );
  }
}

///
/// The Module List
///
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.updateModuleState(); //Update the module code in main! ONCE!
    });

    if(appState.isImportingModules){
      appState.isImportingModules = false;
      ElmModuleList.correctAnimatedModuleListSize(appState: appState, context: context);
    }


    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        title: Text(title),
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
              ElmModuleList.addModuleBelow(moduleIndex: -1, newValue: null, appState: appState);
            },
            child: Row(children: [Icon(Icons.add, color: appState.themeColour,), Text(addModuleText, selectionColor: appState.themeColour,)])
          ),
          ElmIconButton(iconData: Icons.undo, iconColor: appState.themeColour, onPressFunctions: (){
            if (allowUpdateUndoStack){
              allowUpdateUndoStack = false;
              appUndoStack.undo();
              appUndoStackDelayedEnable();
            }
          }),
          ElmIconButton(iconData: Icons.redo, iconColor: appState.themeColour, onPressFunctions: (){
            if (allowUpdateUndoStack){
              allowUpdateUndoStack = false;
              appUndoStack.redo();
              appUndoStackDelayedEnable();
            }
          }),
        ],
      ),
      body: AnimatedList(
        padding: appState.isVertical ? EdgeInsets.fromLTRB(0, 0, 0, 200) : EdgeInsets.fromLTRB(0, 0, 50, 0), //Extra padding is to allow scrolling past the end
        clipBehavior: Clip.none,
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
                key: appState.elmModuleListArr[index].key,
                moduleIndex: index,
                uniqueValue: appState.elmModuleListArr[index].uniqueValue,
                value: appState.elmModuleListArr[index].value,
              ),
            ),
          );
        },
      ),
    );
  }
}
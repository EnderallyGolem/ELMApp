import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; 
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';

import 'main.dart';
import 'util_functions.dart';

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
  dynamic uniqueValue; //NOT copied when copy-pasted. TextControllers for example
  Key? key;

  ElmModuleList({required this.moduleIndex, this.value = null, this.uniqueValue, this.key = null}) {
    //Sets a value if null
    key ??= UniqueKey();
    value ??= {
      'module_dropdown_list': {
        'dropdown_module_display_text': 'util_default_module_dropdown'.tr,
        'dropdown_module_internal_name': 'Empty',
        'dropdown_image': Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20),
      },
      'internal_data': {
        'firstUpdate': true,
      }, //Stored what you type. What you type is not necessarily variables (empty => variable is default value instead of internal data)
      'variables': {
        'select_module_message': 'util_default_module_message'.tr,
        'default_aliases': '',
        'event_number': moduleIndex + 1,
      }
    };
    uniqueValue ??= {
      'controller_data': {},
    };
    //Update values on rebuild
    value['variables']['event_number'] = moduleIndex + 1;
    value['variables']['default_aliases'] = '${value['module_dropdown_list']['dropdown_module_internal_name']}_${value['variables']['event_number']}';

    debugPrint('Building ElmModuleList element: Index ${moduleIndex} ${key}');
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
    return ElmSingleModuleMainWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical);
  }
}

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

  final ElmModuleList<T> widget;
  final T appGenericState;
  final bool isVertical;



  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 170,
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: Row(
                    children: [
                      widget.value['module_dropdown_list']['dropdown_image'],
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
                  items: ProviderMainState.global["modulesEventJsonEnabled"].entries.map<DropdownMenuItem<String>>((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: FittedBox(
                      child: Row(
                        children: [
                          entry.value['Image'],
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
                    if(ProviderMainState.global["modulesEventJson"][value] == null){
                      widget.value['module_dropdown_list']['dropdown_module_display_text'] = value;
                    } else {
                      widget.value['module_dropdown_list']['dropdown_module_display_text'] = ProviderMainState.global["modulesEventJson"][value]!["display_text"];
                      widget.value['module_dropdown_list']['dropdown_image'] = ProviderMainState.global["modulesEventJson"][value]!["Image"];
                    }
                    debugPrint('Set to ${widget.value['module_dropdown_list']['dropdown_module_internal_name']}');
                    ElmModuleList.updateAllModule(appState: appGenericState);
                    widget.value['internal_data']['firstUpdate'] = true;
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
  final ElmModuleList<T> widget;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 300, maxHeight: 200),
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
        margin: const EdgeInsets.all(5),
        height: 200,
        child: ElmDynamicModuleForm(appState: appGenericState, widget: widget, config: ProviderMainState.global['modulesEventJson']['${widget.value['module_dropdown_list']['dropdown_module_internal_name']}']),
      ),
    );
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

    //If module is just changed, it isn't updated properly. Update it once more!
    if(widget.value['internal_data']['firstUpdate']){
      widget.value['internal_data']['firstUpdate'] = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ElmModuleList.updateAllModule(appState: appState);
      });
    }

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
    debugPrint('loopMaxNum = ${loopMaxNum}');
    
    //Run code for each variable
    config['variables'] ??= {};
    config['variables'].forEach((internal_name, value) {
      if (!internal_name.startsWith('#')) {
        updateVariablesFromConfig(internal_name: internal_name, config: value, widget: widget, appState: appState);
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
        formWidgets.add(createWidgetFromConfig(internal_name: internal_name, config: value, widget: widget, appState: appState));
      }
    });
  }
}

void updateVariablesFromConfig({required String internal_name, required Map<String, dynamic> config, required ElmModuleList widget, required GenericProviderState appState}){
  debugPrint('Creating variable with data: $config');
  switch (config['type']) {
    case 'text_concatenate':
      variableTextConcatenate(
        internal_name: internal_name, 
        config: config, 
        widget: widget, 
        appState: appState,
        text_array: config['text_array'],
        text_seperator: config['text_seperator'],
      );
      break;
    case 'number_offset':
      //
      break;
    case 'checkbox_chooser':
      //
      break;
    default:
      debugPrint('Type is unknown');
      break;
  }
}

///
/// Checks if [input] starts with a !, and if it does, returns the variable's value.
/// Otherwise, returns itself.
/// 
/// If [input] is null, return empty string
///
dynamic variableCheckString({required String? input, required ElmModuleList widget, required String internal_name}){
  input ??= "";
  dynamic returnValue;
  if(input.startsWith('!')){
    returnValue = widget.value['variables'][input.substring(1)];
  } else {
    returnValue = input;
  }
  returnValue ??= "";
  return returnValue;
}

///
/// variableCheckString except it checks all values in a nested list/map.
/// 
/// If [input] is null, return empty string
///
dynamic variableCheckDynamic({required dynamic input, required ElmModuleList widget, required String internal_name}){
  input ??= '';
  dynamic inputClone = deepCopy(input);
  iterateAndModifyNested(
    nestedItem: inputClone,
    function: (key, value) {
      return variableCheckString(input: value, widget: widget, internal_name: internal_name);
    }
  );
  inputClone ??= "";
  return inputClone;
}

void variableTextConcatenate({
  required String internal_name, 
  required Map<String, dynamic> config, 
  required ElmModuleList widget, 
  required GenericProviderState appState,
  required List? text_array,
  required String? text_seperator,
}){
  text_array = variableCheckDynamic(input: text_array, widget: widget, internal_name: internal_name);
  text_seperator = variableCheckString(input: text_seperator, widget: widget, internal_name: internal_name);

  widget.value['variables'][internal_name] = text_array!.join(text_seperator!);
  debugPrint('${internal_name}: ${widget.value['variables'][internal_name]}');
}

Widget createWidgetFromConfig({required String internal_name, required Map<String, dynamic> config, required ElmModuleList widget, required GenericProviderState appState}) {
  debugPrint('Creating widget with data: $config');
  switch (config['type']) {
    case 'none':
      return NoInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: config['display_text'],
      );
    case 'aliases':
      return AliasesInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: config['display_text'],
      );
    case 'text':
      return TextInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: config['display_text'],
        default_text: config['default_text'],
      );
    case 'number':
      return NumberInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: config['display_text'],
        integer: config['integer'],
        range: config['range'],
      );
    case 'list':
      return ListInputWidget(
        appState: appState,
        widget: widget,
        internal_name: internal_name,
        display_text: config['display_text'],
        itemConfig: config['item'],
        rowConfig: config['axis_row'],
        colConfig: config['axis_col'],
      );
    default:
      debugPrint('Type is unknown');
      return SizedBox.shrink();
  }
}

class NoInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  String? display_text;

  NoInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
  }){
    display_text = variableCheckString(input: display_text!, widget: widget, internal_name: internal_name);
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
  String? display_text;

  AliasesInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
  }){
    display_text ??= "Aliases";
    display_text = variableCheckString(input: display_text, widget: widget, internal_name: internal_name);
  }

  @override
  Widget build(BuildContext context) {
    widget.uniqueValue['controller_data'][internal_name] ??= widget.value['internal_data'][internal_name] == null ? TextEditingController(text: '') : TextEditingController(text: widget.value['internal_data'][internal_name]);
    widget.value['variables'][internal_name] ??= widget.value['variables']['default_aliases'];
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
              ElmModuleList.updateAllModule(appState: appState);
            },
            child: AutoSizeTextField(
              textAlignVertical: TextAlignVertical.bottom,
              textAlign: TextAlign.center,
              minFontSize: 5,
              maxLines: 3,
              maxLength: 100,
              key: Key('${widget.key} ${internal_name}'),
              controller: widget.uniqueValue['controller_data'][internal_name],
              onChanged: (inputValue) {
                widget.value['internal_data'][internal_name] = inputValue;
                if(inputValue == ''){
                  widget.value['variables'][internal_name] = widget.value['variables']['default_aliases'];
                } else {
                  widget.value['variables'][internal_name] = inputValue;
                }
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                counterText: '',
                //border: OutlineInputBorder(),
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
  String? display_text;
  String? default_text;

  TextInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
    required this.default_text,
  }){
    display_text = variableCheckString(input: display_text, widget: widget, internal_name: internal_name);
    default_text = variableCheckString(input: default_text, widget: widget, internal_name: internal_name);
  }

  @override
  Widget build(BuildContext context) {
    widget.uniqueValue['controller_data'][internal_name] ??= widget.value['internal_data'][internal_name] == null ? TextEditingController(text: '') : TextEditingController(text: widget.value['internal_data'][internal_name]);
    widget.value['variables'][internal_name] ??= default_text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text!),
        SizedBox(
          //Width, height, minFontSize, maxLine and maxlength carefully chosen to prevent freeze
          width: 150,
          height: 25,
          child: Focus(
            onFocusChange: (isFocused) {
              ElmModuleList.updateAllModule(appState: appState);
            },
            child: AutoSizeTextField(
              textAlignVertical: TextAlignVertical.bottom,
              textAlign: TextAlign.center,
              minFontSize: 5,
              maxLines: 3,
              maxLength: 100,
              key: Key('${widget.key} ${internal_name}'),
              controller: widget.uniqueValue['controller_data']['${internal_name}'],
              onChanged: (inputValue) {
                widget.value['internal_data'][internal_name] = inputValue;
                if(inputValue == ''){
                  widget.value['variables'][internal_name] = default_text;
                } else {
                  widget.value['variables'][internal_name] = inputValue;
                }
                print(inputValue);
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                counterText: '',
                //border: OutlineInputBorder(),
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

class NumberInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String internal_name;
  String? display_text;
  bool? integer;
  String? range;

  NumberInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
    required this.integer,
    required this.range,
  }){
    display_text ??= "";
    integer ??= false;
    range ??= "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text!),
        TextField(
          keyboardType: integer! ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter a number ($range)',
          ),
        ),
      ],
    );
  }
}

class ListInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String display_text;
  final String internal_name;
  final Map<String, dynamic> itemConfig;
  final Map<String, dynamic> rowConfig;
  final Map<String, dynamic> colConfig;

  ListInputWidget({
    required this.appState,
    required this.widget,
    required this.internal_name,
    required this.display_text,
    required this.itemConfig,
    required this.rowConfig,
    required this.colConfig,
  });

  @override
  Widget build(BuildContext context) {
    List<String> rows = rowConfig['values'].keys.toList();
    int colSize = int.tryParse(colConfig['size'].split('..').last) ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(display_text),
        Table(
          children: [
            TableRow(
              children: List.generate(colSize, (index) {
                return TextField(
                  decoration: InputDecoration(
                    hintText: itemConfig['display_text'],
                  ),
                );
              }),
            ),
          ],
        ),
      ],
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
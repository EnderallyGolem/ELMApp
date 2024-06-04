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
  late String moduleJsonFileName;

  void dispose();
  void updateModuleState();
  void updateModuleUI();
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
      //Entirely for the dropdown list selecting which module is used
      'module_dropdown_list': {
        'dropdown_module_display_text': 'util_default_module_dropdown'.tr,
        'dropdown_module_internal_name': 'Empty',
        'dropdown_image': Image.asset('assets/icon/moduleassets/misc_empty.png', height: 20, width: 20),
      },
      //Stored internal values. Things you type should be stored here.
      'internal_data': {
        'minimised': false,
        'objects': [],
        'levelModules': [],
        'waveModules': [],
      }, 
      //Stored values that are actually used. If you typed nothing, this can be different from internal_data (uses default value instead)
      'variables': {
        'select_module_message': 'util_default_module_message'.tr,
        'aliases': null,
        'default_aliases': '',
        'event_number': moduleIndex + 1,

        //Lists should be stored like that
        //Run a check to see if it's a map when reading values
        //If it's a map, for variables run for every item
        //If not, it's a single value and proceed as per normal
        'example_list': [
          ['r1c1', 'r1c2', 'r1c3'],
          ['r2c1', 'r2c2', 'r2c3'],
          ['r3c1', 'r3c2', 'r3c3']
        ]
      }
    };
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if(appGenericState.updateCode){
        appGenericState.updateModuleUI(); //Update UI the first time it is loaded. Such a dumb workaround...
        appGenericState.updateCode = false;
      }
    });

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            //Dropdown Button
            SizedBox(
              width: 170,
              height: 30,
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
                  items: ProviderMainState.global["moduleJsons"]["${appGenericState.moduleJsonFileName}_enabled"].entries.map<DropdownMenuItem<String>>((entry) {
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
        margin: const EdgeInsets.all(5),
        height: 200,
        child: ElmDynamicModuleForm(appState: appGenericState, widget: widget, config: ProviderMainState.global["moduleJsons"][appGenericState.moduleJsonFileName]['${widget.value['module_dropdown_list']['dropdown_module_internal_name']}'])
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
    if(widget.uniqueValue['internal_data']['firstUpdate']){
      widget.uniqueValue['internal_data']['firstUpdate'] = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ElmModuleList.updateAllModuleUI(appState: appState);
      });
    }

    //Update level code and export to main
    print('DO THE EXPORTING SUTFFF');
    print(config['raw_code']);
    widget.value['internal_data']['objects'] = variableCheckDynamic(input: config['raw_code'], widget: widget);
    print(widget.value['internal_data']['objects']);
    widget.value['internal_data']['levelModules'] = variableCheckDynamic(input: config['level_modules'], widget: widget);
    widget.value['internal_data']['waveModules'] = variableCheckDynamic(input: config['wave_modules'], widget: widget);
    appState.updateModuleState(); //Update the module code in main! ONCE!

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

///
/// Checks if [input] starts with a !, and if it does, returns the variable's value.
/// Otherwise, returns itself.
/// 
/// If [input] is null, return empty string
///
dynamic variableCheckString({required dynamic input, required ElmModuleList widget}){
  input ??= "";
  if(!(input is String)){
    return input; //If not string (if number maybe) then just immediately return that
  };
  dynamic returnValue;
  if (input.startsWith('!')){
    returnValue = widget.value['variables'][input.substring(1)];
    print('Input: $input');
    print('NotInput: ${widget.value['variables']}');
    print('NotInput: ${widget.value['variables']['L_textList']}');
    print('ReturnVal: $returnValue');
  } else {
    returnValue = input;
  }
  returnValue ??= "";
  return returnValue;
}

///
/// variableCheckString except it checks all values in a nested list/map.
/// 
/// Checks if each value in [input] starts with a !, and if it does, turns into the variable's value.
/// Otherwise, keep unchanged.
/// If null, will become an empty string.
/// 
/// The new (deep-cloned) nested list/map is returned.
///
dynamic variableCheckDynamic({required dynamic input, required ElmModuleList widget}){
  input ??= '';
  dynamic inputClone = deepCopy(input);
  iterateAndModifyNested(
    nestedItem: inputClone,
    function: (key, value) {
      return variableCheckString(input: value, widget: widget);
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
        colConfig: configInput['axis_col'],
      );
    default:
      return SizedBox.shrink();
  }
}

class ListInputWidget<T extends GenericProviderState> extends StatelessWidget {
  final T appState;
  final ElmModuleList<T> widget;
  final String display_text;
  final String internal_name;
  dynamic cell_width;  //Can be either int or double. Urggh.
  dynamic cell_height; //Can be either int or double. Eeurgh.
  dynamic header_width;  //Can be either int or double. Nnngghh.
  dynamic header_height; //Can be either int or double. Rawrrgh.

  Map<String, dynamic>? itemConfig;
  Map<String, dynamic>? rowConfig;
  Map<String, dynamic>? colConfig;

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
    required this.colConfig,
  }){
    cell_width ??= 100;
    cell_width = cell_width.toDouble();
    cell_height ??= 25;
    cell_height = cell_height.toDouble();
    header_width ??= 50;
    header_width = header_width.toDouble();
    header_height ??= 25;
    header_height = header_height.toDouble();

    itemConfig ??= {"type": "text"};
    rowConfig ??= {"axis_type": "none", "size": "1"};
    colConfig ??= {"axis_type": "none", "size": "1"};
  }

  @override
  Widget build(BuildContext context) {

    int columnNum = 3;
    int rowNum = 3;

    return SizedBox(
      width: cell_width * columnNum + header_width,
      height: cell_height * rowNum  + header_height,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Empty top-left cell
                SizedBox(
                  width: header_width,
                  height: header_height
                ),
                //Header row
                ...List.generate(columnNum, (colIndex) {
                  return Container(
                    width: cell_width,
                    height: header_height,
                    alignment: Alignment.center,
                    child: Text('Col $colIndex'),
                  );
                }),
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
                      child: Text('Row $rowIndex'),
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
                      crossAxisCount: columnNum,
                      childAspectRatio: cell_width!/cell_height!,
                    ),
                    itemCount: rowNum * columnNum,
                    itemBuilder: (context, index) {
                      final row = index ~/ columnNum;
                      final column = index % columnNum;
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
                        child: createWidgetFromConfig(
                          //Each Internal Name: oldname_col_row
                          //Each path: internal_name > col > row
                          internal_name: '${internal_name}_${row}_${column}',
                          configInput: itemConfig!, 
                          widget: widget, 
                          appState: appState, 
                          listItemDetails: {
                            'cell_width': cell_width,
                            'cell_height': cell_height
                          },
                          path: [internal_name, row, column]
                        )
                      );
                    },
                  ),
                ),
              ],
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
    widget.uniqueValue['controller_data']['aliases'] ??= widget.value['internal_data']['aliases'] == null ? TextEditingController(text: '') : TextEditingController(text: widget.value['internal_data']['aliases']);
    //If null internal data or null variable, set to default aliases
    if(widget.value['internal_data']['aliases'] == null || widget.value['variables']['aliases'] == null){
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
              ElmModuleList.updateAllModuleUI(appState: appState);
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
                widget.value['internal_data']['aliases'] = inputValue;
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
        text: getNestedProperty(obj: widget.value['internal_data'], path: path) ?? ''
    );
    //If null internal data or null variables, set variable to default and internal data to blank
    //(Internal data set is only necessary for lists)
    if(
      getNestedProperty(obj: widget.value['internal_data'], path: path) == null 
      ||getNestedProperty(obj: widget.value['variables'], path: path) == null 
    ){
      setNestedProperty(obj: widget.value['variables'], path: path, value: default_text);
      setNestedProperty(obj: widget.value['internal_data'], path: path, value: '');
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
              ElmModuleList.updateAllModuleUI(appState: appState);
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
                setNestedProperty(obj: widget.value['internal_data'], path: path, value: inputValue);
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
        ],
      ),
      body: AnimatedList(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 200),
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
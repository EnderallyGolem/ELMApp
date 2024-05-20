import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';


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
    this.buttonWidth = 60,
    this.buttonHeight = 30,
  });

  final IconData iconData;
  final Color iconColor;
  final Function onPressFunctions;
  final double buttonWidth;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      //Copy Wave Button
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        minimumSize: Size(buttonWidth, buttonHeight),
        fixedSize: Size(buttonWidth, buttonHeight),
      ),
      onPressed: () {
        onPressFunctions();
      },
      child: Icon(
        iconData,
        color: iconColor,
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

  void dispose();
  void updateModuleState();
  void updateModuleCodeInMain({required elmModuleListArr});
  void importModuleCode({dynamic moduleCodeToAdd = ''});
}



class ElmModuleList<T extends GenericProviderState> extends StatefulWidget {
  final int moduleIndex;
  dynamic value;
  TextEditingController? controllers;
  String display = "";

  ElmModuleList({required this.moduleIndex, this.value = '', this.controllers = null}) {
    controllers ??= TextEditingController(text: value); //Sets a value if null
    display = '${moduleIndex + 1}';
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

  static void updateAllModule<T extends GenericProviderState>({required T appState}) {
    appState.updateModuleState();
    debugPrint('util_classes | updateAllModule: Updated all modules');
  }

  static void updateModuleValue<T extends GenericProviderState>({int moduleIndex = 0, dynamic newValue, required T appState}) {
    appState.elmModuleListArr[moduleIndex].value = newValue;
    appState.updateModuleState();
    debugPrint('util_classes | updateModuleValue: Updated module for index ${moduleIndex}. New value: ${newValue}');
  }

  static void updateModuleValueNoReload<T extends GenericProviderState>({int moduleIndex = 0, dynamic newValue, required T appState}) {
    appState.elmModuleListArr[moduleIndex].value = newValue;
    debugPrint('util_classes | updateModuleValueNoReload: Updated module for index ${moduleIndex}. New value: ${newValue}');
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
      return elmSingleModuleWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical);
    } else {
      return IntrinsicWidth(
        child: elmSingleModuleWidget(widget: widget, appGenericState: appGenericState, isVertical: isVertical),
      );
    }
  }
}

class elmSingleModuleWidget<T extends GenericProviderState> extends StatelessWidget {
  const elmSingleModuleWidget({
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
            Expanded(child: Text(widget.display)),
            //Shift Up
            ElmIconButton(iconData: isVertical ? Icons.arrow_upward : Icons.arrow_back, iconColor: appGenericState.themeColour, buttonWidth: 45,
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
            ElmIconButton(iconData: isVertical ? Icons.arrow_downward : Icons.arrow_forward, iconColor: appGenericState.themeColour, buttonWidth: 45,
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
            ElmIconButton(iconData: Icons.copy, iconColor: appGenericState.themeColour,
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
            ElmIconButton(iconData: Icons.delete, iconColor: appGenericState.themeColour, 
            onPressFunctions: (){
              //TO-DO: Option to disable warning
              Get.defaultDialog(title: 'waves_deletewave_warning_title'.tr, middleText:  'waves_deletewave_warning_desc'.tr, textCancel: 'Cancel'.tr, textConfirm: 'generic_confirm'.tr, onConfirm: (){
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
            ElmIconButton(iconData: Icons.add, iconColor: appGenericState.themeColour, 
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
          ],
        ),
        //SizedBox(height: 10),
        //Level Modules
        Focus(
          onFocusChange: (isFocused) {
            appGenericState.updateModuleState();
          },
          child: TextField(
            controller: widget.controllers,
            onChanged: (value) {
              // Update the value directly through the provider
              ElmModuleList.updateModuleValueNoReload(
                moduleIndex: widget.moduleIndex,
                newValue: value,
                appState: appGenericState,
              );
            },
          ),
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
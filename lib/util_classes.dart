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
  double buttonWidth;
  double buttonHeight;

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
// To use: Add the following below (change ProviderNewState to something else):

/*
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
*/

abstract class GenericProviderState {

  late List<ElmModuleList> elmModuleListArr = [];
  late bool allowCallback = false;
  late Color themeColour;
  late final GlobalKey<AnimatedListState> animatedModuleListKey;
  late bool updateCode;
  Type getProviderType();

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

  static Widget _buildAnimatedElmModuleList<T extends GenericProviderState>(int moduleIndex, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
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
      (context, animation) => _buildAnimatedElmModuleList<T>(moduleIndex, animation)
    );
  }

  static void addModuleBelow<T extends GenericProviderState>({required int moduleIndex, dynamic newValue = null, required T appState}) {
    moduleIndex = moduleIndex < -1 ? -1 : moduleIndex;
    moduleIndex = moduleIndex > appState.elmModuleListArr.length - 1 ? appState.elmModuleListArr.length - 2 : moduleIndex;
    appState.elmModuleListArr.insert(moduleIndex+1, ElmModuleList<T>(moduleIndex: moduleIndex, value: newValue)); //newValue will be new module list
    appState.animatedModuleListKey.currentState!.insertItem(
      moduleIndex+1, 
      duration: Duration(milliseconds: 150)
    );
    print('hu');
  }

  static void updateAllModule<T extends GenericProviderState>({int firstmoduleIndex = 0, required T appState}) {
    appState.updateModuleState();
    print(appState.elmModuleListArr);
    print('huaa');
  }

  static void updateModuleValue<T extends GenericProviderState>({int moduleIndex = 0, dynamic newValue, required T appState}) {
    appState.elmModuleListArr[moduleIndex].value = newValue;
    appState.updateModuleState();
    print('hua');
  }

  static void updateModuleValueNoReload<T extends GenericProviderState>({int moduleIndex = 0, dynamic newValue, required T appState}) {
    appState.elmModuleListArr[moduleIndex].value = newValue;
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

    return Column(
      key: ValueKey(widget.value),
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.display)),
            //Shift Up
            ElmIconButton(iconData: Icons.arrow_upward, iconColor: appGenericState.themeColour, buttonWidth: 45,
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
                  firstmoduleIndex: widget.moduleIndex,
                  appState: appGenericState,
                );
              }
            ),
            //Shift Down
            ElmIconButton(iconData: Icons.arrow_downward, iconColor: appGenericState.themeColour, buttonWidth: 45,
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
                  firstmoduleIndex: widget.moduleIndex,
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
                  firstmoduleIndex: widget.moduleIndex,
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
                  firstmoduleIndex: widget.moduleIndex,
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
                  firstmoduleIndex: widget.moduleIndex,
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
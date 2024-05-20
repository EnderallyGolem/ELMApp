import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '/util_classes.dart';
import 'package:get/get.dart';

class ProviderWaveState extends ChangeNotifier {

  static List<WaveModule> waveModuleArr = [];
  static bool allowCallback = false;
  static Color wavesColour = Color.fromARGB(255, 58, 104, 183);
  static ScrollController scrollController = ScrollController();
  static double scrollOffset = 0.0;

  void updateWaveState(){
    notifyListeners();                                    //Updates the displayed wave UI state
    updateWaveCodeInMain(waveModuleArr: waveModuleArr);   //Updates wave code in main.dart
    ProviderMainState.updateLevelCode();                  //Updates the full code in main.dart
  }

  //Generate the updated waveCode, then updates the waveCode in main.dart with it
  void updateWaveCodeInMain({required waveModuleArr}){

    dynamic waveCode = {
      "objects": [],
      "levelModules": [],
      "waveModules": [],
    };

    for (int waveIndex = 0; waveIndex < waveModuleArr.length; waveIndex++){
      //TO-DO: Proper updating of waveCode once the proper wave module format is made
      waveCode["objects"].add(waveModuleArr[waveIndex].value);
    }
    ProviderMainState.waveCode = waveCode;
  }

  static void importWaveCode({dynamic waveCodeToAdd = ''}){
    allowCallback = true;
    waveModuleArr = [];
    for(int waveIndex = 0; waveIndex < waveCodeToAdd.length; waveIndex++){
      waveModuleArr.insert(waveIndex, WaveModule(waveIndex: waveIndex, value: waveCodeToAdd[waveIndex].toString())); //TO-DO: Change value
    }
  }
}



//Each wave is a WaveModule class
//Each WaveModule class contains a bunch of EventModule classes [WHICH I HAVE NOT MADE. TO-DO]
///
/// Usage: WaveModule(value: [value])
/// [value] is the code in each wave. it is currently a string. well. that needs to be changed eventually.
///

class WaveModule extends StatefulWidget {
  final int waveIndex;
  dynamic value;
  TextEditingController? controllers;
  String display = "";

  WaveModule({required this.waveIndex, this.value = '', this.controllers = null}) {
    controllers ??= TextEditingController(text: value); //Sets a value if null
    display = '${'waves_wave'.tr} ${waveIndex + 1}';
  }

  static Widget _buildAnimatedWaveModule(int waveIndex, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: waveSizeTween(animation: animation),
        axis: Axis.vertical,
        axisAlignment: 0,
        child: WaveModule(waveIndex: waveIndex),
      ),
    );
  }
  static void deleteModule({required int waveIndex, required appWaveState, required context}) {
    ProviderWaveState.waveModuleArr.removeAt(waveIndex);
    animatedWaveListKey.currentState!.removeItem(
      waveIndex,
      duration: Duration(milliseconds: 150),
      (context, animation) => _buildAnimatedWaveModule(waveIndex, animation)
    );
  }

  static void addModuleBelow({required int waveIndex, dynamic newValue = null, required appWaveState}) {
    waveIndex = waveIndex < -1 ? -1 : waveIndex;
    waveIndex = waveIndex > ProviderWaveState.waveModuleArr.length - 1 ? ProviderWaveState.waveModuleArr.length - 2 : waveIndex;
    ProviderWaveState.waveModuleArr.insert(waveIndex+1, WaveModule(waveIndex: waveIndex, value: newValue)); //newValue will be new module list
    animatedWaveListKey.currentState!.insertItem(
      waveIndex+1, 
      duration: Duration(milliseconds: 150)
    );
  }

  static void updateAllModule({int firstWaveIndex = 0, required appWaveState}) {
    appWaveState.updateWaveState();
  }

  static void updateModuleValue({int waveIndex = 0, dynamic newValue, required appWaveState}) {
    ProviderWaveState.waveModuleArr[waveIndex].value = newValue;
    appWaveState.updateWaveState();
  }

  static void updateModuleValueNoReload({int waveIndex = 0, dynamic newValue, required appWaveState}) {
    ProviderWaveState.waveModuleArr[waveIndex].value = newValue;
  }

  @override
  State<WaveModule> createState() => _WaveModuleState();
}

class _WaveModuleState extends State<WaveModule> {

  @override
  void initState() {
    super.initState();
    if (ProviderWaveState.allowCallback) {
      //allowCallback is set to true if level is imported. This recreates the list when loaded.
      //This check is here to prevent callbacks constantly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ProviderWaveState.allowCallback = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //UI for each wave ------------------------------------------------------------------------------
    var appWaveState = context.watch<ProviderWaveState>();

    return Column(
      key: ValueKey(widget.value),
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.display)),
            //Shift Up
            ElmIconButton(iconData: Icons.arrow_upward, iconColor: ProviderWaveState.wavesColour, buttonWidth: 45,
              onPressFunctions: () {
                WaveModule.addModuleBelow(
                  waveIndex: widget.waveIndex - 2,
                  appWaveState: appWaveState,
                  newValue: widget.value,
                );
                WaveModule.deleteModule(
                  waveIndex: widget.waveIndex + 1, 
                  appWaveState: appWaveState, 
                  context: context,
                );
                WaveModule.updateAllModule(
                  firstWaveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
              }
            ),
            //Shift Down
            ElmIconButton(iconData: Icons.arrow_downward, iconColor: ProviderWaveState.wavesColour, buttonWidth: 45,
              onPressFunctions: () {
                WaveModule.addModuleBelow(
                  waveIndex: widget.waveIndex + 1,
                  appWaveState: appWaveState,
                  newValue: widget.value,
                );
                WaveModule.deleteModule(
                  waveIndex: widget.waveIndex, 
                  appWaveState: appWaveState, 
                  context: context,
                );
                WaveModule.updateAllModule(
                  firstWaveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
              }
            ),
            //Copy
            ElmIconButton(iconData: Icons.copy, iconColor: ProviderWaveState.wavesColour,
              onPressFunctions: () {
                WaveModule.addModuleBelow(
                  waveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                  newValue: widget.value,
                );
                WaveModule.updateAllModule(
                  firstWaveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
              }
            ),
            //Delete
            ElmIconButton(iconData: Icons.delete, iconColor: ProviderWaveState.wavesColour, 
            onPressFunctions: (){
              //TO-DO: Option to disable warning
              Get.defaultDialog(title: 'waves_deletewave_warning_title'.tr, middleText:  'waves_deletewave_warning_desc'.tr, textCancel: 'Cancel'.tr, textConfirm: 'generic_confirm'.tr, onConfirm: (){
                WaveModule.deleteModule(
                  waveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                  context: context
                );
                WaveModule.updateAllModule(
                  firstWaveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
                Get.back();
              });

            }),
            //Add
            ElmIconButton(iconData: Icons.add, iconColor: ProviderWaveState.wavesColour, 
              onPressFunctions:(){
                WaveModule.addModuleBelow(
                  waveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                  newValue: null,
                );
                WaveModule.updateAllModule(
                  firstWaveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
              }
            ),
          ],
        ),
        //SizedBox(height: 10),
        //Level Modules
        Focus(
          onFocusChange: (isFocused) {
            appWaveState.updateWaveState();
          },
          child: TextField(
            controller: widget.controllers,
            onChanged: (value) {
              // Update the value directly through the provider
              WaveModule.updateModuleValueNoReload(
                waveIndex: widget.waveIndex,
                newValue: value,
                appWaveState: appWaveState,
              );
            },
          ),
        ),
      ],
    );
  }
}


class Page_Wave extends StatefulWidget {
  @override
  _Page_WaveState createState() => _Page_WaveState();
}

final GlobalKey<AnimatedListState> animatedWaveListKey = GlobalKey<AnimatedListState>();
class _Page_WaveState extends State<Page_Wave> {
  @override
  void initState() {
    ProviderWaveState.scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProviderWaveState.scrollController.jumpTo(ProviderWaveState.scrollOffset); // Restore scroll position
    });
    super.initState();
  }
  void dispose() {
    super.dispose();
  }
  void _scrollListener() {
    if (mounted){
      ProviderWaveState.scrollOffset = ProviderWaveState.scrollController.offset;
    }
  }
  //UI for all waves ------------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    var appWaveState = context.watch<ProviderWaveState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('page_waves'.tr),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () {
              WaveModule.addModuleBelow(waveIndex: -1, newValue: null, appWaveState: appWaveState);
            },
            child: Row(children: [Icon(Icons.add, color: ProviderWaveState.wavesColour,), Text('waves_addwave'.tr, selectionColor: ProviderWaveState.wavesColour,)])
          ),
        ],
      ),
      body: AnimatedList(
        controller: ProviderWaveState.scrollController,
        scrollDirection: Axis.vertical,
        key: animatedWaveListKey,
        initialItemCount: ProviderWaveState.waveModuleArr.length,
        itemBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: waveSizeTween(animation: animation),
              axis: Axis.vertical,
              axisAlignment: 0,
              child: WaveModule(
                waveIndex: index,
                value: ProviderWaveState.waveModuleArr[index].value,
                controllers: ProviderWaveState.waveModuleArr[index].controllers,
              ),
            ),
          );
        },
      ),
    );
  }
}

dynamic waveSizeTween({required animation}) {
  return CurvedAnimation(
    parent: animation, // Use the provided animation
    curve: Curves.linear, // Apply an ease-out curve
  );
}
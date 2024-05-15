import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import '../main.dart';
//import '/util_classes.dart';


//TO-DO!!!!!!!!!!!!!! Swap out animatedlistplus for doing it manually because animatedlistplus dies with long lists :/

class ProviderWaveState extends ChangeNotifier {

  static List<WaveModule> waveModuleArr = [];
  static bool allowCallback = false;
  static Color wavesColour = Color.fromARGB(255, 58, 104, 183);
  static int nextId = 0;

  void updateWaveState(){
    notifyListeners();                                    //Updates the displayed wave UI state
    updateWaveCodeInMain(waveModuleArr: waveModuleArr);   //Updates wave code in main.dart
    ProviderMainState.updateLevelCode();                  //Updates the full code in main.dart
  }

  //Generate the updated waveCode, then updates the waveCode in main.dart with it
  static void updateWaveCodeInMain({required waveModuleArr}){

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
  int? id;
  dynamic value;
  TextEditingController? controllers;
  String display = "";

  WaveModule({required this.waveIndex, this.value = '', this.controllers = null, this.id = null}) {
    controllers ??= TextEditingController(text: value); //Sets a value if null
    display = 'Wave ${waveIndex + 1}: $value ID: ${id}';
    if(id == null){
      id = ProviderWaveState.nextId;
      ProviderWaveState.nextId++;
    }
  }

  static void deleteModule({required int waveIndex, required appWaveState, required context}) {
    ProviderWaveState.waveModuleArr.removeAt(waveIndex);
    updateAllModuleName(appWaveState: appWaveState, firstWaveIndex: waveIndex);
  }

  static void addModuleBelow({required int waveIndex, dynamic newValue = null, required appWaveState}) {
    ProviderWaveState.waveModuleArr.insert(waveIndex+1, WaveModule(waveIndex: waveIndex, value: newValue)); //newValue will be new module list
    updateAllModuleName(appWaveState: appWaveState, firstWaveIndex: waveIndex);
  }

  static void updateAllModuleName({int firstWaveIndex = 0, required appWaveState}) {
    if (firstWaveIndex < 0){ firstWaveIndex=0; }
    // for (firstWaveIndex; firstWaveIndex < ProviderWaveState.waveModuleArr.length; firstWaveIndex++) {
    //   ProviderWaveState.waveModuleArr[firstWaveIndex].display = 'Wave ${firstWaveIndex + 1}: ${ProviderWaveState.waveModuleArr[firstWaveIndex].value}';
    // }
    appWaveState.updateWaveState();
  }

  static void updateModule({int waveIndex = 0, dynamic newValue, required appWaveState}) {
    ProviderWaveState.waveModuleArr[waveIndex].value = newValue;
    appWaveState.updateWaveState();
  }

  static void updateModuleNoReload({int waveIndex = 0, dynamic newValue, required appWaveState}) {
    ProviderWaveState.waveModuleArr[waveIndex].value = newValue;
  }

  @override
  State<WaveModule> createState() => _WaveModuleState();
}

class _WaveModuleState extends State<WaveModule> {

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
    //UI for each wave ------------------------------------------------------------------------------
    var appWaveState = context.watch<ProviderWaveState>();
    return Column(
      key: ValueKey(widget.value),
      children: [
        Focus(
          onFocusChange: (isFocused) {
            appWaveState.updateWaveState();
          },
          child: TextField(
            controller: widget.controllers,
            onChanged: (value) {
              // Update the value directly through the provider
              WaveModule.updateModuleNoReload(
                waveIndex: widget.waveIndex,
                newValue: value,
                appWaveState: appWaveState,
              );
            },
            decoration: InputDecoration(
              labelText: '${widget.display}',
            ),
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                  WaveModule.deleteModule(
                    waveIndex: widget.waveIndex,
                    appWaveState: appWaveState,
                    context: context
                  );
              },
              child: Icon(
                Icons.delete, 
                color: ProviderWaveState.wavesColour,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                WaveModule.addModuleBelow(
                  waveIndex: widget.waveIndex,
                  appWaveState: appWaveState,
                );
              },
              child: Icon(
                Icons.add,
                color: ProviderWaveState.wavesColour,
              ),
            ),
          ],
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
  //UI for all waves ------------------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    var appWaveState = context.watch<ProviderWaveState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Waves'),
        backgroundColor: Color.fromARGB(255, 175, 214, 249),
        foregroundColor: Color.fromARGB(169, 3, 35, 105),
        actions: [
          ElevatedButton(
            onPressed: () {
              WaveModule.addModuleBelow(waveIndex: -1, newValue: null, appWaveState: appWaveState);
            },
            child: Row(children: [Icon(Icons.add, color: ProviderWaveState.wavesColour,), Text('Add Wave', selectionColor: ProviderWaveState.wavesColour,)])
          ),
        ],
      ),
      body: ImplicitlyAnimatedReorderableList<WaveModule>(
          onReorderFinished: (item, from, to, newItems) {
            WaveModule.deleteModule(appWaveState: appWaveState, context: context, waveIndex: from);
            WaveModule.addModuleBelow(appWaveState: appWaveState, newValue: item.value, waveIndex: to - 1);
          },
        insertDuration: Duration(milliseconds: 150),
        removeDuration: Duration(milliseconds: 150),
        updateDuration: Duration(milliseconds: 150),
        key: animatedWaveListKey,
        items: ProviderWaveState.waveModuleArr,
        areItemsTheSame: (a, b) => a.id == b.id,
        itemBuilder: (context, animation, item, index) {
          return Reorderable(
            // Each item must have an unique key.
            key: ValueKey(item),
            // The animation of the Reorderable builder can be used to
            // change to appearance of the item between dragged and normal
            // state. For example to add elevation when the item is being dragged.
            // This is not to be confused with the animation of the itemBuilder.
            // Implicit animations (like AnimatedContainer) are sadly not yet supported.
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final elevation = lerpDouble(0, 8, t);
              final color = Color.lerp(Colors.white, Colors.white.withOpacity(0.8), t);

              return SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
                animation: animation,
                // child: WaveModule(
                //   waveIndex: index,
                //   value: item.value,
                //   controllers: item.controllers,
                // ),
                child: Material(
                  color: color,
                  elevation: elevation!,
                  type: MaterialType.transparency,
                  child: SizedBox(
                    height: 150,
                    child: ListTile(
                      title: WaveModule(
                        waveIndex: index,
                        id: item.id,
                        value: item.value,
                        controllers: item.controllers,
                      ),
                      trailing: Handle(
                        delay: const Duration(milliseconds: 0),
                        child: Icon(
                          Icons.list,
                          color: ProviderWaveState.wavesColour,
                        ),
                      ),
                    ),
                  ),
                )
              );
            }
          );
        }
      )
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';


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

///
/// Usage: 
/// [value]
///
// class SingleModule extends StatefulWidget {
//   final int waveIndex;
//   dynamic value;
//   TextEditingController? controllers;
//   String display = "";

//   SingleModule({required this.waveIndex, this.value = '', this.controllers = null}) {
//     controllers ??= TextEditingController(text: value); //Sets a value if null
//     display = 'Wave ${waveIndex + 1}: $value';
//   }

//   static void deleteModule({required int waveIndex, required appWaveState, required context}) {
//     ProviderWaveState.SingleModuleArr.removeAt(waveIndex);
//   }

//   static void addModuleBelow({required int waveIndex, dynamic newValue = null, required appWaveState}) {
//     ProviderWaveState.SingleModuleArr.insert(waveIndex+1, SingleModule(waveIndex: waveIndex, value: newValue)); //newValue will be new module list
//     appWaveState.updateWaveState();
//   }

//   static void updateAllModuleName({int firstWaveIndex = 0, required appWaveState}) {
//     if (firstWaveIndex < 0){ firstWaveIndex=0; }
//     for (firstWaveIndex; firstWaveIndex < ProviderWaveState.SingleModuleArr.length; firstWaveIndex++) {
//       ProviderWaveState.SingleModuleArr[firstWaveIndex].display = 'Wave ${firstWaveIndex + 1}: ${ProviderWaveState.SingleModuleArr[firstWaveIndex].value}';
//     }
//     appWaveState.updateWaveState();
//   }

//   static void updateModule({int waveIndex = 0, dynamic newValue, required appWaveState}) {
//     ProviderWaveState.SingleModuleArr[waveIndex].value = newValue;
//     ProviderWaveState.SingleModuleArr[waveIndex].display = 'Wave ${waveIndex + 1}: ${newValue}';
//     appWaveState.updateWaveState();
//   }

//   static void updateModuleNoReload({int waveIndex = 0, dynamic newValue, required appWaveState}) {
//     ProviderWaveState.SingleModuleArr[waveIndex].value = newValue;
//     ProviderWaveState.SingleModuleArr[waveIndex].display = 'Wave ${waveIndex + 1}: ${newValue}';
//   }

//   @override
//   State<SingleModule> createState() => _SingleModuleState();
// }

// class _SingleModuleState extends State<SingleModule> {

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     //UI for each wave ------------------------------------------------------------------------------
//     var appWaveState = context.watch<ProviderWaveState>();
//     return Column(
//       key: ValueKey(widget.value),
//       children: [
//         Focus(
//           onFocusChange: (isFocused) {
//             appWaveState.updateWaveState();
//           },
//           child: TextField(
//             controller: widget.controllers,
//             onChanged: (value) {
//               // Update the value directly through the provider
//               SingleModule.updateModuleNoReload(
//                 waveIndex: widget.waveIndex,
//                 newValue: value,
//                 appWaveState: appWaveState,
//               );
//             },
//             decoration: InputDecoration(
//               labelText: '${widget.display}',
//             ),
//           ),
//         ),
//         SizedBox(height: 10),
//         Row(
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                   SingleModule.deleteModule(
//                     waveIndex: widget.waveIndex,
//                     appWaveState: appWaveState,
//                     context: context
//                   );
//                   SingleModule.updateAllModuleName(
//                     firstWaveIndex: widget.waveIndex,
//                     appWaveState: appWaveState,
//                   );
//               },
//               child: Icon(
//                 Icons.delete, 
//                 color: ProviderWaveState.wavesColour,
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 SingleModule.addModuleBelow(
//                   waveIndex: widget.waveIndex,
//                   appWaveState: appWaveState,
//                 );
//                 SingleModule.updateAllModuleName(
//                   firstWaveIndex: widget.waveIndex,
//                   appWaveState: appWaveState,
//                 );
//               },
//               child: Icon(
//                 Icons.add,
//                 color: ProviderWaveState.wavesColour,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }